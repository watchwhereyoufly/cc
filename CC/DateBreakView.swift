//
//  DateBreakView.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import SwiftUI

struct DateBreakView: View {
    let date: Date
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today'"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday'"
        } else {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        }
        return formatter
    }
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.terminalGreen.opacity(0.3))
                .frame(height: 1)
            
            Text(dateFormatter.string(from: date))
                .foregroundColor(.terminalGreen.opacity(0.7))
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 12)
            
            Rectangle()
                .fill(Color.terminalGreen.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal)
    }
}
