//
//  LingoHighlightTracker.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/7.
//

import Foundation
import LKCommonsTracker
import Homeric

enum LingoTipClickType: String {
    case Entity = "entity" /// 查看实体词
    case ChooseEntity = "choose_entity" /// 选择释义
    case Ignore = "ignore" /// 忽略
}

final class LingoHighlightTracker: NSObject {
    /// 点击百科词条，出现选择菜单
    static func showAbbrMobileTip(abbrId: String) {
        var params: [AnyHashable: Any] = [:]
        params["card_source"] = "im_input_card"
        params["abbr_id"] = abbrId
        Tracker.post(TeaEvent(Homeric.ASL_ABBR_MOBILE_TIP_VIEW, params: params))
    }
    /// 点击菜单项
    static func clickAbbrMobileTip(abbrId: String, clickType: LingoTipClickType) {
        var params: [AnyHashable: Any] = [:]
        params["card_source"] = "im_input_card"
        params["click"] = clickType.rawValue
        params["abbr_id"] = abbrId
        Tracker.post(TeaEvent(Homeric.ASL_ABBR_MOBILE_TIP_CLICK, params: params))
    }

}
