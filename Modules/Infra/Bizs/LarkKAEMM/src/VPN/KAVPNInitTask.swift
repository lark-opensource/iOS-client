//
//  KAVPNInitTask.swift
//  LarkKAEMM
//
//  Created by guhaowei on 2021/11/22.
//

import Foundation
import BootManager
import SangforSDK

class KAVPNInitTask: FlowBootTask, Identifiable {
    static var identify = "KAVPNInitTask"
    static var initResult: Bool = false

    override func execute(_ context: BootContext) {
        #if !targetEnvironment(simulator)
        KAVPNInitTask.initResult = SFMobileSecuritySDK.sharedInstance().initSDK(
            .supportVpn,
            flags: Int32(SFSDKFlags.hostApplication.rawValue),
            extra: nil)
        #endif
    }
}
