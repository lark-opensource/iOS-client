//
//  BDPFeatureGatingBridge.swift
//  TTMicroApp
//  LarkFeatureGating 桥接层
//  Created by Nicholas Tau on 2021/2/20.
//

import Foundation
import LarkFeatureGating

@objc
public final class BDPFeatureGatingBridge: NSObject {
    @objc
    class public func forceJSSDKUpdateCheckEnable() -> Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.jssdk.forceupdate.enable")
    }
}
