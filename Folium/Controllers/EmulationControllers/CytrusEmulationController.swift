//
//  CytrusEmulationController.swift
//  Folium
//
//  Created by Jarrod Norwell on 29/2/2024.
//

#if canImport(Cytrus)

import Cytrus
import Foundation
import GameController
import MetalKit.MTKView
import UIKit

/*
 TODO: add landscape support
 */

class CytrusEmulationController : UIViewController, VirtualControllerButtonDelegate {
    fileprivate var thread: Thread!
    fileprivate var isRunning = false
    
    fileprivate var renderView: MTKView!
    fileprivate var virtualControllerView: VirtualControllerView!
    
    fileprivate var game: CytrusGame
    fileprivate let cytrus = Cytrus.shared
    init(game: CytrusGame) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        thread = .init(block: step)
        thread.name = "Cytrus"
        thread.qualityOfService = .userInteractive
        thread.threadPriority = 1.0
        
        renderView = .init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        renderView.translatesAutoresizingMaskIntoConstraints = false
        renderView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        renderView.layer.borderWidth = 2
        renderView.clipsToBounds = true
        renderView.layer.cornerCurve = .continuous
        renderView.layer.cornerRadius = 8
        view.addSubview(renderView)
        
        virtualControllerView = .init(console: .n3ds, virtualButtonDelegate: self)
        view.addSubview(virtualControllerView)
        
        view.addConstraints([
            renderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            renderView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            renderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            renderView.heightAnchor.constraint(equalTo: renderView.widthAnchor, multiplier: (3 / 5) + (3 / 4)),
            
            virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
            virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect),
                                               name: NSNotification.Name.GCControllerDidConnect, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
            cytrus.configure(layer: renderView.layer as! CAMetalLayer)
            cytrus.insert(game: game.fileURL)
            thread.start()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first, touch.view == renderView else {
            return
        }
        
        cytrus.touchBegan(at: touch.location(in: renderView))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        cytrus.touchEnded()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first, touch.view == renderView else {
            return
        }
        
        cytrus.touchMoved(at: touch.location(in: renderView))
    }
    
    @objc fileprivate func step() {
        while true {
            cytrus.step()
        }
    }
    
    // MARK: Notifications
    @objc fileprivate func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController, let extendedGamepad = controller.extendedGamepad else {
            return
        }
        
        extendedGamepad.dpad.up.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadUp) : self.touchUpInside(.dpadUp)
        }
        
        extendedGamepad.dpad.down.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadDown) : self.touchUpInside(.dpadDown)
        }
        
        extendedGamepad.dpad.left.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadLeft) : self.touchUpInside(.dpadLeft)
        }
        
        extendedGamepad.dpad.right.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.dpadRight) : self.touchUpInside(.dpadRight)
        }
        
        extendedGamepad.buttonOptions?.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.minus) : self.touchUpInside(.minus)
        }
        
        extendedGamepad.buttonMenu.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.plus) : self.touchUpInside(.plus)
        }
        
        extendedGamepad.buttonA.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.a) : self.touchUpInside(.a)
        }
        
        extendedGamepad.buttonB.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.b) : self.touchUpInside(.b)
        }
        
        extendedGamepad.buttonX.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.x) : self.touchUpInside(.x)
        }
        
        extendedGamepad.buttonY.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.y) : self.touchUpInside(.y)
        }
        
        extendedGamepad.leftShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.l) : self.touchUpInside(.l)
        }
        
        extendedGamepad.leftTrigger.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.zl) : self.touchUpInside(.zl)
        }
        
        extendedGamepad.rightShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.r) : self.touchUpInside(.r)
        }
        
        extendedGamepad.rightTrigger.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.zr) : self.touchUpInside(.zr)
        }
    }
    
    // MARK: Delegate
    func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        switch buttonType {
        case .dpadUp:
            cytrus.virtualControllerButtonDown(.directionalPadUp)
        case .dpadDown:
            cytrus.virtualControllerButtonDown(.directionalPadDown)
        case .dpadLeft:
            cytrus.virtualControllerButtonDown(.directionalPadLeft)
        case .dpadRight:
            cytrus.virtualControllerButtonDown(.directionalPadRight)
        case .minus:
            cytrus.virtualControllerButtonDown(.select)
        case .plus:
            cytrus.virtualControllerButtonDown(.start)
        case .a:
            cytrus.virtualControllerButtonDown(.A)
        case .b:
            cytrus.virtualControllerButtonDown(.B)
        case .x:
            cytrus.virtualControllerButtonDown(.X)
        case .y:
            cytrus.virtualControllerButtonDown(.Y)
        case .l:
            cytrus.virtualControllerButtonDown(.triggerL)
        case .zl:
            cytrus.virtualControllerButtonDown(.triggerZL)
        case .r:
            cytrus.virtualControllerButtonDown(.triggerR)
        case .zr:
            cytrus.virtualControllerButtonDown(.triggerZR)
        }
    }
    
    func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        switch buttonType {
        case .dpadUp:
            cytrus.virtualControllerButtonUp(.directionalPadUp)
        case .dpadDown:
            cytrus.virtualControllerButtonUp(.directionalPadDown)
        case .dpadLeft:
            cytrus.virtualControllerButtonUp(.directionalPadLeft)
        case .dpadRight:
            cytrus.virtualControllerButtonUp(.directionalPadRight)
        case .minus:
            cytrus.virtualControllerButtonUp(.select)
        case .plus:
            cytrus.virtualControllerButtonUp(.start)
        case .a:
            cytrus.virtualControllerButtonUp(.A)
        case .b:
            cytrus.virtualControllerButtonUp(.B)
        case .x:
            cytrus.virtualControllerButtonUp(.X)
        case .y:
            cytrus.virtualControllerButtonUp(.Y)
        case .l:
            cytrus.virtualControllerButtonUp(.triggerL)
        case .zl:
            cytrus.virtualControllerButtonUp(.triggerZL)
        case .r:
            cytrus.virtualControllerButtonUp(.triggerR)
        case .zr:
            cytrus.virtualControllerButtonUp(.triggerZR)
        }
    }
}

#endif
