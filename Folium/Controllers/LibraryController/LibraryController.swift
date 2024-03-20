//
//  LibraryController.swift
//  Folium
//
//  Created by Jarrod Norwell on 23/1/2024.
//

import Foundation
import Grape
import MetalKit
#if canImport(Sudachi)
import Sudachi
#endif
import UIKit

struct Help : Codable, Hashable, Identifiable {
    var id = UUID()
    
    let text, secondaryText, tertiaryText: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(secondaryText)
        hasher.combine(tertiaryText)
    }
    
    static func < (lhs: Help, rhs: Help) -> Bool {
        lhs.text < rhs.text
    }
    
    static func == (lhs: Help, rhs: Help) -> Bool {
        lhs.text == rhs.text
    }
}

class LibraryController : UICollectionViewController {
    var dataSource: UICollectionViewDiffableDataSource<AnyHashable, AnyHashable>! = nil
    var snapshot: NSDiffableDataSourceSnapshot<AnyHashable, AnyHashable>! = nil
    
    var cores: [Core]
    
    fileprivate var menu: UIMenu {
        .init(children: [
            UIAction(title: "TrollStore", state: UserDefaults.standard.bool(forKey: "useTrollStore") ? .on : .off, handler: { _ in
                UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "useTrollStore"), forKey: "useTrollStore")
                
                self.navigationItem.setLeftBarButton(.init(image: .init(systemName: "gearshape.fill"), menu: self.menu), animated: true)
            })
        ])
    }
    
    init(collectionViewLayout layout: UICollectionViewLayout, cores: [Core]) {
        self.cores = cores
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Library"
        view.backgroundColor = .systemBackground
        
        navigationItem.setLeftBarButton(.init(image: .init(systemName: "gearshape.fill"), menu: menu), animated: true)
        let systemVersion = UIDevice.current.systemVersion
        if systemVersion == "14.0" || (systemVersion >= "15.0" && systemVersion < "16.7") || systemVersion == "17.0" {
            navigationItem.leftBarButtonItem?.isEnabled = true
        } else {
            navigationItem.leftBarButtonItem?.isEnabled = false
        }
        
        let cytrusGameCellRegistration = UICollectionView.CellRegistration<GameCell, CytrusGame> { cell, indexPath, itemIdentifier in
            if let image = itemIdentifier.imageData.decodeRGB565(width: 48, height: 48) {
                cell.imageView.image = image
            } else {
                cell.missingImageView.image = .init(systemName: "slash.circle")
            }
            cell.set(itemIdentifier.title, itemIdentifier.publisher)
        }
        
        let grapeGameCellRegistration = UICollectionView.CellRegistration<GameCell, GrapeGame> { cell, indexPath, itemIdentifier in
            if !itemIdentifier.isGBA, let cgImage = self.cgImage(from: Grape.shared.icon(from: itemIdentifier.fileURL), width: 32, height: 32) {
                cell.imageView.image = .init(cgImage: cgImage)
            } else {
                cell.missingImageView.image = .init(systemName: "slash.circle")
            }
            cell.set(itemIdentifier.title, itemIdentifier.size)
        }
        
        let kiwiGameCellRegistration = UICollectionView.CellRegistration<GameCell, KiwiGame> { cell, indexPath, itemIdentifier in
            cell.missingImageView.image = .init(systemName: "slash.circle")
            cell.set(itemIdentifier.title, itemIdentifier.size)
        }
        
        let sudachiGameCellRegistration = UICollectionView.CellRegistration<GameCell, SudachiGame> { cell, indexPath, itemIdentifier in
            if let image = UIImage(data: itemIdentifier.imageData) {
                cell.imageView.image = image
            } else {
                cell.missingImageView.image = .init(systemName: "slash.circle")
            }
            cell.set(itemIdentifier.title, itemIdentifier.developer)
        }
        
        let helpCellRegistration = UICollectionView.CellRegistration<HelpCell, Help> { cell, indexPath, itemIdentifier in
            cell.set(itemIdentifier.text, itemIdentifier.secondaryText, itemIdentifier.tertiaryText)
        }
        
        let supplementaryViewRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            var contentConfiguration = UIListContentConfiguration.extraProminentInsetGroupedHeader()
            
            guard let sectionIdentifier = self.dataSource.sectionIdentifier(for: indexPath.section) as? Core else {
                return
            }
            
            contentConfiguration.text = sectionIdentifier.name.rawValue
            contentConfiguration.textProperties.color = .label
            contentConfiguration.secondaryText = sectionIdentifier.console.rawValue
            contentConfiguration.secondaryTextProperties.color = .secondaryLabel
            supplementaryView.contentConfiguration = contentConfiguration
            
            func bootOSButton() -> UIButton { // MARK: Sudachi only for now
                var bootOSButtonConfiguration = UIButton.Configuration.borderless()
                bootOSButtonConfiguration.buttonSize = .medium
                bootOSButtonConfiguration.image = .init(systemName: "power.circle.fill")?
                    .applyingSymbolConfiguration(.init(hierarchicalColor: .tintColor))
                
                return UIButton(configuration: bootOSButtonConfiguration, primaryAction: .init(handler: { _ in
                    switch sectionIdentifier.console {
#if canImport(Sudachi)
                    case .nSwitch:
                        let sudachiEmulationController = SudachiEmulationController(game: nil)
                        sudachiEmulationController.modalPresentationStyle = .fullScreen
                        self.present(sudachiEmulationController, animated: true)
#endif
                    default:
                        break
                    }
                }))
            }
            
            func coreSettingsButton(console: Core.Console) -> UIButton {
                var coreSettingsButtonConfiguration = UIButton.Configuration.borderless()
                coreSettingsButtonConfiguration.buttonSize = .medium
                coreSettingsButtonConfiguration.image = .init(systemName: "gearshape.circle.fill")?
                    .applyingSymbolConfiguration(.init(hierarchicalColor: .tintColor))
                
                return UIButton(configuration: coreSettingsButtonConfiguration, primaryAction: .init(handler: { _ in
                    let iniEditController = UINavigationController(rootViewController: INIEditController(console: console, url: sectionIdentifier.root.appendingPathComponent("config").appendingPathComponent("config.ini")))
                    iniEditController.modalPresentationStyle = .fullScreen
                    self.present(iniEditController, animated: true)
                }))
            }
            
            func importGamesButton() -> UIButton {
                var importGamesButtonConfiguration = UIButton.Configuration.borderless()
                importGamesButtonConfiguration.buttonSize = .medium
                importGamesButtonConfiguration.image = .init(systemName: "arrow.down.circle.fill")?
                    .applyingSymbolConfiguration(.init(hierarchicalColor: .tintColor))
                
                return UIButton(configuration: importGamesButtonConfiguration)
            }
            
            func missingFilesButton() -> UIButton {
                var configuration = UIButton.Configuration.borderless()
                configuration.buttonSize = .large
                let hierarchalColor: UIColor = if sectionIdentifier.missingFiles.contains(where: { $0.fileImportance == .required }) { .systemRed } else { .systemOrange }
                configuration.image = .init(systemName: "exclamationmark.circle.fill")?
                    .applyingSymbolConfiguration(.init(hierarchicalColor: hierarchalColor))
                
                return UIButton(configuration: configuration, primaryAction: .init(handler: { _ in
                    let configuration = UICollectionViewCompositionalLayoutConfiguration()
                    configuration.interSectionSpacing = 20
                    
                    let missingFilesControllerCompositionalLayout = UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, layoutEnvironment in
                        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
                        let item = NSCollectionLayoutItem(layoutSize: itemSize)
                        
                        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                        group.interItemSpacing = .fixed(20)
                        
                        let section = NSCollectionLayoutSection(group: group)
                        section.boundarySupplementaryItems = [
                            .init(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
                                  elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                        ]
                        section.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                        section.interGroupSpacing = 20
                        
                        return section
                    }, configuration: configuration)
                    
                    let missingFilesController = UINavigationController(rootViewController: MissingFilesController(core: sectionIdentifier, collectionViewLayout: missingFilesControllerCompositionalLayout))
                    missingFilesController.modalPresentationStyle = .fullScreen
                    self.present(missingFilesController, animated: true)
                }))
            }
            
            let importGamesView = UICellAccessory.customView(configuration: .init(customView: importGamesButton(), placement: .trailing()))
            let coreSettingsView = UICellAccessory.customView(configuration: .init(customView: coreSettingsButton(console: sectionIdentifier.console), placement: .trailing()))
            let missingFilesView = UICellAccessory.customView(configuration: .init(customView: missingFilesButton(), placement: .trailing()))
            let bootOSView = UICellAccessory.customView(configuration: .init(customView: bootOSButton(), placement: .trailing()))
            
            switch sectionIdentifier.console {
            case .n3ds:
                supplementaryView.accessories = [
                    bootOSView,
                    importGamesView,
                    coreSettingsView
                ]
                
                if !sectionIdentifier.missingFiles.isEmpty {
                    supplementaryView.accessories.insert(missingFilesView, at: 0)
                }
            case .nds:
                supplementaryView.accessories = [
                    bootOSView,
                    importGamesView
                ]
                
                if !sectionIdentifier.missingFiles.isEmpty {
                    supplementaryView.accessories.insert(missingFilesView, at: 0)
                }
            case .nes:
                supplementaryView.accessories = [
                    importGamesView
                ]
                
                if !sectionIdentifier.missingFiles.isEmpty {
                    supplementaryView.accessories.insert(missingFilesView, at: 0)
                }
            case .nSwitch:
                supplementaryView.accessories = [
                    bootOSView,
                    importGamesView,
                    coreSettingsView
                ]
                
                if !sectionIdentifier.missingFiles.isEmpty {
                    supplementaryView.accessories.insert(missingFilesView, at: 0)
                }
            }
        }
        
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
#if canImport(Cytrus)
            case let cytrusGame as CytrusGame:
                collectionView.dequeueConfiguredReusableCell(using: cytrusGameCellRegistration, for: indexPath, item: cytrusGame)
