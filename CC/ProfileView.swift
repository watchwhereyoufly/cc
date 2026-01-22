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
    @State private var showResetConfirmation = false
    @State private var showLocationUpdate = false
    
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
                                .foregroundColor(Color.terminalGreen)
                                .font(.system(size: 20, design: .monospaced))
                        }
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color.terminalGreen)
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
                                .foregroundColor(Color.terminalGreen.opacity(0.6))
                                .font(.system(size: 13, design: .monospaced))
                            Text(profile.name)
                                .foregroundColor(Color.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                        }
                        .padding(.horizontal)
                        
                        // Ideal Vision
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What is your ideal vision?")
                                .foregroundColor(Color.terminalGreen.opacity(0.6))
                                .font(.system(size: 13, design: .monospaced))
                            Text(profile.idealVision)
                                .foregroundColor(Color.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                        }
                        .padding(.horizontal)
                        
                        // Current Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Location")
                                .foregroundColor(Color.terminalGreen.opacity(0.6))
                                .font(.system(size: 13, design: .monospaced))
                            
                            Button(action: {
                                showLocationUpdate = true
                            }) {
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
                            
                            // Location Timeline
                            if !profile.locationHistory.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Location History")
                                        .foregroundColor(Color.terminalGreen.opacity(0.6))
                                        .font(.system(size: 12, design: .monospaced))
                                        .padding(.top, 8)
                                    
                                    ForEach(profile.locationHistory.sorted(by: { $0.date < $1.date })) { location in
                                        HStack {
                                            Text(location.location)
                                                .foregroundColor(Color.terminalGreen)
                                                .font(.system(size: 13, design: .monospaced))
                                            Spacer()
                                            Text(location.date, style: .date)
                                                .foregroundColor(Color.terminalGreen.opacity(0.6))
                                                .font(.system(size: 11, design: .monospaced))
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Selfie
                        if let selfieData = profile.selfieData, let selfieImage = UIImage(data: selfieData) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Selfie")
                                    .foregroundColor(Color.terminalGreen.opacity(0.6))
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
    }
}
