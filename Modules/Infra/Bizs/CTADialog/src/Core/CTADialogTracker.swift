//
//  CTADialogTracker.swift
//  CTADialog
//
//  Created by aslan on 2023/10/19.
//

import Foundation
import Homeric
import LKCommonsTracker

/// 新埋点
struct CTADialogTracker {
    static func popup(featureKey: String, scene: String, model: CTAModel? = nil) {
        let params = Self.createParams(featureKey: featureKey, scene: scene, model: model)
        Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_VIEW, params: params))
    }

    static func click(tag: String? = "i_know", featureKey: String, scene: String, model: CTAModel? = nil) {
        var params = Self.createParams(featureKey: featureKey, scene: scene, model: model)
        params["click"] = tag
        params["target"] = "none"
        Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_CLICK, params: params))
    }

    static func createParams(featureKey: String, scene: String, model: CTAModel?) -> [String: Any] {
        var params: [String: Any] = [:]
        params["function_type"] = featureKey
        if let category = model?.extra_info?.function_category {
            params["function_category"] = category
        }
        if let adminFlag = model?.extra_info?.admin_flag {
            params["admin_flag"] = adminFlag
        }
        if let singleSku = model?.extra_info?.is_single_sku {
            params["is_single_sku"] = singleSku
        }
        params["popup_type"] = "in_app_popup"
        params["function_scene"] = scene
        return params
    }
}
