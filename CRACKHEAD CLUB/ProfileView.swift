//
//  ProfileView.swift
//  CRACKHEAD CLUB
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            Text("Profile")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 20, design: .monospaced))
                        }
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 18))
                        }
                    }
                    .padding()
                    .alert("Edit Profile", isPresented: $showResetConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Edit", role: .destructive) {
                            authManager.resetOnboarding()
                            dismiss()
                        }
                    } message: {
                        Text("Are you sure you want to edit your profile? This will take you back to the onboarding flow where you can update your name, ideal vision, and selfie.")
                    }
                    
                    if let profile = profileManager.currentProfile {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Who are you?")
                                .foregroundColor(.terminalGreen.opacity(0.6))
                                .font(.system(size: 13, design: .monospaced))
                            Text(profile.name)
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                        }
                        .padding(.horizontal)
                        
                        // Ideal Vision
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What is your ideal vision?")
                                .foregroundColor(.terminalGreen.opacity(0.6))
                                .font(.system(size: 13, design: .monospaced))
                            Text(profile.idealVision)
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                        }
                        .padding(.horizontal)
                        
                        // Selfie
                        if let selfieData = profile.selfieData, let selfieImage = UIImage(data: selfieData) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Selfie")
                                    .foregroundColor(.terminalGreen.opacity(0.6))
                                    .font(.system(size: 13, design: .monospaced))
                                
                                Image(uiImage: selfieImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.terminalGreen, lineWidth: 2)
                                    )
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Text("No profile data found")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 15, design: .monospaced))
                            .padding()
                    }
                }
                .padding(.vertical)
            }
        }
        .preferredColorScheme(.dark)
    }
}
