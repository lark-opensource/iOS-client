//
//  Tracker.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/5/12.
//

import Foundation
import LKCommonsTracker

public struct Events {

    private static let prefixEvent = "scs_"

    public static func track(_ name: String, params: [AnyHashable: Any] = [:]) {
#if DEBUG
        Logger.debug("track info event = \(name) params = \(params)")
#endif
        let realName = name.hasPrefix(prefixEvent) ? name : prefixEvent + name
        LKCommonsTracker.Tracker.post(TeaEvent(realName, params: params))
    }
}
