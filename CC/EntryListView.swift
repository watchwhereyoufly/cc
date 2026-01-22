//
//  EntryListView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct EntryListView: View {
    @ObservedObject var entryManager: EntryManager
    
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
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            entryManager.deleteEntry(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
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
}

struct EntryRowView: View {
    let entry: Entry
    @ObservedObject var entryManager: EntryManager
    @State private var showPersonProfile = false
    
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
            // Handle location update entries with same formatting as regular entries
            if entry.entryType == .locationUpdate {
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
                        .foregroundColor(.terminalGreen)
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
        .sheet(isPresented: $showPersonProfile) {
            PersonProfileView(personName: entry.person, entryManager: entryManager)
        }
    }
}
