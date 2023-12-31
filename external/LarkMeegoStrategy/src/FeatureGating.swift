//
//  FeatureGating.swift
//  LarkMeegoStrategy
//
//  Created by shizhengyu on 2023/4/24.
//

import Foundation
import LarkSetting
import LarkContainer

enum FeatureGating {
    // 是否关闭 meego 行为打点
    static let disableMeegoUserTrack = "lark.meego.user.track.disable"
    // 是否开启业务预请求
    static let enableBizPreRequest = "lark.meego.prerequest.enable"

    /// Note：跟用户无关的 FG userResolver 可填 nil，其余尽量都传递 userResolver
    static func get(by key: String, userResolver: UserResolver?) -> Bool {
        if let userResolver = userResolver,
            let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) {
            return featureGatingService.dynamicFeatureGatingValue(with: .init(stringLiteral: key))
        }
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: .init(stringLiteral: key))
    }
}
