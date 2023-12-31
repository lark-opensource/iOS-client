//
//  LiveTracker.swift
//  Lark
//
//  Created by yangyao on 2021/6/16.
//

import Foundation
import LKCommonsTracker

public enum LarkTrackerName: String {
    case pageLive = "vc_live_page_live"
    case pageFloatWindow = "vc_live_page_float_window"
    case linkClicked = "link_clicked"
    case feelGoodPop = "vc_live_feelgood_pop_dev"
    case watchView = "vc_live_watch_view"
    case watchClick = "vc_live_watch_click"
    case shareClick = "vc_live_share_click"
    case shareView = "vc_live_share_view"
    
    
    case liveStreamUrlDev = "vc_live_stream_url_dev"
    case liveStreamRouterDev = "vc_live_stream_router_dev"

    case liveQuicPlay = "vc_live_quic_play"
    case liveQuicFallback = "vc_live_quic_fallback"
    
    case liveQuicAB = "vc_live_quic_ab"
}

public final class LiveTracker {
    public static func tracker(name: LarkTrackerName, params: [AnyHashable: Any], isAB: Bool = false) {
        let event = TeaEvent(name.rawValue)
        var paramsSend: [AnyHashable: Any] = self.commonParamsGenerat()
        params.forEach { (k, v) in
            paramsSend[k] = v
        }
        event.params = paramsSend
        Tracker.post(event)
    }

    public static func commonParamsGenerat() -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        return params
    }
}
