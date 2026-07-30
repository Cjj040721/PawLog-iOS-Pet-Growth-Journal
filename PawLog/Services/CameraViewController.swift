import UIKit
import SwiftUI
@preconcurrency import AVFoundation

/// 拍照结果回调，统一在 MainActor 派发。
final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let onResult: @MainActor @Sendable (UIImage?) -> Void

    nonisolated init(onResult: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        self.onResult = onResult
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        let image = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        Task { @MainActor in
            onResult(image)
        }
    }
}

/// 自定义相机取景控制器。
///
/// 并发说明（遵循 ios-standards）：
/// - UIViewController 由 UIKit 标注为 @MainActor，UI 代码保持 MainActor 隔离；
/// - AVCaptureSession 的 configure / startRunning / capturePhoto 全部在专用串行队列执行，
///   相关属性标记 nonisolated(unsafe)，相关方法标记 nonisolated（方法级隔离而非类级）；
/// - deinit 必须是 nonisolated，只做非隔离清理。
final class CameraViewController: UIViewController {
    private nonisolated(unsafe) let session = AVCaptureSession()
    private nonisolated(unsafe) let photoOutput = AVCapturePhotoOutput()
    private nonisolated(unsafe) var captureDelegate: PhotoCaptureDelegate?
    private nonisolated(unsafe) var isConfigured = false

    private let sessionQueue = DispatchQueue(label: "com.pawlog.camera.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?

    var onCaptured: (@MainActor (UIImage) -> Void)?
    var onFailed: (@MainActor (String) -> Void)?

    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera) && AVCaptureDevice.default(for: .video) != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        previewLayer = preview

        sessionQueue.async { [weak self] in
            self?.configureAndStart()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    nonisolated deinit {
        if session.isRunning {
            session.stopRunning()
        }
    }

    // MARK: - Session（仅在 sessionQueue 上调用）

    nonisolated private func configureAndStart() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(photoOutput)
        else {
            session.commitConfiguration()
            notifyFailure("相机不可用")
            return
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        // 必须先 commit 配置再 startRunning，否则 session 会抛 NSException
        session.commitConfiguration()
        isConfigured = true
        session.startRunning()
    }

    // MARK: - Capture

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured else { return }
            let settings = AVCapturePhotoSettings()
            let delegate = PhotoCaptureDelegate { [weak self] image in
                guard let self else { return }
                if let image {
                    self.onCaptured?(image)
                } else {
                    self.onFailed?("拍照失败，请重试")
                }
            }
            self.captureDelegate = delegate
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    nonisolated private func notifyFailure(_ message: String) {
        Task { @MainActor [weak self] in
            self?.onFailed?(message)
        }
    }
}

/// SwiftUI 包装。captureToken 递增一次触发一次拍照。
struct CameraControllerRepresentable: UIViewControllerRepresentable {
    var captureToken: Int
    var onCaptured: @MainActor @Sendable (UIImage) -> Void
    var onFailed: @MainActor @Sendable (String) -> Void

    final class Coordinator {
        var lastToken = 0
        weak var viewController: CameraViewController?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onCaptured = onCaptured
        controller.onFailed = onFailed
        context.coordinator.viewController = controller
        context.coordinator.lastToken = captureToken
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.onCaptured = onCaptured
        uiViewController.onFailed = onFailed
        if context.coordinator.lastToken != captureToken {
            context.coordinator.lastToken = captureToken
            uiViewController.capturePhoto()
        }
    }
}
