//
//  Display.swift
//  ByteView
//
//  Created by kiri on 2021/3/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

// disable-lint: magic number 
import UIKit

public final class Display {
    public static let pad: Bool = UIDevice.current.userInterfaceIdiom != .phone

    public static let phone: Bool = UIDevice.current.userInterfaceIdiom == .phone

    @inline(__always)
    public static var iPhoneXSeries: Bool {
        return phone && typeIsLike.isIPhoneXSeries
    }

    @inline(__always)
    public static var iPhoneMaxSeries: Bool {
        return phone && (typeIsLike == .iPhoneXR || typeIsLike == .iPhone12ProMax || typeIsLike == .iPhone14ProMax)
    }

    // Device screen sizes:
    // - https://developer.apple.com/design/human-interface-guidelines/foundations/layout/
    @inline(__always)
    public static var typeIsLike: DisplayType {
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
        } else if screenHeight == 852 {
            return .iPhone14Pro
        } else if screenHeight == 932 {
            return .iPhone14ProMax
        }
        return .unknown
    }

    public enum DisplayType: UInt, Comparable {
        case unknown
        case iPhone4
        case iPhone5
        public static let iPhoneSE = iPhone5
        case iPhone6
        public static let iPhone7 = iPhone6
        public static let iPhone8 = iPhone6
        public static let iPhoneSE2 = iPhone6
        case iPhone6plus
        public static let iPhone7plus = iPhone6plus
        public static let iPhone8plus = iPhone6plus
        case iPhoneX
        public static let iPhoneXS = iPhoneX
        public static let iPhone12mini = iPhoneX
        public static let iPhone13mini = iPhoneX
        case iPhoneXSmax
        public static let iPhoneXR = iPhoneXSmax
        case iPhone12
        public static let iPhone12Pro = iPhone12
        public static let iPhone13 = iPhone12
        public static let iPhone13Pro = iPhone12
        case iPhone12ProMax
        public static let iPhone13ProMax = iPhone12ProMax
        case iPhone14Pro
        case iPhone14ProMax

        public var isIPhoneXSeries: Bool {
            DisplayType.iPhoneXTypes.contains(self)
        }
        private static let iPhoneXTypes: Set<DisplayType> = [.iPhoneX, .iPhoneXS, .iPhoneXSmax, .iPhoneXR,
                                                             .iPhone12, .iPhone12mini, .iPhone12Pro, .iPhone12ProMax,
                                                             .iPhone13, .iPhone13mini, .iPhone13Pro, .iPhone13ProMax,
                                                             .iPhone14Pro, .iPhone14ProMax]

        public static func < (lhs: Display.DisplayType, rhs: Display.DisplayType) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}
