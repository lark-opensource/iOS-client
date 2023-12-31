//
//  DevToolPushHandler.swift
//  LarkMicroApp
//
//  Created by tujinqiu on 2020/4/23.
//

import RustPB
import LarkRustClient
import LarkContainer
import ECOInfra

public typealias PushGadgetDevToolType = Openplatform_V1_GadgetDevToolCommonPushRequest.DevToolPushType

/// 开发工具通用push消息
public struct PushDevToolCommon: PushMessage {
    public let type: PushGadgetDevToolType // 类型
    public let content: String // 内容
}

// 开发工具通用push
class DevToolPushHandler: UserPushHandler {
    
    override class var compatibleMode: Bool {
        OPUserScope.compatibleModeEnabled
    }
    
    func process(push message: RustPB.Openplatform_V1_GadgetDevToolCommonPushRequest) throws {
        let pushCenter = try userResolver.userPushCenter
        pushCenter.post(PushDevToolCommon(type: message.pushType,
                                               content: message.content))
    }
}
