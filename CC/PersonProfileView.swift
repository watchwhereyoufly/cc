//
//  PersonProfileView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct PersonProfileView: View {
    let personName: String
    @ObservedObject var entryManager: EntryManager
    @Environment(\.dismiss) var dismiss
    @State private var profile: UserProfile?
    @State private var isLoading = true
    
    private var personEntries: [Entry] {
        entryManager.entries
            .filter { $0.person.lowercased() == personName.lowercased() }
            .sorted { $0.timestamp > $1.timestamp } // Newest first
    }
    
    private var personColor: Color {
        let personLower = personName.lowercased()
        if personLower == "ryan" {
            return .orange
        } else if personLower == "evan" {
            return .pink
        }
        return .terminalGreen
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Text("@\(personName.lowercased())")
                                .foregroundColor(personColor)
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
                        
                        // Profile Section
                        if let profile = profile {
                            VStack(alignment: .leading, spacing: 20) {
                                // Selfie
                                if let selfieData = profile.selfieData, let selfieImage = UIImage(data: selfieData) {
                                    HStack {
                                        Spacer()
                                        Image(uiImage: selfieImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 150)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(personColor, lineWidth: 2)
                                            )
                                        Spacer()
                                    }
                                    .padding(.bottom, 10)
                                }
                                
                                // Ideal Vision
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Who are you?")
                                        .foregroundColor(.terminalGreen.opacity(0.6))
                                        .font(.system(size: 13, design: .monospaced))
                                    Text(profile.idealVision)
                                        .foregroundColor(.terminalGreen)
                                        .font(.system(size: 15, design: .monospaced))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal)
                                
                                // Current Location
                                if let location = profile.currentLocation {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Current Location")
                                            .foregroundColor(.terminalGreen.opacity(0.6))
                                            .font(.system(size: 13, design: .monospaced))
                                        Text(location)
                                            .foregroundColor(.terminalGreen)
                                            .font(.system(size: 15, design: .monospaced))
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom, 20)
                        } else {
                            Text("Profile not found")
                                .foregroundColor(.terminalGreen.opacity(0.6))
                                .font(.system(size: 15, design: .monospaced))
                                .padding(.horizontal)
                        }
                        
                        // Entries Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Entries (\(personEntries.count))")
                                .foregroundColor(.terminalGreen.opacity(0.6))
                                .font(.system(size: 13, design: .monospaced))
                                .padding(.horizontal)
                            
                            if personEntries.isEmpty {
                                Text("No entries yet")
                                    .foregroundColor(.terminalGreen.opacity(0.6))
                                    .font(.system(size: 15, design: .monospaced))
                                    .padding(.horizontal)
                            } else {
                                ForEach(personEntries) { entry in
                                    PersonEntryRowView(entry: entry, personColor: personColor)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(.vertical)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadProfile()
        }
    }
    
    private func loadProfile() {
        isLoading = true
        Task {
            print("🔍 Loading profile for: \(personName)")
            print("   - Entries found: \(personEntries.count)")
            
            // First try to find the profile by name
            var loadedProfile = await ProfileManager.shared.fetchProfileByName(personName)
            
            // If not found by name, try to find it by authorID from entries
            if loadedProfile == nil, let firstEntry = personEntries.first, let authorID = firstEntry.authorID {
                print("🔍 Trying to find profile by authorID: \(authorID)")
                loadedProfile = await ProfileManager.shared.fetchProfileByUserID(authorID)
            }
            
            // If still not found, try fetching all profiles and matching
            if loadedProfile == nil {
                print("🔍 Trying to fetch all profiles and match manually...")
                loadedProfile = await ProfileManager.shared.fetchAllProfilesAndMatch(name: personName)
            }
            
            await MainActor.run {
                self.profile = loadedProfile
                self.isLoading = false
                
                if loadedProfile == nil {
                    print("❌ Could not load profile for: \(personName)")
                    print("   - Entries found: \(personEntries.count)")
                    if let firstEntry = personEntries.first {
                        print("   - First entry authorID: \(firstEntry.authorID ?? "nil")")
                        print("   - First entry authorName: \(firstEntry.authorName ?? "nil")")
                        print("   - First entry person: \(firstEntry.person)")
                    }
                    print("   - Suggestion: Make sure the profile was saved to CloudKit and that 'name' field is queryable in CloudKit Dashboard")
                } else {
                    print("✅ Successfully loaded profile for: \(personName)")
                }
            }
        }
    }
}

struct PersonEntryRowView: View {
    let entry: Entry
    let personColor: Color
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy h:mm a"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Handle activity entries
            if entry.entryType == .activity {
                // Timestamp at top
                HStack {
                    Spacer()
                    Text("[\(timeFormatter.string(from: entry.timestamp))]")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 10, design: .monospaced))
                }
                
                // Activity entry with color-coded person name
                HStack(alignment: .top, spacing: 4) {
                    Text("<@\(entry.person.lowercased())>")
                        .foregroundColor(personColor)
                        .font(.system(size: 15, design: .monospaced))
                    
                    Text(entry.activity)
                        .foregroundColor(.purple)
                        .font(.system(size: 15, design: .monospaced))
                    
                    Spacer()
                }
            }
            // Handle location update entries
            else if entry.entryType == .locationUpdate {
                // Timestamp at top
                HStack {
                    Spacer()
                    Text("[\(timeFormatter.string(from: entry.timestamp))]")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 10, design: .monospaced))
                }
                
                // Location entry with color-coded person name
                HStack(alignment: .top, spacing: 4) {
                    Text("<@\(entry.person.lowercased())>")
                        .foregroundColor(personColor)
                        .font(.system(size: 15, design: .monospaced))
                    
                    Text(entry.activity)
                        .foregroundColor(.yellow)
                        .font(.system(size: 15, design: .monospaced))
                    
                    Spacer()
                }
            } else {
                // Regular entry display
                // Check if this is a health update (sleep or weight)
                let isHealthUpdate = entry.activity.contains("woke up at") || entry.activity.contains("just weighed in")
                
                // Timestamp at top
                HStack {
                    Spacer()
                    Text("[\(timeFormatter.string(from: entry.timestamp))]")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 10, design: .monospaced))
                }
                
                // Activity entry
                HStack(alignment: .top, spacing: 4) {
                    Text("<@\(entry.person.lowercased())>")
                        .foregroundColor(personColor)
                        .font(.system(size: 15, design: .monospaced))
                    
                    if isHealthUpdate {
                        // HealthKit entries display without "Activity:" label
                        Text(entry.activity)
                            .foregroundColor(.white)
                            .font(.system(size: 15, design: .monospaced))
                    } else {
                        (Text("Activity: ")
                            .foregroundColor(.cyan)
                            + Text(entry.activity)
                            .foregroundColor(.terminalGreen))
                            .font(.system(size: 15, design: .monospaced))
                    }
                    
                    Spacer()
                }
                
                // Assumption entry
                if !entry.assumption.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Text("<@\(entry.person.lowercased())>")
                            .foregroundColor(personColor)
                            .font(.system(size: 15, design: .monospaced))
                        
                        (Text("Assumption: ")
                            .foregroundColor(.cyan)
                            + Text(entry.assumption)
                            .foregroundColor(.terminalGreen))
                            .font(.system(size: 15, design: .monospaced))
                        
                        Spacer()
                    }
                }
                
                // Image display
                if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                    HStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250, maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.terminalGreen.opacity(0.3), lineWidth: 1)
                            )
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}
