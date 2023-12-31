//
//  LKPushService.swift
//
//  Created by mochangxing on 2019/11/4.
//

import Foundation

public class LKPushService {
    let pushKitWithCallKitEnable: Bool

    let pushKitWithoutCallKitEnable: Bool

    let callKitEnable: Bool

    /// - Parameter pushKitWithCallKitEnable: featureGating that pushKit is enable when link callKit
    /// - Parameter pushKitWithoutCallKitEnable: featureGating that pushKit is enable when not link callKit
    /// - Parameter callKitEnable: featureGating that callKit is enable
    public init(pushKitWithCallKitEnable: Bool, pushKitWithoutCallKitEnable: Bool, callKitEnable: Bool) {
        self.pushKitWithCallKitEnable = pushKitWithCallKitEnable
        self.pushKitWithoutCallKitEnable = pushKitWithoutCallKitEnable
        self.callKitEnable = callKitEnable
    }

    public func shouldRegisterPushKit() -> Bool {
        #if LKPUSH_CALLKIT
        return pushKitWithCallKitEnable && callKitEnable
        #else
        return pushKitWithoutCallKitEnable
        #endif
    }
}
