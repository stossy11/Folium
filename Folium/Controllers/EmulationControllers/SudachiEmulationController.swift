//
//  SudachiEmulationController.swift
//  Folium
//
//  Created by Jarrod Norwell on 8/3/2024.
//

#if canImport(Sudachi)

import Sudachi
import Foundation
import GameController
import MetalKit.MTKView
import UIKit

class SudachiEmulationController : UIViewController, VirtualControllerButtonDelegate {
    fileprivate var thread: Thread!
    fileprivate var isRunning = false
    
    fileprivate var renderView: MTKView!
    fileprivate var virtualControllerView: VirtualControllerView!
    
    fileprivate var portraitConstraints, landscapeConstraints: [NSLayoutConstraint]!
    
    fileprivate var game: SudachiGame? = nil
    fileprivate let sudachi = Sudachi.shared
    init(game: SudachiGame? = nil) {
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
        thread.name = "Sudachi"
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
        
        virtualControllerView = .init(console: .nSwitch, virtualButtonDelegate: self)
        view.addSubview(virtualControllerView)
        
        portraitConstraints = [
            renderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            renderView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            renderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            renderView.heightAnchor.constraint(equalTo: renderView.widthAnchor, multiplier: 9 / 16),
            
            virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
            virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        landscapeConstraints = [
            renderView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            renderView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            renderView.widthAnchor.constraint(equalTo: renderView.heightAnchor, multiplier: 16 / 9),
            renderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
            virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        let constraints: [NSLayoutConstraint] = if UIApplication.shared.statusBarOrientation == .portrait {
            portraitConstraints
        } else {
            landscapeConstraints
        }
        view.addConstraints(constraints)
        
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
            sudachi.configure(layer: renderView.layer as! CAMetalLayer, with: renderView.frame.size)
            if let game = game {
                sudachi.insert(game: game.fileURL)
            } else {
                sudachi.bootOS()
            }
            thread.start()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        virtualControllerView.layout()
        if UIApplication.shared.statusBarOrientation == .portrait {
            view.removeConstraints(landscapeConstraints)
            view.addConstraints(portraitConstraints)
        } else {
            view.removeConstraints(portraitConstraints)
            view.addConstraints(landscapeConstraints)
        }
        
        coordinator.animate { _ in
            self.view.layoutIfNeeded()
        }
    }
    
    var _touches: [UITouch] = []
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first, touch.view == renderView else {
            return
        }
        
        _touches.append(touch)
        
        sudachi.touchBegan(at: touch.location(in: renderView), for: UInt(_touches.count))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first, let _touch = _touches.firstIndex(where: { $0 == touch }) else {
            return
        }
        
        sudachi.touchEnded(for: UInt(_touch))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first, let _touch = _touches.firstIndex(where: { $0 == touch }), touch.view == renderView else {
            return
        }
        
        sudachi.touchMoved(at: touch.location(in: renderView), for: UInt(_touch))
    }
    
    @objc fileprivate func step() {
        sudachi.step()
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
        
        extendedGamepad.leftThumbstick.valueChangedHandler = { dpad, x, y in
            self.sudachi.thumbstickMoved(.SL, x: x, y: y)
        }
        
        extendedGamepad.rightThumbstick.valueChangedHandler = { dpad, x, y in
            self.sudachi.thumbstickMoved(.SR, x: x, y: y)
        }
    }
    
    // MARK: Delegate
    func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        switch buttonType {
        case .dpadUp:
            sudachi.virtualControllerButtonDown(.directionalPadUp)
        case .dpadDown:
            sudachi.virtualControllerButtonDown(.directionalPadDown)
        case .dpadLeft:
            sudachi.virtualControllerButtonDown(.directionalPadLeft)
        case .dpadRight:
            sudachi.virtualControllerButtonDown(.directionalPadRight)
        case .minus:
            sudachi.virtualControllerButtonDown(.minus)
        case .plus:
            sudachi.virtualControllerButtonDown(.plus)
        case .a:
            sudachi.virtualControllerButtonDown(.A)
        case .b:
            sudachi.virtualControllerButtonDown(.B)
        case .x:
            sudachi.virtualControllerButtonDown(.X)
        case .y:
            sudachi.virtualControllerButtonDown(.Y)
        case .l:
            sudachi.virtualControllerButtonDown(.triggerL)
        case .zl:
            sudachi.virtualControllerButtonDown(.triggerZL)
        case .r:
            sudachi.virtualControllerButtonDown(.triggerR)
        case .zr:
            sudachi.virtualControllerButtonDown(.triggerZR)
        }
    }
    
    func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        switch buttonType {
        case .dpadUp:
            sudachi.virtualControllerButtonUp(.directionalPadUp)
        case .dpadDown:
            sudachi.virtualControllerButtonUp(.directionalPadDown)
        case .dpadLeft:
            sudachi.virtualControllerButtonUp(.directionalPadLeft)
        case .dpadRight:
            sudachi.virtualControllerButtonUp(.directionalPadRight)
        case .minus:
            sudachi.virtualControllerButtonUp(.minus)
        case .plus:
            sudachi.virtualControllerButtonUp(.plus)
        case .a:
            sudachi.virtualControllerButtonUp(.A)
        case .b:
            sudachi.virtualControllerButtonUp(.B)
        case .x:
            sudachi.virtualControllerButtonUp(.X)
        case .y:
            sudachi.virtualControllerButtonUp(.Y)
        case .l:
            sudachi.virtualControllerButtonUp(.triggerL)
        case .zl:
            sudachi.virtualControllerButtonUp(.triggerZL)
        case .r:
            sudachi.virtualControllerButtonUp(.triggerR)
        case .zr:
            sudachi.virtualControllerButtonUp(.triggerZR)
        }
    }
}

#endif
