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
    @ObservedObject private var activityManager = ActivityManager.shared
    @State private var activity: String = ""
    @State private var assumption: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isActivityMode = false
    @State private var selectedActivity: Activity?
    @State private var newActivityName: String = ""
    @State private var showCreateActivity = false
    @State private var activityDuration: String? = nil
    @State private var showCustomDurationPicker = false
    @State private var customDurationHours: Int = 0
    @State private var customDurationMinutes: Int = 30
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
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isActivityMode ? "New Activity" : "New Entry")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isActivityMode.toggle()
                        // Clear fields when switching modes
                        activity = ""
                        assumption = ""
                        selectedImage = nil
                        selectedActivity = nil
                        activityDuration = nil
                        showCustomDurationPicker = false
                        customDurationHours = 0
                        customDurationMinutes = 30
                    }
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.black)
            
            // Entry form content
            if isExpanded {
                if isActivityMode {
                    activityModeView
                } else {
                    entryModeView
                }
            }
        }
    }
    
    // MARK: - Activity Mode View
    private var activityModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Activity")
                .foregroundColor(.terminalGreen)
                .font(.system(size: 15, design: .monospaced))
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(activityManager.activities) { savedActivity in
                        Button(action: {
                            selectedActivity = savedActivity
                        }) {
                            HStack {
                                Text(savedActivity.name)
                                    .foregroundColor(selectedActivity?.id == savedActivity.id ? .black : .terminalGreen)
                                    .font(.system(size: 15, design: .monospaced))
                                Spacer()
                                if selectedActivity?.id == savedActivity.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.black)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding()
                            .background(selectedActivity?.id == savedActivity.id ? Color.terminalGreen : Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.terminalGreen, lineWidth: 1)
                            )
                        }
                        .contextMenu {
                            Button(action: {
                                newActivityName = savedActivity.name
                                selectedActivity = savedActivity
                                showCreateActivity = true
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                activityManager.deleteActivity(savedActivity)
                                if selectedActivity?.id == savedActivity.id {
                                    selectedActivity = nil
                                }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Create Activity Button
                    Button(action: {
                        showCreateActivity = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 14))
                            Text("Create Activity")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            Spacer()
                        }
                        .padding()
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.terminalGreen, lineWidth: 1)
                        )
                    }
                }
            }
            .frame(maxHeight: 200)
            
            // Activity Duration
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Duration")
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                
                HStack(spacing: 12) {
                    // 30 Minutes Button
                    Button(action: {
                        activityDuration = "30 minutes"
                        showCustomDurationPicker = false
                    }) {
                        Text("30 Minutes")
                            .foregroundColor(activityDuration == "30 minutes" ? .black : .terminalGreen)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(activityDuration == "30 minutes" ? Color.terminalGreen : Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.terminalGreen, lineWidth: 1)
                            )
                    }
                    
                    // One Hour Button
                    Button(action: {
                        activityDuration = "1 hour"
                        showCustomDurationPicker = false
                    }) {
                        Text("One Hour")
                            .foregroundColor(activityDuration == "1 hour" ? .black : .terminalGreen)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(activityDuration == "1 hour" ? Color.terminalGreen : Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.terminalGreen, lineWidth: 1)
                            )
                    }
                    
                    // Custom Button
                    Button(action: {
                        showCustomDurationPicker.toggle()
                    }) {
                        Text("Custom")
                            .foregroundColor(showCustomDurationPicker || (activityDuration != nil && activityDuration != "30 minutes" && activityDuration != "1 hour") ? .black : .terminalGreen)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(showCustomDurationPicker || (activityDuration != nil && activityDuration != "30 minutes" && activityDuration != "1 hour") ? Color.terminalGreen : Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.terminalGreen, lineWidth: 1)
                            )
                    }
                }
                
                // Custom Duration Picker
                if showCustomDurationPicker {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hours:")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 13, design: .monospaced))
                            Picker("Hours", selection: $customDurationHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            
                            Text("Minutes:")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 13, design: .monospaced))
                            Picker("Minutes", selection: $customDurationMinutes) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                        }
                        
                        Button(action: {
                            let durationText = formatCustomDuration(hours: customDurationHours, minutes: customDurationMinutes)
                            activityDuration = durationText
                        }) {
                            Text("Set Duration")
                                .foregroundColor(.black)
                                .font(.system(size: 13, design: .monospaced))
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color.terminalGreen)
                                .cornerRadius(2)
                        }
                    }
                    .padding()
                    .background(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.terminalGreen.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            
            // Submit Button
            Button(action: submitActivity) {
                Text("SUBMIT")
                    .foregroundColor(.black)
                    .font(.system(size: 15, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(selectedActivity != nil && activityDuration != nil ? Color.terminalGreen : Color.terminalGreen.opacity(0.5))
                    .cornerRadius(2)
            }
            .disabled(selectedActivity == nil || activityDuration == nil)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .sheet(isPresented: $showCreateActivity) {
            CreateActivityView(
                activityName: $newActivityName,
                editingActivity: selectedActivity,
                onSave: {
                    if !newActivityName.isEmpty {
                        if let editing = selectedActivity {
                            // Update existing activity
                            activityManager.updateActivity(editing, newName: newActivityName)
                            // Update selected activity
                            if let updated = activityManager.activities.first(where: { $0.id == editing.id }) {
                                selectedActivity = updated
                            }
                        } else {
                            // Create new activity
                            activityManager.addActivity(newActivityName)
                            selectedActivity = activityManager.activities.last
                        }
                        newActivityName = ""
                    }
                    showCreateActivity = false
                },
                onCancel: {
                    newActivityName = ""
                    showCreateActivity = false
                }
            )
        }
    }
    
    // MARK: - Entry Mode View
    private var entryModeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Activity Field
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
    
    private func submitActivity() {
        guard let activity = selectedActivity,
              let duration = activityDuration else { return }
        guard let personName = profileManager.currentProfile?.name else {
            print("⚠️ No profile found - cannot create activity entry")
            return
        }
        
        entryManager.addActivityEntry(
            person: personName,
            activityName: activity.name,
            duration: duration
        )
        
        // Clear selection
        selectedActivity = nil
        activityDuration = nil
        showCustomDurationPicker = false
        customDurationHours = 0
        customDurationMinutes = 30
        
        // Collapse the form after submission
        withAnimation(.easeInOut(duration: 0.3)) {
            isExpanded = false
        }
    }
    
    private func formatCustomDuration(hours: Int, minutes: Int) -> String {
        if hours == 0 && minutes == 0 {
            return "30 minutes" // Default
        }
        var parts: [String] = []
        if hours > 0 {
            parts.append(hours == 1 ? "1 hour" : "\(hours) hours")
        }
        if minutes > 0 {
            parts.append(minutes == 1 ? "1 minute" : "\(minutes) minutes")
        }
        return parts.joined(separator: " ")
    }
}
