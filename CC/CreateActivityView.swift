//
//  CreateActivityView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct CreateActivityView: View {
    @Binding var activityName: String
    let editingActivity: Activity?
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    private var isEditing: Bool {
        editingActivity != nil
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text(isEditing ? "Edit Activity" : "Create Activity")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 20, design: .monospaced))
                    Spacer()
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .foregroundColor(.terminalGreen)
                            .font(.system(size: 18))
                    }
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity Name")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                    
                    ZStack(alignment: .topLeading) {
                        if activityName.isEmpty {
                            Text("Enter activity name...")
                                .foregroundColor(.terminalGreen.opacity(0.5))
                                .font(.system(size: 15, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 10)
                        }
                        TextField("", text: $activityName)
                            .textFieldStyle(.plain)
                            .foregroundColor(.terminalGreen)
                            .font(.system(size: 15, design: .monospaced))
                            .padding(10)
                            .focused($isFocused)
                    }
                    .background(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(isFocused ? Color.terminalGreen : Color.terminalGreen.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
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
                    
                    Button(action: onSave) {
                        Text(isEditing ? "Save" : "Create")
                            .foregroundColor(.black)
                            .font(.system(size: 15, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(activityName.isEmpty ? Color.terminalGreen.opacity(0.5) : Color.terminalGreen)
                            .cornerRadius(4)
                    }
                    .disabled(activityName.isEmpty)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isFocused = true
        }
    }
}
