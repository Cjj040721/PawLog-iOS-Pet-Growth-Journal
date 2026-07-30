import Foundation
import SwiftData

/// 照片日记：同一天（按自然日）一条，重复记录为更新。
@Model
final class DayRecord {
    var date: Date = Date() // 已归一化为当天 0 点
    var photoFilename: String?
    var weightKg: Double?
    var note: String?
    var pet: Pet?

    init(date: Date, photoFilename: String? = nil, weightKg: Double? = nil, note: String? = nil) {
        self.date = date.startOfDay
        self.photoFilename = photoFilename
        self.weightKg = weightKg
        self.note = note
    }
}
