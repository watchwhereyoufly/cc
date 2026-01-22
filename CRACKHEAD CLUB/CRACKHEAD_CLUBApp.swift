//
//  CCApp.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI
import CloudKit
import UserNotifications

@main
struct CCApp: App {
    @StateObject private var entryManager = EntryManager()
    @StateObject private var authManager = AuthenticationManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Request notification permissions for CloudKit
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !authManager.isAuthenticated {
                    SignInView(authManager: authManager)
                } else if !UserDefaults.standard.bool(forKey: "CC_ONBOARDING_COMPLETE") || authManager.shouldShowOnboarding {
                    OnboardingView(authManager: authManager)
                } else {
                    ContentView()
                        .environmentObject(entryManager)
                        .environmentObject(authManager)
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // Sync when app becomes active
                            entryManager.syncWithCloudKit()
                        }
                }
            }
        }
    }
}
