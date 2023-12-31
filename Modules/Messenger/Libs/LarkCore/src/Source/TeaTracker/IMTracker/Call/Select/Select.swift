//
//  Select.swift
//  LarkCore
//
//  Created by 李勇 on 2021/5/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel

/// 拨打电话选择页面
public extension IMTracker.Call {
    struct Select {}
}

public extension IMTracker.Call.Select {
    static func View(_ chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CALL_SELECT_VIEW,
                              params: IMTracker.Param.chat(chat),
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

public extension IMTracker.Call.Select {
    struct Click {
        public static func Real(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "real_call", "target": "none"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CALL_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func VC(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "vc_call", "target": "vc_meeting_calling_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CALL_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Voice(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "voice_call", "target": "vc_meeting_calling_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CALL_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}
