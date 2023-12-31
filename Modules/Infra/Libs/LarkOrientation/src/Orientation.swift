//
//  Orientation.swift
//  LarkOrientation
//
//  Created by 李晨 on 2020/2/26.
//

import UIKit
import Foundation
import LarkFoundation

public final class Orientation: NSObject {

    /// iPhone 默认是否支持旋转
    public static var defaultAutorotate: Bool = true

    /// iPhone 默认支持的方向, 默认只支持竖屏
    public static var defaultOrientations: UIInterfaceOrientationMask = .portrait

    /// iPhone 默认挂起页面方向, 默认只支持竖屏
    public static var defaultOrientationForPresentation: UIInterfaceOrientation = .portrait

    /// iPad 默认是否支持旋转
    public static var defaultIPadAutorotate: Bool = true

    /// iPad 默认支持的方向, 默认只支持竖屏
    public static var defaultIPadOrientations: UIInterfaceOrientationMask = .all

    /// iPad 默认挂起页面方向, 默认只支持竖屏
    public static var defaultIPadOrientationForPresentation: UIInterfaceOrientation = .portrait

    /// 是否支持 Navigation 自动修复方向，第一版默认关闭
    static var supportNavigaionFix: Bool = false

    static var shared: Orientation = Orientation()

    static var hadSwizzledResponderMethod: Bool = false

    var patchSet: [Patch] = []

    private let lock = DispatchSemaphore(value: 1)

    override init() {
        super.init()
    }

    public static func add(patches: [Patch]) {
        Orientation.shared.add(patches: patches)
    }

    public static func remove(patchIDs: [String]) {
        Orientation.shared.remove(patchIDs: patchIDs)
    }

    func add(patches: [Patch]) {
        lock.wait(); defer { lock.signal() }
        patches.forEach { (patch) in
            if let index = self.patchSet.firstIndex(where: { (item) -> Bool in
                return item.identifier == patch.identifier
            }) {
                self.patchSet[index] = patch
            } else {
                self.patchSet.append(patch)
            }
        }
    }

    func remove(patchIDs: [String]) {
        lock.wait(); defer { lock.signal() }
        self.patchSet = self.patchSet.filter { (patch) -> Bool in
            return !patchIDs.contains(patch.identifier)
        }
    }

    public static func updateOrientationIfNeeded(vc: UIViewController) {
        let c = UIDevice.current.orientation
        let supportedInterfaceOrientations = vc.supportedInterfaceOrientations
        if !supportedInterfaceOrientations.contains(c.toInterfaceOrientation) {
            let orientation = supportedInterfaceOrientations.anyOrientation
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    @objc
    public static func swizzledIfNeeed() {
        if Orientation.hadSwizzledResponderMethod {
            return
        }
        Orientation.hadSwizzledResponderMethod = true
        var swizzingFuncs: [(AnyClass, Selector, Selector)] = []

        let supportDevices: [UIUserInterfaceIdiom] = [.phone, .pad]
        if supportDevices.contains(UIDevice.current.userInterfaceIdiom) {
            swizzingFuncs += UIViewController.orientationSwizzingFunc
            if supportNavigaionFix {
                swizzingFuncs += UINavigationController.orientationNaviSwizzingFunc
            }
        }
        if Utils.isiOSAppOnMacSystem {
            swizzingFuncs += UIDevice.orientationSwizzingFunc
        }
        swizzingFuncs.forEach { (info) in
            lo_swizzling(
                forClass: info.0,
                originalSelector: info.1,
                swizzledSelector: info.2
            )
        }
    }
}
