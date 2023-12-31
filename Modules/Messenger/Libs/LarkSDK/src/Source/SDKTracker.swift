//
//  SDKTracker.swift
//  LarkSDK
//
//  Created by liuwanlin on 2018/8/13.
//

import Foundation
import Homeric
import LarkSDKInterface
import LarkModel
import LKCommonsTracker
import RustPB
import LarkCore

final class SDKTracker {
    private static let lock = DispatchSemaphore(value: 1)
    private static var _longConnSessionId: String = ""
    private static var longConnSessionId: String {
        get {
            lock.wait(); defer { lock.signal() }
            return _longConnSessionId
        }
        set {
            lock.wait(); defer { lock.signal() }
            _longConnSessionId = newValue
        }
    }

    /// 长链开始建立
    static func trackLongConnStart() {
        longConnSessionId = UUID().uuidString
        Tracker.post(TeaEvent(Homeric.PERF_BOOT_LONGCONN_START, category: "performance", params: [
            "boot_session_id": longConnSessionId,
            "boot_time": Date().timeIntervalSince1970
            ])
        )
    }

    /// 长链成功建立
    static func trackLongConnEnd() {
        Tracker.post(TeaEvent(Homeric.PERF_BOOT_LONGCONN_END, category: "performance", params: [
            "boot_session_id": longConnSessionId,
            "boot_time": Date().timeIntervalSince1970
            ])
        )
    }

    static func trackDocsSync(_ permissionCode: Int) {
        Tracker.post(TeaEvent(Homeric.DOCS_SYNC, category: "docs", params: [
            "share": getDocAuth(permissionCode)
            ])
        )
    }

    private static func getDocAuth(_ permissionCode: Int) -> String {
        var auth: String
        switch permissionCode {
        case 1: auth = "read"
        case 4: auth = "edit"
        case 501: auth = "forbidden"
        default: auth = "unknown"
        }
        return auth
    }
}
