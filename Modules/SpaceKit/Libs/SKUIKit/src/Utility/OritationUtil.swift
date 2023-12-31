//
//  OritationUtil.swift
//  SKUIKit
//
//  Created by Guoxinyi on 2022/8/8.
//
// 封装强制转屏方法，iOS16以上将使用新的转屏接口

import Foundation
import SKFoundation
import EENavigator

public final class LKDeviceOrientation {
    
    public class func setOritation(_ oriation: UIDeviceOrientation) {
        #if swift(>=5.7)
        DocsLogger.info("LKDeviceOrientation setOritation \(oriation.rawValue)")
        if #available(iOS 16.0, *) {
            var scene: UIScene?
            let connectScenes = UIApplication.shared.windowApplicationScenes
            if let activeScene = connectScenes.first(where: {
                    $0.isKind(of: UIWindowScene.self) && $0.activationState == .foregroundActive
            }) {
                scene = activeScene
            } else {
                scene = connectScenes.first(where: { $0.isKind(of: UIWindowScene.self) })
            }
            if let windowScene = scene as? UIWindowScene {
                if let window = windowScene.keyWindow {
                    let rootVC = window.rootViewController
                    UIViewController.docs.topMost(of: rootVC)?.setNeedsUpdateOfSupportedInterfaceOrientations()
                } else if windowScene.windows.count > 0 {
                    let rootVC = windowScene.windows[0].rootViewController
                    UIViewController.docs.topMost(of: rootVC)?.setNeedsUpdateOfSupportedInterfaceOrientations()
                } else {
                    DocsLogger.info("LKDeviceOrientation rootVC is nil")
                }
                
                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS()
                geometryPreferences.interfaceOrientations = LKDeviceOrientation.convertDeviceOrientationToMask(oriation)
                windowScene.requestGeometryUpdate(geometryPreferences, errorHandler: { err in
                    DocsLogger.info("LKDeviceOrientation fail: \(err)")
                })
            } else {
                DocsLogger.info("LKDeviceOrientation fail activeScene is nil")
            }
        } else {
            UIDevice.current.setValue(oriation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
        #else
        UIDevice.current.setValue(oriation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        #endif
    }
    
    public class func convertDeviceOrientationToMask(_ oritation: UIDeviceOrientation) -> UIInterfaceOrientationMask {
        switch oritation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    public class func convertMaskOrientationToDevice(_ orientation: UIInterfaceOrientation) -> UIDeviceOrientation {
        switch orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return.portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return.landscapeLeft
        default:
            return.unknown
        }
    }
    
    public class func forceInterfaceOrientationIfNeed(to orientation: UIInterfaceOrientation?) -> Bool {
        guard !SKDisplay.pad else { return false }
        guard let orientation = orientation, UIApplication.shared.statusBarOrientation != orientation else { return false
        }
        LKDeviceOrientation.setOritation(LKDeviceOrientation.convertMaskOrientationToDevice(orientation))
        return true
    }
    
    public class func forceInterfaceOrientationIfNeed(to orientation: UIInterfaceOrientation?, delay time: Double = 0, completion: (() -> Void)?) {
        guard self.forceInterfaceOrientationIfNeed(to: orientation) else {
            completion?()
            return
        }
        var delayTime: Double = time
        if #available(iOS 16.0, *) {
            delayTime += 0.25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
            completion?()
        }
    }
    
    public class func isLandscape() -> Bool {
        return getInterfaceOrientation().isLandscape
    }
    
    
    public class func getInterfaceOrientation() -> UIInterfaceOrientation {
        guard Thread.isMainThread else {
            return UIApplication.shared.statusBarOrientation
        }
        
        if #available(iOS 13.0, *) {
            var scene: UIScene?
            let connectScenes = UIApplication.shared.windowApplicationScenes
            if let activeScene = connectScenes.first(where: {
                    $0.isKind(of: UIWindowScene.self) && $0.activationState == .foregroundActive
            }) {
                scene = activeScene
            } else {
                scene = connectScenes.first(where: { $0.isKind(of: UIWindowScene.self) })
            }
            if let windowScene = scene as? UIWindowScene {
                return windowScene.interfaceOrientation
            } else {
                return UIApplication.shared.statusBarOrientation
            }
        }
        return UIApplication.shared.statusBarOrientation
    }
}
