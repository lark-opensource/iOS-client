//
//  Display.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/14.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import GameController

public enum DisplayType {
    case unknown
    case iPhone4
    case iPhone5
    case iPhone6
    case iPhone6plus
    static let iPhone7 = iPhone6
    static let iPhone7plus = iPhone6plus
    case iPhoneX
    static let iPhoneXS = iPhoneX
    case iPhoneXSmax
    static let iPhoneXR = iPhoneXSmax
    static let iPhone12mini = iPhoneX
    case iPhone12
    static let iPhone12Pro = iPhone12
    case iPhone12ProMax
    case iPhone14Pro
    case iPhone14ProMax
}

private enum DeviceFamilyKey: Int {
    case phone = 1 /// iPhone and iPod touch devices
    case pad = 2 /// iPad devices
}

public final class Display {
    public class var width: CGFloat { return UIScreen.main.bounds.size.width }
    public class var height: CGFloat { return UIScreen.main.bounds.size.height }
    public class var maxLength: CGFloat { return max(width, height) }
    public class var minLength: CGFloat { return min(width, height) }
    public class var zoomed: Bool { return UIScreen.main.nativeScale >= UIScreen.main.scale }
    public class var retina: Bool { return UIScreen.main.scale >= 2.0 }
    public class var externalKeyboard: Bool {
        guard Display.pad else { return false }
        if #available(iOS 14, *) {
            return GCKeyboard.coalesced != nil
        }
        return false
    }

    private static let uiDeviceFamily = Bundle.main.infoDictionary?["UIDeviceFamily"] as? [Int]

    /// for non universal app runs in iPad devices:
    /// if version < iOS 13, UIDevice.current.userInterfaceIdiom will return .pad
    /// if version >= iOS 13, UIDevice.current.userInterfaceIdiom will return .phone
    /// so we use 'uiDeviceFamily' as an additional check
    public class var phone: Bool {
        if needAdditionalCheck() {
            /// in this case, it means it's a non universal app, and not iPad only
            /// so even if it runs on iPad devices, still returns iPhone
            return uiDeviceFamily!.first == DeviceFamilyKey.phone.rawValue
        }
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    public class var pad: Bool {
        if needAdditionalCheck() {
            /// if uiDeviceFamily only has value 2, it means it is an iPad only app
            /// we assume it is as an iPad
            return uiDeviceFamily!.first == DeviceFamilyKey.pad.rawValue
        }
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    public class var carplay: Bool { return UIDevice.current.userInterfaceIdiom == .carPlay }
    public class var tv: Bool { return UIDevice.current.userInterfaceIdiom == .tv }

    /// 【已废弃】是否是全面屏手机
    @available(*, deprecated, message: "It is unreliable, do not decide device type depending on this API.")
    public class var iPhoneXSeries: Bool {
        guard phone else { return false }
        return height / width > 2.0
    }

    /// 【已废弃】判断设备类型（不一定是真正型号）
    /// All iPhone resolution: https://www.ios-resolution.com/
    @available(*, deprecated, message: "It is unreliable, do not decide device type depending on this API.")
    public class var typeIsLike: DisplayType {
        if phone == false { return .unknown }

        // disable-lint: magic number
        let screenHeight = maxLength
        if screenHeight < 568 {
            return .iPhone4
        } else if screenHeight == 568 {
            return .iPhone5
        } else if screenHeight == 667 {
            return .iPhone6
        } else if screenHeight == 736 {
            return .iPhone6plus
        } else if screenHeight == 812 {
            return .iPhoneX
        } else if screenHeight == 844 {
            return .iPhone12
        } else if screenHeight == 896 {
            return .iPhoneXR
        } else if screenHeight == 926 {
            return .iPhone12ProMax
        } else if screenHeight == 852 {
            return .iPhone14Pro
        } else if screenHeight == 932 {
            return .iPhone14ProMax
        }
        // enable-lint: magic number
        return .unknown
    }

    /// 根据 view 所在 scene 的 size
    /// 在 iOS 13 之前等同于当前 application window 的 size
    /// 在 iOS 13 之后会根据 view 获取对应 scene
    public class func sceneSize(for view: UIView) -> CGSize {
        return Display.sceneWindow(for: view)?.bounds.size ?? .zero
    }

    /// 根据 view 所在 scene 的主 window
    public class func sceneWindow(for view: UIView) -> UIWindow? {
        let window: UIWindow? = view as? UIWindow ?? view.window
         // 适配 iOS 13 UIWidnowScene
         if #available(iOS 13.0, *) {
             if let scene = window?.windowScene,
                let sceneDelegate = scene.delegate as? UIWindowSceneDelegate,
                let window = sceneDelegate.window?.map({ $0 }) {
                return window
             }
         }
        return UIApplication.shared.delegate?.window ?? nil
    }

    private class func needAdditionalCheck() -> Bool {
        if let uiDeviceFamily = uiDeviceFamily {
            /// if uiDeviceFamily includes two values: 1 and 2, it means it's a universal app
            return uiDeviceFamily.count == 1
        }
        return false
    }
}
