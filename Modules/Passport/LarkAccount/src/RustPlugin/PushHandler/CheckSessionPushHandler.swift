//
//  CheckSessionPushHandler.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/7.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsLogging
import LarkContainer

class CheckSessionPushHandler: BaseRustPushHandler<RustPB.Basic_V1_PushSessionValidatingResponse> {
    
    static let logger = Logger.log(DeviceUpdatePushHandler.self, category: "SuiteLogin.CheckSessionPushHandler")
    @Provider private var userSessionService: UserSessionService
    
    override func doProcessing(message: Basic_V1_PushSessionValidatingResponse) {
        CheckSessionPushHandler.logger.info("n_action_session_invalid_invoked", additionalData:["reason": message.serverReason])
        userSessionService.start(reason: .rust)
    }
}
