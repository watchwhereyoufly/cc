//
//  OnboardingView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI
import CloudKit

enum OnboardingStep {
    case whoAreYou
    case idealVision
    case currentLocation
    case takeSelfie
    case welcome
}

struct OnboardingView: View {
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject private var profileManager = ProfileManager.shared
    @EnvironmentObject var entryManager: EntryManager
    @State private var currentStep: OnboardingStep = .whoAreYou
    @State private var selectedName: String = ""
    @State private var idealVision: String = ""
    @State private var currentLocation: String = ""
    @State private var selfieImage: UIImage?
    @State private var showCamera = false
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Group {
                switch currentStep {
                case .whoAreYou:
                    whoAreYouView
                case .idealVision:
                    idealVisionView
                case .currentLocation:
                    currentLocationView
                case .takeSelfie:
                    takeSelfieView
                case .welcome:
                    welcomeView
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            // Pre-populate with existing profile if editing
            if let existingProfile = profileManager.currentProfile {
                selectedName = existingProfile.name
                idealVision = existingProfile.idealVision
                currentLocation = existingProfile.currentLocation ?? ""
                if let selfieData = existingProfile.selfieData {
                    selfieImage = UIImage(data: selfieData)
                }
            }
            
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selfieImage, sourceType: .camera)
        }
    }
    
    // MARK: - Who Are You View
    private var whoAreYouView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Who are you?")
                .foregroundColor(.terminalGreen)
                .font(.system(size: 20, design: .monospaced))
                .padding(.bottom, 40)
            
            VStack(spacing: 20) {
                Button(action: {
                    selectedName = "Evan"
                    nextStep()
                }) {
                    Text("Evan")
                        .foregroundColor(.black)
                        .font(.system(size: 15, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.terminalGreen)
                        .cornerRadius(4)
                }
                
                Button(action: {
                    selectedName = "Ryan"
                    nextStep()
                }) {
                    Text("Ryan")
                        .foregroundColor(.black)
                        .font(.system(size: 15, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.terminalGreen)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Ideal Vision View
    private var idealVisionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What is your ideal vision?")
                .foregroundColor(.terminalGreen)
                .font(.system(size: 20, design: .monospaced))
            
            Text("Tell me who you are, where you are, and what you are doing")
                .foregroundColor(.terminalGreen.opacity(0.7))
                .font(.system(size: 15, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            ZStack(alignment: .topLeading) {
                if idealVision.isEmpty {
                    Text("I am a full time trader who lives on the beach in Florida...")
                        .foregroundColor(.terminalGreen.opacity(0.5))
                        .font(.system(size: 15, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 12)
                }
                TextField("", text: $idealVision, axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                    .padding(12)
            }
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 1)
            )
            .frame(height: 150)
            .padding(.horizontal, 40)
            
            Button(action: {
                if !idealVision.isEmpty {
                    nextStep()
                }
            }) {
                Text("Continue")
                    .foregroundColor(.black)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(idealVision.isEmpty ? Color.terminalGreen.opacity(0.5) : Color.terminalGreen)
                    .cornerRadius(4)
            }
            .disabled(idealVision.isEmpty)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Current Location View
    private var currentLocationView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("What's your current location?")
                .foregroundColor(.terminalGreen)
                .font(.system(size: 20, design: .monospaced))
            
            Text("Where are you right now?")
                .foregroundColor(.terminalGreen.opacity(0.7))
                .font(.system(size: 15, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            ZStack(alignment: .topLeading) {
                if currentLocation.isEmpty {
                    Text("Miami, FL")
                        .foregroundColor(.terminalGreen.opacity(0.5))
                        .font(.system(size: 15, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 12)
                }
                TextField("", text: $currentLocation)
                    .textFieldStyle(.plain)
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                    .padding(12)
            }
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 1)
            )
            .frame(height: 50)
            .padding(.horizontal, 40)
            
            Button(action: {
                if !currentLocation.isEmpty {
                    nextStep()
                }
            }) {
                Text("Continue")
                    .foregroundColor(.black)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(currentLocation.isEmpty ? Color.terminalGreen.opacity(0.5) : Color.terminalGreen)
                    .cornerRadius(4)
            }
            .disabled(currentLocation.isEmpty)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Take Selfie View
    private var takeSelfieView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Take a selfie")
                .foregroundColor(.terminalGreen)
                .font(.system(size: 20, design: .monospaced))
            
            Text("This is what you can show your future self when you get there and where you came from")
                .foregroundColor(.terminalGreen.opacity(0.7))
                .font(.system(size: 15, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            if let selfieImage = selfieImage {
                Image(uiImage: selfieImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.terminalGreen, lineWidth: 2)
                    )
                    .padding(.bottom, 30)
            } else {
                Circle()
                    .fill(Color.black)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.terminalGreen.opacity(0.5))
                            .font(.system(size: 50))
                    )
                    .padding(.bottom, 30)
            }
            
            Button(action: {
                showCamera = true
            }) {
                Text("Take Selfie")
                    .foregroundColor(.black)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.terminalGreen)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            
            if selfieImage != nil {
                Button(action: {
                    nextStep()
                }) {
                    Text("Continue")
                        .foregroundColor(.black)
                        .font(.system(size: 15, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.terminalGreen)
                        .cornerRadius(4)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Welcome to CC,")
                .foregroundColor(.terminalGreen)
                .font(.system(size: 20, design: .monospaced))
            
            Text(selectedName)
                .foregroundColor(.terminalGreen)
                .font(.system(size: 24, design: .monospaced))
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                completeOnboarding()
            }) {
                Text("Continue")
                    .foregroundColor(.black)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.terminalGreen)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Navigation
    private func nextStep() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch currentStep {
            case .whoAreYou:
                currentStep = .idealVision
            case .idealVision:
                currentStep = .currentLocation
            case .currentLocation:
                currentStep = .takeSelfie
            case .takeSelfie:
                currentStep = .welcome
            case .welcome:
                break
            }
            
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
        }
    }
    
    private func completeOnboarding() {
        let selfieData = selfieImage?.jpegData(compressionQuality: 0.8)
        
        // Create initial location history entry
        let initialLocation = LocationHistory(location: currentLocation, date: Date(), isTravel: false)
        
        // Get user's CloudKit ID
        Task {
            let container = CKContainer(identifier: "iCloud.cc.crackheadclub.CCApp")
            var userCloudKitID: String? = nil
            
            do {
                let userRecordID = try await container.userRecordID()
                userCloudKitID = userRecordID.recordName
            } catch {
                print("Error getting user ID: \(error)")
            }
            
            await MainActor.run {
                let profile = UserProfile(
                    name: selectedName,
                    idealVision: idealVision,
                    selfieData: selfieData,
                    currentLocation: currentLocation,
                    locationHistory: [initialLocation],
                    userCloudKitID: userCloudKitID
                )
                
                // Save profile
                ProfileManager.shared.saveProfile(profile)
                
                // Create location entry in timeline
                entryManager.addLocationEntry(userName: selectedName, location: currentLocation, isTravel: false)
                
                // Mark onboarding as complete
                UserDefaults.standard.set(true, forKey: "CC_ONBOARDING_COMPLETE")
                
                // Complete authentication
                authManager.completeOnboarding()
            }
        }
    }
}
