//
//  LiveNativeTracks.swift
//  ByteView
//
//  Created by Ruyue Hong on 2021/2/3.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

final class LiveNativeTracks {
    /// 直播小窗中发起/加入视频会议 not in use
    static func trackJoinMeetingPopupInLiving(_ confirm: Bool, liveId: String?, liveSessionId: String?) {
        LiveTracker.tracker(name: .pageFloatWindow, params: ["from_source": "start_join_meeting_with_live_float_window",
                                                             "action_name": confirm ? "confirm" : "cancel",
                                                             "live_id": liveId ?? "",
                                                             "live_status": "true",
                                                             "live_session_id": liveSessionId ?? "",
                                                             "live_session_type": "real",
                                                             "im_floating_window": 0])
    }

    /// 点击更多 not in use
    static func trackClickMore(isPortrait: Bool, isLiving: Bool) {
        LiveTracker.tracker(name: .pageLive, params: ["action_name": "more",
                                                        "screen_orientation": isPortrait ? 0 : 1,
                                                        "has_created_live": isLiving ? 1 : 0])
    }

    /// 点击分享至会话 not in use
    static func trackClickShare(isPortrait: Bool, isLiving: Bool) {
        LiveTracker.tracker(name: .pageLive, params: ["from_source": "more",
                                                        "action_name": "share",
                                                        "screen_orientation": isPortrait ? 0 : 1,
                                                        "has_created_live": isLiving ? 1 : 0])
    }

    /// 点击复制链接 not in use
    static func trackClickCopyLink(isPortrait: Bool, isLiving: Bool) {
        LiveTracker.tracker(name: .pageLive, params: ["from_source": "more",
                                                        "action_name": "copy_link",
                                                        "screen_orientation": isPortrait ? 0 : 1,
                                                        "has_created_live": isLiving ? 1 : 0])
    }

    /// 点击刷新 not in use
    static func trackClickReload(isPortrait: Bool, isLiving: Bool) {
        LiveTracker.tracker(name: .pageLive, params:  ["from_source": "more",
                                                         "action_name": "reload",
                                                         "screen_orientation": isPortrait ? 0 : 1,
                                                         "has_created_live": isLiving ? 1 : 0])
    }

    /// 小窗出现
    static func trackDisplayFloatWindow(liveId: String?, liveSessionId: String?) {
        LiveTracker.tracker(name: .pageFloatWindow, params: ["action_name": "display",
                                                             "live_id": liveId ?? "",
                                                             "live_status": "true",
                                                             "live_session_id": liveSessionId ?? "",
                                                             "live_session_type": "real",
                                                             "im_floating_window": 0])
    }

    /// 小窗中点击关闭按钮
    static func trackCloseInFloatWindow(liveId: String?, liveSessionId: String?) {
        LiveTracker.tracker(name: .pageFloatWindow, params: ["action_name": "close",
                                                             "live_id": liveId ?? "",
                                                             "live_status": "true",
                                                             "live_session_id": liveSessionId ?? "",
                                                             "live_session_type": "real",
                                                             "im_floating_window": 0])
    }

    /// 小窗中点击任意区域返回直播观看页
    static func trackBackToLivePageInFloatWindow(liveId: String?, liveSessionId: String?) {
        LiveTracker.tracker(name: .pageFloatWindow, params: ["action_name": "back_to_live_page",
                                                             "live_id": liveId ?? "",
                                                             "live_status": "true",
                                                             "live_session_id": liveSessionId ?? "",
                                                             "live_session_type": "real",
                                                             "im_floating_window": 0])
    }

    /// 直播在播放状态，切换播放状态的时候上报
    static func trackModeChangeInLive(mode: Int) {
        LiveTracker.tracker(name: .pageLive, params: ["action_name": "display", "mode": mode])
    }

    static func trackLiveSdkError(code: Int) {
        LiveTracker.tracker(name: .pageFloatWindow, params: ["live_error": code])
    }

    static func trackFirstFrameTime(interval: Int) {
        LiveTracker.tracker(name: .pageFloatWindow, params: ["first_frame_interval": interval])
    }

    static func trackStallTime(interval: Int) {        
        LiveTracker.tracker(name: .pageFloatWindow, params: ["stall_time_interval": interval])
    }
}
