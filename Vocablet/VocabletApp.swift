import SwiftUI

@main
struct VocabletApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var loc = LocalizationManager.shared

    init() {
        NotificationService.shared.requestPermission()
        NotificationService.shared.scheduleReviewReminder()
        // Tab bar 未選中的圖示與文字改成暖色系，移除系統黑
        UITabBar.appearance().unselectedItemTintColor = UIColor(
            red: 0.541, green: 0.541, blue: 0.541, alpha: 1  // #8A8A8A
        )
        // 移除 List section 頂部多餘留白
        UITableView.appearance().sectionHeaderTopPadding = 0
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(loc)
        }
    }
}
