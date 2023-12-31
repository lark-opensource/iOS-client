//
//  Display.swift
//  ByteView
//
//  Created by kiri on 2021/3/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

struct Display {
    @inline(__always)
    static var pad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    @inline(__always)
    static var phone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    @inline(__always)
    static var isLandscape: Bool {
        UIApplication.shared.statusBarOrientation.isLandscape
    }

    static var iPhoneXSeries: Bool {
        return phone && typeIsLike.isIPhoneXSeries
    }

    static var typeIsLike: DisplayType {
        if !phone { return .unknown }
        let screenSize = UIScreen.main.bounds.size
        let screenHeight = Int(max(screenSize.width, screenSize.height))
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
        }
        return .unknown
    }

    enum DisplayType {
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

        var isIPhoneXSeries: Bool {
            DisplayType.iPhoneXTypes.contains(self)
        }
        private static let iPhoneXTypes: Set<DisplayType> = [.iPhoneX, .iPhoneXS, .iPhoneXSmax, .iPhoneXR,
                                                             .iPhone12, .iPhone12mini, .iPhone12Pro, .iPhone12ProMax]
    }
}
