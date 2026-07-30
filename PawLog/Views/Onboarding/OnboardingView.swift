import SwiftUI

/// 首次启动：强制创建宠物档案，完成前无法进入主页。
struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            PetFormView(existingPet: nil) { _ in }
                .interactiveDismissDisabled()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 2) {
                            Text("欢迎来到 PawLog")
                                .font(.headline)
                            Text("先为你的宠物建立一份档案吧")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
    }
}
