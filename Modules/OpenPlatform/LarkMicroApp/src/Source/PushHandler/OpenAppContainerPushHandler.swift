//
//  OpenAppContainerPushHandler.swift
//  LarkMicroApp
//
//  Created by laisanpin on 2022/7/20.
//  产品化止血推送

import RustPB
import LarkRustClient
import LarkContainer
import ECOInfra

public typealias PushOpenAppContainerCommand = Openplatform_V1_PushOpenAppContainerCommand.Command

public struct PushOpenAppContainerCommon: PushMessage {
    public let command: PushOpenAppContainerCommand // 类型 unknown, leastVersionUpdate 止血有更新
    public let cliID: String // 止血小程序appId
    public let extra: String // 预留信息
}

class OpenAppContainerPushHandler: UserPushHandler {
    
    override class var compatibleMode: Bool {
        OPUserScope.compatibleModeEnabled
    }
    
    func process(push message: RustPB.Openplatform_V1_PushOpenAppContainerCommand) throws {
        let pushCenter = try userResolver.userPushCenter
        pushCenter.post(PushOpenAppContainerCommon(command: message.command,
                                                        cliID: message.cliID,
                                                        extra: message.extra))
    }
}
