//
//  KiwiEmulationController.swift
//  Folium
//
//  Created by Jarrod Norwell on 21/2/2024.
//

import Foundation
import GameController
import Kiwi
import UIKit

class KiwiEmulationController : EmulationScreensController {
    fileprivate var displayLink: CADisplayLink!
    fileprivate var isRunning: Bool = false
    
    fileprivate var kiwiGame: KiwiGame!
    fileprivate let kiwi = Kiwi.shared
    override init(game: AnyHashable) {
        super.init(game: game)
        guard let game = game as? KiwiGame else {
            return
        }
        
        kiwiGame = game
        
        kiwi.insert(game: kiwiGame.fileURL)
        
        displayLink = .init(target: self, selector: #selector(step))
        displayLink.preferredFrameRateRange = .init(minimum: 30, maximum: 60, preferred: 60)
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
            
            displayLink.add(to: .current, forMode: .common)
        }
    }
    
    @objc fileprivate func step() {
        guard let primaryScreen = primaryScreen as? UIImageView,
              let primaryBlurredScreen = primaryBlurredScreen as? UIImageView else {
            return
        }
        
        kiwi.step()
        
        guard let cgImage = cgImage(from: kiwi.screenFramebuffer(), width: 256 * 6, height: 240 * 6) else {
            return
        }
        
        primaryScreen.image = .init(cgImage: cgImage)
        UIView.transition(with: primaryBlurredScreen, duration: 0.66, options: .transitionCrossDissolve) {
            primaryBlurredScreen.image = .init(cgImage: cgImage)
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
    }
    
    // MARK: Virtual Controller Delegates
    override func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchDown(buttonType)
        switch buttonType {
        case .dpadUp:
            kiwi.virtualControllerButtonDown(0b00010000)
        case .dpadDown:
            kiwi.virtualControllerButtonDown(0b00100000)
        case .dpadLeft:
            kiwi.virtualControllerButtonDown(0b01000000)
        case .dpadRight:
            kiwi.virtualControllerButtonDown(0b10000000)
        case .minus:
            kiwi.virtualControllerButtonDown(0b00000100)
        case .plus:
            kiwi.virtualControllerButtonDown(0b00001000)
        case .a:
            kiwi.virtualControllerButtonDown(0b00000001)
        case .b:
            kiwi.virtualControllerButtonDown(0b00000010)
        default:
            break
        }
    }
    
    override func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchUpInside(buttonType)
        switch buttonType {
        case .dpadUp:
            kiwi.virtualControllerButtonUp(0b00010000)
        case .dpadDown:
            kiwi.virtualControllerButtonUp(0b00100000)
        case .dpadLeft:
            kiwi.virtualControllerButtonUp(0b01000000)
        case .dpadRight:
            kiwi.virtualControllerButtonUp(0b10000000)
        case .minus:
            kiwi.virtualControllerButtonUp(0b00000100)
        case .plus:
            kiwi.virtualControllerButtonUp(0b00001000)
        case .a:
            kiwi.virtualControllerButtonUp(0b00000001)
        case .b:
            kiwi.virtualControllerButtonUp(0b00000010)
        default:
            break
        }
    }
}
