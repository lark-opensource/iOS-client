//
//  FeatureGating.swift
//  LarkMeego
//
//  Created by shizhengyu on 2022/5/19.
//

import Foundation
import LarkSetting
import LarkContainer

enum FeatureGating {
    // url 链接开关（详情、单视图列表）
    static let urlEntranceEnable = "lark.meego.entrance.openurl"
    // 创单功能开关
    static let createWorkItemEnable = "lark.meego.create_work_item"
    // 会话多选开关（创单）
    static let multiSelectEntranceEnable = "lark.meego.multiselect.entrance"
    // meego 业务是否开启 flutter engine 预热
    static let flutterEnginePreload4MeegoEnable = "lark.meego.flutter.engine.preload.enable"
    // 分发长链推送数据，默认 false
    static let enableDispatchPushMessage = "lark.meego.push_data"
    // 是否开启用户态隔离容器
    static let enableUserContainer = "ios.container.scope.user.meego"
    // 是否开启 applink 路由跳转
    static let enableMeegoApplink = "lark.meego.applink.enable"

    /// Note：跟用户无关的 FG userResolver 可填 nil，其余尽量都传递 userResolver
    static func get(by key: String, userResolver: UserResolver?) -> Bool {
        #if FC_EXAMPLE
        return true
        #else
        if let userResolver = userResolver,
            let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) {
            return featureGatingService.dynamicFeatureGatingValue(with: .init(stringLiteral: key))
        }
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: .init(stringLiteral: key))
        #endif
    }
}
