import SwiftUI

@main
struct VocabletApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var loc = LocalizationManager.shared

    init() {
        NotificationService.shared.requestPermission()
        NotificationService.shared.scheduleReviewReminder()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(loc)
        }
    }
}
