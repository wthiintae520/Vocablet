import SwiftUI

struct ContentView: View {
    @EnvironmentObject var loc: LocalizationManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Image(systemName: "books.vertical.fill") }
                .tag(0)
            SearchView()
                .tabItem { Image(systemName: "magnifyingglass") }
                .tag(1)
            FlashcardView()
                .tabItem { Image(systemName: "rectangle.on.rectangle.angled") }
                .tag(2)
            SettingsView()
                .tabItem { Image(systemName: "gearshape.fill") }
                .tag(3)
        }
        .tint(Color(red: 0.722, green: 0.831, blue: 0.910))
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocalizationManager.shared)
}
