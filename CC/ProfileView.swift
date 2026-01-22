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
                    
                    if let profile = profileManager.currentProfile {
                        // Name - tappable to edit
                        Button(action: {
                            showEditName = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Who are you?")
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
                                Text("What is your ideal vision?")
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
    }
}
