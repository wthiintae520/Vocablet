import SwiftUI

struct ContentView: View {
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocalizationManager.shared)
}
