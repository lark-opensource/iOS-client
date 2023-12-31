//
//  DeleteConfirm.swift
//  LarkCore
//
//  Created by 赵家琛 on 2021/5/20.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel

/// IM业务，消息删除二次确认页面
public extension IMTracker.Msg {
    struct DeleteConfirm {}
}

/// 删除二次确认页面展示
public extension IMTracker.Msg.DeleteConfirm {
    static func View(_ chat: Chat, _ messageInfos: [(String, LarkModel.Message.TypeEnum)]) {
        let params: [AnyHashable: Any] = [
            "msg_id": messageInfos.map({ $0.0 }),
            "msg_type": messageInfos.map({ IMTracker.Base.messageType($0.1) })
        ]
        Tracker.post(TeaEvent(Homeric.IM_MSG_DELETE_CONFIRM_VIEW,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

/// 在「删除二次确认」页，点击删除
public extension IMTracker.Msg.DeleteConfirm {
    static func Click(_ chat: Chat, _ messageInfos: [(String, LarkModel.Message.TypeEnum)]) {
        let params: [AnyHashable: Any] = [
            "click": "delete",
            "target": "im_chat_main_view",
            "msg_id": messageInfos.map({ $0.0 }),
            "msg_type": messageInfos.map({ IMTracker.Base.messageType($0.1) })
        ]
        Tracker.post(TeaEvent(Homeric.IM_MSG_DELETE_CONFIRM_CLICK,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}
