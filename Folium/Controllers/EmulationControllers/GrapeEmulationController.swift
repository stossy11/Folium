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

class GrapeEmulationController : UIViewController, VirtualControllerButtonDelegate {
    fileprivate var displayLink: CADisplayLink!
    fileprivate var isRunning = false
    
    fileprivate var topImageView, bottomImageView, topBlurredImageView, bottomBlurredImageView: UIImageView!
    fileprivate var visualEffectView: UIVisualEffectView!
    fileprivate var virtualControllerView: VirtualControllerView!
    
    fileprivate var portraitConstraints, landscapeConstraints: [NSLayoutConstraint]!
    
    var device: SDL_AudioDeviceID!
    
    fileprivate var game: GrapeGame
    fileprivate let grape = Grape.shared
    init(game: GrapeGame) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
        grape.insert(game: game.fileURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        displayLink = .init(target: self, selector: #selector(step))
        displayLink.preferredFrameRateRange = .init(minimum: 30, maximum: 60, preferred: 60)
        
        topBlurredImageView = .init()
        topBlurredImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBlurredImageView)
        
        if !game.isGBA {
            bottomBlurredImageView = .init()
            bottomBlurredImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bottomBlurredImageView)
        }
        
        visualEffectView = .init(effect: UIBlurEffect(style: .systemChromeMaterial))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualEffectView)
        
        topImageView = .init()
        topImageView.translatesAutoresizingMaskIntoConstraints = false
        topImageView.clipsToBounds = true
        topImageView.layer.cornerCurve = .continuous
        topImageView.layer.cornerRadius = 8
        view.addSubview(topImageView)
        
        if !game.isGBA {
            bottomImageView = .init()
            bottomImageView.translatesAutoresizingMaskIntoConstraints = false
            bottomImageView.clipsToBounds = true
            bottomImageView.isUserInteractionEnabled = true
            bottomImageView.layer.cornerCurve = .continuous
            bottomImageView.layer.cornerRadius = 8
            view.addSubview(bottomImageView)
        }

        virtualControllerView = .init(console: .nds, virtualButtonDelegate: self)
        view.addSubview(virtualControllerView)
        
        portraitConstraints = if game.isGBA {
            [
                topBlurredImageView.topAnchor.constraint(equalTo: view.topAnchor),
                topBlurredImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                topBlurredImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                topImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                topImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                topImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                topImageView.heightAnchor.constraint(equalTo: topImageView.widthAnchor, multiplier: 3 / 4),
                
                virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
                virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                topBlurredImageView.bottomAnchor.constraint(equalTo: topImageView.bottomAnchor, constant: 10)
            ]
        } else {
            [
                topBlurredImageView.topAnchor.constraint(equalTo: view.topAnchor),
                topBlurredImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                topBlurredImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                topImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                topImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                topImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                topImageView.heightAnchor.constraint(equalTo: topImageView.widthAnchor, multiplier: 3 / 4),
                
                bottomBlurredImageView.topAnchor.constraint(equalTo: topBlurredImageView.bottomAnchor),
                bottomBlurredImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bottomBlurredImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                bottomImageView.topAnchor.constraint(equalTo: topImageView.bottomAnchor, constant: 20),
                bottomImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                bottomImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                bottomImageView.heightAnchor.constraint(equalTo: bottomImageView.widthAnchor, multiplier: 3 / 4),
                
                virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
                virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                topBlurredImageView.bottomAnchor.constraint(equalTo: topImageView.bottomAnchor, constant: 10),
                bottomBlurredImageView.bottomAnchor.constraint(equalTo: bottomImageView.bottomAnchor, constant: 20)
            ]
        }
        
        landscapeConstraints = if game.isGBA {
            [
                topBlurredImageView.topAnchor.constraint(equalTo: view.topAnchor),
                topBlurredImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                topBlurredImageView.widthAnchor.constraint(equalTo: topBlurredImageView.heightAnchor, multiplier: 4 / 3),
                topBlurredImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                
                visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                topImageView.topAnchor.constraint(equalTo: topBlurredImageView.topAnchor, constant: 20),
                topImageView.leadingAnchor.constraint(equalTo: topBlurredImageView.leadingAnchor, constant: 20),
                topImageView.bottomAnchor.constraint(equalTo: topBlurredImageView.bottomAnchor, constant: -20),
                topImageView.trailingAnchor.constraint(equalTo: topBlurredImageView.trailingAnchor, constant: -20),
                
                virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
                virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        } else {
            [
                topBlurredImageView.topAnchor.constraint(equalTo: view.topAnchor),
                topBlurredImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 2 / 4),
                topBlurredImageView.widthAnchor.constraint(equalTo: topBlurredImageView.heightAnchor, multiplier: 4 / 3),
                topBlurredImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                
                visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                
                topImageView.topAnchor.constraint(equalTo: topBlurredImageView.topAnchor, constant: 20),
                topImageView.leadingAnchor.constraint(equalTo: topBlurredImageView.leadingAnchor, constant: 20),
                topImageView.bottomAnchor.constraint(equalTo: topBlurredImageView.bottomAnchor, constant: -10),
                topImageView.trailingAnchor.constraint(equalTo: topBlurredImageView.trailingAnchor, constant: -20),
                
                bottomBlurredImageView.topAnchor.constraint(equalTo: topBlurredImageView.bottomAnchor),
                bottomBlurredImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bottomBlurredImageView.widthAnchor.constraint(equalTo: bottomBlurredImageView.heightAnchor, multiplier: 4 / 3),
                bottomBlurredImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                
                bottomImageView.topAnchor.constraint(equalTo: bottomBlurredImageView.topAnchor, constant: 10),
                bottomImageView.leadingAnchor.constraint(equalTo: bottomBlurredImageView.leadingAnchor, constant: 20),
                bottomImageView.bottomAnchor.constraint(equalTo: bottomBlurredImageView.bottomAnchor, constant: -20),
                bottomImageView.trailingAnchor.constraint(equalTo: bottomBlurredImageView.trailingAnchor, constant: -20),
                
                virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
                virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]
        }
        
        let constraints: [NSLayoutConstraint] = if UIApplication.shared.statusBarOrientation == .portrait {
            portraitConstraints
        } else {
            landscapeConstraints
        }
        view.addConstraints(constraints)
        
        
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
            
            if !game.isGBA {
                grape.updateScreenLayout(with: bottomImageView.frame.size)
            }
            displayLink.add(to: .current, forMode: .common)
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
            
            if !self.game.isGBA {
                self.grape.updateScreenLayout(with: self.bottomImageView.frame.size)
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad && !game.isGBA { .landscape } else { .all }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first, touch.view == bottomImageView, !game.isGBA else {
            return
        }
        
        grape.touchBegan(at: touch.location(in: bottomImageView))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if !game.isGBA {
            grape.touchEnded()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first, touch.view == bottomImageView, !game.isGBA else {
            return
        }
        
        grape.touchMoved(at: touch.location(in: bottomImageView))
    }
    
    @objc fileprivate func step() {
        grape.step()
        
        let screenFramebuffer = grape.screenFramebuffer(isGBA: game.isGBA)
        
        
        guard let topCGImage = cgImage(from: screenFramebuffer, width: game.isGBA ? 240 : 256, height: game.isGBA ? 160 : 192) else {
            return
        }
        
        topBlurredImageView.image = .init(cgImage: topCGImage)
        topImageView.image = .init(cgImage: topCGImage)
        
        if !game.isGBA {
            guard let bottomCGImage = cgImage(from: screenFramebuffer.advanced(by: 256 * 192), width: 256, height: 192) else {
                return
            }
            
            bottomBlurredImageView.image = .init(cgImage: bottomCGImage)
            bottomImageView.image = .init(cgImage: bottomCGImage)
        }
    }
    
    fileprivate func cgImage(from screenFramebuffer: UnsafeMutablePointer<UInt32>, width: Int, height: Int) -> CGImage? {
        var imageRef: CGImage?
        
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
        
        extendedGamepad.rightShoulder.pressedChangedHandler = { button, value, pressed in
            pressed ? self.touchDown(.r) : self.touchUpInside(.r)
        }
    }
    
    // MARK: Delegate
    func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
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
    
    func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
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
