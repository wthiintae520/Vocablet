import SwiftUI

@main
struct VocabletApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var loc = LocalizationManager.shared

    init() {
        NotificationService.shared.requestPermission()
        NotificationService.shared.scheduleReviewReminder()
        // Tab bar 未選中的圖示與文字改成暖色系，移除系統黑
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        let gray     = UIColor(red: 0.541, green: 0.541, blue: 0.541, alpha: 1) // #8A8A8A
        let selected = UIColor(red: 0.722, green: 0.831, blue: 0.910, alpha: 1) // #B8D4E8
        for layout in [tabAppearance.stackedLayoutAppearance,
                        tabAppearance.inlineLayoutAppearance,
                        tabAppearance.compactInlineLayoutAppearance] {
            layout.normal.iconColor   = gray
            layout.selected.iconColor = selected
        }
        UITabBar.appearance().standardAppearance   = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
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
