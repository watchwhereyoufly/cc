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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
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
                    .background(Color.black)
                    .sheet(isPresented: $showCalendar) {
                        CalendarView(entryManager: entryManager)
                        .presentationDetents([.large])
                    }
                    
                    // Entries List (with timestamps at top)
                    EntryListView(entryManager: entryManager)
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
