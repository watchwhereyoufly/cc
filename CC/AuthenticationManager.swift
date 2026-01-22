//
//  AuthenticationManager.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import CloudKit
import Combine
import AuthenticationServices

class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserID: String?
    @Published var isLoading = false
    @Published var hasCompletedSignIn = false // Track if user has completed sign-in flow
    @Published var shouldShowOnboarding = false // Track if onboarding should be shown
    
    private let container: CKContainer
    private let signInKey = "CC_HAS_SIGNED_IN"
    
    override init() {
        container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
        super.init()
        // Check if user has previously completed Sign in with Apple
        hasCompletedSignIn = UserDefaults.standard.bool(forKey: signInKey)
        
        if hasCompletedSignIn {
            // User has signed in with Apple before, check CloudKit/iCloud status
            checkAuthenticationStatus()
        } else {
            // First time - show sign-in screen (don't check CloudKit yet)
            isAuthenticated = false
            isLoading = false
        }
    }
    
    func checkAuthenticationStatus() {
        isLoading = true
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Error checking account status: \(error)")
                    self.isAuthenticated = false
                    return
                }
                
                switch status {
                case .available:
                    // User is signed into iCloud - allow access
                    self.isAuthenticated = true
                    self.hasCompletedSignIn = true
                    self.getCurrentUserID()
                    // Mark that sign-in is complete
                    UserDefaults.standard.set(true, forKey: self.signInKey)
                case .noAccount:
                    // No iCloud account - require sign-in
                    self.isAuthenticated = false
                    self.hasCompletedSignIn = false
                    UserDefaults.standard.set(false, forKey: self.signInKey)
                case .couldNotDetermine:
                    // Can't determine - require sign-in
                    self.isAuthenticated = false
                    self.hasCompletedSignIn = false
                    UserDefaults.standard.set(false, forKey: self.signInKey)
                case .restricted:
                    // Restricted - require sign-in
                    self.isAuthenticated = false
                    self.hasCompletedSignIn = false
                    UserDefaults.standard.set(false, forKey: self.signInKey)
                case .temporarilyUnavailable:
                    // Temporarily unavailable - require sign-in
                    self.isAuthenticated = false
                    self.hasCompletedSignIn = false
                    UserDefaults.standard.set(false, forKey: self.signInKey)
                @unknown default:
                    self.isAuthenticated = false
                    self.hasCompletedSignIn = false
                    UserDefaults.standard.set(false, forKey: self.signInKey)
                }
            }
        }
    }
    
    private func getCurrentUserID() {
        Task {
            do {
                let recordID = try await container.userRecordID()
                await MainActor.run {
                    self.currentUserID = recordID.recordName
                }
            } catch {
                print("Error getting user ID: \(error)")
            }
        }
    }
    
    func signIn() {
        // CloudKit authentication happens automatically when user signs in with Apple
        // This will trigger the account status check
        checkAuthenticationStatus()
    }
    
    func completeOnboarding() {
        // Mark onboarding as complete and authenticate
                    UserDefaults.standard.set(true, forKey: "CC_ONBOARDING_COMPLETE")
        shouldShowOnboarding = false
        isAuthenticated = true
    }
    
    func resetOnboarding() {
        // Reset onboarding to allow user to go through it again
        UserDefaults.standard.set(false, forKey: "CC_ONBOARDING_COMPLETE")
        shouldShowOnboarding = true
    }
}
