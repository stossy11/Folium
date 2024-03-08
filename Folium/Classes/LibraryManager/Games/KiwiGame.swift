//
//  KiwiGame.swift
//  Folium
//
//  Created by Jarrod Norwell on 26/2/2024.
//

import Foundation

struct KiwiGame : Comparable, Hashable, Identifiable {
    var id = UUID()
    
    let core: Core
    let fileURL: URL
    let size, title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fileURL)
        hasher.combine(size)
        hasher.combine(title)
    }
    
    static func < (lhs: KiwiGame, rhs: KiwiGame) -> Bool {
        lhs.title < rhs.title
    }
    
    static func == (lhs: KiwiGame, rhs: KiwiGame) -> Bool {
        lhs.title == rhs.title
    }
}
