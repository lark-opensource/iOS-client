//
//  MessageMenuInterceptor.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/5.
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

public class IMMessageActionInterceptor: MessageActionInterceptor {
    static var logger = Logger.log(IMMessageActionInterceptor.self, category: "Lark.IM.MessageActionInterceptor")
    static var oldSubInterceptors: [MessageActionSubInterceptorType: MessageActionInterceptor] = [:]
    static var subInterceptorTypes: [MessageActionSubInterceptorType: MessageActionInterceptor.Type] = [:]

    var subInterceptors: [MessageActionSubInterceptorType: MessageActionInterceptor] = [:]

    /// 为防止劣化,拦截器暂时不对外开放注册,统一收归在LarkMessageCore中.
    internal func registor(subType: MessageActionSubInterceptorType, interceptor: MessageActioSubnInterceptor) {
        Self.oldSubInterceptors[subType] = interceptor
    }

    internal static func registor(interceptor: MessageActioSubnInterceptor.Type) {
        Self.subInterceptorTypes[interceptor.subType] = interceptor
    }

    required public init() {
        /// 实例化subModules
        Self.subInterceptorTypes.forEach { key, value in
            subInterceptors[key] = value.init()
        }
    }

    public func intercept(context: MessageActionInterceptorContext) -> [MessageActionType: MessageActionInterceptedType] {
        var interceptList: [MessageActionType: MessageActionInterceptedType] = [:]
        MessageActionSubInterceptorType.allCases.map { subInterceptor in
            guard let interceptor = self.subInterceptors[subInterceptor] else { return }
            Self.logger.info("messageMenuTrace" + "Use messageAction subInterceptor, type = \(subInterceptor), messageId = \((context.message.id))")
            // 生成当前子拦截器的拦截配置
            let subInterceptList = interceptor.intercept(context: context)
            /// 合并字典后若对按钮有重复拦截,选择优先级更高的拦截结果
            return interceptList.merge(interceptor.intercept(context: context)) { $1 }
        }
        return interceptList
    }
}
