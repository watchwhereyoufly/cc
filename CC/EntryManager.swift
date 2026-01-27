//
//  EntryManager.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import Combine
import CloudKit

class EntryManager: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var isSyncing = false
    
    private let entriesKey = "CC_ENTRIES"
    private let cloudKitService = CloudKitService()
    private var cancellables = Set<AnyCancellable>()
    @Published var currentUserID: String?
    @Published var currentUserName: String?
    
    init() {
        loadEntries()
        setupCloudKitObserver()
        setupNotificationObserver()
        setupProfileObserver()
        getCurrentUserInfo()
        syncWithCloudKit()
    }
    
    private func setupProfileObserver() {
        // Observe profile changes to update author name
        ProfileManager.shared.$currentProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profile in
                self?.currentUserName = profile?.name
            }
            .store(in: &cancellables)
    }
    
    private func getCurrentUserInfo() {
        Task {
            // Get user ID from CloudKit
            if let userID = await cloudKitService.getCurrentUserID() {
                await MainActor.run {
                    self.currentUserID = userID
                }
            }
            
            // Get user name from profile
            await MainActor.run {
                self.currentUserName = ProfileManager.shared.currentProfile?.name
            }
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitUpdate"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncWithCloudKit()
            }
            .store(in: &cancellables)
    }
    
    func addLocationEntry(userName: String, location: String, isTravel: Bool = false, whatFor: String = "", isReturnHome: Bool = false) {
        let message: String
        if isReturnHome {
            message = "returned home to \(location)"
        } else if isTravel {
            if !whatFor.isEmpty {
                message = "is now in \(location) for \(whatFor)"
            } else {
                message = "is now in \(location)"
            }
        } else {
            message = "moved to \(location)"
        }
        
        // Create a special entry for location updates
        let entry = Entry(
            person: userName,
            activity: message,
            assumption: "",
            imageData: nil,
            authorID: currentUserID,
            authorName: currentUserName ?? userName,
            entryType: .locationUpdate
        )
        entries.append(entry)
        saveEntriesLocally()
        
        // Save to CloudKit
        Task {
            do {
                try await cloudKitService.saveEntry(entry)
            } catch {
                print("Failed to save location entry to CloudKit: \(error)")
            }
        }
    }
    
    func addEntry(person: String, activity: String, assumption: String, imageData: Data? = nil) {
        // Get current user info for author identification
        let authorID = currentUserID
        let authorName = currentUserName ?? person // Fallback to person name if no profile name
        
        let entry = Entry(
            person: person,
            activity: activity,
            assumption: assumption,
            imageData: imageData,
            authorID: authorID,
            authorName: authorName,
            entryType: .regular
        )
        entries.append(entry) // Add to end for messaging style (newest at bottom)
        saveEntriesLocally()
        
        // Save to CloudKit asynchronously
        Task {
            do {
                try await cloudKitService.saveEntry(entry)
            } catch {
                print("Failed to save to CloudKit: \(error)")
            }
        }
    }
    
    func addActivityEntry(person: String, activityName: String, duration: String) {
        // Get current user info for author identification
        let authorID = currentUserID
        let authorName = currentUserName ?? person
        
        // Create activity entry with format: "completed a '[activity]' activity for [duration]"
        let activityText = "completed a \"\(activityName)\" activity for \(duration)"
        
        let entry = Entry(
            person: person,
            activity: activityText,
            assumption: "", // No assumption for activity entries
            imageData: nil, // No image for activity entries
            authorID: authorID,
            authorName: authorName,
            entryType: .activity,
            activityDuration: duration
        )
        entries.append(entry) // Add to end for messaging style (newest at bottom)
        saveEntriesLocally()
        
        // Save to CloudKit asynchronously
        Task {
            do {
                try await cloudKitService.saveEntry(entry)
            } catch {
                print("Failed to save activity entry to CloudKit: \(error)")
            }
        }
    }
    
    func deleteEntry(_ entry: Entry) {
        // Only allow deleting your own entries
        guard let currentUserID = currentUserID,
              let entryAuthorID = entry.authorID,
              entryAuthorID == currentUserID else {
            print("⚠️ Cannot delete entry: Not the author")
            return
        }
        
        // Remove locally first for immediate UI update
        entries.removeAll { $0.id == entry.id }
        saveEntriesLocally()
        
        // Delete from CloudKit asynchronously
        Task {
            do {
                try await cloudKitService.deleteEntry(entry)
                print("✅ Entry deleted from CloudKit - will sync to other devices")
            } catch {
                print("❌ Failed to delete from CloudKit: \(error)")
                // If CloudKit delete fails, we should restore the entry locally
                // But for now, we'll let the sync handle it
            }
        }
    }
    
    // MARK: - Update Entry
    func updateEntry(entry: Entry, activity: String, assumption: String, imageData: Data?) {
        // Only allow updating own entries
        guard let currentUserID = currentUserID,
              let entryAuthorID = entry.authorID,
              entryAuthorID == currentUserID else {
            print("⚠️ Cannot update entry: Not the author")
            return
        }
        
        // Find and update the entry
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            // Create a new entry with updated values but preserve the same ID and CloudKit record
            let updatedEntry = Entry(
                id: entry.id,
                person: entry.person,
                activity: activity,
                assumption: assumption,
                timestamp: entry.timestamp, // Keep original timestamp
                cloudKitRecordID: entry.cloudKitRecordID, // Keep CloudKit record ID
                lastModified: Date(), // Update modification date
                imageData: imageData,
                imageURL: entry.imageURL,
                authorID: entry.authorID,
                authorName: entry.authorName,
                entryType: entry.entryType
            )
            
            entries[index] = updatedEntry
            saveEntriesLocally()
            
            // Update in CloudKit
            Task {
                do {
                    try await cloudKitService.saveEntry(updatedEntry)
                    print("✅ Entry updated in CloudKit")
                } catch {
                    print("❌ Failed to update entry in CloudKit: \(error)")
                }
            }
        }
    }
    
    // MARK: - Delete All User Entries
    func deleteAllUserEntries() async {
        guard let userID = currentUserID else {
            print("⚠️ Cannot delete entries: No user ID")
            return
        }
        
        do {
            // Delete all entries from CloudKit
            try await cloudKitService.deleteAllEntriesByAuthor(userID)
            
            // Remove from local storage
            await MainActor.run {
                entries.removeAll { $0.authorID == userID }
                saveEntriesLocally()
            }
            
            print("✅ All user entries deleted")
        } catch {
            print("❌ Failed to delete all entries: \(error)")
        }
    }
    
    // MARK: - CloudKit Sync
    func syncWithCloudKit() {
        guard !isSyncing else { return }
        isSyncing = true
        
        Task {
            do {
                let cloudEntries = try await cloudKitService.fetchAllEntries()
                await MainActor.run {
                    mergeEntries(cloudEntries)
                    isSyncing = false
                }
            } catch {
                await MainActor.run {
                    print("Sync failed: \(error)")
                    isSyncing = false
                }
            }
        }
    }
    
    private func mergeEntries(_ cloudEntries: [Entry]) {
        var mergedEntries: [Entry] = []
        var localEntryMap: [UUID: Entry] = [:]
        
        // Create map of local entries
        for entry in entries {
            localEntryMap[entry.id] = entry
        }
        
        // Process cloud entries (prefer cloud version if newer)
        for cloudEntry in cloudEntries {
            if let localEntry = localEntryMap[cloudEntry.id] {
                // Both exist - use the one with newer lastModified
                if let cloudModified = cloudEntry.lastModified,
                   let localModified = localEntry.lastModified,
                   cloudModified > localModified {
                    mergedEntries.append(cloudEntry)
                } else {
                    mergedEntries.append(localEntry)
                }
            } else {
                // Only in cloud - add it
                mergedEntries.append(cloudEntry)
            }
        }
        
        // Add local entries that aren't in cloud, but ONLY if they were never uploaded
        // (don't have a cloudKitRecordID). If they have a cloudKitRecordID but aren't in cloud,
        // they were deleted and should be removed.
        for localEntry in entries {
            if !cloudEntries.contains(where: { $0.id == localEntry.id }) {
                // Only keep local entries that were never uploaded to CloudKit
                // (no cloudKitRecordID means they haven't been synced yet)
                if localEntry.cloudKitRecordID == nil {
                    mergedEntries.append(localEntry)
                }
                // If it has a cloudKitRecordID but isn't in cloud, it was deleted - don't add it back
            }
        }
        
        // Sort by timestamp (oldest first for messaging style)
        mergedEntries.sort { $0.timestamp < $1.timestamp }
        
        entries = mergedEntries
        saveEntriesLocally()
    }
    
    private func setupCloudKitObserver() {
        // Observe CloudKit service sync status
        cloudKitService.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSyncing, on: self)
            .store(in: &cancellables)
    }
    
    func handleCloudKitNotification() {
        // Called when CloudKit notification is received
        syncWithCloudKit()
    }
    
    // MARK: - Local Storage
    private func saveEntriesLocally() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            entries = decoded.sorted { $0.timestamp < $1.timestamp } // Oldest first for messaging style
        }
    }
}
