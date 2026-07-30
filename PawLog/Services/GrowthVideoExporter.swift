import UIKit
@preconcurrency import AVFoundation

/// 成长视频的一帧：只携带标量 / 文件 URL，@Model 对象不跨 async 边界。
struct GrowthVideoFrame: Sendable {
    let imageURL: URL
    let caption: String
}

/// 用 AVMutableComposition + CoreAnimationTool 合成竖屏幻灯片视频。
/// 整张画布由 CALayer 树渲染（图片 + 日期字幕），底层 composition 只有空时间区间。
enum GrowthVideoExporter {
    nonisolated static let canvasSize = CGSize(width: 1080, height: 1920)
    nonisolated static let secondsPerFrame: Double = 1.5

    nonisolated static func export(frames: [GrowthVideoFrame], to outputURL: URL) async throws -> URL {
        guard !frames.isEmpty else { throw ExportError.noFrames }
        try? FileManager.default.removeItem(at: outputURL)

        let timescale: CMTimeScale = 600
        let frameDuration = CMTime(seconds: secondsPerFrame, preferredTimescale: timescale)

        // 1. composition：只建立总时长（全部为空区间，画面由 animationTool 的 CALayer 提供）
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { throw ExportError.compositionFailed }

        var cursor = CMTime.zero
        for _ in frames {
            videoTrack.insertEmptyTimeRange(CMTimeRange(start: cursor, duration: frameDuration))
            cursor = cursor + frameDuration
        }
        let totalSeconds = CMTimeGetSeconds(cursor)

        // 2. CALayer 树：每张图 + 字幕各一层，用 opacity 关键帧动画控制出现窗口
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: canvasSize)
        parentLayer.backgroundColor = UIColor.black.cgColor

        let videoLayer = CALayer()
        videoLayer.frame = parentLayer.frame
        parentLayer.addSublayer(videoLayer)

        let fade: Double = 0.2 // 淡入淡出各 0.2s
        for (index, frame) in frames.enumerated() {
            let start = Double(index) * secondsPerFrame
            let end = start + secondsPerFrame

            if let imageLayer = makeImageLayer(url: frame.imageURL) {
                imageLayer.add(visibilityAnimation(start: start, end: end, total: totalSeconds, fade: fade), forKey: nil)
                videoLayer.addSublayer(imageLayer)
            }

            let captionLayer = makeCaptionLayer(text: frame.caption)
            captionLayer.add(visibilityAnimation(start: start, end: end, total: totalSeconds, fade: fade), forKey: nil)
            videoLayer.addSublayer(captionLayer)
        }

        // 3. videoComposition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = canvasSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: cursor)
        instruction.backgroundColor = UIColor.black.cgColor
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        // 4. 导出
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.compositionFailed
        }
        try await exportSession.export(to: outputURL, as: .mp4)
        return outputURL
    }

    // 按 aspect-fill 把照片重绘到 1080x1920 画布（同时归一化 EXIF 方向）
    nonisolated private static func makeImageLayer(url: URL) -> CALayer? {
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let normalized = renderer.image { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(origin: .zero, size: canvasSize))
            let scale = max(canvasSize.width / image.size.width, canvasSize.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let drawRect = CGRect(
                x: (canvasSize.width - drawSize.width) / 2,
                y: (canvasSize.height - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            )
            image.draw(in: drawRect)
        }
        guard let cgImage = normalized.cgImage else { return nil }
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: canvasSize)
        layer.contents = cgImage
        layer.opacity = 0
        return layer
    }

    nonisolated private static func makeCaptionLayer(text: String) -> CATextLayer {
        let layer = CATextLayer()
        layer.string = text
        layer.fontSize = 56
        layer.font = UIFont.boldSystemFont(ofSize: 56)
        layer.foregroundColor = UIColor.white.cgColor
        layer.alignmentMode = .center
        layer.contentsScale = 1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 8
        layer.shadowOffset = .zero
        layer.frame = CGRect(x: 0, y: canvasSize.height - 260, width: canvasSize.width, height: 120)
        layer.opacity = 0
        return layer
    }

    /// 关键帧动画：在 [start, end] 窗口内可见，带淡入淡出；窗口外完全透明。
    nonisolated private static func visibilityAnimation(start: Double, end: Double, total: Double, fade: Double) -> CAKeyframeAnimation {
        let clampedTotal = max(total, end)
        func t(_ seconds: Double) -> NSNumber {
            NSNumber(value: min(max(seconds / clampedTotal, 0), 1))
        }
        let fadeInEnd = min(start + fade, end)
        let fadeOutStart = max(end - fade, fadeInEnd)

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0, 0, 1, 1, 0, 0]
        animation.keyTimes = [
            0,
            t(start),
            t(fadeInEnd),
            t(fadeOutStart),
            t(end),
            1
        ]
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = clampedTotal
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        return animation
    }

    enum ExportError: LocalizedError {
        case noFrames
        case compositionFailed

        var errorDescription: String? {
            switch self {
            case .noFrames: "没有可用于合成的照片"
            case .compositionFailed: "视频合成失败"
            }
        }
    }
}
