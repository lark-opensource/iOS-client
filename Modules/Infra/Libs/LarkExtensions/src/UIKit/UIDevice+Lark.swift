//
//  UIDevice+Lark.swift
//  Lark
//
//  Created by Sylar on 2017/11/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import UIKit

extension UIDevice: LarkUIKitExtensionCompatible {}

private var _modelName: String?
extension LarkUIKitExtension where BaseType == UIDevice {
    public func modelName() -> String {
        if let name = _modelName { return name } // check cache

        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        let name = extraModel(identifier: identifier)
        _modelName = name

        return name
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func extraModel(identifier: String) -> String {
        if #available(iOS 13.0, *), ProcessInfo.processInfo.isMacCatalystApp {
            return "MacCatalystApp"
        }

        if #available(iOS 14.0.1, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return "iOSAppOnMac"
        }

        switch identifier {
        // iPod
        case "iPod5,1": return "iPod Touch 5"
        case "iPod7,1": return "iPod Touch 6"
        case "iPod9,1": return "iPod Touch 7"

        // iPhone
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
        case "iPhone4,1": return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2": return "iPhone 5"
        case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3": return "iPhone 7"
        case "iPhone9,2", "iPhone9,4": return "iPhone 7 Plus"
        case "iPhone8,4": return "iPhone SE"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,6", "iPhone11,4": return "iPhone XS Max"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone13,1": return "iPhone 12 Mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 Mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"

        // iPad
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
        case "iPad5,3", "iPad5,4": return "iPad Air 2"
        case "iPad6,11", "iPad6,12": return "iPad 5"
        case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad Mini 3"
        case "iPad5,1", "iPad5,2": return "iPad Mini 4"
        case "iPad6,3", "iPad6,4": return "iPad Pro 9.7-in."
        case "iPad6,7", "iPad6,8": return "iPad Pro 12.9-in. (1st generation)"
        case "iPad7,1", "iPad7,2": return "iPad Pro 12.9-in. (2nd generation)"
        case "iPad7,3", "iPad7,4": return "iPad Pro (10.5-inch)"
        case "iPad7,5", "iPad7,6": return "iPad (6th generation)"
        case "iPad7,11", "iPad7,12": return "iPad (7th generation)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":
            return "iPad Pro 11-in. (1st generation)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":
            return "iPad Pro 12.9-in. (3rd generation)"
        case "iPad8,9", "iPad8,10": return "iPad Pro 11-in. (2nd generation)"
        case "iPad8,11", "iPad8,12": return "iPad Pro 12.9-in. (4th generation)"
        case "iPad11,1", "iPad11,2": return "iPad Mini (5th generation)"
        case "iPad11,3", "iPad11,4": return "iPad Air (3rd generation)"
        case "iPad11,6", "iPad11,7": return "iPad (8th generation)"
        case "iPad12,1", "iPad12,2": return "iPad (9th generation)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4rd generation)"
        case "iPad13,4", "iPad13,5", "iPad 13,6", "iPad 13,7":
            return "iPad Pro 11-in. (3rd generation)"
        case "iPad13,8", "iPad 13,9", "iPad 13,10", "iPad 13,11":
            return "iPad Pro 12.9-in. (5th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad13,18", "iPad13,19": return "iPad (10th generation)"
        case "iPad14,1", "iPad14,2": return "iPad Mini (6th generation)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-in. (4th generation)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-in. (6th generation)"

        // HomePod
        case "AudioAccessory1,1": return "HomePod"
        case "AudioAccessory5,1": return "HomePod Mini"
        case "AudioAccessory6,1": return "HomePod (2nd generation)"

        // Simulator
        case "i386", "x86_64", "arm64":
            if let ident = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                return "\(self.extraModel(identifier: ident)) (Simulator)"
            } else {
                return "iOS"
            }
        default: return identifier
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}
