import SwiftUI
import SwiftData

/// 成长时间线：照片日记 + 里程碑合并按日期倒序展示。
struct TimelineView: View {
    @Environment(AppStore.self) private var store
    let pet: Pet

    @State private var showCapture = false
    @State private var showMilestoneEditor = false

    private enum Item: Identifiable {
        case record(DayRecord)
        case milestone(Milestone)

        var id: PersistentIdentifier {
            switch self {
            case .record(let record): record.persistentModelID
            case .milestone(let milestone): milestone.persistentModelID
            }
        }

        var date: Date {
            switch self {
            case .record(let record): record.date
            case .milestone(let milestone): milestone.date
            }
        }
    }

    private var items: [Item] {
        let records = pet.records.map(Item.record)
        let milestones = pet.milestones.map(Item.milestone)
        return (records + milestones).sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                timelineList
            }
        }
        .navigationTitle(pet.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showCapture = true
                    } label: {
                        Label("记录今天", systemImage: "camera")
                    }
                    Button {
                        showMilestoneEditor = true
                    } label: {
                        Label("添加里程碑", systemImage: "star")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCapture) {
            CaptureFlowView(pet: pet) {
                showCapture = false
            }
        }
        .sheet(isPresented: $showMilestoneEditor) {
            NavigationStack {
                MilestoneEditView(pet: pet) {
                    showMilestoneEditor = false
                }
                .navigationTitle("添加里程碑")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有成长记录", systemImage: "camera.badge.ellipsis")
        } description: {
            Text("每天一张照片，见证 \(pet.name) 的长大")
        } actions: {
            Button("立即记录") {
                showCapture = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var timelineList: some View {
        List {
            ForEach(items) { item in
                switch item {
                case .record(let record):
                    DayRecordRow(record: record)
                case .milestone(let milestone):
                    MilestoneRow(milestone: milestone)
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct DayRecordRow: View {
    let record: DayRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let image = PhotoStore.load(record.photoFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.date.pawLogShortFormatted)
                        .font(.headline)
                    Spacer()
                    if let weight = record.weightKg {
                        Text(String(format: "%.1f kg", weight))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MilestoneRow: View {
    let milestone: Milestone

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .frame(width: 64, height: 64)
                .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.date.pawLogShortFormatted)
                    .font(.headline)
                Text(milestone.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
