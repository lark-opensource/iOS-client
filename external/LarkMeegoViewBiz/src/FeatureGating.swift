//
//  FeatureGating.swift
//  LarkMeegoViewBiz
//
//

import Foundation
import LarkSetting
import LarkContainer

enum FeatureGating {
     // 视图预请求是否走下沉新接口
    static let viewNewApiEnable = "meego.mobile.view.sub_task"

    /// Note：跟用户无关的 FG userResolver 可填 nil，其余尽量都传递 userResolver
    static func get(by key: String, userResolver: UserResolver?) -> Bool {
        if let userResolver = userResolver,
            let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) {
            return featureGatingService.dynamicFeatureGatingValue(with: .init(stringLiteral: key))
        }
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: .init(stringLiteral: key))
    }
}