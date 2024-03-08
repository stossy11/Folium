//
//  CytrusGame.swift
//  Folium
//
//  Created by Jarrod Norwell on 29/2/2024.
//

import Foundation

struct CytrusGame : Comparable, Hashable, Identifiable {
    var id = UUID()
    
    let core: Core
    let fileURL: URL
    let imageData: Data
    let publisher, title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fileURL)
        hasher.combine(imageData)
        hasher.combine(publisher)
        hasher.combine(title)
    }
    
    static func < (lhs: CytrusGame, rhs: CytrusGame) -> Bool {
        lhs.title < rhs.title
    }
    
    static func == (lhs: CytrusGame, rhs: CytrusGame) -> Bool {
        lhs.title == rhs.title
    }
}
