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
import MetalKit
import UIKit

class CytrusEmulationController : EmulationScreensController {
    fileprivate var thread: Thread!
    fileprivate var isRunning: Bool = false
    
    fileprivate var cytrusGame: CytrusGame!
    fileprivate let cytrus = Cytrus.shared
    override init(game: AnyHashable) {
        super.init(game: game)
        guard let game = game as? CytrusGame else {
            return
        }
        
        cytrusGame = game
        
        thread = .init(block: step)
        thread.name = "Cytrus"
        thread.qualityOfService = .userInteractive
        thread.threadPriority = 0.9
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
            guard let primaryScreen = primaryScreen as? MTKView, let secondaryScreen = secondaryScreen as? MTKView else {
                return
            }
            
            cytrus.configure(primaryLayer: primaryScreen.layer as! CAMetalLayer, with: primaryScreen.frame.size,
                             secondaryLayer: secondaryScreen.layer as! CAMetalLayer, secondarySize: secondaryScreen.frame.size)
            cytrus.insert(game: cytrusGame.fileURL)
            
            thread.start()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            self.cytrus.orientationChanged(orientation: UIApplication.shared.statusBarOrientation, with: self.secondaryScreen.frame.size)
        }
    }
    
    @objc fileprivate func step() {
        while true {
            cytrus.step()
        }
    }
    
    // MARK: Touch Delegates
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        func position(in view: UIView, with location: CGPoint) -> (x: Float, y: Float) {
            let radius = view.frame.width / 2
            return (Float((location.x - radius) / radius), Float(-(location.y - radius) / radius))
        }
        
        switch touch.view {
        case virtualControllerView.dpadView:
            cytrus.thumbstickMoved(.circlePad, x: position(in: virtualControllerView.dpadView,
                                                           with: touch.location(in: virtualControllerView.dpadView)).x,
                                   y: position(in: virtualControllerView.dpadView, with: touch.location(in: virtualControllerView.dpadView)).y)
        case virtualControllerView.xybaView:
            cytrus.thumbstickMoved(.cStick, x: position(in: virtualControllerView.xybaView,
                                                           with: touch.location(in: virtualControllerView.xybaView)).x,
                                   y: position(in: virtualControllerView.xybaView, with: touch.location(in: virtualControllerView.xybaView)).y)
        case secondaryScreen:
            cytrus.touchBegan(at: touch.location(in: secondaryScreen))
        default:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        switch touch.view {
        case virtualControllerView.dpadView:
            cytrus.thumbstickMoved(.circlePad, x: 0, y: 0)
        case virtualControllerView.xybaView:
            cytrus.thumbstickMoved(.cStick, x: 0, y: 0)
        case secondaryScreen:
            cytrus.touchEnded()
        default:
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        func position(in view: UIView, with location: CGPoint) -> (x: Float, y: Float) {
            let radius = view.frame.width / 2
            return (Float((location.x - radius) / radius), Float(-(location.y - radius) / radius))
        }
        
        switch touch.view {
        case virtualControllerView.dpadView:
            cytrus.thumbstickMoved(.circlePad, x: position(in: virtualControllerView.dpadView,
                                                           with: touch.location(in: virtualControllerView.dpadView)).x,
                                   y: position(in: virtualControllerView.dpadView, with: touch.location(in: virtualControllerView.dpadView)).y)
        case virtualControllerView.xybaView:
            cytrus.thumbstickMoved(.cStick, x: position(in: virtualControllerView.xybaView,
                                                           with: touch.location(in: virtualControllerView.xybaView)).x,
                                   y: position(in: virtualControllerView.xybaView, with: touch.location(in: virtualControllerView.xybaView)).y)
        case secondaryScreen:
            cytrus.touchMoved(at: touch.location(in: secondaryScreen))
        default:
            break
        }
    }
    
    // MARK: Physical Controller Delegates
    override func controllerDidConnect(_ notification: Notification) {
        super.controllerDidConnect(notification)
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
            self.cytrus.thumbstickMoved(.circlePad, x: x, y: y)
        }
        
        extendedGamepad.rightThumbstick.valueChangedHandler = { dpad, x, y in
            self.cytrus.thumbstickMoved(.cStick, x: x, y: y)
        }
    }
    
    // MARK: Virtual Controller Delegates
    override func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchDown(buttonType)
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
    
    override func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchUpInside(buttonType)
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


/*
import Cytrus
import Foundation
import GameController
import MetalKit.MTKView
import UIKit

/*
 MARK: Supported
 - Physical Controller
 - Virtual Controller
 - Landscape Orientation (Partial)
 - Touch Input (Portrait Only)
 - Audio Output
 - Audio Input
 - Video Output
 */

class KeyboardController : UIViewController, UITextFieldDelegate {
    var visualEffectView: UIVisualEffectView!
    
    var bottomConstraint, bottomBackupConstraint: NSLayoutConstraint!
    
