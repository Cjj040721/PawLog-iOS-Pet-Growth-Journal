import Foundation

/// 小组件「在一起第 N 天」的计数基准，通过 App Group UserDefaults 共享给 widget。
enum CountBase: String, CaseIterable, Identifiable, Sendable {
    case adoption
    case birthday

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adoption: "领养日"
        case .birthday: "生日"
        }
    }
}

enum WidgetSharedSettings {
    private static let countBaseKey = "dayCountBase"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: PhotoStore.appGroupID)
    }

    static var countBase: CountBase {
        get {
            guard let raw = defaults?.string(forKey: countBaseKey),
                  let base = CountBase(rawValue: raw) else {
                return .adoption // 默认领养日
            }
            return base
        }
        set {
            defaults?.set(newValue.rawValue, forKey: countBaseKey)
        }
    }
}
