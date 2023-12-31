//
//  LarkInterface+ApplyConfig.swift
//  LarkInterface
//
//  Created by Meng on 2019/8/19.
//

import UIKit
import Foundation

public enum ApplyConfig {

    case on

    case off

    case downgraded

}

public enum DeviceFamilyKey: Int {
    case phone = 1
    case pad = 2
}

extension ApplyConfig {
    private static let deviceFamily = Bundle.main.infoDictionary?["UIDeviceFamily"] as? [Int] ?? []

    public static func apply(phone: ApplyConfig, pad: ApplyConfig, others: ApplyConfig) -> ApplyConfig {
        /// for non universal app runs in iPad devices:
        /// if version < iOS 13, UIDevice.current.userInterfaceIdiom will return .pad
        /// if version >= iOS 13, UIDevice.current.userInterfaceIdiom will return .phone
        /// so we use 'uiDeviceFamily' as an additional check
        if deviceFamily.count == 1 {
            return deviceFamily.first == DeviceFamilyKey.phone.rawValue ? phone : pad
        }
        /// if uiDeviceFamily includes two values: 1 and 2, it means it's a universal app
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return phone
        case .pad:
            return pad
        default:
            return others
        }
    }

    public static func apply(phone: ApplyConfig, others: ApplyConfig) -> ApplyConfig {
        return apply(phone: phone, pad: others, others: others)
    }

    public static func apply(pad: ApplyConfig, others: ApplyConfig) -> ApplyConfig {
        return apply(phone: others, pad: pad, others: others)
    }
}
