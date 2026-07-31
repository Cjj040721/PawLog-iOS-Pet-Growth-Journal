import WidgetKit
import SwiftUI

/// 小组件的 entry 与视图放在 Shared:app target 的调试走查页(-debugWidget)可直接渲染同一份代码。
struct PetWidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let petName: String?
    let daysTogether: Int?
    let photoData: Data?

    static let placeholder = PetWidgetEntry(date: Date(), petName: "宠物", daysTogether: 1, photoData: nil)
}

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
                // 无照片占位:pawFill 圆 + pawPrimary 爪印(§7)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.pawPrimary)
                    .frame(width: 56, height: 56)
                    .background(Color.pawFill, in: Circle())
            }

            if let name = entry.petName, let days = entry.daysTogether {
                // 情感大数字:rounded bold + 文字级 pawPrimaryStrong(§2/§7)
                Text("第 \(days) 天")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.pawPrimaryStrong)
                Text(name)
                    .font(.caption)
                    .foregroundStyle(Color.pawTextSecondary)
            } else {
                Text("打开 PawLog 创建档案")
                    .font(.caption)
                    .foregroundStyle(Color.pawTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.pawSurface, for: .widget)
    }
}
