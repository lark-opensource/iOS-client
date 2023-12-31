//
//  ScreenUtil.swift
//  DocsCommon
//
//  Created by weidong fu on 3/12/2017.
//

import Foundation
import SKFoundation
import EENavigator

public final class SKDisplay {
    public class var phone: Bool { return UIDevice.current.userInterfaceIdiom == .phone }
    public class var pad: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    ///判断iPad分屏（非台前调度下）
    public class var isInSplitScreen: Bool {
        if #available(iOS 13.0, *) {
            return SKDisplay.pad &&
                   UIApplication.shared.connectedScenes.count > 1 &&
                   SKDisplay.activeWindowBounds.height == SKDisplay.mainScreenBounds.height &&
                   SKDisplay.activeWindowBounds.width < SKDisplay.mainScreenBounds.width
        } else {
            return false
        }
    }
    public static var topBannerHeight: CGFloat = 0.0
    public static let keyboardAssistantBarHeight: CGFloat = 55.0
    // 获取当前屏幕的scale
    public static var scale: CGFloat {
        if #available(iOS 13.0, *) {
            if Thread.isMainThread, let activeScene = UIApplication.shared.windowApplicationScenes.first(where: {
                $0.isKind(of: UIWindowScene.self)
            }), let windowScene = activeScene as? UIWindowScene {
                return windowScene.screen.scale
            } else {
                return UIScreen.main.scale
            }
        } else {
            return UIScreen.main.scale
        }
    }
    // 获取整个屏幕的bounds
    public static var mainScreenBounds: CGRect {
        return UIScreen.main.bounds
    }
    // 获取当前view所在window的bounds
    public static func windowBounds(_ view: UIView) -> CGRect {
        return view.window?.bounds ?? SKDisplay.activeWindowBounds
    }
    
    ///获取当前activeWindow
    public static var activeWindow: UIWindow? {
        guard Thread.isMainThread else { return nil }
        if #available(iOS 13.0, *) {
            var window: UIWindow?
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
                if let delegate = windowScene.delegate as? UIWindowSceneDelegate {
                    window = delegate.window?.map { $0 }
                } else {
                    window = windowScene.windows.first { $0.isKeyWindow }
                }
            }
            return window
        } else {
            let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            return keyWindow
        }
    }
    
    // 获取当前的ActiveWindow的bounds
    public static var activeWindowBounds: CGRect {
        return Self.activeWindow?.bounds ?? UIScreen.main.bounds
    }
}


public extension CGFloat {

    /// Baseline width for scaling. Any width greater than this value will lead to a greater scaled item size.
    static let scaleBaseline: CGFloat = 375.0

    /// Maximum width that applies to scaling mechanism. For example, a width of 768 will not lead to a greater item size.
    static let maximumScalingWidth: CGFloat = 500.0

    /// Used to scale UICollectionViewCell's item size to fit the window width,
    /// so that the collection view shows exactly same amount of cells for every possible size of window.
    ///
    /// To prevent cells from being too large on iPad, the window width passed in will be ignore when it's
    /// greater than 500pt. 500 is a fine-tuned number to distinguish between iPhone and iPad.
    ///
    /// You should only use this method when the cells are not shown in a popover window. Popover windows
    /// prefers a static window width of `scaleBaseline`, thus the item should not be scaled.
    ///
    /// - Parameter width: Current view's window's width
    /// - Returns: Scaled length
    func scaledForWindow(atWidth width: CGFloat?) -> CGFloat {
        guard let width = width else { return self }
        guard width <= Self.maximumScalingWidth else { return self }
        return self * width / Self.scaleBaseline
    }


}

// https://www.theiphonewiki.com/wiki/Models
public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"

            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPhone12,8":                              return "iPhone SE (2nd generation)"

            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad11,6", "iPad11,7":                    return "iPad (8th generation)"

            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,3", "iPad11,4":                    return "iPad Air (3rd generation)"
            case "iPad13,1", "iPad13,2":                    return "iPad Air (4th generation)"

            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"

            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch) (1st generation)"
            case "iPad8,9", "iPad8,10":                     return "iPad Pro (11-inch) (2nd generation)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch) (1st generation)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12":                    return "iPad Pro (12.9-inch) (4th generation)"

            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"

            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()

}
