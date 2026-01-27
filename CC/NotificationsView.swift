//
//  NotificationsView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var settings = NotificationSettings.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Text("Notifications")
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
                    
                    // Notifications On/Off
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Notifications")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            Spacer()
                            Toggle("", isOn: $settings.notificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .terminalGreen))
                        }
                        Text("Enable or disable all notifications")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding(.horizontal)
                    
                    // Feed Update Notifications
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Feed Update")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            Spacer()
                            Toggle("", isOn: $settings.feedUpdateNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: .terminalGreen))
                                .disabled(!settings.notificationsEnabled)
                        }
                        Text("Get notified when someone else posts to the feed")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding(.horizontal)
                    .opacity(settings.notificationsEnabled ? 1.0 : 0.5)
                    
                    // Reminder Notifications
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Set Reminder")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            Spacer()
                            Toggle("", isOn: $settings.reminderNotificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .terminalGreen))
                                .disabled(!settings.notificationsEnabled)
                        }
                        Text("Get reminded to post an entry at a set time")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 12, design: .monospaced))
                        
                        if settings.reminderNotificationsEnabled && settings.notificationsEnabled {
                            DatePicker("Reminder Time", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 13, design: .monospaced))
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    .opacity(settings.notificationsEnabled ? 1.0 : 0.5)
                    
                    // HealthKit Section Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HealthKit")
                            .foregroundColor(.terminalGreen)
                            .font(.system(size: 18, design: .monospaced))
                            .padding(.top, 8)
                        
                        // HealthKit Authorization Button
                        if !HealthKitManager.shared.isAuthorized {
                            Button(action: {
                                HealthKitManager.shared.requestAuthorization()
                            }) {
                                Text("Authorize HealthKit")
                                    .foregroundColor(.black)
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Color.terminalGreen)
                                    .cornerRadius(2)
                            }
                            .padding(.top, 4)
                        } else {
                            Text("HealthKit authorized ✓")
                                .foregroundColor(.terminalGreen.opacity(0.7))
                                .font(.system(size: 11, design: .monospaced))
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // HealthKit Auto-Post Workouts
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Auto-Post Workouts")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { HealthKitManager.shared.autoPostWorkouts },
                                set: { HealthKitManager.shared.setAutoPostWorkouts($0) }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .terminalGreen))
                            .disabled(!HealthKitManager.shared.isAuthorized)
                        }
                        Text("Automatically post workouts from Apple Health as activity entries")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding(.horizontal)
                    .opacity(HealthKitManager.shared.isAuthorized ? 1.0 : 0.5)
                    
                    // HealthKit Auto-Post Sleep
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Auto-Post Sleep")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { HealthKitManager.shared.autoPostSleep },
                                set: { HealthKitManager.shared.setAutoPostSleep($0) }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .terminalGreen))
                            .disabled(!HealthKitManager.shared.isAuthorized)
                        }
                        Text("Automatically post sleep data when you wake up")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding(.horizontal)
                    .opacity(HealthKitManager.shared.isAuthorized ? 1.0 : 0.5)
                    
                    // HealthKit Auto-Post Weight
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Auto-Post Weight")
                                .foregroundColor(.terminalGreen)
                                .font(.system(size: 15, design: .monospaced))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { HealthKitManager.shared.autoPostWeight },
                                set: { HealthKitManager.shared.setAutoPostWeight($0) }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .terminalGreen))
                            .disabled(!HealthKitManager.shared.isAuthorized)
                        }
                        Text("Automatically post weight when you weigh in")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding(.horizontal)
                    .opacity(HealthKitManager.shared.isAuthorized ? 1.0 : 0.5)
                }
                .padding(.vertical)
            }
        }
        .preferredColorScheme(.dark)
    }
}
