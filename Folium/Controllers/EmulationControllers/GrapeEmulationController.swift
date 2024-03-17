//
//  GrapeEmulationController.swift
//  Folium
//
//  Created by Jarrod Norwell on 26/2/2024.
//

import Foundation
import GameController
import Grape
import SDL2
import UIKit

class GrapeEmulationController : EmulationScreensController {
    fileprivate var displayLink: CADisplayLink!
    fileprivate var isRunning: Bool = false
    
    fileprivate var device: SDL_AudioDeviceID!
    
    fileprivate let grape = Grape.shared
    override init(game: AnyHashable) {
        super.init(game: game)
        guard let game = game as? GrapeGame else {
            return
        }
        
        grape.insert(game: game.fileURL)
        
        displayLink = .init(target: self, selector: #selector(step))
        displayLink.preferredFrameRateRange = .init(minimum: 30, maximum: 60, preferred: 60)
        
        SDL_SetMainReady()
        SDL_InitSubSystem(SDL_INIT_AUDIO)
        
        typealias Callback = @convention(c)(UnsafeMutableRawPointer?, UnsafeMutablePointer<UInt8>?, Int32) -> Void
        
        let callback: Callback = { userdata, stream, len in
            guard let userdata else {
                return
            }
            
            let vc = Unmanaged<GrapeEmulationController>.fromOpaque(userdata).takeUnretainedValue()
            
            SDL_memcpy(stream, vc.grape.audioBuffer(), Int(len))
        }
        
        var spec = SDL_AudioSpec()
        spec.callback = callback
        spec.userdata = Unmanaged.passUnretained(self).toOpaque()
        spec.channels = 2
        spec.format = SDL_AudioFormat(AUDIO_S16)
        spec.freq = 48000
        spec.samples = 1024
        
        device = SDL_OpenAudioDevice(nil, 0, &spec, nil, 0)
        SDL_PauseAudioDevice(device, 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
            
            guard let game = game as? GrapeGame else {
                return
            }
            
            if !game.isGBA {
                grape.updateScreenLayout(with: secondaryScreen.frame.size)
            }
            
            displayLink.add(to: .current, forMode: .common)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let game = game as? GrapeGame else {
            return
        }
        
        coordinator.animate { _ in
            if !game.isGBA {
                self.grape.updateScreenLayout(with: self.secondaryScreen.frame.size)
            }
        }
    }
    
    @objc fileprivate func step() {
        guard let game = game as? GrapeGame, let primaryScreen = primaryScreen as? UIImageView,
        let secondaryScreen = secondaryScreen as? UIImageView else {
            return
        }
        
        grape.step()
        
        let screenFramebuffer = grape.screenFramebuffer(isGBA: game.isGBA)
        guard let topCGImage = cgImage(from: screenFramebuffer, width: game.isGBA ? 240 : 256, height: game.isGBA ? 160 : 192) else {
            return
        }
        
        primaryScreen.image = .init(cgImage: topCGImage)
        
        if !game.isGBA {
            guard let bottomCGImage = cgImage(from: screenFramebuffer.advanced(by: 256 * 192), width: 256, height: 192) else {
                return
            }
            
            secondaryScreen.image = .init(cgImage: bottomCGImage)
        }
    }
    
    // MARK: Touch Delegates
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let game = game as? GrapeGame, let touch = touches.first, touch.view == secondaryScreen, !game.isGBA else {
            return
        }
        
        grape.touchBegan(at: touch.location(in: secondaryScreen))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let game = game as? GrapeGame else {
            return
        }
        
        if !game.isGBA {
            grape.touchEnded()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let game = game as? GrapeGame, let touch = touches.first, touch.view == secondaryScreen, !game.isGBA else {
            return
        }
        
        grape.touchMoved(at: touch.location(in: secondaryScreen))
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
        
        extendedGamepad.rightShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.r) : self.touchUpInside(.r)
        }
    }
    
    // MARK: Virtual Controller Delegates
    override func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchDown(buttonType)
        switch buttonType {
        case .dpadUp:
            grape.virtualControllerButtonDown(6)
        case .dpadDown:
            grape.virtualControllerButtonDown(7)
        case .dpadLeft:
            grape.virtualControllerButtonDown(5)
        case .dpadRight:
            grape.virtualControllerButtonDown(4)
        case .minus:
            grape.virtualControllerButtonDown(2)
        case .plus:
            grape.virtualControllerButtonDown(3)
        case .a:
            grape.virtualControllerButtonDown(0)
        case .b:
            grape.virtualControllerButtonDown(1)
        case .x:
            grape.virtualControllerButtonDown(10)
        case .y:
            grape.virtualControllerButtonDown(11)
        case .l:
            grape.virtualControllerButtonDown(9)
        case .r:
            grape.virtualControllerButtonDown(8)
        default:
            break
        }
    }
    
    override func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
        super.touchUpInside(buttonType)
        switch buttonType {
        case .dpadUp:
            grape.virtualControllerButtonUp(6)
        case .dpadDown:
            grape.virtualControllerButtonUp(7)
        case .dpadLeft:
            grape.virtualControllerButtonUp(5)
        case .dpadRight:
            grape.virtualControllerButtonUp(4)
        case .minus:
            grape.virtualControllerButtonUp(2)
        case .plus:
            grape.virtualControllerButtonUp(3)
        case .a:
            grape.virtualControllerButtonUp(0)
        case .b:
            grape.virtualControllerButtonUp(1)
        case .x:
            grape.virtualControllerButtonUp(10)
        case .y:
            grape.virtualControllerButtonUp(11)
        case .l:
            grape.virtualControllerButtonUp(9)
        case .r:
            grape.virtualControllerButtonUp(8)
        default:
            break
        }
    }
}
