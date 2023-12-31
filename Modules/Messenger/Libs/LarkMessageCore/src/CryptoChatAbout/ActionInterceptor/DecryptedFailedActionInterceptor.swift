//
//  DecryptedFailedActionInterceptor.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/4/13.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMenuController
import LarkSDKInterface
import LarkContainer
import LarkSearchCore
import LarkUIKit
import LarkGuide
import LarkSetting
import RustPB
import LKCommonsLogging
import UniverseDesignToast

/// 密聊解密失败消息拦截器, 拦截所有按钮
public final class DecryptedFailedActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .isSecretChatDecryptedFailed }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        if context.message.isSecretChatDecryptedFailed {
            MessageActionType.allCases.forEach { interceptedActions.updateValue(.hidden, forKey: $0) }
        }
        return interceptedActions
    }
}
