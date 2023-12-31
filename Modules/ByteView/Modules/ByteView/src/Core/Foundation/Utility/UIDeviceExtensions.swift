//
//  UIDeviceExtensions.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/11/7.
//

import Foundation
import UIKit
import ByteViewCommon
import ByteViewSetting
import ByteViewUI

extension UIDevice {
    /// 旋转屏幕
    /// - Parameters:
    ///   - view: 传入所在的View，iOS16及以上版本用它获取windowScene，不传会取VCScene.windowScene
    static func updateDeviceOrientationForViewScene(_ view: UIView? = nil,
                                                    to orientation: UIInterfaceOrientation? = nil,
                                                    animated: Bool = false) {
        guard Display.phone else { return }
        if !animated {
            UIView.setAnimationsEnabled(false)
        }
        if #available(iOS 16.0, *) {
            if let window = (view as? UIWindow), let targetWindowScene = window.windowScene ?? VCScene.windowScene {
                innerUpdateWindowSceneOrientationForWindowScene(targetWindowScene, to: orientation)
            } else if let targetWindowScene = view?.window?.windowScene ?? VCScene.windowScene {
                innerUpdateWindowSceneOrientationForWindowScene(targetWindowScene, to: orientation)
            } else {
                Logger.ui.warn("rotate device failed, due to invalid window scene")
            }
        } else {
            innerUpdateDeviceOrientation(orientation)
        }
        if !animated {
            UIView.setAnimationsEnabled(true)
        }
    }

    /// iOS16及以上系统的转屏方法，使用UIWindowScene做旋转
    @available(iOS 16.0, *)
    private static func innerUpdateWindowSceneOrientationForWindowScene(_ scene: UIWindowScene, to orientation: UIInterfaceOrientation? = nil) {
        let targetOrientation = orientation?.interfaceOrientationMask ?? scene.interfaceOrientation.interfaceOrientationMask
        Logger.ui.info("updateDeviceOrientation to \(targetOrientation), isAutomatic = \(orientation == nil)")
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: targetOrientation)) { error in
            Logger.ui.warn("change orientation failed, error: \(error)")
        }
        scene.windows.forEach {
            if !$0.isHidden, ($0 is FloatingWindow) || $0.isKeyWindow {
                $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }

    /// iOS15及以下系统的转屏方法，使用UIDevice做旋转
    private static func innerUpdateDeviceOrientation(_ orientation: UIInterfaceOrientation? = nil) {
        let value = (orientation ?? UIApplication.shared.statusBarOrientation).rawValue
        Logger.ui.info("updateDeviceOrientation to \(value), isAutomatic = \(orientation == nil)")
        UIDevice.current.setValue(value, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

extension UIInterfaceOrientation {
    var interfaceOrientationMask: UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .allButUpsideDown
        }
    }
}

extension UIInterfaceOrientationMask {

    var supportedOrientations: [UIInterfaceOrientation] {
        switch self {
        case .portrait:
            return [.portrait]
        case .landscapeLeft:
            return [.landscapeLeft]
        case .landscapeRight:
            return [.landscapeRight]
        case .portraitUpsideDown:
            return [.portraitUpsideDown]
        case .landscape:
            return [.landscapeLeft, .landscapeRight]
        case .all:
            return [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
        case .allButUpsideDown:
            return [.portrait, .landscapeLeft, .landscapeRight]
        default:
            return [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
        }
    }
}
