import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Request notification permission from user
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            completion(granted)
        }
    }
    
    /// Schedule weekly recap notification for next Monday at 9:00 AM
    func scheduleWeeklyRecap() {
        let center = UNUserNotificationCenter.current()
        
        // Remove any existing weekly recap notifications
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-recap"])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Stash 周回顾"
        content.body = "来看看这周你保存了哪些内容吧！"
        content.sound = .default
        
        // Create trigger for next Monday at 9:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(identifier: "weekly-recap", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule weekly recap: \(error)")
            } else {
                print("Weekly recap notification scheduled")
            }
        }
    }
    
    /// Schedule a notification with dynamic content based on saved items count
    func scheduleRecapWithCount(_ count: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-recap"])
        
        let content = UNMutableNotificationContent()
        content.title = "Stash 周回顾"
        content.body = "这周你保存了 \(count) 条内容，快来回顾一下吧！"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 2
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-recap", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule recap: \(error)")
            }
        }
    }
}
