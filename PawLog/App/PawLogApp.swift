import SwiftUI
import SwiftData

@main
struct PawLogApp: App {
    private let container: ModelContainer

    init() {
        container = SharedModelContainer.make()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // 全局 tint = 暖阳杏主色;文字级着色用 pawPrimaryStrong(design-language §9.2)
                .tint(.pawPrimary)
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pets: [Pet]
    @State private var store: AppStore?

    var body: some View {
        Group {
            #if DEBUG
            if DebugWalkthrough.compareCardRequested {
                DebugCompareCardScreen()
            } else if DebugWalkthrough.widgetRequested {
                DebugWidgetScreen()
            } else {
                content
            }
            #else
            content
            #endif
        }
        .environment(store)
        .task {
            if store == nil {
                DemoDataSeeder.seedIfRequested(modelContext: modelContext)
                store = AppStore(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let store {
            if let pet = store.selectedPet ?? pets.first {
                MainTabView(pet: pet)
            } else {
                OnboardingView()
            }
        } else {
            ProgressView()
        }
    }
}
