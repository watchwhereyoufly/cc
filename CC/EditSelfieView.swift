//
//  EditSelfieView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct EditSelfieView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selfieImage: UIImage?
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Edit Selfie")
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
                
                VStack(spacing: 20) {
                    Text("Take a selfie")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 20, design: .monospaced))
                    
                    Text("This is what you can show your future self when you get there and where you came from")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 15, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
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
                    } else if let existingSelfie = profileManager.currentProfile?.selfieData,
                              let existingImage = UIImage(data: existingSelfie) {
                        Image(uiImage: existingImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.terminalGreen, lineWidth: 2)
                            )
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
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            showImagePicker = true
                            imagePickerSource = .camera
                        }) {
                            Text("Take Photo")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.terminalGreen)
                                .cornerRadius(4)
                        }
                        
                        Button(action: {
                            showImagePicker = true
                            imagePickerSource = .photoLibrary
                        }) {
                            Text("Choose Photo")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.terminalGreen)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    if selfieImage != nil {
                        Button(action: {
                            saveSelfie()
                        }) {
                            Text("Save")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.terminalGreen)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selfieImage, sourceType: imagePickerSource)
        }
    }
    
    private func saveSelfie() {
        guard let profile = profileManager.currentProfile else { return }
        
        let selfieData = selfieImage?.jpegData(compressionQuality: 0.8)
        
        let updatedProfile = UserProfile(
            id: profile.id,
            name: profile.name,
            idealVision: profile.idealVision,
            selfieData: selfieData,
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
