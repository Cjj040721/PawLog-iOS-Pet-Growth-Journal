import SwiftUI
import PhotosUI
import AVFoundation

/// 「记录今天」完整流程：拍照（对比模式叠加最近一张照片）→ 填写体重/备注 → 保存。
/// 相机不可用（如模拟器）时降级为相册选图 + 叠加预览。
struct CaptureFlowView: View {
    /// NavigationPath 需要 Hashable，UIImage 本身不满足，用 id 包装。
    struct CapturedPhoto: Hashable {
        let id = UUID()
        let image: UIImage

        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    let pet: Pet
    var onDone: () -> Void

    @State private var path = NavigationPath()

    /// 最近一张有照片的记录，作为对比叠加层
    private var lastPhoto: UIImage? {
        let latest = pet.records
            .filter { $0.photoFilename != nil }
            .sorted { $0.date > $1.date }
            .first
        return PhotoStore.load(latest?.photoFilename)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if CameraViewController.isCameraAvailable {
                    CompareCameraView(overlay: lastPhoto) { image in
                        path.append(CapturedPhoto(image: image))
                    }
                } else {
                    FallbackPickerView(overlay: lastPhoto) { image in
                        path.append(CapturedPhoto(image: image))
                    }
                }
            }
            .navigationDestination(for: CapturedPhoto.self) { photo in
                DayRecordEditorView(pet: pet, image: photo.image, onDone: onDone)
                    .navigationTitle("记录今天")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onDone() }
                }
            }
        }
    }
}

// MARK: - 对比模式相机

private struct CompareCameraView: View {
    let overlay: UIImage?
    var onCapture: @MainActor @Sendable (UIImage) -> Void

    @State private var overlayOpacity: Double = 0.4
    @State private var captureToken = 0
    @State private var cameraAuthorized = false
    @State private var errorMessage: String?
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            if cameraAuthorized {
                CameraControllerRepresentable(
                    captureToken: captureToken,
                    onCaptured: onCapture,
                    onFailed: { message in errorMessage = message }
                )
                .ignoresSafeArea()

                if let overlay {
                    Image(uiImage: overlay)
                        .resizable()
                        .scaledToFill()
                        .opacity(overlayOpacity)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                Spacer()
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.6), in: Capsule())
                }
                if overlay != nil {
                    HStack {
                        Image(systemName: "square.stack")
                            .foregroundStyle(.white)
                        Slider(value: $overlayOpacity, in: 0...1)
                            .tint(.white)
                        Text("\(Int(overlayOpacity * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white)
                            .frame(width: 44)
                    }
                    .padding(.horizontal)
                }
                Button {
                    captureToken += 1
                } label: {
                    ZStack {
                        Circle().stroke(.white, lineWidth: 4).frame(width: 72, height: 72)
                        Circle().fill(.white).frame(width: 58, height: 58)
                    }
                }
                .disabled(!cameraAuthorized)

                // 不想拍照时也可以从相册选一张
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2), in: Capsule())
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(.black)
        .task {
            cameraAuthorized = await Self.requestCameraAccess()
            if !cameraAuthorized {
                errorMessage = "没有相机权限，请在系统设置中开启"
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onCapture(image)
                }
            }
        }
    }

    private static func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}

// MARK: - 模拟器 / 无相机降级：相册选图 + 叠加预览

private struct FallbackPickerView: View {
    let overlay: UIImage?
    var onPicked: (UIImage) -> Void

    @State private var overlayOpacity: Double = 0.4
    @State private var pickedItem: PhotosPickerItem?
    @State private var previewImage: UIImage?

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            if let overlay {
                Image(uiImage: overlay)
                    .resizable()
                    .scaledToFill()
                    .opacity(previewImage == nil ? 1 : overlayOpacity)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()
                if previewImage != nil, overlay != nil {
                    HStack {
                        Image(systemName: "square.stack")
                        Slider(value: $overlayOpacity, in: 0...1)
                        Text("\(Int(overlayOpacity * 100))%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 44)
                    }
                    .padding(.horizontal)
                }
                let pickerTitle = previewImage == nil ? "从相册选择照片" : "重新选择"
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label(pickerTitle, systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                if previewImage != nil {
                    Button("使用这张照片") {
                        if let previewImage { onPicked(previewImage) }
                    }
                    .font(.headline)
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 32)
        }
        .onChange(of: pickedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    previewImage = image
                }
            }
        }
    }
}
