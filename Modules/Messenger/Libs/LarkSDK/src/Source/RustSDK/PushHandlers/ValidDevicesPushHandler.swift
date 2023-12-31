//
//  ValidDevicesPushHandler.swift
//  LarkSDK
//
//  Created by KT on 2020/5/12.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer

final class ValidDevicesPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var authAPI: AuthAPI? { try? userResolver.resolve(assert: AuthAPI.self) }

    func process(push message: RustPB.Device_V1_PushValidDevicesResponse) {
        self.authAPI?.updateValidSessions(with: message.devices)
    }
}
