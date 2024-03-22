//
//  LibraryManager.swift
//  Folium
//
//  Created by Jarrod Norwell on 1/18/24.
//

#if canImport(Cytrus)
import Cytrus
#endif

#if canImport(Sudachi)
import Sudachi
#endif

import Foundation
import UIKit

struct MissingFile : Hashable, Identifiable {
    enum FileImportance : String, CustomStringConvertible {
        case optional = "Optional", required = "Required"
        
        var description: String {
            rawValue
        }
    }
    
    var id = UUID()
    
    let coreName: Core.Name
    let directory: URL
    var fileImportance: FileImportance
    let fileName: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(coreName)
        hasher.combine(directory)
        hasher.combine(fileImportance)
        hasher.combine(fileName)
    }
}

struct Core : Comparable, Hashable {
    enum Name : String, Hashable {
        case cytrus = "Cytrus", grape = "Grape", kiwi = "Kiwi", sudachi = "Sudachi"
    }
    
    enum Console : String, Hashable {
        case n3ds = "Nintendo 3DS", nds = "Nintendo DS", nes = "Nintendo Entertainment System", nSwitch = "Nintendo Switch"
        
        func buttonColors() -> [VirtualControllerButton.ButtonType : UIColor] {
            switch self {
            case .n3ds, .nds:
                [
                    .a : .systemRed,
                    .b : .systemYellow,
                    .x : .systemBlue,
                    .y : .systemGreen
                ]
            case .nes:
                [
                    .a : .systemRed,
                    .b : .systemRed
                ]
            default:
                [
                    :
                ]
            }
        }
    }
    
    let console: Console
    let name: Name
    var games: [AnyHashable]
    var missingFiles: [MissingFile]
    let root: URL
    
    static func < (lhs: Core, rhs: Core) -> Bool {
        lhs.name.rawValue < rhs.name.rawValue
    }
}

class DirectoriesManager {
    static let shared = DirectoriesManager()
    
    func directories() -> [String : [String : [String : MissingFile.FileImportance]]] {
        [
            "Cytrus" : [
                "cache" : [:],
                "cheats" : [:],
                "config" : [:],
                "dump" : [:],
                "external_dlls" : [:],
                "load" : [:],
                "log" : [:],
                "nand" : [:],
                "roms" : [:],
                "sdmc" : [:],
                "shaders" : [:],
                "states" : [:],
                "sysdata" : [
                    "aes_keys.txt" : .required
                ]
            ],
            "Grape" : [
                "config" : [:],
                "roms" : [:],
                "sysdata" : [
                    "bios7.bin" : .required,
                    "bios9.bin" : .required,
                    "firmware.bin" : .required,
                    "gba_bios.bin" : .optional,
                    "sd.img" : .optional
                ]
            ],
            "Kiwi" : [
                "roms" : [:]
            ],
            "Sudachi" : [
                "amiibo" : [:],
                "cache" : [:],
                "config" : [:],
                "crash_dumps" : [:],
                "dump" : [:],
                "keys" : [
                    "prod.keys" : .required,
                    "title.keys" : .required
                ],
                "load" : [:],
                "log" : [:],
                "nand" : [:],
                "play_time" : [:],
                "roms" : [:],
                "screenshots" : [:],
                "sdmc" : [:],
                "shader" : [:],
                "tas" : [:],
                "icons" : [:]
            ]
        ]
    }
    
    func createMissingDirectoriesInDocumentsDirectory() throws {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try directories().forEach { directory, subdirectories in
            let coreDirectory = documentsDirectory.appendingPathComponent(directory, conformingTo: .folder)
            if !FileManager.default.fileExists(atPath: coreDirectory.path) {
                try FileManager.default.createDirectory(at: coreDirectory, withIntermediateDirectories: false)
                
                try subdirectories.forEach { subdirectory, files in
                    let coreSubdirectory = coreDirectory.appendingPathComponent(subdirectory, conformingTo: .folder)
                    if !FileManager.default.fileExists(atPath: coreSubdirectory.path) {
                        try FileManager.default.createDirectory(at: coreSubdirectory, withIntermediateDirectories: false)
                    }
                }
            } else {
                try subdirectories.forEach { subdirectory, files in
                    let coreSubdirectory = coreDirectory.appendingPathComponent(subdirectory, conformingTo: .folder)
                    if !FileManager.default.fileExists(atPath: coreSubdirectory.path) {
                        try FileManager.default.createDirectory(at: coreSubdirectory, withIntermediateDirectories: false)
                    }
                }
            }
        }
    }
    
    func scanDirectoriesForRequiredFiles(for core: inout Core) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let directory = directories().first(where: { $0.key == core.name.rawValue }) else {
            return
        }
        
        directory.value.forEach { subdirectory, fileNames in
            let coreSubdirectory = documentsDirectory.appendingPathComponent(directory.key, conformingTo: .folder)
                .appendingPathComponent(subdirectory, conformingTo: .folder)
            fileNames.forEach { (fileName, fileImportance) in
                if !FileManager.default.fileExists(atPath: coreSubdirectory.appendingPathComponent(fileName, conformingTo: .fileURL).path) {
                    core.missingFiles.append(.init(coreName:core.name, directory: coreSubdirectory, fileImportance: fileImportance, fileName: fileName))
                }
            }
        }
    }
}

enum LibraryManagerError : Error {
    case invalidEnumerator, invalidURL
}

class LibraryManager {
    static let shared = LibraryManager()
    
