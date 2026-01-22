//
//  EntryFormView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI
import PhotosUI

struct EntryFormView: View {
    @ObservedObject var entryManager: EntryManager
    @Binding var isExpanded: Bool
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var activity: String = ""
    @State private var assumption: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @FocusState private var focusedField: Field?
    
    private var currentPersonName: String {
        profileManager.currentProfile?.name ?? "Unknown"
    }
    
    enum Field {
        case activity, assumption
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsible header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("New Entry")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 10, design: .monospaced))
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.black)
            }
            
            // Entry form content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
            // Activity Field
            VStack(alignment: .leading, spacing: 6) {
                Text("[Activity]")
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                
                ZStack(alignment: .topLeading) {
                    if activity.isEmpty {
                        Text("studied and logged my winning and losing trades...")
                            .foregroundColor(.terminalGreen.opacity(0.5))
                            .font(.system(size: 15, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)
                    }
                    TextField("", text: $activity, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                        .padding(10)
                        .focused($focusedField, equals: .activity)
                }
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(focusedField == .activity ? Color.terminalGreen : Color.terminalGreen.opacity(0.5), lineWidth: 1)
                )
                .lineLimit(3...8)
            }
            
            // Assumption Field
            VStack(alignment: .leading, spacing: 6) {
                Text("[Assumption]")
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                
                ZStack(alignment: .topLeading) {
                    if assumption.isEmpty {
                        Text("I am full time trader who lives on the beach...")
                            .foregroundColor(.terminalGreen.opacity(0.5))
                            .font(.system(size: 15, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)
                    }
                    TextField("", text: $assumption, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                        .padding(10)
                        .focused($focusedField, equals: .assumption)
                }
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(focusedField == .assumption ? Color.terminalGreen : Color.terminalGreen.opacity(0.5), lineWidth: 1)
                )
                .lineLimit(3...8)
            }
            
            // Image Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("[Image]")
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                
                if let image = selectedImage {
                    HStack(spacing: 12) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 1)
                            )
                        
                        Button(action: {
                            self.selectedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 20))
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Button(action: {
                            showImagePicker = true
                            imagePickerSource = .camera
                        }) {
                            Text("Take Photo")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.terminalGreen)
                                .cornerRadius(2)
                        }
                        
                        Button(action: {
                            showImagePicker = true
                            imagePickerSource = .photoLibrary
                        }) {
                            Text("Add Photo")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.terminalGreen)
                                .cornerRadius(2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: imagePickerSource)
            }
            
            // Submit Button
            Button(action: submitEntry) {
                Text("SUBMIT")
                    .foregroundColor(.black)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.terminalGreen)
                    .cornerRadius(2)
            }
            .disabled(activity.isEmpty || assumption.isEmpty)
            .opacity(activity.isEmpty || assumption.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    private func submitEntry() {
        guard !activity.isEmpty && !assumption.isEmpty else { return }
        guard let personName = profileManager.currentProfile?.name else {
            print("⚠️ No profile found - cannot create entry")
            return
        }
        
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        
        entryManager.addEntry(
            person: personName,
            activity: activity,
            assumption: assumption,
            imageData: imageData
        )
        
        // Clear fields
        activity = ""
        assumption = ""
        selectedImage = nil
        focusedField = nil
        
        // Collapse the form after submission
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }
}
