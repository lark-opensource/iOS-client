//
//  SwitchUserContext.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LarkContainer
import LarkAccountInterface

final class SwitchUserContext {
    
    //切换目标用户 ID
    let switchUserID: String
    //切换目标用户 model
    var switchUserInfo: V4UserInfo?
    //切换目标用户的 credential id; 优先级比较低.
    //如果有 switchUserInfo, 优先使用.
    //现在用于 applink 在特殊场景下无法通过本地或则 user/list 获取 credential id 时使用
    var credentialId: String?
    //切换上下文的额外自定义信息
    var additionInfo: SwitchUserContextAdditionInfo?
    //需要验证场景的切换. 目前用于退出登录的自动切换逻辑
    var continueSwitchBlock: ((V4EnterAppInfo) -> Void)?
    //切换目标用户deviceInfo
    var deviceInfo: DeviceInfoTuple?
    
    init(userID: String) {
        self.switchUserID = userID
    }
    
    init(userInfo: V4UserInfo) {
        self.switchUserID = userInfo.userID
        self.switchUserInfo = userInfo
    }
}

struct SwitchUserContextAdditionInfo {
    //自定义切换中的 toast
    var toast: String?
}
