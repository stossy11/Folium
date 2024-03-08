//
//  GrapeGame.swift
//  Folium
//
//  Created by Jarrod Norwell on 26/2/2024.
//

import Foundation

struct CCharAddress {
    let offset: Int
    let size: Int
    let title: String
    
    var bytes: UnsafeMutablePointer<UInt8>
    
    func string() -> String? {
        guard let string = String(bytesNoCopy: bytes + offset, length: size, encoding: .utf8, freeWhenDone: false) else {
            return nil
        }
        
        return string
    }
}

struct GrapeGame : Comparable, Hashable, Identifiable {
    var id = UUID()
    
    let core: Core
    let fileURL: URL
    let isGBA: Bool
    let size, title: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fileURL)
        hasher.combine(isGBA)
        hasher.combine(size)
        hasher.combine(title)
    }
    
    static func < (lhs: GrapeGame, rhs: GrapeGame) -> Bool {
        lhs.title < rhs.title
    }
    
    static func == (lhs: GrapeGame, rhs: GrapeGame) -> Bool {
        lhs.title == rhs.title
    }
}
