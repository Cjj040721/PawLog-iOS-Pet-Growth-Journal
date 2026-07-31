import SwiftUI

/// 设计令牌:颜色 / 圆角 / 间距 / 动效 / 主按钮 / 空状态,唯一依据 design/design-language.md。
/// 色值在 Shared/DesignTokens.xcassets(colorset 深浅双值,两个 target 都编译),
/// 这里按名集中定义,界面只引用常量,不手写 hex。
extension Color {
    // 品牌色(§1.1);文字级着色一律用 pawPrimaryStrong(对比度 5.1:1)
    // 全部 nonisolated:SwiftUI 部分 ViewBuilder 闭包是非隔离上下文(坑清单 #3)
    nonisolated static let pawPrimary = Color("pawPrimary")
    nonisolated static let pawPrimaryStrong = Color("pawPrimaryStrong")
    nonisolated static let pawPrimarySoft = Color("pawPrimarySoft")
    // 中性色(§1.2)
    nonisolated static let pawBg = Color("pawBg")
    nonisolated static let pawSurface = Color("pawSurface")
    nonisolated static let pawFill = Color("pawFill")
    nonisolated static let pawText = Color("pawText")
    nonisolated static let pawTextSecondary = Color("pawTextSecondary")
    nonisolated static let pawSeparator = Color("pawSeparator")
    // 语义色(§1.3)
    nonisolated static let pawSuccess = Color("pawSuccess")
    nonisolated static let pawWarning = Color("pawWarning")
    nonisolated static let pawWarningText = Color("pawWarningText")
    nonisolated static let pawError = Color("pawError")
    nonisolated static let pawMilestone = Color("pawMilestone")
    nonisolated static let pawMilestoneSoft = Color("pawMilestoneSoft")
}

enum PawRadius {
    /// 小元素:标签、芯片、小按钮
    static let small: CGFloat = 8
    /// 缩略图(时间线 64pt 照片、里程碑图标块、选择网格)
    static let thumbnail: CGFloat = 12
    /// 卡片、表单弹层内的图(记录编辑页 200pt 照片)
    static let card: CGFloat = 16
    /// 产出物卡片(对比图、视频封面)
    static let artifact: CGFloat = 20
}

/// 4pt 网格,只允许这些值(§3.1)
enum PawSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let page: CGFloat = 32
}

enum PawMotion {
    /// 默认动画,不用 linear(§5)
    static let standard = Animation.spring(response: 0.35, dampingFraction: 0.8)
}

/// 表单底部主行动按钮:全宽胶囊,pawPrimary 填充 + 白字;
/// 按下 scale 0.97 + opacity 0.85,弹簧回弹(§4)
struct PawPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PawSpacing.m)
            .background(Color.pawPrimary, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(PawMotion.standard, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PawPrimaryButtonStyle {
    static var pawPrimary: PawPrimaryButtonStyle { PawPrimaryButtonStyle() }
}

/// 空状态三件套(§4):pawPrimarySoft 圆底 + pawPrimary 图标(64pt)+ 一句话标题 + 可选主按钮。
struct PawEmptyState: View {
    let systemImage: String
    let title: String
    var message: String?
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: PawSpacing.l) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(Color.pawPrimary)
                .frame(width: 64, height: 64)
                .background(Color.pawPrimarySoft, in: Circle())
            VStack(spacing: PawSpacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.pawText)
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Color.pawTextSecondary)
                }
            }
            .multilineTextAlignment(.center)
            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.pawPrimary)
            }
        }
        .padding(PawSpacing.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