#endif
            case let grapeGame as GrapeGame:
                collectionView.dequeueConfiguredReusableCell(using: grapeGameCellRegistration, for: indexPath, item: grapeGame)
            case let kiwiGame as KiwiGame:
                collectionView.dequeueConfiguredReusableCell(using: kiwiGameCellRegistration, for: indexPath, item: kiwiGame)
#if canImport(Sudachi)
            case let sudachiGame as SudachiGame:
                collectionView.dequeueConfiguredReusableCell(using: sudachiGameCellRegistration, for: indexPath, item: sudachiGame)
#endif
            case let help as Help:
                collectionView.dequeueConfiguredReusableCell(using: helpCellRegistration, for: indexPath, item: help)
            default:
                nil
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch indexPath.section {
            case 0:
                nil
            default:
                collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryViewRegistration, for: indexPath)
            }
        }
        
        snapshot = .init()
        snapshot.appendSections(["Help"])
        snapshot.appendItems([
            Help(text: "Getting Started", secondaryText: "Guides cannot be provided for legal reasons, Google is your friend", tertiaryText: "Jarrod Norwell")
        ], toSection: "Help")
        snapshot.appendSections(cores.sorted())
        cores.forEach { core in
            if !core.missingFiles.contains(where: { $0.fileImportance == .required }), !core.games.isEmpty {
                switch core.games {
#if canImport(Cytrus)
                case let cytrusGames as [CytrusGame]:
                    snapshot.appendItems(cytrusGames.sorted(), toSection: core)
#endif
                case let grapeGames as [GrapeGame]:
                    snapshot.appendItems(grapeGames.sorted(), toSection: core)
                case let kiwiGames as [KiwiGame]:
                    snapshot.appendItems(kiwiGames.sorted(), toSection: core)
#if canImport(Sudachi)
                case let sudachiGames as [SudachiGame]:
                    Sudachi.shared.insert(games: sudachiGames.reduce(into: [URL](), { $0.append($1.fileURL) }))
                    snapshot.appendItems(sudachiGames.sorted(), toSection: core)
#endif
                default:
                    break
                }
            }
        }
        
        Task {
            await dataSource.apply(snapshot)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        .init(previewProvider: {
            guard let indexPath = collectionView.indexPathForItem(at: point), let cell = collectionView.cellForItem(at: indexPath) as? GameCell else {
                return .init()
            }
            
            let vc = UIViewController()
            let imageView = UIImageView(image: cell.imageView.image ?? cell.missingImageView.image)
            imageView.contentMode = .scaleAspectFit
            vc.view = imageView
            vc.preferredContentSize = cell.imageView.frame.size
            
            return vc
        }, actionProvider:  { _ in
                .init(children: [
                    UIMenu(title: "Boot Options", image: .init(systemName: "power"), children: [
                        UIAction(title: "Boot Custom", handler: { _ in }),
                        UIAction(title: "Boot Global", handler: { _ in }),
                        UIAction(title: "Reset Custom", image: .init(systemName: "arrow.uturn.backward"), attributes: .destructive, handler: { _ in })
                    ]),
                    UIAction(title: "View Detailed", image: .init(systemName: "info"), handler: { _ in }),
                    UIMenu(title: "Content Options", image: .init(systemName: "questionmark.folder"), children: [
                        UIAction(title: "Install DLC", handler: { _ in }),
                        UIMenu(title: "Update Options", children: [
                            UIAction(title: "Install Update", handler: { _ in }),
                            UIAction(title: "Install & Delete Update", attributes: .destructive, handler: { _ in })
                        ])
                    ]),
                    UIAction(title: "Delete Game", image: .init(systemName: "trash"), attributes: .destructive, handler: { _ in })
                ])
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let object = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        switch object {
#if canImport(Cytrus)
        case let cytrusGame as CytrusGame:
            let cytrusEmulationController = CytrusEmulationController(game: cytrusGame)
            cytrusEmulationController.modalPresentationStyle = .fullScreen
            present(cytrusEmulationController, animated: true)
#endif
        case let grapeGame as GrapeGame:
            let grapeEmulationController = GrapeEmulationController(game: grapeGame)
            grapeEmulationController.modalPresentationStyle = .fullScreen
            present(grapeEmulationController, animated: true)
        case let kiwiGame as KiwiGame:
            let kiwiEmulationController = KiwiEmulationController(game: kiwiGame)
            kiwiEmulationController.modalPresentationStyle = .fullScreen
            present(kiwiEmulationController, animated: true)
#if canImport(Sudachi)
        case let sudachiGame as SudachiGame:
            let sudachiEmulationController = SudachiEmulationController(game: sudachiGame)
            sudachiEmulationController.modalPresentationStyle = .fullScreen
            present(sudachiEmulationController, animated: true)
#endif
        default:
            break
        }
    }
    
    fileprivate func cgImage(from screenFramebuffer: UnsafeMutablePointer<UInt32>, width: Int, height: Int) -> CGImage? {
        var imageRef: CGImage? = nil
        
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue).union(.byteOrderDefault)
        guard let providerRef = CGDataProvider(dataInfo: nil, data: screenFramebuffer, size: totalBytes,
                                               releaseData: {_,_,_  in}) else {
            return nil
        }
        
        imageRef = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel,
                           bytesPerRow: bytesPerRow, space: colorSpaceRef, bitmapInfo: bitmapInfo, provider: providerRef,
                           decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        return imageRef
    }
}
