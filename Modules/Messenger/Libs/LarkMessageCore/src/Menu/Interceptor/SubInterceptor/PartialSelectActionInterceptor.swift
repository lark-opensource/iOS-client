//
//  PartialSelectActionInterceptor.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/7.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkMenuController
import LarkSearchCore

/// 局部选择菜单拦截器
public final class PartialSelectActionInterceptor: MessageActioSubnInterceptor {

    public required init() { }
    public static var subType: MessageActionSubInterceptorType { .partialSelect }
    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        let fg = context.userResolver.fg.dynamicFeatureGatingValue(with: "im.messenger.part_reply")
        var interceptedActions: [MessageActionType: MessageActionInterceptedType] = [:]
        if context.isInPartialSelect {
            MessageActionType.allCases.forEach { type in
                switch type {
                case .search, .copy, .cardCopy:
                    break
                case .reply:
                    if fg {
                        break
                    } else {
                        interceptedActions.updateValue(.hidden, forKey: type)
                    }
                case .selectTranslate:
                    if !AIFeatureGating.selectTranslate.isEnabled {
                        interceptedActions.updateValue(.hidden, forKey: type)
                    }
                default:
                    interceptedActions.updateValue(.hidden, forKey: type)
                }
            }
        }
        return interceptedActions
    }
}
