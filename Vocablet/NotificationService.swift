import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleReviewReminder(hour: Int = 20, minute: Int = 0) {
        center.removePendingNotificationRequests(withIdentifiers: ["vocablet.daily.review"])

        let content = UNMutableNotificationContent()
        content.title = "今天來複習單字吧！"
        content.body = "保持每天練習，讓英文更上一層樓 ✨"
        content.sound = .default
        content.badge = 1

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "vocablet.daily.review", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["vocablet.daily.review"])
    }

    func loadScheduledHour(completion: @escaping (Int, Int) -> Void) {
        center.getPendingNotificationRequests { requests in
            if let req = requests.first(where: { $0.identifier == "vocablet.daily.review" }),
               let trigger = req.trigger as? UNCalendarNotificationTrigger,
               let hour = trigger.dateComponents.hour,
               let minute = trigger.dateComponents.minute {
                DispatchQueue.main.async { completion(hour, minute) }
            } else {
                DispatchQueue.main.async { completion(20, 0) }
            }
        }
    }
}
