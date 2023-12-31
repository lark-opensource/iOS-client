//
//  DLPInterceptor.swift
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
import LarkAccountInterface

/// DLP拦截器
public final class DLPActionInterceptor: MessageActioSubnInterceptor {
    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .dlp }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        if context.message.dlpState == .dlpBlock {
            MessageActionType.allCases.forEach { type in
                switch type {
                case .delete:
                    break
                default:
                    interceptedActions.updateValue(.hidden, forKey: type)
                }
            }
        }
        return interceptedActions
    }
}
