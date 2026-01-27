//
//  ProfileView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var authManager: AuthenticationManager
    @EnvironmentObject var entryManager: EntryManager
    @Environment(\.dismiss) var dismiss
    @State private var showLocationUpdate = false
    @State private var showEditName = false
    @State private var showEditIdealVision = false
    @State private var showEditSelfie = false
    @State private var showResetConfirmation = false
    @State private var showNotifications = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text("Profile")
                            .foregroundColor(Color.terminalGreen)
                            .font(.system(size: 20, design: .monospaced))
                            .contentShape(Rectangle())
                            .onLongPressGesture(minimumDuration: 2.0) {
                                resetProfileAndOnboarding()
                            }
                        Spacer()
                        Button(action: {
                            showNotifications = true
                        }) {
                            Image(systemName: "bell")
                                .foregroundColor(Color.terminalGreen)
                                .font(.system(size: 18))
                        }
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color.terminalGreen)
                                .font(.system(size: 18))
                        }
                    }
                    .padding()
                    
                    if let profile = profileManager.currentProfile {
                        // Name - tappable to edit
                        Button(action: {
                            showEditName = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What is your name?")
                                    .foregroundColor(Color.terminalGreen.opacity(0.6))
                                    .font(.system(size: 13, design: .monospaced))
                                HStack {
                                    Text(profile.name)
                                        .foregroundColor(Color.terminalGreen)
                                        .font(.system(size: 15, design: .monospaced))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.terminalGreen.opacity(0.5))
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Ideal Vision - tappable to edit
                        Button(action: {
                            showEditIdealVision = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Who are you?")
                                    .foregroundColor(Color.terminalGreen.opacity(0.6))
                                    .font(.system(size: 13, design: .monospaced))
                                HStack(alignment: .top) {
                                    Text(profile.idealVision)
                                        .foregroundColor(Color.terminalGreen)
                                        .font(.system(size: 15, design: .monospaced))
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.terminalGreen.opacity(0.5))
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Current Location - tappable to edit
                        Button(action: {
                            showLocationUpdate = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Location")
                                    .foregroundColor(Color.terminalGreen.opacity(0.6))
                                    .font(.system(size: 13, design: .monospaced))
                                
                                HStack {
                                    if let location = profile.currentLocation {
                                        Text(location)
                                            .foregroundColor(Color.terminalGreen)
                                            .font(.system(size: 15, design: .monospaced))
                                    } else {
                                        Text("Not set")
                                            .foregroundColor(Color.terminalGreen.opacity(0.5))
                                            .font(.system(size: 15, design: .monospaced))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.terminalGreen.opacity(0.5))
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Selfie - tappable to edit
                        Button(action: {
                            showEditSelfie = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Selfie")
                                    .foregroundColor(Color.terminalGreen.opacity(0.6))
                                    .font(.system(size: 13, design: .monospaced))
                                
                                if let selfieData = profile.selfieData, let selfieImage = UIImage(data: selfieData) {
                                    HStack {
                                        Image(uiImage: selfieImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.terminalGreen, lineWidth: 2)
                                            )
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.terminalGreen.opacity(0.5))
                                            .font(.system(size: 12))
                                    }
                                } else {
                                    HStack {
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 80, height: 80)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 2)
                                            )
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .foregroundColor(.terminalGreen.opacity(0.5))
                                                    .font(.system(size: 30))
                                            )
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.terminalGreen.opacity(0.5))
                                            .font(.system(size: 12))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // CC Member since date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CC Member since")
                                .foregroundColor(Color.terminalGreen.opacity(0.6))
                                .font(.system(size: 13, design: .monospaced))
                            
                            Text(formatMemberDate(profile.createdAt))
                                .foregroundColor(Color.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    } else {
                        Text("No profile data found")
                            .foregroundColor(Color.terminalGreen.opacity(0.6))
                            .font(.system(size: 15, design: .monospaced))
                            .padding()
                    }
                }
                .padding(.vertical)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLocationUpdate) {
            LocationUpdateView(entryManager: entryManager)
        }
        .sheet(isPresented: $showEditName) {
            EditNameView()
        }
        .sheet(isPresented: $showEditIdealVision) {
            EditIdealVisionView()
        }
        .sheet(isPresented: $showEditSelfie) {
            EditSelfieView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
        .alert("Reset Profile?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                performReset()
            }
        } message: {
            Text("This will delete your profile, all your entries, reset onboarding, and sign you out. You'll need to go through onboarding again. Continue?")
        }
    }
    
    private func resetProfileAndOnboarding() {
        showResetConfirmation = true
    }
    
    private func performReset() {
        Task {
            // Get user ID before clearing everything
            let userID = entryManager.currentUserID
            
            // Delete all user entries from CloudKit
            if let userID = userID {
                await entryManager.deleteAllUserEntries()
            }
            
            // Delete profile from CloudKit
            if let profile = profileManager.currentProfile {
                await profileManager.deleteProfile(profile)
            }
            
            // Clear all local data
            UserDefaults.standard.removeObject(forKey: "CC_USER_PROFILE")
            UserDefaults.standard.removeObject(forKey: "CC_ENTRIES")
            UserDefaults.standard.set(false, forKey: "CC_ONBOARDING_COMPLETE")
            UserDefaults.standard.set(false, forKey: "CC_HAS_SIGNED_IN")
            
            // Clear in-memory data
            await MainActor.run {
                profileManager.currentProfile = nil
                entryManager.entries = []
                
                // Reset authentication
                authManager.isAuthenticated = false
                authManager.hasCompletedSignIn = false
                authManager.shouldShowOnboarding = true
                authManager.currentUserID = nil
            }
            
            // Dismiss and the app will show sign-in screen
            dismiss()
        }
    }
    
    private func formatMemberDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
