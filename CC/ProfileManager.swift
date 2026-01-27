//
//  ProfileManager.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import Foundation
import CloudKit
import Combine

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var currentProfile: UserProfile?
    @Published var isLoadingFromCloudKit = false
    
    private let profileKey = "CC_USER_PROFILE"
    
    private init() {
        loadProfile()
    }
    
    func saveProfile(_ profile: UserProfile) {
        currentProfile = profile
        saveProfileLocally()
        
        // Save to CloudKit
        Task {
            do {
                // Ensure userCloudKitID is set
                var profileToSave = profile
                if profileToSave.userCloudKitID == nil {
                    let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
                    let userRecordID = try await container.userRecordID()
                    profileToSave.userCloudKitID = userRecordID.recordName
                    await MainActor.run {
                        self.currentProfile = profileToSave
                        self.saveProfileLocally()
                    }
                }
                
                let record = profileToSave.toCKRecord()
                let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
                let database = container.publicCloudDatabase
                let savedRecord = try await database.save(record)
                print("✅ Saved profile to CloudKit: \(savedRecord.recordID)")
                print("   - Name: \(profileToSave.name)")
                print("   - userCloudKitID: \(profileToSave.userCloudKitID ?? "nil")")
                print("   - Record ID: \(savedRecord.recordID.recordName)")
            } catch {
                print("❌ Failed to save profile to CloudKit: \(error)")
                if let ckError = error as? CKError {
                    print("   - Code: \(ckError.code.rawValue)")
                    print("   - Description: \(ckError.localizedDescription)")
                    if let serverError = ckError.userInfo["NSUnderlyingError"] as? NSError {
                        print("   - Server Error: \(serverError.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func loadProfile() {
        // First try local storage
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentProfile = decoded
        }
        
        // Then try to load from CloudKit if we have a user ID
        Task {
            await loadProfileFromCloudKit()
        }
    }
    
    func loadProfileFromCloudKit() async {
        await MainActor.run {
            isLoadingFromCloudKit = true
        }
        
        // Get current user ID from CloudKit
        let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
        
        do {
            let userRecordID = try await container.userRecordID()
            let userIDString = userRecordID.recordName
            let database = container.publicCloudDatabase
            
            // Query for profile by userCloudKitID
            let predicate = NSPredicate(format: "userCloudKitID == %@", userIDString)
            let query = CKQuery(recordType: "UserProfile", predicate: predicate)
            
            let (matchResults, _) = try await database.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let profile = UserProfile(from: record) {
                        await MainActor.run {
                            self.currentProfile = profile
                            self.saveProfileLocally()
                            self.isLoadingFromCloudKit = false
                            // Mark onboarding as complete since we found the profile
                            UserDefaults.standard.set(true, forKey: "CC_ONBOARDING_COMPLETE")
                        }
                        print("✅ Loaded profile from CloudKit for user: \(userIDString)")
                        return
                    }
                case .failure(let error):
                    print("Error fetching profile record: \(error)")
                }
            }
            
            // If no profile found by userCloudKitID, try to find any profile (for backward compatibility)
            // This handles old profiles that don't have userCloudKitID set
            if currentProfile == nil {
                let allQuery = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
                let (allResults, _) = try await database.records(matching: allQuery)
                
                for (_, result) in allResults {
                    switch result {
                    case .success(let record):
                        if let profile = UserProfile(from: record) {
                            // Update it with the current user's ID and save it
                            var updatedProfile = profile
                            updatedProfile.userCloudKitID = userIDString
                            await MainActor.run {
                                self.currentProfile = updatedProfile
                                self.saveProfileLocally()
                            }
                            // Save the updated profile back to CloudKit
                            self.saveProfile(updatedProfile)
                            await MainActor.run {
                                self.isLoadingFromCloudKit = false
                                // Mark onboarding as complete since we found the profile
                                UserDefaults.standard.set(true, forKey: "CC_ONBOARDING_COMPLETE")
                            }
                            print("✅ Found and updated old profile from CloudKit")
                            return
                        }
                    case .failure(let error):
                        print("Error fetching profile record: \(error)")
                    }
                }
            }
            
            // No profile found in CloudKit - user needs to go through onboarding
            await MainActor.run {
                self.isLoadingFromCloudKit = false
                self.currentProfile = nil
                // Ensure onboarding flag is false so user can go through onboarding
                UserDefaults.standard.set(false, forKey: "CC_ONBOARDING_COMPLETE")
                print("ℹ️ No profile found in CloudKit - user needs to complete onboarding")
            }
        } catch {
            print("Failed to load profile from CloudKit: \(error)")
            await MainActor.run {
                self.isLoadingFromCloudKit = false
                self.currentProfile = nil
                // Ensure onboarding flag is false so user can go through onboarding
                UserDefaults.standard.set(false, forKey: "CC_ONBOARDING_COMPLETE")
            }
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
            let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
            let database = container.publicCloudDatabase
            
            // Try querying by name first (case-insensitive)
            let namePredicate = NSPredicate(format: "name ==[c] %@", name)
            let nameQuery = CKQuery(recordType: "UserProfile", predicate: namePredicate)
            
            let (matchResults, _) = try await database.records(matching: nameQuery)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let profile = UserProfile(from: record) {
                        print("✅ Found profile by name: \(name) -> \(profile.name)")
                        return profile
                    }
                case .failure(let error):
                    print("Error fetching profile record: \(error)")
                }
            }
            
            // If name query fails, try fetching all profiles and matching manually
            // (This is a fallback if name field isn't queryable)
            print("⚠️ Name query didn't find profile, trying fallback method...")
            let allQuery = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
            let (allResults, _) = try await database.records(matching: allQuery)
            
            for (_, result) in allResults {
                switch result {
                case .success(let record):
                    if let profile = UserProfile(from: record),
                       profile.name.lowercased() == name.lowercased() {
                        print("✅ Found profile by fallback method: \(name) -> \(profile.name)")
                        return profile
                    }
                case .failure(let error):
                    print("Error fetching profile record: \(error)")
                }
            }
        } catch {
            print("❌ Failed to fetch profile from CloudKit: \(error)")
            if let ckError = error as? CKError {
                print("   - Code: \(ckError.code.rawValue)")
                print("   - Description: \(ckError.localizedDescription)")
            }
        }
        
        print("⚠️ Profile not found for name: \(name)")
        return nil
    }
    
    // MARK: - Fetch Profile by User ID
    func fetchProfileByUserID(_ userID: String) async -> UserProfile? {
        // First check local cache (if it's the current user's profile)
        if let currentProfile = currentProfile, currentProfile.userCloudKitID == userID {
            return currentProfile
        }
        
        // Fetch from CloudKit
        do {
            let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
            let database = container.publicCloudDatabase
            
            // Query for profile by userCloudKitID (this should be queryable)
            let predicate = NSPredicate(format: "userCloudKitID == %@", userID)
            let query = CKQuery(recordType: "UserProfile", predicate: predicate)
            
            let (matchResults, _) = try await database.records(matching: query)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let profile = UserProfile(from: record) {
                        print("✅ Found profile by userID: \(userID) -> \(profile.name)")
                        return profile
                    }
                case .failure(let error):
                    print("Error fetching profile record: \(error)")
                }
            }
        } catch {
            print("❌ Failed to fetch profile by userID from CloudKit: \(error)")
            if let ckError = error as? CKError {
                print("   - Code: \(ckError.code.rawValue)")
                print("   - Description: \(ckError.localizedDescription)")
            }
        }
        
        print("⚠️ Profile not found for userID: \(userID)")
        return nil
    }
    
    // MARK: - Fetch All Profiles and Match (Fallback)
    func fetchAllProfilesAndMatch(name: String) async -> UserProfile? {
        do {
            let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
            let database = container.publicCloudDatabase
            
            // Fetch ALL profiles from CloudKit
            let allQuery = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
            let (allResults, _) = try await database.records(matching: allQuery)
            
            print("📋 Found \(allResults.count) total profiles in CloudKit")
            
            var allProfiles: [UserProfile] = []
            for (_, result) in allResults {
                switch result {
                case .success(let record):
                    if let profile = UserProfile(from: record) {
                        allProfiles.append(profile)
                        print("   - Profile: \(profile.name) (userCloudKitID: \(profile.userCloudKitID ?? "nil"))")
                    }
                case .failure(let error):
                    print("   - Error loading profile: \(error)")
                }
            }
            
            // Try to match by name (case-insensitive)
            if let matched = allProfiles.first(where: { $0.name.lowercased() == name.lowercased() }) {
                print("✅ Found profile by matching all profiles: \(name) -> \(matched.name)")
                return matched
            }
            
            print("⚠️ No profile found matching name: \(name)")
            print("   Available profiles: \(allProfiles.map { $0.name })")
            
        } catch {
            print("❌ Failed to fetch all profiles: \(error)")
            if let ckError = error as? CKError {
                print("   - Code: \(ckError.code.rawValue)")
                print("   - Description: \(ckError.localizedDescription)")
            }
        }
        
        return nil
    }
    
    // MARK: - Delete Profile
    func deleteProfile(_ profile: UserProfile) async {
        // Delete from CloudKit
        if let recordID = profile.cloudKitRecordID {
            do {
                let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
                let database = container.publicCloudDatabase
                try await database.deleteRecord(withID: recordID)
                print("✅ Deleted profile from CloudKit: \(recordID)")
            } catch {
                print("❌ Failed to delete profile from CloudKit: \(error)")
                if let ckError = error as? CKError {
                    print("   - Code: \(ckError.code.rawValue)")
                    print("   - Description: \(ckError.localizedDescription)")
                }
            }
        }
        
        // Clear local profile
        await MainActor.run {
            self.currentProfile = nil
            UserDefaults.standard.removeObject(forKey: profileKey)
        }
    }
}

