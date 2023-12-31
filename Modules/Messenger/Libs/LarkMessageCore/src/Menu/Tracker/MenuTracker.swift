//
//  MenuTracker.swift
//  Action
//
//  Created by lizhiqiang on 2019/7/19.
//

import Foundation
import Homeric
import LKCommonsTracker

final class MenuTracker {
    static func trackViewInChat(isCrypto: Bool) {
        Tracker.post(TeaEvent(Homeric.THREAD_DETAIL_PAGE_VIEW_IN_CHAT_CLICKED, params: ["chat_mode": isCrypto ? "secret" : "classic"]))
    }

    static func trackMultiSelectEnter() {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_ENTER))
    }

    static func trackMultiSelectFavoriteClick(batchSelect: Bool) {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_FAVORITE_CLICK, params: ["followingmessage": batchSelect ? "true" : "false"]))
    }

    static func trackMultiSelectForwardClick(batchSelect: Bool) {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_FORWARD_CLICK, params: ["followingmessage": batchSelect ? "true" : "false"]))
    }

    /// 逐条转发
    static func trackMultiSelectQuickForwardClick(batchSelect: Bool) {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_QUICKFORWARD_CLICK, params: ["followingmessage": batchSelect ? "true" : "false"]))
    }

    static func trackMultiSelectDeleteClick(batchSelect: Bool) {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_DELETE_CLICK, params: ["followingmessage": batchSelect ? "true" : "false"]))
    }

    static func showAudioText() {
        Tracker.post(TeaEvent(Homeric.AUDIO_CONVERT_TO_TEXT))
    }

    static func hideAudioText(isAuto: Bool) {
        Tracker.post(TeaEvent(Homeric.AUDIO_HIDE_TEXT, params: ["is_auto": isAuto ? "y" : "n"]))
    }
}
