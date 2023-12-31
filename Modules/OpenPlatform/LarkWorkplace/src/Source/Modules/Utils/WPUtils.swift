//
//  WPUtils.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/5/4.
//

import Foundation
import Heimdallr
import LarkFoundation

struct WPUtils {
    static var appMemory: UInt64? {
        return hmd_getAppMemoryBytes()
    }

    static var appVersion: String {
        LarkFoundation.Utils.appVersion
    }

    static func getBlockHeight(size: FavoriteAppDisplaySize) -> Int {
        switch size {
        case .small:
            return 150
        case .medium, .large:
            return 324
        }
    }
}
