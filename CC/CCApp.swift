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
                // Check if user has actually signed in with Apple (not just iCloud available)
                let hasSignedInWithApple = UserDefaults.standard.bool(forKey: "CC_HAS_SIGNED_IN")
                let hasProfile = ProfileManager.shared.currentProfile != nil
                let isLoadingProfile = ProfileManager.shared.isLoadingFromCloudKit
                
                if !hasSignedInWithApple || !authManager.isAuthenticated {
                    // Need to sign in with Apple
                    SignInView(authManager: authManager)
                } else if isLoadingProfile {
                    // Show loading while checking CloudKit for profile
                    // Add timeout to prevent infinite loading
                    ZStack {
                        Color.black.ignoresSafeArea()
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
                            Text("Loading your profile...")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                                .padding(.top, 16)
                        }
                    }
                    .onAppear {
                        // Set a timeout - if loading takes more than 5 seconds, assume no profile exists
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            if ProfileManager.shared.isLoadingFromCloudKit {
                                print("⚠️ Profile loading timeout - assuming no profile exists")
                                ProfileManager.shared.isLoadingFromCloudKit = false
                                ProfileManager.shared.currentProfile = nil
                                UserDefaults.standard.set(false, forKey: "CC_ONBOARDING_COMPLETE")
                            }
                        }
                    }
                } else {
                    // Signed in - check onboarding
                    let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "CC_ONBOARDING_COMPLETE")
                    
                    if !hasCompletedOnboarding || !hasProfile || authManager.shouldShowOnboarding {
                        OnboardingView(authManager: authManager)
                            .environmentObject(entryManager)
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
}
