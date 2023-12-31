//
//  PreloadContinueLocation.swift
//  OPFoundation
//
//  Created by baojianjun on 2023/5/17.
//

import Foundation
import LarkCoreLocation

/// 持续定位的预定位
public protocol PreloadContinueLocation {
    func fetchAndCleanCache(uniqueID: OPAppUniqueID) -> LarkLocation?
}
