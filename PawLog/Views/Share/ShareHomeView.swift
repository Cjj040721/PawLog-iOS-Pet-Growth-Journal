import SwiftUI

/// 「回顾」入口页：对比图（≥2 张照片）、成长视频（≥5 张照片）；不满足时禁用并提示还差几张。
struct ShareHomeView: View {
    let pet: Pet

    private var photoRecords: [DayRecord] {
        pet.records
            .filter { $0.photoFilename != nil }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    CompareView(pet: pet, photoRecords: photoRecords)
                } label: {
                    Label("生成对比图", systemImage: "rectangle.split.2x1")
                }
                .disabled(photoRecords.count < 2)
                if photoRecords.count < 2 {
                    Text("还差 \(2 - photoRecords.count) 张照片（需要 2 张）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("对比图")
            }

            Section {
                NavigationLink {
                    GrowthVideoView(pet: pet, photoRecords: photoRecords)
                } label: {
                    Label("生成成长视频", systemImage: "play.rectangle")
                }
                .disabled(photoRecords.count < 5)
                if photoRecords.count < 5 {
                    Text("还差 \(5 - photoRecords.count) 张照片（需要 5 张）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("成长视频")
            }
        }
        .navigationTitle("回顾")
    }
}
