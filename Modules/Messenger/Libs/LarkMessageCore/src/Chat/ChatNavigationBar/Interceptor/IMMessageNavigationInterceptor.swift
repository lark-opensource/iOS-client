//
//  IMMessageNavigationInterceptor.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/10/27.
//

import Foundation
import LarkModel
import LarkOpenChat
import LarkMenuController
import LarkSDKInterface
import LarkContainer
import LarkSearchCore
import LarkUIKit
import LarkGuide
import LarkSetting
import RustPB
import LKCommonsLogging

public class IMMessageNavigationInterceptor: ChatNavigationInterceptor {
    static var logger = Logger.log(IMMessageNavigationInterceptor.self, category: "Lark.IM.IMMessageNavigationInterceptor")

    static var subInterceptorTypes: [ChatNavigationSubInterceptorType: ChatNavigationInterceptor.Type] = [:]
    var subInterceptors: [ChatNavigationSubInterceptorType: ChatNavigationInterceptor] = [:]

    internal static func registor(interceptor: ChatNavigationSubInterceptor.Type) {
        Self.subInterceptorTypes[interceptor.subType] = interceptor
    }

    required public init() {
        /// 实例化subModules
        Self.subInterceptorTypes.forEach { key, value in
            subInterceptors[key] = value.init()
        }
    }

    public func intercept(context: ChatNavigationInterceptorContext) -> [ChatNavigationExtendItemType: Bool] {
        var interceptList: [ChatNavigationExtendItemType: Bool] = [:]
        ChatNavigationSubInterceptorType.allCases.map { subInterceptor in
            guard let interceptor = self.subInterceptors[subInterceptor] else { return }
            Self.logger.info("chatNavigationTrace" + "Use subInterceptor, type = \(subInterceptor)")
            // 生成当前子拦截器的拦截配置
            let subInterceptList = interceptor.intercept(context: context)
            /// 合并字典后若对按钮有重复拦截,选择优先级更高的拦截结果
            return interceptList.merge(interceptor.intercept(context: context)) { $1 }
        }
        return interceptList
    }
}