    var keyboardConfig: KeyboardConfig
    init(keyboardConfig: KeyboardConfig) {
        self.keyboardConfig = keyboardConfig
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.clipsToBounds = true
        visualEffectView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        visualEffectView.layer.borderWidth = 3
        visualEffectView.layer.cornerCurve = .continuous
        visualEffectView.layer.cornerRadius = 35
        view.addSubview(visualEffectView)
        bottomConstraint = visualEffectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        bottomBackupConstraint = bottomConstraint
        view.addConstraints([
            visualEffectView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            bottomConstraint,
            visualEffectView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        
        let textField = MinimalRoundedTextField(keyboardConfig.hintText, .all)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        visualEffectView.contentView.addSubview(textField)
        view.addConstraints([
            textField.topAnchor.constraint(equalTo: visualEffectView.contentView.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: visualEffectView.contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: visualEffectView.contentView.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        
        var buttons: [UIButton] = []
        switch keyboardConfig.buttonConfig {
        case .single:
            var configuration = UIButton.Configuration.filled()
            configuration.attributedTitle = .init("Okay", attributes: .init([
                .font : UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
            ]))
            configuration.buttonSize = .large
            configuration.cornerStyle = .capsule
            
            buttons.append(.init(configuration: configuration, primaryAction: .init(handler: { _ in
                NotificationCenter.default.post(name: .init("closeKeyboard"), object: nil, userInfo: [
                    "buttonPressed" : 0
                ])
                self.dismiss(animated: true)
            })))
        case .dual:
            var cancelConfiguration = UIButton.Configuration.filled()
            cancelConfiguration.attributedTitle = .init("Cancel", attributes: .init([
                .font : UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
            ]))
            cancelConfiguration.buttonSize = .large
            cancelConfiguration.cornerStyle = .capsule
            
            var okayConfiguration = UIButton.Configuration.filled()
            okayConfiguration.attributedTitle = .init("Okay", attributes: .init([
                .font : UIFont.boldSystemFont(ofSize: UIFont.buttonFontSize)
            ]))
            okayConfiguration.buttonSize = .medium
            okayConfiguration.cornerStyle = .capsule
            
            let cancelButton = UIButton(configuration: cancelConfiguration, primaryAction: .init(handler: { _ in
                NotificationCenter.default.post(name: .init("closeKeyboard"), object: nil, userInfo: [
                    "buttonPressed" : 0,
                ])
                self.dismiss(animated: true)
            }))
            cancelButton.tintColor = .systemRed
            
            buttons.append(cancelButton)
            buttons.append(.init(configuration: okayConfiguration, primaryAction: .init(handler: { _ in
                NotificationCenter.default.post(name: .init("closeKeyboard"), object: nil, userInfo: [
                    "buttonPressed" : 0,
                    "keyboardText" : textField.text ?? ""
                ])
                self.dismiss(animated: true)
            })))
        case .triple:
            break
        case .none:
            break
        @unknown default:
            fatalError()
        }
        
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 20
        visualEffectView.contentView.addSubview(stackView)
        view.addConstraints([
            stackView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: visualEffectView.contentView.bottomAnchor, constant: -20)
        ])
        
        NotificationCenter.default.addObserver(forName: .init(UIResponder.keyboardWillShowNotification), object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo, let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            
            self.bottomConstraint.constant = -frame.height
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        
        NotificationCenter.default.addObserver(forName: .init(UIResponder.keyboardWillHideNotification), object: nil, queue: .main) { notification in
            self.bottomConstraint = self.bottomBackupConstraint
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitActiveAppearance.self], action: #selector(traitDidChange))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        }
    }
    
    @objc fileprivate func traitDidChange() {
        visualEffectView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
    }
}


class CytrusEmulationController : UIViewController, VirtualControllerButtonDelegate {
    fileprivate var thread: Thread!
    fileprivate var isRunning = false
    
    fileprivate var renderView: MTKView!
    fileprivate var virtualControllerView: VirtualControllerView!
    
    fileprivate var portraitConstraints, landscapeConstraints: [NSLayoutConstraint]!
    
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
        renderView.layer.borderWidth = 3
        renderView.clipsToBounds = true
        renderView.layer.cornerCurve = .continuous
        renderView.layer.cornerRadius = 8
        view.addSubview(renderView)
        
        virtualControllerView = .init(console: .n3ds, virtualButtonDelegate: self)
        view.addSubview(virtualControllerView)
        
        portraitConstraints = [
            renderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            renderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            renderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            renderView.heightAnchor.constraint(equalTo: renderView.widthAnchor, multiplier: (3 / 5) + (3 / 4)),
            
            virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
            virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        
        landscapeConstraints = [
            renderView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            renderView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            renderView.widthAnchor.constraint(equalTo: renderView.heightAnchor, multiplier: 5 / 3),
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
        
        NotificationCenter.default.addObserver(forName: .init("openKeyboard"), object: nil, queue: .main) { notification in
            guard let config = notification.object as? KeyboardConfig else {
                return
            }
            
            let keyboardController = KeyboardController(keyboardConfig: config)
            keyboardController.modalPresentationStyle = .overFullScreen
            self.present(keyboardController, animated: true)
        }
        
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitActiveAppearance.self], action: #selector(traitDidChange))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
            cytrus.configure(layer: renderView.layer as! CAMetalLayer, with: renderView.frame.size)
            cytrus.insert(game: game.fileURL)
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
        
        cytrus.orientationChanged(orientation: UIApplication.shared.statusBarOrientation, for: renderView.layer as! CAMetalLayer)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait, .portraitUpsideDown]
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
    
    @objc fileprivate func traitDidChange() {
        renderView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
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
            self.cytrus.thumbstickMoved(.circlePad, x: x, y: y)
        }
        
        extendedGamepad.rightThumbstick.valueChangedHandler = { dpad, x, y in
            self.cytrus.thumbstickMoved(.cStick, x: x, y: y)
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
*/

#endif
