import SwiftUI

struct MainTabView: View {
    let pet: Pet

    /// 调试专用：`-initialTab N` 指定启动 Tab（截图/走查用），默认 0。
    @State private var selection: Int = {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "-initialTab"), index + 1 < args.count,
              let tab = Int(args[index + 1]) else { return 0 }
        return tab
    }()

    var body: some View {
        TabView(selection: $selection) {
            Tab("时间线", systemImage: "calendar.day.timeline.left", value: 0) {
                NavigationStack {
                    TimelineView(pet: pet)
                }
            }
            Tab("体重", systemImage: "chart.line.uptrend.xyaxis", value: 1) {
                NavigationStack {
                    WeightChartView(pet: pet)
                }
            }
            Tab("回顾", systemImage: "play.rectangle.on.rectangle", value: 2) {
                NavigationStack {
                    ShareHomeView(pet: pet)
                }
            }
            Tab("我的", systemImage: "pawprint.fill", value: 3) {
                NavigationStack {
                    ProfileView(pet: pet)
                }
            }
        }
    }
}
