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
    
    func addLocationEntry(userName: String, location: String, isTravel: Bool = false, whatFor: String = "") {
        let message: String
        if isTravel {
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
            authorName: authorName
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
    
    func deleteEntry(_ entry: Entry) {
        entries.removeAll { $0.id == entry.id }
        saveEntriesLocally()
        
        // Delete from CloudKit asynchronously
        Task {
            do {
                try await cloudKitService.deleteEntry(entry)
            } catch {
                print("Failed to delete from CloudKit: \(error)")
            }
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
        
        // Add local entries that aren't in cloud
        for localEntry in entries {
            if !cloudEntries.contains(where: { $0.id == localEntry.id }) {
                mergedEntries.append(localEntry)
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
