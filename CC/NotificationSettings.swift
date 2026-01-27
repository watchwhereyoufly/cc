//
//  NotificationSettings.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import Foundation
import Combine

class NotificationSettings: ObservableObject {
    static let shared = NotificationSettings()
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "CC_NOTIFICATIONS_ENABLED")
        }
    }
    
    @Published var feedUpdateNotifications: Bool {
        didSet {
            UserDefaults.standard.set(feedUpdateNotifications, forKey: "CC_FEED_UPDATE_NOTIFICATIONS")
        }
    }
    
    @Published var reminderNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(reminderNotificationsEnabled, forKey: "CC_REMINDER_NOTIFICATIONS_ENABLED")
        }
    }
    
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: "CC_REMINDER_TIME")
        }
    }
    
    private init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "CC_NOTIFICATIONS_ENABLED")
        self.feedUpdateNotifications = UserDefaults.standard.bool(forKey: "CC_FEED_UPDATE_NOTIFICATIONS")
        self.reminderNotificationsEnabled = UserDefaults.standard.bool(forKey: "CC_REMINDER_NOTIFICATIONS_ENABLED")
        
        if let savedTime = UserDefaults.standard.object(forKey: "CC_REMINDER_TIME") as? Date {
            self.reminderTime = savedTime
        } else {
            // Default to 9 AM
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }
}
