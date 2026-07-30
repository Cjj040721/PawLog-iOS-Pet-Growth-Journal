import UIKit
import SwiftData

/// 调试专用：启动参数带 `-seedDemoData` 且无档案时，灌入一只演示宠物 + 8 天成长记录。
/// 仅用于模拟器截图和走查，正常使用不会触发。
enum DemoDataSeeder {
    @MainActor
    static func seedIfRequested(modelContext: ModelContext) {
        guard CommandLine.arguments.contains("-seedDemoData") else { return }
        let existing = (try? modelContext.fetchCount(FetchDescriptor<Pet>())) ?? 0
        guard existing == 0 else { return }

        let calendar = Calendar.current
        let today = Date().startOfDay
        let birthday = calendar.date(byAdding: .month, value: -2, to: today)
        let adoptionDate = calendar.date(byAdding: .day, value: -7, to: today)

        let pet = Pet(
            name: "豆豆",
            breed: "柯基",
            birthday: birthday,
            adoptionDate: adoptionDate,
            photoFilename: makePhoto(dayIndex: 7, label: "豆豆")
        )
        modelContext.insert(pet)

        // 8 天记录：体重从 2.4kg 长到 3.8kg
        for index in 0..<8 {
            let date = calendar.date(byAdding: .day, value: index - 7, to: today) ?? today
            let weight = 2.4 + Double(index) * 0.2
            let record = DayRecord(
                date: date,
                photoFilename: makePhoto(dayIndex: index, label: "第 \(index + 1) 天"),
                weightKg: (weight * 10).rounded() / 10,
                note: index == 7 ? "今天会坐下握手了！" : nil
            )
            record.pet = pet
            modelContext.insert(record)
        }

        if let adoptionDate {
            let milestone = Milestone(title: "第一天到家", date: adoptionDate)
            milestone.pet = pet
            modelContext.insert(milestone)
        }
        if let vaccineDate = calendar.date(byAdding: .day, value: -3, to: today) {
            let milestone = Milestone(title: "第一次打疫苗", date: vaccineDate)
            milestone.pet = pet
            modelContext.insert(milestone)
        }

        try? modelContext.save()
    }

    /// 程序化生成一张「照片」：不同色调渐变 + 文字，便于在时间线/视频里区分天数。
    @MainActor
    private static func makePhoto(dayIndex: Int, label: String) -> String? {
        let size = CGSize(width: 1080, height: 1350)
        let hue = (Double(dayIndex) * 0.09).truncatingRemainder(dividingBy: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor(hue: hue, saturation: 0.55, brightness: 0.9, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(hue: (hue + 0.12).truncatingRemainder(dividingBy: 1), saturation: 0.6, brightness: 0.75, alpha: 1).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 140, y: 700, width: 800, height: 520))

            let text = label as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 120),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(x: (size.width - textSize.width) / 2, y: 300),
                withAttributes: attributes
            )
        }
        return PhotoStore.save(image)
    }
}