    func library() throws -> [Core] {
        func romsDirectoryCrawler(for coreName: Core.Name) throws -> [URL] {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            guard let enumerator = FileManager.default.enumerator(at: documentsDirectory.appendingPathComponent(coreName.rawValue, conformingTo: .folder)
                .appendingPathComponent("roms", conformingTo: .folder), includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
                throw LibraryManagerError.invalidEnumerator
            }
            
            var urls: [URL] = []
            try enumerator.forEach { element in
                switch element {
                case let url as URL:
                    let attributes = try url.resourceValues(forKeys: [.isRegularFileKey])
                    if let isRegularFile = attributes.isRegularFile, isRegularFile {
                        switch coreName {
#if canImport(Cytrus)
                        case .cytrus:
                            if ["3ds", "3dsx", "app", "cci", "cxi"].contains(url.pathExtension.lowercased()) {
                                urls.append(url)
                            }
#endif
                        case .grape:
                            if ["gba", "nds"].contains(url.pathExtension.lowercased()) {
                                urls.append(url)
                            }
                        case .kiwi:
                            if url.pathExtension.lowercased() == "nes" {
                                urls.append(url)
                            }
#if canImport(Sudachi)
                        case .sudachi:
                            if ["nca", "nro", "nso", "nsp", "xci"].contains(url.pathExtension.lowercased()) {
                                urls.append(url)
                            }
#endif
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
            
            return urls
        }
        
        func games(from urls: [URL], for core: inout Core) {
            switch core.name {
#if canImport(Cytrus)
            case .cytrus:
                core.games = urls.reduce(into: [CytrusGame]()) { partialResult, element in
                    let information = Cytrus.shared.information(for: element)
                    
                    let game = CytrusGame(core: core, fileURL: element, imageData: information.iconData,
                                          publisher: information.publisher,
                                          title: information.title)
                    partialResult.append(game)
                }
#endif
            case .grape:
                core.games = urls.reduce(into: [GrapeGame]()) { partialResult, element in
                    let attributes = try? FileManager.default.attributesOfItem(atPath: element.path)
                    
                    let fileSize = attributes?[.size] as? Int64 ?? 0
                    
                    let byteFormatter = ByteCountFormatter()
                    byteFormatter.allowedUnits = [.useKB, .useMB]
                    byteFormatter.countStyle = .file
                    
                    let isGBA = element.pathExtension.lowercased() == "gba"
                    let title = element.lastPathComponent.replacingOccurrences(of: ".nds", with: "")
                    
                    let game = GrapeGame(core: core, fileURL: element, isGBA: isGBA, size: byteFormatter.string(fromByteCount: fileSize), title: title)
                    partialResult.append(game)
                }
            case .kiwi:
                core.games = urls.reduce(into: [KiwiGame]()) { partialResult, element in
                    let attributes = try? FileManager.default.attributesOfItem(atPath: element.path)
                    
                    let fileSize = attributes?[.size] as? Int64 ?? 0
                    
                    let byteFormatter = ByteCountFormatter()
                    byteFormatter.allowedUnits = [.useKB, .useMB]
                    byteFormatter.countStyle = .file
                    
                    let game = KiwiGame(core: core, fileURL: element, size: byteFormatter.string(fromByteCount: fileSize), title: element.lastPathComponent.replacingOccurrences(of: ".nes", with: ""))
                    partialResult.append(game)
                }
#if canImport(Sudachi)
            case .sudachi:
                core.games = urls.reduce(into: [SudachiGame]()) { partialResult, element in
                    let information = Sudachi.shared.information(for: element)
                
                    let game = SudachiGame(core: core, developer: information.developer, fileURL: element,
                                           imageData: information.iconData,
                                           title: information.title)
                    partialResult.append(game)
                }
#endif
            default:
                break
            }
        }
        
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
#if canImport(Cytrus)
        var cytrusCore = Core(console: .n3ds, name: .cytrus, games: [], missingFiles: [], root: directory.appendingPathComponent(Core.Name.cytrus.rawValue, conformingTo: .folder))
        games(from: try romsDirectoryCrawler(for: .cytrus), for: &cytrusCore)
        DirectoriesManager.shared.scanDirectoriesForRequiredFiles(for: &cytrusCore)
#endif
        
        var grapeCore = Core(console: .nds, name: .grape, games: [], missingFiles: [], root: directory.appendingPathComponent(Core.Name.grape.rawValue, conformingTo: .folder))
        games(from: try romsDirectoryCrawler(for: .grape), for: &grapeCore)
        DirectoriesManager.shared.scanDirectoriesForRequiredFiles(for: &grapeCore)
        
        var kiwiCore = Core(console: .nes, name: .kiwi, games: [], missingFiles: [], root: directory.appendingPathComponent(Core.Name.kiwi.rawValue, conformingTo: .folder))
        games(from: try romsDirectoryCrawler(for: .kiwi), for: &kiwiCore)
        DirectoriesManager.shared.scanDirectoriesForRequiredFiles(for: &kiwiCore)
        
#if canImport(Sudachi)
        var sudachiCore = Core(console: .nSwitch, name: .sudachi, games: [], missingFiles: [], root: directory.appendingPathComponent(Core.Name.sudachi.rawValue, conformingTo: .folder))
        games(from: try romsDirectoryCrawler(for: .sudachi), for: &sudachiCore)
        DirectoriesManager.shared.scanDirectoriesForRequiredFiles(for: &sudachiCore)
#endif
        
#if canImport(Cytrus)
        return [cytrusCore, grapeCore, kiwiCore]
#elseif canImport(Sudachi)
        return [grapeCore, kiwiCore, sudachiCore]
#else
        return [grapeCore, kiwiCore]
#endif
    }
}
