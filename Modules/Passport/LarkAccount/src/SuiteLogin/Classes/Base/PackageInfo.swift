//
//  PackageInfo.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/15.
//

import Foundation
import LarkReleaseConfig

class PackageInfo {
    static func isChannelR() -> Bool {
        /*
         KA-R专有部署channel: crc
         KA-R私有部署channel: kacrc
         */
        return ReleaseConfig.releaseChannel == "crc"
            || ReleaseConfig.releaseChannel == "kacrc"
    }

    /// KA 华住海外
    static func isChannelHZOversea() -> Bool {
        return ReleaseConfig.releaseChannel == "saib6and"
    }

    static func isChannelCMBC() -> Bool {
        return  ReleaseConfig.releaseChannel == "ka522s2"
            ||  ReleaseConfig.releaseChannel == "cmbc"
            ||  ReleaseConfig.releaseChannel == "kacmbc"
    }

}
