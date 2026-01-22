//
//  CalendarView.swift
//  CRACKHEAD CLUB
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var entryManager: EntryManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate: Date = Date()
    @State private var selectedDateEntries: [Entry] = []
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }
    
    private var datesWithEntries: Set<String> {
        Set(entryManager.entries.map { entry in
            let dateString = formatDateKey(entry.timestamp)
            return dateString
        })
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Archive Calendar")
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
                
                // Calendar
                CalendarMonthView(
                    selectedDate: $selectedDate,
                    datesWithEntries: datesWithEntries,
                    onDateSelected: { date in
                        selectedDate = date
                        loadEntriesForDate(date)
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Selected Date Header
                HStack {
                    Text(formatDateHeader(selectedDate))
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 15, design: .monospaced))
                    Spacer()
                    Text("\(selectedDateEntries.count) entries")
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 13, design: .monospaced))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Entries for selected date
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if selectedDateEntries.isEmpty {
                            Text("No entries for this date")
                                .foregroundColor(.terminalGreen.opacity(0.6))
                                .font(.system(size: 15, design: .monospaced))
                                .padding()
                        } else {
                            ForEach(selectedDateEntries) { entry in
                                CalendarEntryRowView(entry: entry)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadEntriesForDate(selectedDate)
        }
    }
    
    private func loadEntriesForDate(_ date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        selectedDateEntries = entryManager.entries.filter { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct CalendarMonthView: View {
    @Binding var selectedDate: Date
    let datesWithEntries: Set<String>
    let onDateSelected: (Date) -> Void
    
    @State private var currentMonth: Date = Date()
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstDay = monthInterval.start
        let lastDay = monthInterval.end
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysToAdd = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: daysToAdd)
        
        var currentDay = firstDay
        while currentDay < lastDay {
            days.append(currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Month/Year Header with Navigation
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                Text(monthYearString)
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 18, design: .monospaced))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.terminalGreen)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 8)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .foregroundColor(.terminalGreen.opacity(0.7))
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasEntries: datesWithEntries.contains(formatDateKey(date)),
                            onTap: {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let hasEntries: Bool
    let onTap: () -> Void
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }
    
    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .foregroundColor(isSelected ? .black : (isToday ? .terminalGreen : .terminalGreen.opacity(0.8)))
                    .font(.system(size: 14, design: .monospaced))
                    .fontWeight(isSelected ? .bold : .regular)
                
                if hasEntries {
                    Circle()
                        .fill(isSelected ? Color.terminalGreen : Color.terminalGreen.opacity(0.6))
                        .frame(width: 4, height: 4)
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.terminalGreen : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isToday && !isSelected ? Color.terminalGreen : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct CalendarEntryRowView: View {
    let entry: Entry
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
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
            // Time
            HStack {
                Text("[\(timeFormatter.string(from: entry.timestamp))]")
                    .foregroundColor(.terminalGreen.opacity(0.7))
                    .font(.system(size: 10, design: .monospaced))
                Spacer()
            }
            
            // Activity
            HStack(alignment: .top, spacing: 4) {
                Text("<@\(entry.person.lowercased())>")
                    .foregroundColor(personColor)
                    .font(.system(size: 15, design: .monospaced))
                
                (Text("Activity: ")
                    .foregroundColor(.cyan)
                    + Text(entry.activity)
                    .foregroundColor(.terminalGreen))
                    .font(.system(size: 15, design: .monospaced))
                
                Spacer()
            }
            
            // Assumption
            HStack(alignment: .top, spacing: 4) {
                Text("<@\(entry.person.lowercased())>")
                    .foregroundColor(personColor)
                    .font(.system(size: 15, design: .monospaced))
                
                (Text("Assumption: ")
                    .foregroundColor(.cyan)
                    + Text(entry.assumption)
                    .foregroundColor(.terminalGreen))
                    .font(.system(size: 15, design: .monospaced))
                
                Spacer()
            }
            
            // Image
            if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                HStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250, maxHeight: 250)
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
    }
}
