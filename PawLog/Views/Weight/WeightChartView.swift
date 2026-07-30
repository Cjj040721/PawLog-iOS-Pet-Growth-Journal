import SwiftUI
import Charts

/// 体重曲线：1 个月 / 3 个月 / 全部；不足 2 条含体重记录时显示空状态。
struct WeightChartView: View {
    let pet: Pet

    private enum Range: String, CaseIterable, Identifiable {
        case month = "1 个月"
        case threeMonths = "3 个月"
        case all = "全部"

        var id: String { rawValue }
    }

    @State private var range: Range = .month

    private struct Point: Identifiable {
        let date: Date
        let weight: Double
        var id: Date { date }
    }

    private var allPoints: [Point] {
        pet.records
            .compactMap { record in
                record.weightKg.map { Point(date: record.date, weight: $0) }
            }
            .sorted { $0.date < $1.date }
    }

    private var visiblePoints: [Point] {
        guard range != .all else { return allPoints }
        let months = range == .month ? 1 : 3
        guard let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else {
            return allPoints
        }
        return allPoints.filter { $0.date >= cutoff }
    }

    var body: some View {
        VStack {
            Picker("范围", selection: $range) {
                ForEach(Range.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if visiblePoints.count >= 2 {
                Chart(visiblePoints) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("体重 (kg)", point.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("日期", point.date),
                        y: .value("体重 (kg)", point.weight)
                    )
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .padding()
                Spacer()
            } else {
                Spacer()
                ContentUnavailableView {
                    Label("暂无体重曲线", systemImage: "chart.line.downtrend.xyaxis")
                } description: {
                    Text("记录至少两次体重后生成曲线")
                }
                Spacer()
            }
        }
        .navigationTitle("体重")
    }
}
