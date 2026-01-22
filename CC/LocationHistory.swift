//
//  LocationHistory.swift
//  CC
//
//  Created by Evan Roberts on 1/22/26.
//

import Foundation

struct LocationHistory: Codable, Identifiable {
    let id: UUID
    let location: String
    let date: Date
    let isTravel: Bool // true for travel, false for permanent move
    
    init(id: UUID = UUID(), location: String, date: Date = Date(), isTravel: Bool = false) {
        self.id = id
        self.location = location
        self.date = date
        self.isTravel = isTravel
    }
}
