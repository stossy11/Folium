//
//  EmulationVirtualControllerController.swift
//  Folium
//
//  Created by Jarrod Norwell on 13/3/2024.
//

import Foundation
import GameController
import UIKit

class EmulationVirtualControllerController : UIViewController, VirtualControllerButtonDelegate {
    var virtualControllerView: VirtualControllerView!
    
    var game: AnyHashable
    init(game: AnyHashable) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        switch game {
        case let cytrusGame as CytrusGame:
            virtualControllerView = .init(console: cytrusGame.core.console, virtualButtonDelegate: self)
        case let grapeGame as GrapeGame:
            virtualControllerView = .init(console: grapeGame.core.console, virtualButtonDelegate: self)
        case let kiwiGame as KiwiGame:
            virtualControllerView = .init(console: kiwiGame.core.console, virtualButtonDelegate: self)
        case let sudachiGame as SudachiGame:
            virtualControllerView = .init(console: sudachiGame.core.console, virtualButtonDelegate: self)
        default:
            fatalError()
        }
        
        view.addSubview(virtualControllerView)
        view.addConstraints([
            virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
            virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        NotificationCenter.default.addObserver(forName: .init(NSNotification.Name.GCControllerDidConnect), object: nil, queue: .main, using: controllerDidConnect)
        NotificationCenter.default.addObserver(forName: .init(NSNotification.Name.GCControllerDidDisconnect), object: nil, queue: .main, using: controllerDidDisconnect)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.GCControllerDidDisconnect, object: nil)
    }
    
    func controllerDidConnect(_ notification: Notification) {
        UIView.animate(withDuration: 0.2) {
            self.virtualControllerView.alpha = 0
        }
    }
    
    func controllerDidDisconnect(_ notification: Notification) {
        UIView.animate(withDuration: 0.2) {
            self.virtualControllerView.alpha = 1
        }
    }
    
    func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {}
    
    func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {}
}
