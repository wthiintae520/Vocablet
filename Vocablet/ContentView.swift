import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("單字", systemImage: "books.vertical.fill") }
                .tag(0)

            SearchView()
                .tabItem { Label("搜尋", systemImage: "magnifyingglass") }
                .tag(1)

            FlashcardView()
                .tabItem { Label("字卡", systemImage: "rectangle.on.rectangle.angled") }
                .tag(2)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(.lilyAccent)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
