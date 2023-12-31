//
//  PerfDegradeTracks.swift
//  ByteView
//
//  Created by liujianlong on 2021/8/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewRtcBridge

struct PerfAdjustTrackId {
    var actionId: String
    var lastAdjustDirection: RtcPerfAdjustDirection
    var adjustType: AdjustType

    mutating func updateForDirection(_ direction: RtcPerfAdjustDirection, type: AdjustType) {
        if direction != lastAdjustDirection || type != adjustType {
            lastAdjustDirection = direction
            adjustType = type
            actionId = UUID().uuidString
            Logger.getLogger("PerfAdjust.Manager").info("update actionId due to direction change actionId: \(actionId), direction: \(direction), type: \(type)")
        }
    }
}

enum PerfDegradeTracks {
    enum AdjustApiType: String {
        case old
        case new
    }

    static let contentStatic = "setting_low_performance"
    static let contentDynamic = "onthecall_low_performance"

    static let locationPreview = "preview"
    static let locationWaitingRoom = "waiting_room"
    static let locationMeetingSetting = "meeting_setting"
    static let locationOnTheCall = "onthecall"

    static let clickClose = "close"
    static let clickStopEffect = "stop_effect"
    static let clickStopCamera = "stop_camera"
    static let clickKnown = "known"

    static let requestTypeReq = "req"
    static let requestTypeResp = "resp"

    static func trackPerfWarningView(content: String,
                                     location: String,
                                     isCamOn: Bool,
                                     isBackgroundOn: Bool,
                                     isAvatarOn: Bool,
                                     isFilterOn: Bool,
                                     isTouchUpOn: Bool) {
        VCTracker.post(name: .vc_meeting_popup_view,
                       params: [.content: content,
                                .location: location,
                                "is_cam_on": isCamOn,
                                "is_background_on": isBackgroundOn,
                                "is_avatar_on": isAvatarOn,
                                "is_filter_on": isFilterOn,
                                "is_touch_up_on": isTouchUpOn])
    }

    static func trackPerfWarningClick(click: String,
                                      content: String,
                                      location: String,
                                      isCamOn: Bool,
                                      isBackgroundOn: Bool,
                                      isAvatarOn: Bool,
                                      isFilterOn: Bool,
                                      isTouchUpOn: Bool) {
        VCTracker.post(name: .vc_meeting_popup_click,
                       params: [.click: click,
                                .content: content,
                                .location: location,
                                "is_cam_on": isCamOn,
                                "is_background_on": isBackgroundOn,
                                "is_avatar_on": isAvatarOn,
                                "is_filter_on": isFilterOn,
                                "is_touch_up_on": isTouchUpOn])
    }

    static func trackMeetSettingClickClose(location: String,
                                           isCamOn: Bool,
                                           isBackgroundOn: Bool,
                                           isAvatarOn: Bool,
                                           isFilterOn: Bool,
                                           isTouchUpOn: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "close",
                                .target: TrackEventName.vc_meeting_onthecall_view,
                                "is_cam_on": isCamOn,
                                "is_background_on": isBackgroundOn,
                                "is_avatar_on": isAvatarOn,
                                "is_filter_on": isFilterOn,
                                "is_touch_up_on": isTouchUpOn])

    }

    static func trackDegradeToastFor(type: AdjustType) {
        VCTracker.post(name: .vc_meeting_popup_view,
                       params: [.content: type.degradeToastContent])
    }

    static func trackUpgradeToastFor(type: AdjustType) {
        VCTracker.post(name: .vc_meeting_popup_view,
                       params: [.content: type.upgradeToastContent])
    }

    static func trackPerfAdjustStatus(apiType: AdjustApiType,
                                      direction: RtcPerfAdjustDirection,
                                      requestType: String,
                                      actionId: String,
                                      type: AdjustType = .performance,
                                      unit: RtcPerfAdjustUnitType? = nil,
                                      level: Int? = nil) {
        let event: TrackEventName = direction == .up ? .vc_meeting_dynamic_upgrade_status : .vc_meeting_dynamic_degrade_status

        var params: TrackParams = ["api_type": apiType.rawValue,
                                   "report_type": requestType,
                                   "action_id": actionId]
        if apiType == .old, let unit = unit {
            params[.action_name] = unit.trackActionName
        }
        if apiType == .new, let level = level {
            params["ongoing_strategy_type"] = type.trackString
            params["action_level"] = level
        }

        VCTracker.post(name: event,
                       params: params)
    }
}

private extension RtcPerfAdjustUnitType {
    var trackActionName: String {
        switch self {
        case .videoPubCamera:
            return "video_pub_camera"  // 本地视频发布流
        case .videoSubCamera:
            return "video_sub_camera"  // 远端视频订阅流
        case .videoPubScreen:
            return "video_pub_screen"  // 本地共享发布流
        case .videoSubScreen:
            return "video_sub_screen"  // 远端共享订阅流
        case .videoPubScreenCast:
            return "video_pub_screen_cast"  // 投屏发送流
        }
    }
}

private extension AdjustType {
    var trackString: String {
        switch self {
        case .performance:
            return "cpu"
        case .battery:
            return "battery"
        case .thermal:
            return "thermal"
        }
    }

    var degradeToastContent: String {
        switch self {
        case .performance:
            return "video_degrade"
        case .thermal:
            return "thermal_strategy_degrade"
        default:
            return ""
        }
    }

    var upgradeToastContent: String {
        switch self {
        case .thermal:
            return "thermal_strategy_upgrade"
        default:
            return ""
        }
    }
}
