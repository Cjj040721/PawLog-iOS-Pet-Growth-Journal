import SwiftUI

/// 成长视频：≥5 张照片按时间顺序合成竖屏视频（每张约 1.5s + 日期字幕）。
struct GrowthVideoView: View {
    let pet: Pet
    let photoRecords: [DayRecord]

    @State private var isExporting = false
    @State private var videoURL: URL?
    @State private var showShareSheet = false
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if isExporting {
                ProgressView("正在合成视频…")
            } else if let videoURL {
                Label("视频已生成", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                HStack(spacing: 24) {
                    Button {
                        Task { await saveToAlbum(videoURL) }
                    } label: {
                        Label("存相册", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("重新生成") {
                    self.videoURL = nil
                }
                .font(.footnote)
            } else {
                Label("共 \(photoRecords.count) 张照片，每张约 1.5 秒", systemImage: "film")
                    .foregroundStyle(.secondary)
                Button("生成成长视频") {
                    export()
                }
                .buttonStyle(.borderedProminent)
                .disabled(photoRecords.count < 5)
                if photoRecords.count < 5 {
                    Text("还差 \(5 - photoRecords.count) 张照片（需要 5 张）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("成长视频")
        .sheet(isPresented: $showShareSheet) {
            if let videoURL {
                ShareSheet(items: [videoURL])
            }
        }
    }

    private func export() {
        isExporting = true
        statusMessage = nil

        // 先提取标量 / 文件 URL，@Model 对象不跨 async 边界
        let frames: [GrowthVideoFrame] = photoRecords.compactMap { record in
            guard let filename = record.photoFilename else { return nil }
            return GrowthVideoFrame(
                imageURL: PhotoStore.url(for: filename),
                caption: caption(for: record)
            )
        }
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pawlog-growth-\(UUID().uuidString).mp4")

        Task { @MainActor in
            do {
                let url = try await GrowthVideoExporter.export(frames: frames, to: outputURL)
                isExporting = false
                videoURL = url
            } catch {
                isExporting = false
                statusMessage = "视频合成失败：\(error.localizedDescription)"
            }
        }
    }

    private func caption(for record: DayRecord) -> String {
        var parts = [record.date.pawLogShortFormatted]
        if let birthday = pet.birthday {
            parts.append(Date.ageDescription(from: birthday, to: record.date))
        } else if let adoption = pet.adoptionDate {
            parts.append("到家第 \(Date.daysTogether(from: adoption, to: record.date)) 天")
        }
        return parts.joined(separator: " · ")
    }

    private func saveToAlbum(_ url: URL) async {
        do {
            try await PhotoLibrarySaver.saveVideo(at: url)
            statusMessage = "已保存到相册"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
