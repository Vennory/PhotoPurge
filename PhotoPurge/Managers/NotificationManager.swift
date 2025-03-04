import Foundation
import UserNotifications
import Photos

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(at time: Date?, random: Bool = false) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Review Media"
        content.body = "Swipe through your recent photos and videos to keep your library organized!"
        content.sound = .default
        
        // Check if there are unreviewed photos before scheduling
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@", oneMonthAgo as NSDate)
        
        let assets = PHAsset.fetchAssets(with: fetchOptions)
        guard assets.count > 0 else { return }
        
        var notificationTime = time ?? Date()
        if random {
            // Random time between 9 AM and 9 PM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = Int.random(in: 9...21)
            components.minute = Int.random(in: 0...59)
            notificationTime = calendar.date(from: components) ?? Date()
        }
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "photoReview",
                                          content: content,
                                          trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
} 
