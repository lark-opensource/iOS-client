//
//  Orientation+UIViewController.swift
//  LarkOrientation
//
//  Created by 李晨 on 2020/2/27.
//

import UIKit
import Foundation

extension UIViewController {
    private struct AssociatedKeys {
        static var shouldAutorotate = "viewController_shouldAutorotate"
        static var supportedOrientations = "viewController_supportedOrientations"
        static var preferredOrientationForPresentation = "viewController_preferredInterfaceOrientationForPresentation"
    }

    static var orientationSwizzingFunc: [(AnyClass, Selector, Selector)] {
        return [
            (UIViewController.self, #selector(getter: UIViewController.shouldAutorotate), #selector(UIViewController.lo_shouldAutorotate)),
            (UIViewController.self, #selector(getter: UIViewController.supportedInterfaceOrientations), #selector(UIViewController.lo_supportedInterfaceOrientations)),
            (UIViewController.self, #selector(getter: UIViewController.preferredInterfaceOrientationForPresentation), #selector(UIViewController.lo_preferredInterfaceOrientationForPresentation))
        ]
    }

    /// ViewController 是否支持转屏
    /// 优先级高于 matcher
    public var orientationAutorotate: Bool? {
        get {
            if let autorotate = objc_getAssociatedObject(self, &AssociatedKeys.shouldAutorotate) as? Bool {
                return autorotate
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.shouldAutorotate, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var supportOrientations: UIInterfaceOrientationMask? {
        get {
            if let orientations = objc_getAssociatedObject(self, &AssociatedKeys.supportedOrientations) as? UIInterfaceOrientationMask {
                return orientations
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.supportedOrientations, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var preferredOrientationForPresentation: UIInterfaceOrientation? {
        get {
            if let orientation = objc_getAssociatedObject(self, &AssociatedKeys.preferredOrientationForPresentation) as? UIInterfaceOrientation {
                return orientation
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.preferredOrientationForPresentation, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}

extension UIViewController {
    @objc
    func lo_shouldAutorotate() -> Bool {
        if let autorotate = self.orientationAutorotate {
            return autorotate
        }
        let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        for patch in Orientation.shared.patchSet where patch.supportDevices.contains(userInterfaceIdiom) {
            if let shouldAutorotate = patch.optionInfo.shouldAutorotate,
                patch.matcher(self) {
                return shouldAutorotate
            }
        }
        if userInterfaceIdiom == .pad {
            return Orientation.defaultIPadAutorotate
        } else {
            return Orientation.defaultAutorotate
        }
    }

    @objc
    func lo_supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let supportOrientations = self.supportOrientations {
            return supportOrientations
        }
        let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        for patch in Orientation.shared.patchSet where patch.supportDevices.contains(userInterfaceIdiom) {
            if let supportedInterfaceOrientations = patch.optionInfo.supportedInterfaceOrientations,
                patch.matcher(self) {
                return supportedInterfaceOrientations
            }
        }
        if userInterfaceIdiom == .pad {
            return Orientation.defaultIPadOrientations
        } else {
            return Orientation.defaultOrientations
        }
    }

    @objc
    func lo_preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        if let preferredOrientationForPresentation = self.preferredOrientationForPresentation {
            return preferredOrientationForPresentation
        }
        let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        for patch in Orientation.shared.patchSet where patch.supportDevices.contains(userInterfaceIdiom) {
            if let preferredInterfaceOrientationForPresentation = patch.optionInfo.preferredInterfaceOrientationForPresentation,
                patch.matcher(self) {
                return preferredInterfaceOrientationForPresentation
            }
        }
        if userInterfaceIdiom == .pad {
            return Orientation.defaultIPadOrientationForPresentation
        } else {
            return Orientation.defaultOrientationForPresentation
        }
    }
}
