//
//  Entry.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import CloudKit

struct Entry: Identifiable, Codable {
    let id: UUID
    let person: String // "Ryan" or "Evan"
    let activity: String
    let assumption: String
    let timestamp: Date
    var cloudKitRecordIDString: String?
    var lastModified: Date?
    var imageData: Data?
    var imageURL: String? // Local file URL for cached images
    
    var cloudKitRecordID: CKRecord.ID? {
        get {
            guard let recordIDString = cloudKitRecordIDString else { return nil }
            return CKRecord.ID(recordName: recordIDString)
        }
        set {
            cloudKitRecordIDString = newValue?.recordName
        }
    }
    
    init(id: UUID = UUID(), person: String, activity: String, assumption: String, timestamp: Date = Date(), cloudKitRecordID: CKRecord.ID? = nil, lastModified: Date? = nil, imageData: Data? = nil, imageURL: String? = nil) {
        self.id = id
        self.person = person
        self.activity = activity
        self.assumption = assumption
        self.timestamp = timestamp
        self.cloudKitRecordIDString = cloudKitRecordID?.recordName
        self.lastModified = lastModified ?? timestamp
        self.imageData = imageData
        self.imageURL = imageURL
    }
    
    // MARK: - CloudKit Conversion
    func toCKRecord() -> CKRecord {
        let recordID = cloudKitRecordID ?? CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "Entry", recordID: recordID)
        
        record["id"] = id.uuidString
        record["person"] = person
        record["activity"] = activity
        record["assumption"] = assumption
        record["timestamp"] = timestamp
        record["lastModified"] = lastModified ?? timestamp
        
        // Handle image as CKAsset
        if let imageData = imageData {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(id.uuidString).jpg")
            do {
                try imageData.write(to: tempURL)
                record["image"] = CKAsset(fileURL: tempURL)
            } catch {
                print("Error creating image asset: \(error)")
            }
        }
        
        return record
    }
    
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let person = record["person"] as? String,
              let activity = record["activity"] as? String,
              let assumption = record["assumption"] as? String,
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }
        
        self.id = id
        self.person = person
        self.activity = activity
        self.assumption = assumption
        self.timestamp = timestamp
        self.cloudKitRecordID = record.recordID
        self.lastModified = record["lastModified"] as? Date ?? record.modificationDate ?? timestamp
        
        // Handle image from CKAsset
        if let imageAsset = record["image"] as? CKAsset {
            do {
                let imageData = try Data(contentsOf: imageAsset.fileURL!)
                self.imageData = imageData
                // Cache the image locally
                let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("\(id.uuidString).jpg")
                try imageData.write(to: cacheURL)
                self.imageURL = cacheURL.path
            } catch {
                print("Error loading image from asset: \(error)")
                self.imageData = nil
            }
        } else {
            self.imageData = nil
        }
    }
}
