#if DEBUG
import SwiftUI

/// 截图走查专用(仅 DEBUG,与 -seedDemoData / -initialTab 同类):
/// `-debugCompareCard` 直接展示对比图产出物卡片;`-debugWidget` 展示小组件样式(systemSmall 尺寸)。
/// 模拟器无法点选照片/添加小组件,用这两个入口做视觉验收,不进 Release。
enum DebugWalkthrough {
    static var compareCardRequested: Bool { CommandLine.arguments.contains("-debugCompareCard") }
    static var widgetRequested: Bool { CommandLine.arguments.contains("-debugWidget") }
}

struct DebugCompareCardScreen: View {
    private let firstImage = DebugWalkthrough.demoImage(top: .systemOrange, bottom: .systemBrown)
    private let secondImage = DebugWalkthrough.demoImage(top: .systemTeal, bottom: .systemIndigo)

    var body: some View {
        ScrollView {
            // 与 CompareView.render() 同路径:ImageRenderer scale=2,预览 scaledToFit
            Image(uiImage: renderedCard())
                .resizable()
                .scaledToFit()
                .padding()
        }
        .background(Color.pawBg)
    }

    private func renderedCard() -> UIImage {
        let card = CompareCardView(
            firstImage: firstImage,
            firstLabel: "2026-07-01 · 到家第 7 天",
            secondImage: secondImage,
            secondLabel: "2026-07-30 · 到家第 36 天"
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }
}

struct DebugWidgetScreen: View {
    var body: some View {
        ZStack {
            Color.pawBg.ignoresSafeArea()
            // containerBackground 只在真小组件里生效,走查页用同色圆角底模拟 systemSmall
            PawLogWidgetEntryView(entry: PetWidgetEntry(
                date: Date(),
                petName: "豆豆",
                daysTogether: 42,
                photoData: nil
            ))
            .frame(width: 170, height: 170)
            .background(Color.pawSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(radius: 8, y: 4)
        }
    }
}

private extension DebugWalkthrough {
    static func demoImage(top: UIColor, bottom: UIColor) -> UIImage {
        let size = CGSize(width: 600, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            top.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height / 2)))
            bottom.setFill()
            ctx.fill(CGRect(x: 0, y: size.height / 2, width: size.width, height: size.height / 2))
        }
    }
}
#endif
