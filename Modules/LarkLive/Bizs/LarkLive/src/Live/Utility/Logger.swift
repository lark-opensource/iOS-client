//
//  Logger.swift
//  ByteView
//
//  Created by kiri on 2020/8/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging

public enum Logger {
    static func getLogger(_ category: String) -> LKCommonsLogging.Log {
        return LKCommonsLogging.Logger.log("LarkLive", category: "LarkLive.\(category)")
    }

    public static let network = getLogger("Network")
    public static let live = getLogger("larkLive")
    public static let urlTracker = getLogger("urlTracker")
}
