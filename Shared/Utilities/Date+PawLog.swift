import Foundation

extension Date {
    nonisolated var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 「在一起第 N 天」：基准日当天为第 1 天。
    nonisolated static func daysTogether(from base: Date, to date: Date = Date()) -> Int {
        let days = Calendar.current.dateComponents([.day], from: base.startOfDay, to: date.startOfDay).day ?? 0
        return max(1, days + 1)
    }

    /// 年龄描述，用于对比图标注：不满 1 个月按天，之后按月。
    nonisolated static func ageDescription(from birthday: Date, to date: Date) -> String {
        let months = Calendar.current.dateComponents([.month], from: birthday.startOfDay, to: date.startOfDay).month ?? 0
        if months >= 1 {
            return "\(months) 个月大"
        }
        let days = Calendar.current.dateComponents([.day], from: birthday.startOfDay, to: date.startOfDay).day ?? 0
        return "出生第 \(max(1, days + 1)) 天"
    }

    var pawLogShortFormatted: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}
