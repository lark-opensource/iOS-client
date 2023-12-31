//
//  PrivateModeInterceptor.swift
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

/// 密盾聊菜单拦截器
public final class PrivateModeActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .privateMode }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        if context.chat.isPrivateMode {
            let interceptList: [MessageActionType] = [.takeActionV2, .search, .translate, .favorite, .flag, .addToSticker]
            interceptList.forEach {
                interceptedActions.updateValue(.hidden, forKey: $0)
            }
        }
        return interceptedActions
    }
}
