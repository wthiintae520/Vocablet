import SwiftUI

struct ContentView: View {
    @EnvironmentObject var loc: LocalizationManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(loc.booklets, systemImage: "books.vertical.fill") }
                .tag(0)
            SearchView()
                .tabItem { Label(loc.tabSearch, systemImage: "magnifyingglass") }
                .tag(1)
            FlashcardView()
                .tabItem { Label(loc.tabFlashcard, systemImage: "rectangle.on.rectangle.angled") }
                .tag(2)
            SettingsView()
                .tabItem { Label(loc.tabSettings, systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(.lilyAccent)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocalizationManager.shared)
}
