//
//  CTTelephonyNetworkInfo+Lark.swift
//  Lark
//
//  Created by qihongye on 2018/1/3.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import CoreTelephony
import Foundation
import LarkCompatible

extension CTTelephonyNetworkInfo: LarkUIKitExtensionCompatible {}

public extension LarkUIKitExtension where BaseType == CTTelephonyNetworkInfo {
    // swiftlint:disable identifier_name
    enum SpecificStatus {
        case 📶2G
        case 📶3G
        case 📶4G
        case 📶5G
        case 📶unknown
    }

    // swiftlint:enable identifier_name

    static let shared = BaseType()

    var currentSpecificStatus: SpecificStatus {
        guard let radioAccessTechnology = self.base.currentRadioAccessTechnology else {
            return .📶unknown
        }

        switch radioAccessTechnology {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge:
            return .📶2G
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMA1x,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .📶3G
        case CTRadioAccessTechnologyLTE:
            return .📶4G
        default:
            if #available(iOS 14.1, *) {
                if [
                    CTRadioAccessTechnologyNR,
                    CTRadioAccessTechnologyNRNSA
                ].contains(radioAccessTechnology) {
                    return .📶5G
                }
            }
            return .📶unknown
        }
    }
}
