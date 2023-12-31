//
//  DeviceNotifySettingPushHandler.swift
//  Lark-Rust
//
//  Created by zc09v on 2017/12/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface

import LarkContainer

final class DeviceNotifySettingPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    func process(push message: RustPB.Device_V1_PushDeviceNotifySettingResponse) {
        var authAPI = try? userResolver.resolve(assert: AuthAPI.self)
        authAPI?.isNotify = message.isNotify
    }
}
