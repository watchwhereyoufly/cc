//
//  AppDelegate.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import UIKit
import CloudKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for remote notifications
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ Registered for remote notifications")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
              let cloudKitService = CloudKitService.shared else {
            completionHandler(.noData)
            return
        }
        
        if cloudKitService.handleNotification(notification) {
            // Notify EntryManager to sync
            NotificationCenter.default.post(name: NSNotification.Name("CloudKitUpdate"), object: nil)
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}
