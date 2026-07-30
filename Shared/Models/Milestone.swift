import Foundation
import SwiftData

@Model
final class Milestone {
    var title: String = ""
    var date: Date = Date()
    var pet: Pet?

    init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
}
