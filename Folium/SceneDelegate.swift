//
//  SceneDelegate.swift
//  Folium
//
//  Created by Jarrod Norwell on 1/8/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        window = .init(windowScene: windowScene)
        guard let window else {
            return
        }
        
        Task {
            try DirectoriesManager.shared.createMissingDirectoriesInDocumentsDirectory()
            
            let cores = try LibraryManager.shared.library()
            
            let configuration = UICollectionViewCompositionalLayoutConfiguration()
            configuration.interSectionSpacing = 20
            
            let collectionViewLayout: UICollectionViewCompositionalLayout = .init(sectionProvider: { sectionIndex, layoutEnvironment in
                let iPad = UIDevice.current.userInterfaceIdiom == .pad
                let itemsInGroup: CGFloat = if sectionIndex == 0 { 1 } else if UIApplication.shared.statusBarOrientation == .portrait {
                    iPad ? 6 : 3
                } else {
                    iPad ? 8 : 5
                }
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1 / itemsInGroup), heightDimension: .estimated(sectionIndex == 0 ? 120 : 300))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
                let group: NSCollectionLayoutGroup = if #available(iOS 17, *) {
                    .horizontal(layoutSize: groupSize, repeatingSubitem: item, count: Int(itemsInGroup))
                } else if #available(iOS 16, *) {
                    .horizontal(layoutSize: groupSize, repeatingSubitem: item, count: Int(itemsInGroup))
                } else {
                    .horizontal(layoutSize: groupSize, subitem: item, count: Int(itemsInGroup))
                }
                
                if sectionIndex == 0 {
                    group.contentInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
                }
                group.interItemSpacing = .fixed(20)
                
                let section = NSCollectionLayoutSection(group: group)
                if sectionIndex > 0 {
                    section.boundarySupplementaryItems = [
                        .init(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
                              elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                    ]
                }
                section.contentInsets = .init(top: sectionIndex == 0 ? 20 : 0, leading: sectionIndex == 0 ? 0 : 20, bottom: sectionIndex == cores.count ? 20 : 0, trailing: sectionIndex == 0 ? 0 : 20)
                section.interGroupSpacing = sectionIndex == 0 ? 0 : 20
                if sectionIndex == 0 {
                    section.orthogonalScrollingBehavior = .groupPaging
                } else {
                    section.orthogonalScrollingBehavior = .none
                }
                return section
            }, configuration: configuration)
            
            window.rootViewController = UINavigationController(rootViewController: LibraryController(collectionViewLayout: collectionViewLayout, cores: cores))
            window.tintColor = .systemGreen
        }
        
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
