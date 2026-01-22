//
//  CloudKitService.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import CloudKit
import Combine

class CloudKitService: ObservableObject {
    static var shared: CloudKitService?
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "Entry"
    
    @Published var isSyncing = false
    @Published var lastSyncError: Error?
    
    init() {
        container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
        database = container.publicCloudDatabase
        CloudKitService.shared = self
        setupSubscriptions()
    }
    
    // MARK: - Save Entry
    func saveEntry(_ entry: Entry) async throws {
        let record = entry.toCKRecord()
        
        do {
            let savedRecord = try await database.save(record)
            print("✅ Saved entry to CloudKit: \(savedRecord.recordID)")
            print("   - Type: \(entry.entryType.rawValue)")
            print("   - Person: \(entry.person)")
            print("   - Activity: \(entry.activity.prefix(50))...")
        } catch {
            print("❌ Error saving to CloudKit: \(error)")
            if let ckError = error as? CKError {
                print("   - Code: \(ckError.code.rawValue)")
                print("   - Description: \(ckError.localizedDescription)")
            }
            throw error
        }
    }
    
    // MARK: - Fetch All Entries
    func fetchAllEntries() async throws -> [Entry] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            var entries: [Entry] = []
            
            print("📥 Fetching entries from CloudKit... Found \(matchResults.count) records")
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let entry = Entry(from: record) {
                        entries.append(entry)
                        print("   ✅ Loaded entry: \(entry.id) - \(entry.entryType.rawValue)")
                    } else {
                        print("   ⚠️ Failed to decode entry from record: \(record.recordID)")
                    }
                case .failure(let error):
                    print("   ❌ Error fetching record: \(error)")
                }
            }
            
            print("📥 Total entries loaded: \(entries.count)")
            return entries
        } catch {
            print("❌ Error fetching from CloudKit: \(error)")
            if let ckError = error as? CKError {
                print("   - Code: \(ckError.code.rawValue)")
                print("   - Description: \(ckError.localizedDescription)")
            }
            throw error
        }
    }
    
    // MARK: - Delete Entry
    func deleteEntry(_ entry: Entry) async throws {
        guard let recordID = entry.cloudKitRecordID else {
            throw CloudKitError.missingRecordID
        }
        
        do {
            try await database.deleteRecord(withID: recordID)
            print("✅ Deleted entry from CloudKit: \(recordID)")
        } catch {
            print("❌ Error deleting from CloudKit: \(error)")
            throw error
        }
    }
    
    // MARK: - Setup Subscriptions
    func setupSubscriptions() {
        // Subscribe to new entries
        let createSubscription = CKQuerySubscription(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "EntryCreated",
            options: [.firesOnRecordCreation]
        )
        
        let createNotification = CKSubscription.NotificationInfo()
        createNotification.shouldSendContentAvailable = true
        createSubscription.notificationInfo = createNotification
        
        // Subscribe to deleted entries
        let deleteSubscription = CKQuerySubscription(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "EntryDeleted",
            options: [.firesOnRecordDeletion]
        )
        
        let deleteNotification = CKSubscription.NotificationInfo()
        deleteNotification.shouldSendContentAvailable = true
        deleteSubscription.notificationInfo = deleteNotification
        
        // Subscribe to updated entries
        let updateSubscription = CKQuerySubscription(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "EntryUpdated",
            options: [.firesOnRecordUpdate]
        )
        
        let updateNotification = CKSubscription.NotificationInfo()
        updateNotification.shouldSendContentAvailable = true
        updateSubscription.notificationInfo = updateNotification
        
        Task {
            do {
                try await database.save(createSubscription)
                try await database.save(deleteSubscription)
                try await database.save(updateSubscription)
                print("✅ CloudKit subscriptions created")
            } catch {
                // Subscription might already exist, that's okay
                if let ckError = error as? CKError, ckError.code == .serverRecordChanged {
                    print("ℹ️ Subscription already exists")
                } else {
                    print("⚠️ Error creating subscriptions: \(error)")
                }
            }
        }
    }
    
    // MARK: - Handle Notification
    func handleNotification(_ notification: CKNotification) -> Bool {
        guard let queryNotification = notification as? CKQueryNotification else {
            return false
        }
        
        // Check if this is an Entry record notification
        // CKQueryNotification doesn't have recordType, but we can check the subscription ID
        let subscriptionID = queryNotification.subscriptionID ?? ""
        if subscriptionID.contains("Entry") {
            return true
        }
        
        return false
    }
    
    // MARK: - Get Current User ID
    func getCurrentUserID() async -> String? {
        do {
            let userRecordID = try await container.userRecordID()
            return userRecordID.recordName
        } catch {
            print("❌ Error getting user ID: \(error)")
            return nil
        }
    }
}

enum CloudKitError: LocalizedError {
    case missingRecordID
    
    var errorDescription: String? {
        switch self {
        case .missingRecordID:
            return "Entry is missing CloudKit record ID"
        }
    }
}
