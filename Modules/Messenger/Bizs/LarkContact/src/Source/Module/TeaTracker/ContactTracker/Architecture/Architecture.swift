//
//  Architecture.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/5/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkContainer

///「组织架构目录」页面相关埋点
extension ContactTracker {
    struct Architecture {}
}

///「组织架构目录页」的展示
extension ContactTracker.Architecture {
    /// 展示
    static func View(resolver: UserResolver) {
        let params = ContactTracker.Parms.MemberType(resolver: resolver)
        Tracker.post(TeaEvent(Homeric.CONTACT_ARCHITECTURE_VIEW, params: params))
    }
}

///「组织架构目录页」的动作事件
extension ContactTracker.Architecture {
    struct Click {
        /// 点击进入组织架构人员页
        static func Architecture(layerCount: Int) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "architecture_layer"
            params["target"] = "contact_architecture_member_view"
            params["layer_count"] = "\(layerCount)"
            Tracker.post(TeaEvent(Homeric.CONTACT_ARCHITECTURE_CLICK, params: params))
        }
    }
}
