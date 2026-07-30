import UIKit

/// 照片以 JPEG 文件形式存放在 App Group 容器中（app 与 widget 共享），@Model 只保存文件名。
enum PhotoStore {
    static let appGroupID = "group.com.junjia.pawlog.shared"

    static var baseURL: URL {
        let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return root.appendingPathComponent("Photos", isDirectory: true)
    }

    @discardableResult
    static func save(_ image: UIImage, quality: CGFloat = 0.85) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let directory = baseURL
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: directory.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func url(for filename: String) -> URL {
        baseURL.appendingPathComponent(filename)
    }

    static func load(_ filename: String?) -> UIImage? {
        guard let filename, !filename.isEmpty else { return nil }
        return UIImage(contentsOfFile: url(for: filename).path)
    }

    static func delete(_ filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        try? FileManager.default.removeItem(at: url(for: filename))
    }
}
