//
//  MinutesDeviceHelper.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2021/8/2.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import LarkStorage

public struct MinutesDeviceHelper {
    public static func deviceRemainingFreeSpaceInBytes() -> Int64? {
        guard
            let attrs = try? AbsPath.document.attributesOfFileSystem(),
            let freeSize = attrs[.systemFreeSize] as? NSNumber
        else {
            // something failed
            return nil
        }
        return freeSize.int64Value
    }

    public static func deviceTotalSpaceInBytes() -> Int64? {
        guard
            let attrs = try? AbsPath.document.attributesOfFileSystem(),
            let totoalSize = attrs[.systemSize] as? NSNumber
        else {
            // something failed
            return nil
        }
        return totoalSize.int64Value
    }
}
