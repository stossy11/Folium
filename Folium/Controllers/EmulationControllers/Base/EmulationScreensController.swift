//
//  EmulationScreensController.swift
//  Folium
//
//  Created by Jarrod Norwell on 17/3/2024.
//

import Foundation
import UIKit

class EmulationScreensController : EmulationVirtualControllerController {
    var primaryScreen, secondaryScreen: UIView!
    fileprivate let device = MTLCreateSystemDefaultDevice()
    
    fileprivate var portraitConstraints, landscapeConstraints: [NSLayoutConstraint]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch game {
        case _ as CytrusGame:
            setupCytrusScreen()
        case let grapeGame as GrapeGame:
            grapeGame.isGBA ? setupGrapeScreen() : setupGrapeScreens()
        case _ as KiwiGame:
            setupKiwiScreen()
        case _ as SudachiGame:
            setupSudachiScreen()
        default:
            fatalError()
        }
        
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(traitDidChange))
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIApplication.shared.statusBarOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown {
            view.removeConstraints(landscapeConstraints)
            view.addConstraints(portraitConstraints)
        } else {
            view.removeConstraints(portraitConstraints)
            view.addConstraints(landscapeConstraints)
        }
        
        coordinator.animate { _ in
            self.virtualControllerView.layout()
            self.view.layoutIfNeeded()
        }
    }
    
    func setupCytrusScreen() {
        
    }
    
    func setupGrapeScreen() {
        primaryScreen = UIImageView(frame: .zero)
        primaryScreen.translatesAutoresizingMaskIntoConstraints = false
        primaryScreen.clipsToBounds = true
        primaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        primaryScreen.layer.borderWidth = 4
        primaryScreen.layer.cornerCurve = .continuous
        primaryScreen.layer.cornerRadius = 8
        view.addSubview(primaryScreen)
        view.insertSubview(primaryScreen, belowSubview: virtualControllerView)
        
        portraitConstraints = [
            primaryScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            primaryScreen.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            primaryScreen.heightAnchor.constraint(equalTo: primaryScreen.widthAnchor, multiplier: 2 / 3)
        ]
        
        landscapeConstraints = [
            primaryScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            primaryScreen.widthAnchor.constraint(equalTo: primaryScreen.heightAnchor, multiplier: 3 / 2),
            primaryScreen.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ]
        
        view.addConstraints(UIApplication.shared.statusBarOrientation == .portrait ||
                            UIApplication.shared.statusBarOrientation == .portraitUpsideDown ? portraitConstraints : landscapeConstraints)
    }
    
    func setupGrapeScreens() {
        primaryScreen = UIImageView(frame: .zero)
        primaryScreen.translatesAutoresizingMaskIntoConstraints = false
        primaryScreen.clipsToBounds = true
        primaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        primaryScreen.layer.borderWidth = 4
        primaryScreen.layer.cornerCurve = .continuous
        primaryScreen.layer.cornerRadius = 8
        view.addSubview(primaryScreen)
        view.insertSubview(primaryScreen, belowSubview: virtualControllerView)
        
        secondaryScreen = UIImageView(frame: .zero)
        secondaryScreen.translatesAutoresizingMaskIntoConstraints = false
        secondaryScreen.clipsToBounds = true
        secondaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        secondaryScreen.layer.borderWidth = 4
        secondaryScreen.layer.cornerCurve = .continuous
        secondaryScreen.layer.cornerRadius = 8
        secondaryScreen.isUserInteractionEnabled = true
        view.addSubview(secondaryScreen)
        view.insertSubview(secondaryScreen, belowSubview: virtualControllerView)
        
        portraitConstraints = [
            primaryScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            primaryScreen.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            primaryScreen.heightAnchor.constraint(equalTo: primaryScreen.widthAnchor, multiplier: 3 / 4),
            
            secondaryScreen.topAnchor.constraint(equalTo: primaryScreen.safeAreaLayoutGuide.bottomAnchor, constant: 10),
            secondaryScreen.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            secondaryScreen.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            secondaryScreen.heightAnchor.constraint(equalTo: secondaryScreen.widthAnchor, multiplier: 3 / 4)
        ]
        
        landscapeConstraints = [
            primaryScreen.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            primaryScreen.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: -5),
            primaryScreen.heightAnchor.constraint(equalTo: primaryScreen.widthAnchor, multiplier: 3 / 4),
            primaryScreen.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            secondaryScreen.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 5),
            secondaryScreen.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            secondaryScreen.heightAnchor.constraint(equalTo: primaryScreen.widthAnchor, multiplier: 3 / 4),
            secondaryScreen.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ]
        
        view.addConstraints(UIApplication.shared.statusBarOrientation == .portrait ||
                            UIApplication.shared.statusBarOrientation == .portraitUpsideDown ? portraitConstraints : landscapeConstraints)
    }
    
    func setupKiwiScreen() {
        primaryScreen = UIImageView(frame: .zero)
        primaryScreen.translatesAutoresizingMaskIntoConstraints = false
        primaryScreen.clipsToBounds = true
        primaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        primaryScreen.layer.borderWidth = 4
        primaryScreen.layer.cornerCurve = .continuous
        primaryScreen.layer.cornerRadius = 8
        view.addSubview(primaryScreen)
        view.insertSubview(primaryScreen, belowSubview: virtualControllerView)
        
        portraitConstraints = [
            primaryScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            primaryScreen.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            primaryScreen.heightAnchor.constraint(equalTo: primaryScreen.widthAnchor, multiplier: 3 / 4)
        ]
        
        landscapeConstraints = [
            primaryScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            primaryScreen.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            primaryScreen.widthAnchor.constraint(equalTo: primaryScreen.heightAnchor, multiplier: 4 / 3),
            primaryScreen.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ]
        
        view.addConstraints(UIApplication.shared.statusBarOrientation == .portrait ||
                            UIApplication.shared.statusBarOrientation == .portraitUpsideDown ? portraitConstraints : landscapeConstraints)
    }
    
    func setupSudachiScreen() {
        
    }
    
    @objc fileprivate func traitDidChange() {
        primaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        if secondaryScreen.isDescendant(of: view) {
            secondaryScreen.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        }
    }
    
    func cgImage(from screenFramebuffer: UnsafeMutablePointer<UInt32>, width: Int, height: Int) -> CGImage? {
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
}
