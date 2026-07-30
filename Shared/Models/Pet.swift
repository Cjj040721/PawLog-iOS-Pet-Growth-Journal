import Foundation
import SwiftData

@Model
final class Pet {
    var name: String = ""
    var breed: String?
    var birthday: Date?
    var adoptionDate: Date?
    var photoFilename: String?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \DayRecord.pet)
    var records: [DayRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \Milestone.pet)
    var milestones: [Milestone] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.pet)
    var reminders: [Reminder] = []

    init(
        name: String = "",
        breed: String? = nil,
        birthday: Date? = nil,
        adoptionDate: Date? = nil,
        photoFilename: String? = nil
    ) {
        self.name = name
        self.breed = breed
        self.birthday = birthday
        self.adoptionDate = adoptionDate
        self.photoFilename = photoFilename
        self.createdAt = Date()
    }
}
