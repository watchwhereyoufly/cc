//
//  ContentView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var entryManager: EntryManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEntryFormExpanded = false
    @State private var showProfile = false
    @State private var showCalendar = false
    @State private var selectedFilter: FeedFilter = .all
    
    enum FeedFilter: String {
        case entries = "entries"
        case activities = "activities"
        case all = "all"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 0) {
                        HStack {
                            Button(action: {
                                showCalendar = true
                            }) {
                                Text("CClub")
                                    .foregroundColor(.terminalGreen)
                                    .font(.system(size: 15, design: .monospaced))
                            }
                            Spacer()
                            
                            Button(action: {
                                showProfile = true
                            }) {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.terminalGreen)
                                    .font(.system(size: 20))
                            }
                            .sheet(isPresented: $showProfile) {
                                ProfileView(authManager: authManager)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        
                        // Filter Buttons
                        HStack(spacing: 0) {
                            // Entries Button
                            Button(action: {
                                selectedFilter = .entries
                            }) {
                                Text("entries")
                                    .foregroundColor(selectedFilter == .entries ? .terminalGreen : .terminalGreen.opacity(0.5))
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            
                            // Activities Button
                            Button(action: {
                                selectedFilter = .activities
                            }) {
                                Text("activities")
                                    .foregroundColor(selectedFilter == .activities ? .terminalGreen : .terminalGreen.opacity(0.5))
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            
                            // All Button
                            Button(action: {
                                selectedFilter = .all
                            }) {
                                Text("all")
                                    .foregroundColor(selectedFilter == .all ? .terminalGreen : .terminalGreen.opacity(0.5))
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color.black)
                    .sheet(isPresented: $showCalendar) {
                        CalendarView(entryManager: entryManager)
                        .presentationDetents([.large])
                    }
                    
                    // Entries List (with timestamps at top)
                    EntryListView(entryManager: entryManager, filter: selectedFilter)
                        .background(Color.black)
                    
                    // Entry Form (at bottom, collapsible)
                    EntryFormView(entryManager: entryManager, isExpanded: $isEntryFormExpanded)
                        .background(Color.black)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark) // Force dark mode
    }
}

#Preview {
    ContentView()
}
