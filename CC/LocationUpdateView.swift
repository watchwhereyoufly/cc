//
//  LocationUpdateView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct LocationUpdateView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var entryManager: EntryManager
    @Environment(\.dismiss) var dismiss
    
    @State private var newLocation: String = ""
    @State private var whatFor: String = ""
    @State private var isTravel: Bool = false
    @State private var showLocationInput = false
    @State private var selectedAction: String? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Update Location")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 20, design: .monospaced))
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
                
                // Current location display
                if let profile = profileManager.currentProfile,
                   let currentLocation = profile.currentLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Location:")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 13, design: .monospaced))
                        Text(currentLocation)
                            .foregroundColor(.terminalGreen)
                            .font(.system(size: 15, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                // Location History
                if let profile = profileManager.currentProfile,
                   !profile.locationHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location History")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 13, design: .monospaced))
                            .padding(.top, 8)
                        
                        ForEach(profile.locationHistory.sorted(by: { $0.date < $1.date })) { location in
                            HStack {
                                Text(location.location)
                                    .foregroundColor(.terminalGreen)
                                    .font(.system(size: 13, design: .monospaced))
                                Spacer()
                                Text(location.date, style: .date)
                                    .foregroundColor(.terminalGreen.opacity(0.6))
                                    .font(.system(size: 11, design: .monospaced))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                // Action buttons
                if !showLocationInput {
                    VStack(spacing: 16) {
                        Button(action: {
                            isTravel = false
                            showLocationInput = true
                            selectedAction = "location"
                        }) {
                            Text("New Location")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.terminalGreen)
                                .cornerRadius(4)
                        }
                        
                        Button(action: {
                            isTravel = true
                            showLocationInput = true
                            selectedAction = "travel"
                        }) {
                            Text("New Travel")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.terminalGreen)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Location input
                if showLocationInput {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isTravel ? "Where are you traveling to?" : "What's your new location?")
                            .foregroundColor(.terminalGreen)
                            .font(.system(size: 15, design: .monospaced))
                        
                        ZStack(alignment: .topLeading) {
                            if newLocation.isEmpty {
                                Text("Enter location...")
                                    .foregroundColor(.terminalGreen.opacity(0.5))
                                    .font(.system(size: 15, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 12)
                            }
                            TextField("", text: $newLocation)
                                .textFieldStyle(.plain)
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                                .padding(12)
                        }
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 1)
                        )
                        
                        // "What for?" field - only show for travel
                        if isTravel {
                            Text("What for?")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            
                            ZStack(alignment: .topLeading) {
                                if whatFor.isEmpty {
                                    Text("Enter reason...")
                                        .foregroundColor(.terminalGreen.opacity(0.5))
                                        .font(.system(size: 15, design: .monospaced))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 12)
                                }
                                TextField("", text: $whatFor)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.terminalGreen)
                                    .font(.system(size: 15, design: .monospaced))
                                    .padding(12)
                            }
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                showLocationInput = false
                                selectedAction = nil
                                newLocation = ""
                                whatFor = ""
                            }) {
                                Text("Cancel")
                                    .foregroundColor(.terminalGreen)
                                    .font(.system(size: 15, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.terminalGreen, lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                submitLocation()
                            }) {
                                Text("Submit")
                                    .foregroundColor(.black)
                                    .font(.system(size: 15, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(newLocation.isEmpty || (isTravel && whatFor.isEmpty) ? Color.terminalGreen.opacity(0.5) : Color.terminalGreen)
                                    .cornerRadius(4)
                            }
                            .disabled(newLocation.isEmpty || (isTravel && whatFor.isEmpty))
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func submitLocation() {
        guard !newLocation.isEmpty,
              let profile = profileManager.currentProfile else { return }
        
        let userName = profile.name
        
        if isTravel {
            // Just create entry, don't update profile
            entryManager.addLocationEntry(userName: userName, location: newLocation, isTravel: true, whatFor: whatFor)
        } else {
            // Update profile with new location
            var updatedHistory = profile.locationHistory
            let newLocationEntry = LocationHistory(location: newLocation, date: Date(), isTravel: false)
            updatedHistory.append(newLocationEntry)
            
            let updatedProfile = UserProfile(
                id: profile.id,
                name: profile.name,
                idealVision: profile.idealVision,
                selfieData: profile.selfieData,
                createdAt: profile.createdAt,
                currentLocation: newLocation,
                locationHistory: updatedHistory,
                cloudKitRecordID: profile.cloudKitRecordID
            )
            
            profileManager.saveProfile(updatedProfile)
            entryManager.addLocationEntry(userName: userName, location: newLocation, isTravel: false)
        }
        
        dismiss()
    }
}
