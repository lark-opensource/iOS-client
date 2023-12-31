//
//  ShareTracker.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2021/1/13.
//

import Foundation
import Homeric
import LKCommonsTracker
import LarkShareContainer

class ShareTracker {
    static func clickShareEntry(appId: String, from: String, opTracking: String) {
        Tracker.post(TeaEvent(Homeric.OP_SHARE_CLICK, params: [
            "appId": appId,
            "entry_name": from,
            "op_tracking": opTracking
        ]))
    }

    enum ShareStatus: String {
        case success
        case failure
        case cancel
    }

    static func shareFinish(
        appId: String, from: String, opTracking: String, status: ShareStatus, shareType: ShareTabType
    ) {
        Tracker.post(TeaEvent(Homeric.OP_SHARE_FINISH, params: [
            "appId": appId,
            "entry_name": from,
            "op_tracking": opTracking,
            "status": status.rawValue,
            "share_type": shareType.trackerType
        ]))
    }
}

extension ShareTabType {
    var trackerType: String {
        switch self {
        case .viaChat:
            return "card"
        case .viaLink:
            return "link"
        case .viaQRCode:
            return "qr_code"
        }
    }
}
