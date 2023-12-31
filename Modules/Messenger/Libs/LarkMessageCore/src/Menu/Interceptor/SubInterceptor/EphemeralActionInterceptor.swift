//
//  File.swift
//  Ephemeral
//
//  Created by Zigeng on 2023/2/2.
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

/// 临时消息拦截器
public final class EphemeralActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .ephemeral }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        if context.message.isEphemeral {
            let whiteList: [MessageActionType] = [.delete]
            MessageActionType.allCases.forEach {
                if !whiteList.contains($0) {
                    interceptedActions.updateValue(.hidden, forKey: $0)
                }
            }
        }
        return interceptedActions
    }
}
