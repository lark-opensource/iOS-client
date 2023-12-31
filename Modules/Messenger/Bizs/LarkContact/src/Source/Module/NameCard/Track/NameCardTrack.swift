//
//  NameCardTrack.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/4/23.
//

import Foundation
import Homeric
import LKCommonsTracker
import RustPB

/// 埋点
final class NameCardTrack {

    /// 点击“名片夹”时上报
    static func trackClickNameCard() {
        Tracker.post(TeaEvent(Homeric.CONTACT_CONTACTCARDS))
    }

    /// 通过profile添加到名片夹
    static func trackClickAddInProfile() {
        Tracker.post(TeaEvent(Homeric.PROFILE_CONTACTCARDS_ADD))
    }

    /// 在名片夹列表点击（加号）按钮
    static func trackClickAddInList() {
        Tracker.post(TeaEvent(Homeric.CONTACT_CONTACTCARDS_ADD))
    }

    /// 点进名片夹编辑页的来源
    static func trackAddOkInEdit(_ source: String?) {
        guard let aSource = source else { return }
        let params = ["source": aSource] as [String: Any]
        Tracker.post(TeaEvent(Homeric.CONTACT_CONTACTCARDS_ADD_OK, params: params))
    }
}
