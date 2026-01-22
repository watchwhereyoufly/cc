//
//  EntryListView.swift
//  CRACKHEAD CLUB
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct EntryListView: View {
    @ObservedObject var entryManager: EntryManager
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                if entryManager.entries.isEmpty {
                    Text("No entries yet. Start manifesting!")
                        .foregroundColor(.terminalGreen.opacity(0.6))
                        .font(.system(size: 15, design: .monospaced))
                        .padding()
                } else {
                    ForEach(entryManager.entries) { entry in
                        EntryRowView(entry: entry, entryManager: entryManager)
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
            .padding(.horizontal)
            .padding(.vertical, 8)
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
                
                Text("Activity: ")
                    .foregroundColor(.cyan)
                    .font(.system(size: 15, design: .monospaced))
                + Text(entry.activity)
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                
                Spacer()
            }
            
            // Assumption entry
            HStack(alignment: .top, spacing: 4) {
                Button(action: {
                    showPersonProfile = true
                }) {
                    Text("<@\(entry.person.lowercased())>")
                        .foregroundColor(personColor)
                        .font(.system(size: 15, design: .monospaced))
                }
                
                Text("Assumption: ")
                    .foregroundColor(.cyan)
                    .font(.system(size: 15, design: .monospaced))
                + Text(entry.assumption)
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 15, design: .monospaced))
                
                Spacer()
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
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .sheet(isPresented: $showPersonProfile) {
            PersonProfileView(personName: entry.person, entryManager: entryManager)
        }
    }
}
