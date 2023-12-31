//
//  ScreenUtil.swift
//  DocsCommon
//
//  Created by weidong fu on 3/12/2017.
//

import Foundation
import EENavigator
import LarkContainer

enum DisplayType {
    case unknown
    case iPhone4
    case iPhone5
    case iPhone6
    case iPhone6plus
    static let iPhone7 = iPhone6
    static let iPhone7plus = iPhone6plus
    static let iPhone8 = iPhone6
    static let iPhone8plus = iPhone6plus
    case iPhoneX
    static let iPhoneXS = iPhoneX
    case iPhoneXR
    static let iPhoneXSMax = iPhoneXR
    case iPhone12mini
    case iPhone12
    static let iPhone12Pro = iPhone12
    case iPhone12ProMax
    case ipadWithSafeArea
    case ipadWithoutSafeArea
    case iPhone14Pro
    case iPhone14ProMax
}

public enum heightConstants {
    static let iPhone5: CGFloat = 568
    static let iPhone6: CGFloat = 667
    static let iPhone6plus: CGFloat = 736
    static let iPhoneX: CGFloat = 812
    static let iPhoneXR: CGFloat = 896
    static let iPhone12mini: CGFloat = 780
    static let iPhone12: CGFloat = 844
    static let iPhone12ProMax: CGFloat = 926
    static let iPhone14Pro: CGFloat = 852
    static let iPhone14ProMax: CGFloat = 932
}

final class Display {
    class var width: CGFloat { return UIScreen.main.bounds.size.width }
    class var height: CGFloat { return UIScreen.main.bounds.size.height }
    class var maxLength: CGFloat { return max(width, height) }
    class var minLength: CGFloat { return min(width, height) }
    class var zoomed: Bool { return UIScreen.main.nativeScale >= UIScreen.main.scale }
    class var retina: Bool { return UIScreen.main.scale >= 2.0 }
    class var phone: Bool { return UIDevice.current.userInterfaceIdiom == .phone }
    class var pad: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    class var carplay: Bool { return UIDevice.current.userInterfaceIdiom == .carPlay }
    class var tv: Bool { return UIDevice.current.userInterfaceIdiom == .tv }
    class var typeIsLike: DisplayType {
        if phone == false && pad == true {
            if let bottom = Container.shared.getCurrentUserResolver().navigator.mainSceneWindow?.safeAreaInsets.bottom,
               bottom > 0 {
                return .ipadWithSafeArea
            } else {
                return .ipadWithoutSafeArea
            }
        } else if phone == false {
            return .unknown
        }

        let screenHeight = maxLength
        if screenHeight < heightConstants.iPhone5 {
            return .iPhone4
        } else if screenHeight == heightConstants.iPhone5 {
            return .iPhone5
        } else if screenHeight == heightConstants.iPhone6 {
            return .iPhone6
        } else if screenHeight == heightConstants.iPhone6plus {
            return .iPhone6plus
        } else if screenHeight == heightConstants.iPhoneX {
            return .iPhoneX
        } else if screenHeight == heightConstants.iPhoneXR {
            return .iPhoneXR
        } else if screenHeight == heightConstants.iPhone12mini {
            return .iPhone12mini
        } else if screenHeight == heightConstants.iPhone12 {
            return .iPhone12
        } else if screenHeight == heightConstants.iPhone12ProMax {
            return .iPhone12ProMax
        } else if screenHeight == heightConstants.iPhone14Pro {
            return .iPhone14Pro
        } else if screenHeight == heightConstants.iPhone14ProMax {
            return .iPhone14ProMax
        }
        return .unknown
    }

    class func realTabbarHeight() -> CGFloat {
        // bar的高度
        let barHeight: CGFloat = 44
        if isXSeries() {
            let instrinsicHeight: CGFloat = 83
            let homeBarHeight: CGFloat = 5
            return instrinsicHeight - homeBarHeight
        }
        return barHeight
    }

    class func realTopBarHeight() -> CGFloat {
        return realNavBarHeight() + realStatusBarHeight()
    }

    class func realNavBarHeight() -> CGFloat {
        let navBarHeight: CGFloat = 44.0
        return navBarHeight
    }

    class func realStatusBarHeight() -> CGFloat {
        return topSafeAreaHeight
    }

    static let topSafeAreaHeight: CGFloat = {
        var height: CGFloat = 20.0
        if isDynamicIsland() {
            height = 54.0
        } else if isXSeries() && !Display.pad {
            height = 44.0
        }
        return height
    }()

    static let bottomSafeAreaHeight: CGFloat = {
        var height: CGFloat = 0.0
        if isXSeries() {
            height = 34.0
        }
        return height
    }()

    class func isDynamicIsland() -> Bool {
        return (
                Display.typeIsLike == .iPhone14Pro ||
                Display.typeIsLike == .iPhone14ProMax
        )
    }

    class func isXSeries() -> Bool { // 是否是 X 系列
        return (
                Display.typeIsLike == .iPhoneX ||
                Display.typeIsLike == .iPhoneXR ||
                Display.typeIsLike == .iPhoneXS ||
                Display.typeIsLike == .iPhoneXSMax ||
                Display.typeIsLike == .iPhone12mini ||
                Display.typeIsLike == .iPhone12 ||
                Display.typeIsLike == .iPhone12Pro ||
                Display.typeIsLike == .iPhone12ProMax ||
                Display.typeIsLike == .ipadWithSafeArea ||
                Display.typeIsLike == .iPhone14Pro ||
                Display.typeIsLike == .iPhone14ProMax 
        )
    }
    
    class func oldSeries() -> Bool {
        return (
            Display.typeIsLike == .iPhone4 ||
            Display.typeIsLike == .iPhone5 ||
            Display.typeIsLike == .iPhone6 ||
            Display.typeIsLike == .iPhone6plus ||
            Display.typeIsLike == .iPhone7 ||
            Display.typeIsLike == .iPhone7plus ||
            Display.typeIsLike == .iPhone8 ||
            Display.typeIsLike == .iPhone8plus
        )
    }
}

extension Double {
    var fitScreen: Double {
        let originWidth: CGFloat = 375.0
        return self / originWidth * Double(UIScreen.main.bounds.size.width)
    }
}
