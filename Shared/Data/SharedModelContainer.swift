import Foundation
import SwiftData

/// app 与 widget extension 共用的 SwiftData 容器（存储在 App Group 容器中）。
/// App Group 不可用（如个人账号签名受限）时自动降级为应用内本地存储，保证 app 可用。
enum SharedModelContainer {
    static let schema = Schema([Pet.self, DayRecord.self, Milestone.self, Reminder.self])

    static func make() -> ModelContainer {
        let groupConfiguration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(PhotoStore.appGroupID)
        )
        if let container = try? ModelContainer(for: schema, configurations: [groupConfiguration]) {
            return container
        }
        let localConfiguration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [localConfiguration])
        } catch {
            fatalError("无法创建 SwiftData 容器: \(error)")
        }
    }
}
