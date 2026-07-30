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
        .environment(store)
        .task {
            if store == nil {
                DemoDataSeeder.seedIfRequested(modelContext: modelContext)
                store = AppStore(modelContext: modelContext)
            }
        }
    }
}
