//
//  HealthKitManager.swift
//  CC
//
//  Created by Evan Roberts on 1/27/26.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var autoPostWorkouts = false
    @Published var autoPostSleep = false
    @Published var autoPostWeight = false
    
    private var workoutObserverQuery: HKObserverQuery?
    private var sleepObserverQuery: HKObserverQuery?
    private var weightObserverQuery: HKObserverQuery?
    
    private var lastProcessedWorkoutDate: Date?
    private var lastProcessedSleepDate: Date?
    private var lastProcessedWeightDate: Date?
    
    private let autoPostKey = "CC_HEALTHKIT_AUTO_POST"
    private let autoPostSleepKey = "CC_HEALTHKIT_AUTO_POST_SLEEP"
    private let autoPostWeightKey = "CC_HEALTHKIT_AUTO_POST_WEIGHT"
    private let lastProcessedKey = "CC_HEALTHKIT_LAST_PROCESSED"
    private let lastProcessedSleepKey = "CC_HEALTHKIT_LAST_PROCESSED_SLEEP"
    private let lastProcessedWeightKey = "CC_HEALTHKIT_LAST_PROCESSED_WEIGHT"
    
    private init() {
        // Load saved preferences
        autoPostWorkouts = UserDefaults.standard.bool(forKey: autoPostKey)
        autoPostSleep = UserDefaults.standard.bool(forKey: autoPostSleepKey)
        autoPostWeight = UserDefaults.standard.bool(forKey: autoPostWeightKey)
        
        if let lastDate = UserDefaults.standard.object(forKey: lastProcessedKey) as? Date {
            lastProcessedWorkoutDate = lastDate
        }
        if let lastDate = UserDefaults.standard.object(forKey: lastProcessedSleepKey) as? Date {
            lastProcessedSleepDate = lastDate
        }
        if let lastDate = UserDefaults.standard.object(forKey: lastProcessedWeightKey) as? Date {
            lastProcessedWeightDate = lastDate
        }
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit is not available on this device")
            return
        }
        
        // Request read access to workouts, sleep, and weight
        let workoutType = HKObjectType.workoutType()
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let typesToRead: Set<HKObjectType> = [workoutType, sleepType, weightType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ HealthKit authorization error: \(error)")
                    self?.isAuthorized = false
                } else {
                    self?.isAuthorized = success
                    print("✅ HealthKit authorization: \(success)")
                    
                    if success {
                        self?.setupWorkoutObserver()
                        self?.setupSleepObserver()
                        self?.setupWeightObserver()
                    }
                }
            }
        }
    }
    
    // MARK: - Workout Observer
    private func setupWorkoutObserver() {
        guard isAuthorized else { return }
        
        // Stop existing observer if any
        if let existingQuery = workoutObserverQuery {
            healthStore.stop(existingQuery)
        }
        
        // Create observer query for workouts
        let workoutType = HKObjectType.workoutType()
        
        workoutObserverQuery = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("❌ Workout observer error: \(error)")
                completionHandler()
                return
            }
            
            // Process new workouts
            self?.processNewWorkouts()
            completionHandler()
        }
        
        // Execute the observer query
        if let query = workoutObserverQuery {
            healthStore.execute(query)
            print("✅ Workout observer set up")
        }
    }
    
    // MARK: - Process Workouts
    private func processNewWorkouts() {
        guard autoPostWorkouts else { return }
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Query for workouts from the last processed date (or last 24 hours if first time)
        let startDate = lastProcessedWorkoutDate ?? Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let self = self,
                  let workouts = samples as? [HKWorkout],
                  error == nil else {
                if let error = error {
                    print("❌ Error fetching workouts: \(error)")
                }
                return
            }
            
            // Process workouts (newest first)
            var latestDate = self.lastProcessedWorkoutDate
            for workout in workouts {
                // Only process if this workout is newer than last processed
                if let lastDate = self.lastProcessedWorkoutDate, workout.endDate <= lastDate {
                    continue
                }
                
                // Post workout as activity entry
                self.postWorkoutAsActivity(workout)
                
                // Update latest date
                if latestDate == nil || workout.endDate > latestDate! {
                    latestDate = workout.endDate
                }
            }
            
            // Update last processed date
            if let latest = latestDate {
                DispatchQueue.main.async {
                    self.lastProcessedWorkoutDate = latest
                    UserDefaults.standard.set(latest, forKey: self.lastProcessedKey)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Post Workout
    private func postWorkoutAsActivity(_ workout: HKWorkout) {
        // Get workout type name
        let workoutTypeName = formatWorkoutType(workout.workoutActivityType)
        
        // Calculate duration
        let duration = workout.duration
        let durationText = formatDuration(duration)
        
        // Get current user info
        guard let personName = ProfileManager.shared.currentProfile?.name else {
            print("⚠️ Cannot post workout: Profile not available")
            return
        }
        
        // Post notification to create activity entry
        NotificationCenter.default.post(
            name: NSNotification.Name("HealthKitWorkoutCompleted"),
            object: nil,
            userInfo: [
                "workoutType": workoutTypeName,
                "duration": durationText,
                "personName": personName
            ]
        )
        
        print("✅ Posted workout notification: \(workoutTypeName) for \(durationText)")
    }
    
    // MARK: - Format Workout Type
    private func formatWorkoutType(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running:
            return "Run"
        case .cycling:
            return "Bike"
        case .walking:
            return "Walk"
        case .swimming:
            return "Swim"
        case .traditionalStrengthTraining:
            return "Strength Training"
        case .functionalStrengthTraining:
            return "Functional Training"
        case .yoga:
            return "Yoga"
        case .crossTraining:
            return "Cross Training"
        case .elliptical:
            return "Elliptical"
        case .rowing:
            return "Rowing"
        case .hiking:
            return "Hike"
        case .tennis:
            return "Tennis"
        case .basketball:
            return "Basketball"
        case .soccer:
            return "Soccer"
        case .americanFootball:
            return "Football"
        case .baseball:
            return "Baseball"
        case .golf:
            return "Golf"
        case .boxing:
            return "Boxing"
        case .martialArts:
            return "Martial Arts"
        case .dance:
            return "Dance"
        case .coreTraining:
            return "Core Training"
        case .flexibility:
            return "Flexibility"
        case .pilates:
            return "Pilates"
        case .barre:
            return "Barre"
        case .cooldown:
            return "Cooldown"
        case .crossCountrySkiing:
            return "Cross Country Skiing"
        case .downhillSkiing:
            return "Downhill Skiing"
        case .snowboarding:
            return "Snowboarding"
        case .surfingSports:
            return "Surfing"
        case .waterSports:
            return "Water Sports"
        case .climbing:
            return "Climbing"
        case .mixedCardio:
            return "Mixed Cardio"
        case .handCycling:
            return "Hand Cycling"
        case .discSports:
            return "Disc Sports"
        case .fitnessGaming:
            return "Fitness Gaming"
        default:
            return "Exercise"
        }
    }
    
    // MARK: - Format Duration
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return hours == 1 ? "1 hour \(minutes) minutes" : "\(hours) hours \(minutes) minutes"
        } else if hours > 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        } else if minutes > 0 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        } else {
            return "30 minutes" // Default fallback
        }
    }
    
    // MARK: - Sleep Observer
    private func setupSleepObserver() {
        guard isAuthorized else { return }
        
        // Stop existing observer if any
        if let existingQuery = sleepObserverQuery {
            healthStore.stop(existingQuery)
        }
        
        // Create observer query for sleep
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        sleepObserverQuery = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("❌ Sleep observer error: \(error)")
                completionHandler()
                return
            }
            
            // Process new sleep data
            self?.processNewSleep()
            completionHandler()
        }
        
        // Execute the observer query
        if let query = sleepObserverQuery {
            healthStore.execute(query)
            print("✅ Sleep observer set up")
        }
    }
    
    // MARK: - Process Sleep
    private func processNewSleep() {
        guard autoPostSleep else { return }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Query for sleep from the last processed date (or last 24 hours if first time)
        let startDate = lastProcessedSleepDate ?? Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let self = self,
                  let sleepSamples = samples as? [HKCategorySample],
                  error == nil else {
                if let error = error {
                    print("❌ Error fetching sleep: \(error)")
                }
                return
            }
            
            // Group sleep samples by night (sleep sessions that ended today)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            var latestDate = self.lastProcessedSleepDate
            var sleepSessionsByNight: [Date: [HKCategorySample]] = [:]
            
            for sample in sleepSamples {
                // Only process if this sleep session is newer than last processed
                if let lastDate = self.lastProcessedSleepDate, sample.endDate <= lastDate {
                    continue
                }
                
                // Group by the date the sleep session ended (wake up date)
                let wakeUpDate = calendar.startOfDay(for: sample.endDate)
                
                // Only process sleep sessions that ended today (woke up today)
                if wakeUpDate == today {
                    if sleepSessionsByNight[wakeUpDate] == nil {
                        sleepSessionsByNight[wakeUpDate] = []
                    }
                    sleepSessionsByNight[wakeUpDate]?.append(sample)
                    
                    // Update latest date
                    if latestDate == nil || sample.endDate > latestDate! {
                        latestDate = sample.endDate
                    }
                }
            }
            
            // Post sleep data for each night
            for (_, sessions) in sleepSessionsByNight {
                self.postSleepAsEntry(sessions)
            }
            
            // Update last processed date
            if let latest = latestDate {
                DispatchQueue.main.async {
                    self.lastProcessedSleepDate = latest
                    UserDefaults.standard.set(latest, forKey: self.lastProcessedSleepKey)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Post Sleep
    private func postSleepAsEntry(_ sleepSessions: [HKCategorySample]) {
        // Calculate total sleep time
        var totalSleepSeconds: TimeInterval = 0
        var deepSleepSeconds: TimeInterval = 0
        var remSleepSeconds: TimeInterval = 0
        var lightSleepSeconds: TimeInterval = 0
        
        for session in sleepSessions {
            let duration = session.endDate.timeIntervalSince(session.startDate)
            totalSleepSeconds += duration
            
            // Categorize sleep stages
            switch session.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepSleepSeconds += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remSleepSeconds += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue, HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                lightSleepSeconds += duration
            default:
                break
            }
        }
        
        // Format sleep data
        let totalHours = Int(totalSleepSeconds) / 3600
        let totalMinutes = (Int(totalSleepSeconds) % 3600) / 60
        
        var sleepDataParts: [String] = []
        sleepDataParts.append("\(totalHours)h \(totalMinutes)m total")
        
        if deepSleepSeconds > 0 {
            let deepMinutes = Int(deepSleepSeconds) / 60
            sleepDataParts.append("\(deepMinutes)m deep")
        }
        if remSleepSeconds > 0 {
            let remMinutes = Int(remSleepSeconds) / 60
            sleepDataParts.append("\(remMinutes)m REM")
        }
        
        let sleepDataText = sleepDataParts.joined(separator: ", ")
        
        // Get wake-up time (end date of the latest sleep session)
        let wakeUpTime = sleepSessions.map { $0.endDate }.max() ?? Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let wakeUpTimeString = timeFormatter.string(from: wakeUpTime)
        
        // Get current user info
        guard let personName = ProfileManager.shared.currentProfile?.name else {
            print("⚠️ Cannot post sleep: Profile not available")
            return
        }
        
        // Post notification to create entry
        NotificationCenter.default.post(
            name: NSNotification.Name("HealthKitSleepCompleted"),
            object: nil,
            userInfo: [
                "sleepData": sleepDataText,
                "wakeUpTime": wakeUpTimeString,
                "personName": personName
            ]
        )
        
        print("✅ Posted sleep notification: \(sleepDataText)")
    }
    
    // MARK: - Weight Observer
    private func setupWeightObserver() {
        guard isAuthorized else { return }
        
        // Stop existing observer if any
        if let existingQuery = weightObserverQuery {
            healthStore.stop(existingQuery)
        }
        
        // Create observer query for weight
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        
        weightObserverQuery = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("❌ Weight observer error: \(error)")
                completionHandler()
                return
            }
            
            // Process new weight data
            self?.processNewWeight()
            completionHandler()
        }
        
        // Execute the observer query
        if let query = weightObserverQuery {
            healthStore.execute(query)
            print("✅ Weight observer set up")
        }
    }
    
    // MARK: - Process Weight
    private func processNewWeight() {
        guard autoPostWeight else { return }
        
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Query for weight from the last processed date (or last 24 hours if first time)
        let startDate = lastProcessedWeightDate ?? Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let self = self,
                  let weightSamples = samples as? [HKQuantitySample],
                  error == nil else {
                if let error = error {
                    print("❌ Error fetching weight: \(error)")
                }
                return
            }
            
            // Process weight samples (newest first)
            var latestDate = self.lastProcessedWeightDate
            
            for sample in weightSamples {
                // Only process if this weight is newer than last processed
                if let lastDate = self.lastProcessedWeightDate, sample.endDate <= lastDate {
                    continue
                }
                
                // Post weight as entry
                self.postWeightAsEntry(sample)
                
                // Update latest date
                if latestDate == nil || sample.endDate > latestDate! {
                    latestDate = sample.endDate
                }
            }
            
            // Update last processed date
            if let latest = latestDate {
                DispatchQueue.main.async {
                    self.lastProcessedWeightDate = latest
                    UserDefaults.standard.set(latest, forKey: self.lastProcessedWeightKey)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Post Weight
    private func postWeightAsEntry(_ weightSample: HKQuantitySample) {
        // Convert weight to pounds
        let weightInPounds = weightSample.quantity.doubleValue(for: HKUnit.pound())
        let weightText = String(format: "%.1f lbs", weightInPounds)
        
        // Get current user info
        guard let personName = ProfileManager.shared.currentProfile?.name else {
            print("⚠️ Cannot post weight: Profile not available")
            return
        }
        
        // Post notification to create entry
        NotificationCenter.default.post(
            name: NSNotification.Name("HealthKitWeightCompleted"),
            object: nil,
            userInfo: [
                "weight": weightText,
                "personName": personName
            ]
        )
        
        print("✅ Posted weight notification: \(weightText)")
    }
    
    // MARK: - Toggle Auto-Post
    func setAutoPostWorkouts(_ enabled: Bool) {
        autoPostWorkouts = enabled
        UserDefaults.standard.set(enabled, forKey: autoPostKey)
        
        if enabled && isAuthorized {
            setupWorkoutObserver()
            // Also process any recent workouts
            processNewWorkouts()
        } else if let query = workoutObserverQuery {
            healthStore.stop(query)
            workoutObserverQuery = nil
        }
    }
    
    func setAutoPostSleep(_ enabled: Bool) {
        autoPostSleep = enabled
        UserDefaults.standard.set(enabled, forKey: autoPostSleepKey)
        
        if enabled && isAuthorized {
            setupSleepObserver()
            // Also process any recent sleep
            processNewSleep()
        } else if let query = sleepObserverQuery {
            healthStore.stop(query)
            sleepObserverQuery = nil
        }
    }
    
    func setAutoPostWeight(_ enabled: Bool) {
        autoPostWeight = enabled
        UserDefaults.standard.set(enabled, forKey: autoPostWeightKey)
        
        if enabled && isAuthorized {
            setupWeightObserver()
            // Also process any recent weight
            processNewWeight()
        } else if let query = weightObserverQuery {
            healthStore.stop(query)
            weightObserverQuery = nil
        }
    }
    
    // MARK: - Manual Sync
    func syncRecentWorkouts() {
        guard isAuthorized && autoPostWorkouts else { return }
        processNewWorkouts()
    }
    
    func syncRecentSleep() {
        guard isAuthorized && autoPostSleep else { return }
        processNewSleep()
    }
    
    func syncRecentWeight() {
        guard isAuthorized && autoPostWeight else { return }
        processNewWeight()
    }
}
