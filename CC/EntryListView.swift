//
//  EntryListView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct EntryListView: View {
    @ObservedObject var entryManager: EntryManager
    @State private var isRefreshing = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if entryManager.entries.isEmpty {
                        Text("No entries yet. Start manifesting!")
                            .foregroundColor(.terminalGreen.opacity(0.6))
                            .font(.system(size: 15, design: .monospaced))
                            .padding()
                    } else {
                        ForEach(Array(entryManager.entries.enumerated()), id: \.element.id) { index, entry in
                            VStack(spacing: 0) {
                                // Show date break if this is a new day
                                if index == 0 || !Calendar.current.isDate(entryManager.entries[index - 1].timestamp, inSameDayAs: entry.timestamp) {
                                    DateBreakView(date: entry.timestamp)
                                        .padding(.vertical, 8)
                                }
                                
                                EntryRowView(entry: entry, entryManager: entryManager)
                                    .id(entry.id)
                            }
                        }
                        
                        // Refresh indicator at bottom
                        VStack(spacing: 8) {
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
                            } else if dragOffset > 50 {
                                Text("Pull up to refresh")
                                    .foregroundColor(.terminalGreen.opacity(0.7))
                                    .font(.system(size: 11, design: .monospaced))
                            }
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Detect upward drag (positive translation.height = dragging up)
                        if value.translation.height > 0 && !isRefreshing {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 80 && !isRefreshing {
                            // Trigger refresh when dragged up enough
                            Task {
                                await refreshEntries()
                            }
                        } else {
                            dragOffset = 0
                        }
                    }
            )
            .onAppear {
                // Scroll to bottom (newest) when view appears
                if let lastEntry = entryManager.entries.last {
                    withAnimation {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: entryManager.entries.count) { _ in
                // Auto-scroll to bottom when new entries are added
                if let lastEntry = entryManager.entries.last {
                    withAnimation {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func refreshEntries() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        dragOffset = 0
        
        // Trigger CloudKit sync
        entryManager.syncWithCloudKit()
        
        // Wait for sync to complete
        while entryManager.isSyncing {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Small delay to ensure UI updates are complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        isRefreshing = false
    }
}

struct EntryRowView: View {
    let entry: Entry
    @ObservedObject var entryManager: EntryManager
    @State private var showPersonProfile = false
    @State private var showEditEntry = false
    
    // Check if this entry belongs to the current user
    private var isOwnEntry: Bool {
        guard let currentUserID = entryManager.currentUserID,
              let entryAuthorID = entry.authorID else {
            return false
        }
        return currentUserID == entryAuthorID
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        return formatter
    }
    
    private var personColor: Color {
        let personLower = entry.person.lowercased()
        if personLower == "ryan" {
            return .orange
        } else if personLower == "evan" {
            return .pink
        }
        return .terminalGreen
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Handle activity entries
            if entry.entryType == .activity {
                // Timestamp at top
                HStack {
                    Spacer()
                    Text("[\(timeFormatter.string(from: entry.timestamp))]")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 10, design: .monospaced))
                }
                
                // Activity entry with color-coded person name
                HStack(alignment: .top, spacing: 4) {
                    Button(action: {
                        showPersonProfile = true
                    }) {
                        Text("<@\(entry.person.lowercased())>")
                            .foregroundColor(personColor)
                            .font(.system(size: 15, design: .monospaced))
                    }
                    
                    Text(entry.activity)
                        .foregroundColor(.purple)
                        .font(.system(size: 15, design: .monospaced))
                    
                    Spacer()
                }
            }
            // Handle location update entries with same formatting as regular entries
            else if entry.entryType == .locationUpdate {
                // All location entries should be yellow
                
                // Timestamp at top
                HStack {
                    Spacer()
                    Text("[\(timeFormatter.string(from: entry.timestamp))]")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 10, design: .monospaced))
                }
                
                // Location entry with color-coded person name
                HStack(alignment: .top, spacing: 4) {
                    Button(action: {
                        showPersonProfile = true
                    }) {
                        Text("<@\(entry.person.lowercased())>")
                            .foregroundColor(personColor)
                            .font(.system(size: 15, design: .monospaced))
                    }
                    
                    Text(entry.activity)
                        .foregroundColor(.yellow)
                        .font(.system(size: 15, design: .monospaced))
                    
                    Spacer()
                }
            } else {
                // Regular entry display
                // Timestamp at top
                HStack {
                    Spacer()
                    Text("[\(timeFormatter.string(from: entry.timestamp))]")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 10, design: .monospaced))
                }
                
                // Activity entry
                HStack(alignment: .top, spacing: 4) {
                    Button(action: {
                        showPersonProfile = true
                    }) {
                        Text("<@\(entry.person.lowercased())>")
                            .foregroundColor(personColor)
                            .font(.system(size: 15, design: .monospaced))
                    }
                    
                    (Text("Activity: ")
                        .foregroundColor(.cyan)
                        + Text(entry.activity)
                        .foregroundColor(.terminalGreen))
                        .font(.system(size: 15, design: .monospaced))
                    
                    Spacer()
                }
                
                // Assumption entry
                if !entry.assumption.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Button(action: {
                            showPersonProfile = true
                        }) {
                            Text("<@\(entry.person.lowercased())>")
                                .foregroundColor(personColor)
                                .font(.system(size: 15, design: .monospaced))
                        }
                        
                        (Text("Assumption: ")
                            .foregroundColor(.cyan)
                            + Text(entry.assumption)
                            .foregroundColor(.terminalGreen))
                            .font(.system(size: 15, design: .monospaced))
                        
                        Spacer()
                    }
                }
                
                // Image display
                if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                    HStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.terminalGreen.opacity(0.3), lineWidth: 1)
                            )
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contextMenu {
            if isOwnEntry {
                Button(action: {
                    showEditEntry = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: {
                    entryManager.deleteEntry(entry)
                }) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showPersonProfile) {
            PersonProfileView(personName: entry.person, entryManager: entryManager)
        }
        .sheet(isPresented: $showEditEntry) {
            EditEntryView(entry: entry, entryManager: entryManager)
        }
    }
}
