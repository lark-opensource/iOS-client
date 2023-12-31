//
//  EnterpriseEntityWordTracker.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/1/14.
//

import Foundation
import LKCommonsTracker
import Homeric
import ServerPB

final class EnterpriseEntityWordTracker: NSObject {
    /// 在消息上气泡点击了高亮的实体词
    static func clickMessageEnterpriseEntityWord(chatId: String) {
        var params: [AnyHashable: Any] = [:]
        params["chat_id"] = chatId
        Tracker.post(TeaEvent(Homeric.CLICK_ON_HIGHLIGHT_ENTITY_MOBILE, params: params))
    }

    /// 在实体词卡片上点击了词条详情
    static func clickMessageEnterpriseEntityWordCardMore(entityId: String) {
        var params: [AnyHashable: Any] = [:]
        params["entity_id"] = entityId
        Tracker.post(TeaEvent(Homeric.CLICK_ON_MOREINFORMATION, params: params))
    }

    /// 在实体词卡片上点击了查看更多释义
    static func clickMessageEnterpriseEntityWordCardMoreParaphrase(entityId: String) {
        var params: [AnyHashable: Any] = [:]
        params["entity_id"] = entityId
        Tracker.post(TeaEvent(Homeric.CLICK_ON_MORERESULTS, params: params))
    }

    /// 在消息气泡菜单里点击了 查询 按钮
    static func clickMessageMenuQueryEnterpriseaEntityWords(markLength: Int) {
        var params: [AnyHashable: Any] = [:]
        params["mark_length"] = markLength
        Tracker.post(TeaEvent(Homeric.CLICK_ON_MORERESULTS, params: params))
    }

    /// 在查询结果里点击了词条详情
    static func clickEntityWordsListCheckMore() {
        Tracker.post(TeaEvent(Homeric.LEARN_MORE_FROM_LOOKUP_RESULTS))
    }

    /// 实体词卡片点击了点赞按钮
    static func clickEntityWordsCardLike() {
        Tracker.post(TeaEvent(Homeric.CLICK_ON_LIKE_MOBILE))
    }

    /// 实体词卡片点击了点踩按钮
    static func clickEntityWordsCardDislike() {
        Tracker.post(TeaEvent(Homeric.CLICK_ON_DISLIKE_MOBILE))
    }
}
