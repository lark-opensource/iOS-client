//
//  LeanModeSwitchFailedPushHandler.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/13.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer

/// 离线开启精简模式，联网之后失去使用权限，会收到此push
final class LeanModeSwitchFailedPushHandler: UserPushHandler {

    private var leanModeAPI: LeanModeAPI? { try? userResolver.resolve(assert: LeanModeAPI.self) }

    func process(push message: PushLeanModeSwitchFailedByAuthorityChangeResponse) throws {
        leanModeAPI?.updateOfflineSwitchFailedStatus()
    }
}
