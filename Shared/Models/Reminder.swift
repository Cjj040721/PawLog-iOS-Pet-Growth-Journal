import Foundation
import SwiftData

enum ReminderType: String, CaseIterable, Identifiable, Codable, Sendable {
    case vaccine
    case deworm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vaccine: "疫苗"
        case .deworm: "驱虫"
        }
    }
}

@Model
final class Reminder {
    var typeRaw: String = ReminderType.vaccine.rawValue
    var dueDate: Date = Date()
    var notificationID: String = ""
    var pet: Pet?

    var type: ReminderType {
        get { ReminderType(rawValue: typeRaw) ?? .vaccine }
        set { typeRaw = newValue.rawValue }
    }

    init(type: ReminderType, dueDate: Date, notificationID: String = UUID().uuidString) {
        self.typeRaw = type.rawValue
        self.dueDate = dueDate
        self.notificationID = notificationID
    }
}
