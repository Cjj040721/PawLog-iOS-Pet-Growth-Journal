import UIKit
@preconcurrency import AVFoundation

/// 成长视频的一帧：只携带标量 / 文件 URL，@Model 对象不跨 async 边界。
struct GrowthVideoFrame: Sendable {
    let imageURL: URL
    let caption: String
}

/// 用 AVAssetWriter + PixelBufferAdaptor 逐帧写入合成竖屏幻灯片视频（1080×1920, 30fps）。
/// 每张照片：aspect-fill 归一化 + 字幕烘焙成单张 CGImage；
/// 相邻照片之间 0.2s 交叉淡化（双图 alpha 混合）；逐帧 autoreleasepool 控内存，
/// 任一时刻只驻留「当前 + 上一张」两张全尺寸图，峰值内存与照片总数无关。
/// 字幕样式按 design/design-language.md §6.2：暖墨底 + 奶油字圆角底条。
enum GrowthVideoExporter {
    nonisolated static let canvasSize = CGSize(width: 1080, height: 1920)
    nonisolated static let secondsPerFrame: Double = 1.5
    nonisolated private static let fps: Int32 = 30
    nonisolated private static let fadeSeconds: Double = 0.2

    // §6.2 产出物配色：暖墨 #1E1712（底 / 字幕底条）、奶油 #EBE7E0（字）
    nonisolated private static let warmInk = UIColor(red: 0x1E / 255, green: 0x17 / 255, blue: 0x12 / 255, alpha: 1)
    nonisolated private static let cream = UIColor(red: 0xEB / 255, green: 0xE7 / 255, blue: 0xE0 / 255, alpha: 1)

    /// 逐帧写入视频。`progress` 在每个视频帧写入后回调（0...1，单调递增），在后台队列触发。
    nonisolated static func export(
        frames: [GrowthVideoFrame],
        to outputURL: URL,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        guard !frames.isEmpty else { throw ExportError.noFrames }
        try? FileManager.default.removeItem(at: outputURL)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(canvasSize.width),
            AVVideoHeightKey: Int(canvasSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 12_000_000,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps,
            ],
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            ]
        )
        guard writer.canAdd(input) else { throw ExportError.writerFailed }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? ExportError.writerFailed }
        writer.startSession(atSourceTime: .zero)

        let framesPerPhoto = Int(Double(fps) * secondsPerFrame) // 45
        let fadeFrames = Int(Double(fps) * fadeSeconds) // 6
        let totalVideoFrames = frames.count * framesPerPhoto

        var previous: CGImage?
        var written = 0
        for frame in frames {
            if Task.isCancelled {
                writer.cancelWriting()
                throw ExportError.cancelled
            }
            // 渲染路径(UIImage 解码 + renderer 位图)全在 autoreleasepool 内,
            // 否则中间位图堆到函数返回,120 帧峰值冲到 ~9GB(实测)
            guard let current = autoreleasepool(invoking: { renderPhotoFrame(frame) }) else { continue } // 读不出照片就跳过
            for local in 0..<framesPerPhoto {
                while !input.isReadyForMoreMediaData {
                    try await Task.sleep(for: .milliseconds(1))
                }
                // 本张照片窗口的前 fadeFrames 帧与上一张交叉淡化
                let fadeIn: Double = (previous != nil && local < fadeFrames)
                    ? Double(local + 1) / Double(fadeFrames + 1)
                    : 1
                let pts = CMTime(value: CMTimeValue(written), timescale: fps)
                autoreleasepool {
                    if let buffer = composite(current: current, previous: previous, fadeIn: fadeIn, adaptor: adaptor) {
                        adaptor.append(buffer, withPresentationTime: pts)
                    }
                }
                written += 1
                progress?(Double(written) / Double(totalVideoFrames))
            }
            previous = current
        }

        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else {
            throw writer.error ?? ExportError.writerFailed
        }
        return outputURL
    }

    /// 按 aspect-fill 把照片重绘到 1080×1920 画布（同时归一化 EXIF 方向），再烘焙字幕。
    private nonisolated static func renderPhotoFrame(_ frame: GrowthVideoFrame) -> CGImage? {
        guard let image = UIImage(contentsOfFile: frame.imageURL.path) else { return nil }
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let composed = renderer.image { _ in
            warmInk.setFill()
            UIRectFill(CGRect(origin: .zero, size: canvasSize))
            let scale = max(canvasSize.width / image.size.width, canvasSize.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: CGRect(
                x: (canvasSize.width - drawSize.width) / 2,
                y: (canvasSize.height - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            ))
            drawCaption(frame.caption)
        }
        return composed.cgImage
    }

    /// §6.2：奶油白 rounded semibold 56px，40% 暖墨圆角底条（半径 28，内边距 24×12），
    /// 底条下缘距画布底 260px。空字幕不画。
    private nonisolated static func drawCaption(_ text: String) {
        guard !text.isEmpty else { return }
        let base = UIFont.systemFont(ofSize: 56, weight: .semibold)
        let font = base.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: 56) } ?? base
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: cream]

        let maxTextWidth = canvasSize.width - 2 * 24 - 2 * 40 // 底条内边距 + 画布留白
        let textRect = (text as NSString).boundingRect(
            with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        let barRect = CGRect(
            x: (canvasSize.width - ceil(textRect.width) - 48) / 2,
            y: canvasSize.height - 260 - ceil(textRect.height) - 24,
            width: ceil(textRect.width) + 48,
            height: ceil(textRect.height) + 24
        )
        warmInk.withAlphaComponent(0.4).setFill()
        UIBezierPath(roundedRect: barRect, cornerRadius: 28).fill()
        (text as NSString).draw(
            in: CGRect(x: barRect.minX + 24, y: barRect.minY + 12, width: maxTextWidth, height: textRect.height),
            withAttributes: attributes
        )
    }

    /// 把「当前帧图」写入像素缓冲；fadeIn < 1 时与上一张做 alpha 混合（交叉淡化）。
    private nonisolated static func composite(
        current: CGImage,
        previous: CGImage?,
        fadeIn: Double,
        adaptor: AVAssetWriterInputPixelBufferAdaptor
    ) -> CVPixelBuffer? {
        guard let pool = adaptor.pixelBufferPool else { return nil }
        var pixelBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer) == kCVReturnSuccess,
              let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(canvasSize.width),
            height: Int(canvasSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }

        let rect = CGRect(origin: .zero, size: canvasSize)
        context.setFillColor(warmInk.cgColor)
        context.fill(rect)
        if fadeIn < 1, let previous {
            context.draw(previous, in: rect)
            context.setAlpha(fadeIn)
        }
        context.draw(current, in: rect)
        return buffer
    }

    enum ExportError: LocalizedError {
        case noFrames
        case writerFailed
        case cancelled

        var errorDescription: String? {
            switch self {
            case .noFrames: "没有可用于合成的照片"
            case .writerFailed: "视频合成失败"
            case .cancelled: "视频合成已取消"
            }
        }
    }
}
