//
//  SmartCorrectTracker.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/6/3.
//

import Foundation
import UIKit
import LKCommonsTracker
import Homeric

enum SmartCorrectAction: String {
    case show = "correction_show"
    case click = "correction_click"
    case apply = "correction_apply"
    case abandon = "disable"
}

final class SmartCorrectTracker: NSObject {
    /// 在消息上气泡点击了高亮的实体词
    static func smartCorrectAction(_ action: SmartCorrectAction) {
        var params: [AnyHashable: Any] = [:]
        params["action"] = action.rawValue
        Tracker.post(TeaEvent(Homeric.SUITE_AI_CORRECTION_COMPLETE, params: params))
    }
}
