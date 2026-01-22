//
//  EntryManager.swift
//  CRACKHEAD CLUB
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import Combine
import CloudKit

class EntryManager: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var isSyncing = false
    
    private let entriesKey = "CRACKHEAD_CLUB_ENTRIES"
    private let cloudKitService = CloudKitService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadEntries()
        setupCloudKitObserver()
        setupNotificationObserver()
        syncWithCloudKit()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitUpdate"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncWithCloudKit()
            }
            .store(in: &cancellables)
    }
    
    func addEntry(person: String, activity: String, assumption: String, imageData: Data? = nil) {
        let entry = Entry(person: person, activity: activity, assumption: assumption, imageData: imageData)
        entries.insert(entry, at: 0) // Add to beginning for newest first
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
        
        // Sort by timestamp (newest first)
        mergedEntries.sort { $0.timestamp > $1.timestamp }
        
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
            entries = decoded.sorted { $0.timestamp > $1.timestamp } // Newest first
        }
    }
}
