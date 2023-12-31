//
//  AppStateDefines.swift
//  LarkAppStateSDK-LarkAppStateSDKAuto
//
//  Created by bytedance on 2022/7/28.
//

import Foundation
import RustPB

typealias UpdateOpenAppLastHappenTimeRequest = RustPB.Openplatform_V1_UpdateOpenAppLastHappenTimeRequest
typealias OpenApp = RustPB.Basic_V1_OpenApp
public class AppStateDefines {
    static public let monitorName = "op_app_strategy_info_check"
}

