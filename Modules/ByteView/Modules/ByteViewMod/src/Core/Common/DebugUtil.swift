//
//  DebugUtil.swift
//  ByteViewMod
//
//  Created by kiri on 2022/2/10.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
#if canImport(LarkDebug)
import LarkDebug
#endif

struct DebugUtil {
    static var isDebug: Bool {
        #if canImport(LarkDebug)
        return appCanDebug()
        #else
        return false
        #endif
    }
}
