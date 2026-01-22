//
//  EditIdealVisionView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct EditIdealVisionView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var idealVision: String = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Edit Ideal Vision")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 20, design: .monospaced))
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.terminalGreen)
                            .font(.system(size: 18))
                    }
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("What is your ideal vision?")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                    
                    Text("Tell me who you are, where you are, and what you are doing")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 13, design: .monospaced))
                    
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
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.terminalGreen, lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            saveIdealVision()
                        }) {
                            Text("Save")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(idealVision.isEmpty ? Color.terminalGreen.opacity(0.5) : Color.terminalGreen)
                                .cornerRadius(4)
                        }
                        .disabled(idealVision.isEmpty)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            idealVision = profileManager.currentProfile?.idealVision ?? ""
        }
    }
    
    private func saveIdealVision() {
        guard !idealVision.isEmpty,
              let profile = profileManager.currentProfile else { return }
        
        let updatedProfile = UserProfile(
            id: profile.id,
            name: profile.name,
            idealVision: idealVision,
            selfieData: profile.selfieData,
            createdAt: profile.createdAt,
            currentLocation: profile.currentLocation,
            locationHistory: profile.locationHistory,
            cloudKitRecordID: profile.cloudKitRecordID,
            userCloudKitID: profile.userCloudKitID
        )
        
        profileManager.saveProfile(updatedProfile)
        dismiss()
    }
}
