//
//  Activity.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import Foundation
import Combine
import CloudKit

struct Activity: Identifiable, Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    var cloudKitRecordIDString: String?
    var userCloudKitID: String? // CloudKit user ID who owns this activity
    
    var cloudKitRecordID: CKRecord.ID? {
        get {
            guard let recordIDString = cloudKitRecordIDString else { return nil }
            return CKRecord.ID(recordName: recordIDString)
        }
        set {
            cloudKitRecordIDString = newValue?.recordName
        }
    }
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), cloudKitRecordID: CKRecord.ID? = nil, userCloudKitID: String? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.cloudKitRecordIDString = cloudKitRecordID?.recordName
        self.userCloudKitID = userCloudKitID
    }
    
    // MARK: - CloudKit Conversion
    func toCKRecord() -> CKRecord {
        let recordID = cloudKitRecordID ?? CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "Activity", recordID: recordID)
        
        record["id"] = id.uuidString
        record["name"] = name
        record["createdAt"] = createdAt
        
        if let userCloudKitID = userCloudKitID {
            record["userCloudKitID"] = userCloudKitID
        }
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.cloudKitRecordIDString = record.recordID.recordName
        self.userCloudKitID = record["userCloudKitID"] as? String
    }
}

class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    
    private let activitiesKey = "CC_SAVED_ACTIVITIES"
    private let container: CKContainer
    private let database: CKDatabase
    
    private init() {
        container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
        database = container.publicCloudDatabase
        loadActivities()
        syncWithCloudKit()
    }
    
    func addActivity(_ name: String) {
        Task {
            // Get current user ID
            var userCloudKitID: String? = nil
            do {
                let userRecordID = try await container.userRecordID()
                userCloudKitID = userRecordID.recordName
            } catch {
                print("Error getting user ID for activity: \(error)")
            }
            
            let activity = Activity(name: name, userCloudKitID: userCloudKitID)
            
            await MainActor.run {
                activities.append(activity)
                saveActivitiesLocally()
            }
            
            // Save to CloudKit
            do {
                let record = activity.toCKRecord()
                let savedRecord = try await database.save(record)
                await MainActor.run {
                    // Update with CloudKit record ID
                    if let index = activities.firstIndex(where: { $0.id == activity.id }) {
                        var updated = activities[index]
                        updated.cloudKitRecordID = savedRecord.recordID
                        activities[index] = updated
                        saveActivitiesLocally()
                    }
                }
                print("✅ Saved activity to CloudKit: \(name)")
            } catch {
                print("❌ Failed to save activity to CloudKit: \(error)")
            }
        }
    }
    
    func deleteActivity(_ activity: Activity) {
        // Remove locally first
        activities.removeAll { $0.id == activity.id }
        saveActivitiesLocally()
        
        // Delete from CloudKit
        if let recordID = activity.cloudKitRecordID {
            Task {
                do {
                    try await database.deleteRecord(withID: recordID)
                    print("✅ Deleted activity from CloudKit: \(activity.name)")
                } catch {
                    print("❌ Failed to delete activity from CloudKit: \(error)")
                }
            }
        }
    }
    
    func updateActivity(_ activity: Activity, newName: String) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            var updated = Activity(
                id: activity.id,
                name: newName,
                createdAt: activity.createdAt,
                cloudKitRecordID: activity.cloudKitRecordID,
                userCloudKitID: activity.userCloudKitID
            )
            activities[index] = updated
            saveActivitiesLocally()
            
            // Update in CloudKit
            if let recordID = activity.cloudKitRecordID {
                Task {
                    do {
                        let record = updated.toCKRecord()
                        try await database.save(record)
                        print("✅ Updated activity in CloudKit: \(newName)")
                    } catch {
                        print("❌ Failed to update activity in CloudKit: \(error)")
                    }
                }
            }
        }
    }
    
    private func saveActivitiesLocally() {
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: activitiesKey)
        }
    }
    
    private func loadActivities() {
        // Load from local storage first
        if let data = UserDefaults.standard.data(forKey: activitiesKey),
           let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
            activities = decoded
        }
    }
    
    func syncWithCloudKit() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                // Get current user ID
                let userRecordID = try await container.userRecordID()
                let userIDString = userRecordID.recordName
                
                // Query for activities by this user
                let predicate = NSPredicate(format: "userCloudKitID == %@", userIDString)
                let query = CKQuery(recordType: "Activity", predicate: predicate)
                
                let (matchResults, _) = try await database.records(matching: query)
                
                var cloudActivities: [Activity] = []
                for (_, result) in matchResults {
                    switch result {
                    case .success(let record):
                        if let activity = Activity(from: record) {
                            cloudActivities.append(activity)
                        }
                    case .failure(let error):
                        print("Error loading activity: \(error)")
                    }
                }
                
                // Merge with local activities
                await MainActor.run {
                    var merged = activities
                    
                    // Add activities from CloudKit that aren't local
                    for cloudActivity in cloudActivities {
                        if !merged.contains(where: { $0.id == cloudActivity.id }) {
                            merged.append(cloudActivity)
                        }
                    }
                    
                    // Sort by creation date
                    merged.sort { $0.createdAt < $1.createdAt }
                    
                    activities = merged
                    saveActivitiesLocally()
                    isLoading = false
                }
                
                print("✅ Synced \(cloudActivities.count) activities from CloudKit")
            } catch {
                print("❌ Failed to sync activities from CloudKit: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
