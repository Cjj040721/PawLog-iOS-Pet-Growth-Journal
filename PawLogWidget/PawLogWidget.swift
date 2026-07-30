import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline

struct PetWidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let petName: String?
    let daysTogether: Int?
    let photoData: Data?

    static let placeholder = PetWidgetEntry(date: Date(), petName: "宠物", daysTogether: 1, photoData: nil)
}

/// WidgetKit 的 completion 不是 Sendable，strict concurrency 下需要显式包装后跨隔离传递。
private struct CompletionBox<T>: @unchecked Sendable {
    let handler: (T) -> Void

    func callAsFunction(_ value: T) { handler(value) }
}

struct PetWidgetProvider: TimelineProvider {
    /// 共享容器在 extension 进程内只建一次
    private nonisolated(unsafe) static var cachedContainer: ModelContainer?

    func placeholder(in context: Context) -> PetWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PetWidgetEntry) -> Void) {
        let box = CompletionBox(handler: completion)
        Task { @MainActor in
            box(loadEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetWidgetEntry>) -> Void) {
        let box = CompletionBox(handler: completion)
        Task { @MainActor in
            let entry = loadEntry()
            // 每天 0 点后刷新一次，保证「第 N 天」每天更新
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date().startOfDay) ?? Date().addingTimeInterval(86400)
            box(Timeline(entries: [entry], policy: .after(tomorrow)))
        }
    }

    @MainActor
    private func loadEntry() -> PetWidgetEntry {
        if Self.cachedContainer == nil {
            Self.cachedContainer = SharedModelContainer.make()
        }
        guard let container = Self.cachedContainer else { return .placeholder }

        let context = ModelContext(container)
        guard let pet = try? context.fetch(FetchDescriptor<Pet>()).first else {
            return PetWidgetEntry(date: Date(), petName: nil, daysTogether: nil, photoData: nil)
        }

        // 计数基准：用户在档案页选择（共享 UserDefaults），默认领养日，未填则用生日
        let baseDate: Date? = switch WidgetSharedSettings.countBase {
        case .adoption: pet.adoptionDate ?? pet.birthday
        case .birthday: pet.birthday ?? pet.adoptionDate
        }
        let days = baseDate.map { Date.daysTogether(from: $0) }

        let photoData: Data? = pet.photoFilename.flatMap { filename in
            let url = PhotoStore.url(for: filename)
            guard let image = UIImage(contentsOfFile: url.path),
                  let downscaled = image.preparingThumbnail(of: CGSize(width: 400, height: 400)) else {
                return nil
            }
            return downscaled.jpegData(compressionQuality: 0.8)
        }

        return PetWidgetEntry(date: Date(), petName: pet.name, daysTogether: days, photoData: photoData)
    }
}

// MARK: - View

struct PawLogWidgetEntryView: View {
    let entry: PetWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            if let data = entry.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }

            if let name = entry.petName, let days = entry.daysTogether {
                Text("在一起第 \(days) 天")
                    .font(.headline)
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("打开 PawLog 创建档案")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget

struct PawLogWidget: Widget {
    let kind = "PawLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetWidgetProvider()) { entry in
            PawLogWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("PawLog")
        .description("看看今天是在一起的第几天")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct PawLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        PawLogWidget()
    }
}
