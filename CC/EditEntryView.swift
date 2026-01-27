//
//  EditEntryView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct EditEntryView: View {
    let entry: Entry
    @ObservedObject var entryManager: EntryManager
    @Environment(\.dismiss) var dismiss
    
    @State private var activity: String = ""
    @State private var assumption: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @FocusState private var focusedField: Field?
    
    enum Field {
        case activity, assumption
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text(entry.entryType == .activity ? "Edit Activity" : "Edit Entry")
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
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Activity Field (only for regular entries)
                    if entry.entryType == .regular {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("[Activity]")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            
                            ZStack(alignment: .topLeading) {
                                if activity.isEmpty {
                                    Text("Enter activity...")
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
                                    Text("Enter assumption...")
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
                            } else if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                                HStack(spacing: 12) {
                                    Image(uiImage: uiImage)
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
                    } else if entry.entryType == .activity {
                        // For activity entries, allow editing the activity name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("[Activity Name]")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            
                            ZStack(alignment: .topLeading) {
                                if activity.isEmpty {
                                    Text("Enter activity name...")
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
                    } else {
                        // For location entries, show read-only info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Entry Type: \(entry.entryType.rawValue)")
                                .foregroundColor(.terminalGreen.opacity(0.7))
                                .font(.system(size: 13, design: .monospaced))
                            Text(entry.activity)
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                        }
                        .padding()
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    // Save Button (for regular and activity entries)
                    if entry.entryType == .regular || entry.entryType == .activity {
                        Button(action: saveEntry) {
                            Text("SAVE")
                                .foregroundColor(.black)
                                .font(.system(size: 15, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(canSave ? Color.terminalGreen : Color.terminalGreen.opacity(0.5))
                                .cornerRadius(2)
                        }
                        .disabled(!canSave)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Pre-populate fields
            activity = entry.activity
            assumption = entry.assumption
            if let imageData = entry.imageData {
                selectedImage = UIImage(data: imageData)
            }
        }
    }
    
    private var canSave: Bool {
        if entry.entryType == .regular {
            return !activity.isEmpty && !assumption.isEmpty
        } else if entry.entryType == .activity {
            return !activity.isEmpty
        }
        return false
    }
    
    private func saveEntry() {
        if entry.entryType == .regular {
            guard !activity.isEmpty && !assumption.isEmpty else { return }
            
            let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
            
            entryManager.updateEntry(
                entry: entry,
                activity: activity,
                assumption: assumption,
                imageData: imageData
            )
        } else if entry.entryType == .activity {
            guard !activity.isEmpty else { return }
            
            entryManager.updateEntry(
                entry: entry,
                activity: activity,
                assumption: "",
                imageData: nil
            )
        }
        
        dismiss()
    }
}
