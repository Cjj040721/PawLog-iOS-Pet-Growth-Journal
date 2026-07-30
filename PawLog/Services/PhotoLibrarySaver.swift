import Photos
import UIKit

/// 相册写入（对比图 / 成长视频）。
/// 必须 nonisolated：performChanges 的回调在 Photos 的后台队列执行，
/// 若继承 MainActor 隔离，Swift 6 的运行时检查会 dispatch_assert_queue_fail 崩溃。
enum PhotoLibrarySaver {
    nonisolated static func saveImage(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw SaverError.permissionDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    nonisolated static func saveVideo(at url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw SaverError.permissionDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }

    enum SaverError: LocalizedError {
        case permissionDenied

        var errorDescription: String? { "没有相册写入权限，请在系统设置中开启" }
    }
}
