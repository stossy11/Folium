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

class KiwiEmulationController : UIViewController, VirtualControllerButtonDelegate {
    fileprivate var displayLink: CADisplayLink!
    fileprivate var isRunning = false
    
    fileprivate var imageView, blurredImageView: UIImageView!
    fileprivate var visualEffectView: UIVisualEffectView!
    fileprivate var virtualControllerView: VirtualControllerView!
    fileprivate var buttonStackView: UIStackView!
    
    fileprivate var addPlayerButton: BlurredImageButton!
    
    fileprivate var portraitConstraints, landscapeConstraints: [NSLayoutConstraint]!
    
    fileprivate let kiwi = Kiwi.shared
    init(game: KiwiGame) {
        super.init(nibName: nil, bundle: nil)
        kiwi.insert(rom: game.fileURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        displayLink = .init(target: self, selector: #selector(step))
        displayLink.preferredFrameRateRange = .init(minimum: 30, maximum: 60, preferred: 60)
        
        blurredImageView = .init()
        blurredImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurredImageView)
        
        visualEffectView = .init(effect: UIBlurEffect(style: .systemChromeMaterial))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(visualEffectView)
        
        imageView = .init()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.layer.cornerCurve = .continuous
        imageView.layer.cornerRadius = 8
        visualEffectView.contentView.addSubview(imageView)
        
        addPlayerButton = .init(with: {
            
        })
        addPlayerButton.translatesAutoresizingMaskIntoConstraints = false
        let systemName = if #available(iOS 16, *) { "person.line.dotted.person.fill" } else { "person.2.wave.2.fill" }
        addPlayerButton.set(systemName, .secondaryLabel)
        visualEffectView.contentView.addSubview(addPlayerButton)
        
        buttonStackView = .init(arrangedSubviews: [addPlayerButton])
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .equalSpacing
        buttonStackView.spacing = 10
        visualEffectView.contentView.addSubview(buttonStackView)
        
        virtualControllerView = .init(console: .nes, virtualButtonDelegate: self)
        view.addSubview(virtualControllerView)
        
        portraitConstraints = [
            blurredImageView.topAnchor.constraint(equalTo: view.topAnchor),
            blurredImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurredImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: visualEffectView.contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: visualEffectView.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: visualEffectView.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3 / 4),
            
            buttonStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            
            virtualControllerView.topAnchor.constraint(equalTo: view.topAnchor),
            virtualControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            virtualControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            virtualControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            blurredImageView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20)
        ]
        
        landscapeConstraints = [
            blurredImageView.topAnchor.constraint(equalTo: view.topAnchor),
            blurredImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurredImageView.widthAnchor.constraint(equalTo: blurredImageView.heightAnchor, multiplier: 4 / 3),
            blurredImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: blurredImageView.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: blurredImageView.leadingAnchor, constant: 20),
            imageView.bottomAnchor.constraint(equalTo: blurredImageView.bottomAnchor, constant: -20),
            imageView.trailingAnchor.constraint(equalTo: blurredImageView.trailingAnchor, constant: -20),
            
            buttonStackView.topAnchor.constraint(equalTo: visualEffectView.contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: visualEffectView.contentView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
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
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidDisconnect),
                                               name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isRunning {
            isRunning = true
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
        }
    }
    
    @objc fileprivate func step() {
        kiwi.step()
        
        guard let cgImage = cgImage(from: kiwi.screenFramebuffer(), width: 256, height: 240) else {
            return
        }
        
        imageView.image = .init(cgImage: cgImage)
        blurredImageView.image = .init(cgImage: cgImage)
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
    }
    
    @objc fileprivate func controllerDidDisconnect(_ notification: Notification) {
        guard let subview = buttonStackView.arrangedSubviews.last else {
            return
        }
        
        buttonStackView.removeArrangedSubview(subview)
    }
    
    // MARK: Delegate
    func touchDown(_ buttonType: VirtualControllerButton.ButtonType) {
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
    
    func touchUpInside(_ buttonType: VirtualControllerButton.ButtonType) {
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
