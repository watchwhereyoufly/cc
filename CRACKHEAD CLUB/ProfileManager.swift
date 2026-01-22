//
//  ProfileManager.swift
//  CRACKHEAD CLUB
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import CloudKit
import Combine

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var currentProfile: UserProfile?
    
    private let profileKey = "CRACKHEAD_CLUB_USER_PROFILE"
    
    private init() {
        loadProfile()
    }
    
    func saveProfile(_ profile: UserProfile) {
        currentProfile = profile
        saveProfileLocally()
        
        // Save to CloudKit
        Task {
            do {
                let record = profile.toCKRecord()
                let container = CKContainer(identifier: "iCloud.cc.CRACKHEAD-CLUB")
                let database = container.privateCloudDatabase
                let _ = try await database.save(record)
                print("✅ Saved profile to CloudKit")
            } catch {
                print("Failed to save profile to CloudKit: \(error)")
            }
        }
    }
    
    func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentProfile = decoded
        }
    }
    
    private func saveProfileLocally() {
        if let encoded = try? JSONEncoder().encode(currentProfile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    // MARK: - Fetch Profile by Name
    func fetchProfileByName(_ name: String) async -> UserProfile? {
        // First check local cache (if it's the current user's profile)
        if let currentProfile = currentProfile, currentProfile.name.lowercased() == name.lowercased() {
            return currentProfile
        }
        
        // Fetch from CloudKit
        do {
            let container = CKContainer(identifier: "iCloud.cc.CRACKHEAD-CLUB")
            let database = container.privateCloudDatabase
            
            // Query for profile by name
            let predicate = NSPredicate(format: "name == %@", name)
            let query = CKQuery(recordType: "UserProfile", predicate: predicate)
            
            let (matchResults, _) = try await database.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let profile = UserProfile(from: record) {
                        return profile
                    }
                case .failure(let error):
                    print("Error fetching profile record: \(error)")
                }
            }
        } catch {
            print("Failed to fetch profile from CloudKit: \(error)")
        }
        
        return nil
    }
}

