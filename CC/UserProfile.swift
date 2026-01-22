//
//  UserProfile.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import CloudKit

struct UserProfile: Codable {
    let id: UUID
    let name: String // "Ryan" or "Evan"
    let idealVision: String
    let selfieData: Data?
    let createdAt: Date
    var currentLocation: String?
    var locationHistory: [LocationHistory]
    var cloudKitRecordIDString: String?
    
    var cloudKitRecordID: CKRecord.ID? {
        get {
            guard let recordIDString = cloudKitRecordIDString else { return nil }
            return CKRecord.ID(recordName: recordIDString)
        }
        set {
            cloudKitRecordIDString = newValue?.recordName
        }
    }
    
    init(id: UUID = UUID(), name: String, idealVision: String, selfieData: Data? = nil, createdAt: Date = Date(), currentLocation: String? = nil, locationHistory: [LocationHistory] = [], cloudKitRecordID: CKRecord.ID? = nil) {
        self.id = id
        self.name = name
        self.idealVision = idealVision
        self.selfieData = selfieData
        self.createdAt = createdAt
        self.currentLocation = currentLocation
        self.locationHistory = locationHistory
        self.cloudKitRecordIDString = cloudKitRecordID?.recordName
    }
    
    // MARK: - CloudKit Conversion
    func toCKRecord() -> CKRecord {
        let recordID = cloudKitRecordID ?? CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "UserProfile", recordID: recordID)
        
        record["id"] = id.uuidString
        record["name"] = name
        record["idealVision"] = idealVision
        record["createdAt"] = createdAt
        
        // Store location data
        if let currentLocation = currentLocation {
            record["currentLocation"] = currentLocation
        }
        
        // Store location history as JSON
        if !locationHistory.isEmpty {
            if let historyData = try? JSONEncoder().encode(locationHistory),
               let historyString = String(data: historyData, encoding: .utf8) {
                record["locationHistory"] = historyString
            }
        }
        
        // Handle selfie as CKAsset
        if let selfieData = selfieData {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(id.uuidString)_selfie.jpg")
            do {
                try selfieData.write(to: tempURL)
                record["selfie"] = CKAsset(fileURL: tempURL)
            } catch {
                print("Error creating selfie asset: \(error)")
            }
        }
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let idealVision = record["idealVision"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.idealVision = idealVision
        self.createdAt = createdAt
        self.currentLocation = record["currentLocation"] as? String
        self.cloudKitRecordIDString = record.recordID.recordName
        
        // Load location history from JSON
        if let historyString = record["locationHistory"] as? String,
           let historyData = historyString.data(using: .utf8),
           let decodedHistory = try? JSONDecoder().decode([LocationHistory].self, from: historyData) {
            self.locationHistory = decodedHistory
        } else {
            self.locationHistory = []
        }
        
        // Handle selfie from CKAsset
        var loadedSelfieData: Data? = nil
        if let selfieAsset = record["selfie"] as? CKAsset {
            do {
                loadedSelfieData = try Data(contentsOf: selfieAsset.fileURL!)
            } catch {
                print("Error loading selfie from asset: \(error)")
                loadedSelfieData = nil
            }
        }
        self.selfieData = loadedSelfieData
    }
}
