import SwiftUI
import SwiftData

/// 对比图：挑选两张照片，左右分屏 + 各自日期 / 年龄标注，ImageRenderer 渲染后可存相册或分享。
struct CompareView: View {
    let pet: Pet
    let photoRecords: [DayRecord]

    @State private var selected: [PersistentIdentifier] = []
    @State private var renderedImage: UIImage?
    @State private var showShareSheet = false
    @State private var statusMessage: String?

    private var selectedRecords: [DayRecord] {
        photoRecords.filter { selected.contains($0.persistentModelID) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 16) {
            if let renderedImage {
                Image(uiImage: renderedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                HStack(spacing: 24) {
                    Button {
                        Task { await saveToAlbum(renderedImage) }
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

                Button("重新选择照片") {
                    self.renderedImage = nil
                    selected = []
                }
                .font(.footnote)
            } else {
                Text("选择两张照片")
                    .font(.headline)
                    .padding(.top)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(photoRecords) { record in
                            photoCell(record)
                        }
                    }
                    .padding(.horizontal)
                }

                Button("生成对比图") {
                    render()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected.count != 2)
                .padding(.bottom)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("对比图")
        .sheet(isPresented: $showShareSheet) {
            if let renderedImage {
                ShareSheet(items: [renderedImage])
            }
        }
    }

    private func photoCell(_ record: DayRecord) -> some View {
        let isSelected = selected.contains(record.persistentModelID)
        return Button {
            if isSelected {
                selected.removeAll { $0 == record.persistentModelID }
            } else if selected.count < 2 {
                selected.append(record.persistentModelID)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                if let image = PhotoStore.load(record.photoFilename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 100, minHeight: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, .tint)
                        .padding(6)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
    }

    private func render() {
        let pair = selectedRecords
        guard pair.count == 2,
              let first = PhotoStore.load(pair[0].photoFilename),
              let second = PhotoStore.load(pair[1].photoFilename) else { return }

        let card = CompareCardView(
            firstImage: first,
            firstLabel: label(for: pair[0]),
            secondImage: second,
            secondLabel: label(for: pair[1])
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        renderedImage = renderer.uiImage
    }

    /// 日期 + 年龄（优先按生日算月龄，没有生日则按到家天数）
    private func label(for record: DayRecord) -> String {
        var parts = [record.date.pawLogShortFormatted]
        if let birthday = pet.birthday {
            parts.append(Date.ageDescription(from: birthday, to: record.date))
        } else if let adoption = pet.adoptionDate {
            parts.append("到家第 \(Date.daysTogether(from: adoption, to: record.date)) 天")
        }
        return parts.joined(separator: " · ")
    }

    private func saveToAlbum(_ image: UIImage) async {
        do {
            try await PhotoLibrarySaver.saveImage(image)
            statusMessage = "已保存到相册"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

/// 被 ImageRenderer 渲染的对比卡片（1080pt 宽逻辑尺寸，scale=2 输出）
struct CompareCardView: View {
    let firstImage: UIImage
    let firstLabel: String
    let secondImage: UIImage
    let secondLabel: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                CompareHalf(image: firstImage)
                CompareHalf(image: secondImage)
            }
            .frame(width: 540, height: 540)
            .clipped()

            HStack(spacing: 0) {
                Text(firstLabel)
                    .frame(maxWidth: .infinity)
                Text(secondLabel)
                    .frame(maxWidth: .infinity)
            }
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .background(.black)
        }
        .frame(width: 540)
    }
}

/// 对比图的一侧：完整显示照片（scaledToFit），四周留白，空白处用同图的模糊放大填充，不裁切主体。
private struct CompareHalf: View {
    let image: UIImage

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .blur(radius: 50)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(20)
        }
        .frame(width: 270, height: 540)
        .background(.black)
        .clipped()
    }
}
