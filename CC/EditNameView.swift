//
//  EditNameView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct EditNameView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var newName: String = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Edit Name")
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
                    Text("Who are you?")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            newName = "Evan"
                            saveName()
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
                            newName = "Ryan"
                            saveName()
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
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            newName = profileManager.currentProfile?.name ?? ""
        }
    }
    
    private func saveName() {
        guard !newName.isEmpty,
              let profile = profileManager.currentProfile else { return }
        
        let updatedProfile = UserProfile(
            id: profile.id,
            name: newName,
            idealVision: profile.idealVision,
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
