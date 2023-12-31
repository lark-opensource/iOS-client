//
//  RecallInterceptor.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/7.
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

/// 撤回消息拦截器, 拦截所有按钮
public final class RecallActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .recall }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        if context.message.isRecalled {
            MessageActionType.allCases.forEach { interceptedActions.updateValue(.hidden, forKey: $0) }
        }
        return interceptedActions
    }
}
