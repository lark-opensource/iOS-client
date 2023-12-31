//
//  TrackCommonParams.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import QuartzCore

public final class TrackCommonParams {
    private static var currentEnvId: String?
    private static var commonParams: [String: [String: Any]] = [:]
    private static var meetingEnvMap: [String: String] = [:]

    @RwAtomic
    /// NTP 时间与本地时间偏移量，单位毫秒
    public static var ntpOffset: Int64?

    /// NTP 时间，如果 ntp 为空，则兜底到本地时间
    public static var clientNtpTime: Int64 {
        var clientNtpTime = Int64(Date().timeIntervalSince1970 * 1000)
        if let ntpOffset = Self.ntpOffset {
            clientNtpTime += ntpOffset
        }
        return clientNtpTime
    }

    public static func removeAll() {
        Queue.tracker.async {
            Logger.tracker.withEnv(currentEnvId).info("removeAllCommonParams")
            currentEnvId = nil
            meetingEnvMap = [:]
            commonParams = [:]
        }
    }

    /// 更新当前会议的envId
    public static func updateCurrentEnvId(_ envId: String?) {
        Queue.tracker.async {
            if let envId = envId, !envId.isEmpty {
                Logger.tracker.withEnv(envId).info("updateCurrentEnvId")
                currentEnvId = envId
            } else if let id = currentEnvId {
                Logger.tracker.withEnv(id).info("removeCurrentEnvId")
                currentEnvId = nil
            }
        }
    }

    public static func removeValue(for envId: String) {
        if envId.isEmpty { return }
        Queue.tracker.async {
            Logger.tracker.withEnv(envId).info("removeCommonParams")
            if currentEnvId == envId {
                currentEnvId = nil
            }
            commonParams.removeValue(forKey: envId)
        }
    }

    /// 更新其他会议通参
    public static func setValue(_ params: [String: Any], for envId: String) {
        if envId.isEmpty { return }
        Queue.tracker.async {
            Logger.tracker.withEnv(envId).info("updateCommonParams: current = \(currentEnvId ?? "<nil>"), params = \(params)")
            if currentEnvId == nil {
                currentEnvId = envId
            }
            if params.isEmpty {
                commonParams.removeValue(forKey: envId)
            } else {
                commonParams[envId] = params
                if let meetingId = params["conference_id"] as? String {
                    meetingEnvMap[meetingId] = envId
                }
            }
        }
    }

    /// https://juejin.cn/post/6955756689228300302
    static var vpnType: String {
        var result = "none"
        guard let cD = CFNetworkCopySystemProxySettings() else {
            return result
        }
        let nD = cD.takeRetainedValue() as NSDictionary
        guard let keys = nD["__SCOPED__"] as? [String: Any] else {
            return result
        }
        let keyValues: [String] = [
            "tap",
            "tun",
            "ppp",
            "ipsec"
        ]
        for key in keys.keys {
            keyValues.forEach {
                if key.contains($0) {
                    result = key
                }
            }
        }
        return result
    }

    /// must use in `Queue.tracker`
    public static func fill(event: inout TrackEvent) {
        var params = event.params
        if let envId = findEnvId(params) {
            if envId.isEmpty {
                // 手动置空，忽略会议通参
            } else if let common = commonParams[envId] {
                params.updateParams(common, isOverwrite: false)
            }
        } else if let envId = currentEnvId, let common = commonParams[envId] {
            // 默认走当前会议通参
            params.updateParams(common, isOverwrite: false)
        }
        let clientNtpTime = Self.clientNtpTime
        params.updateParams([
            "client_type": "", // 不同的客户端，包括独立的App，硬件App，默认为空，代表Lark，其他待定
            "participant_type": "lark_user",
            "network_type": ReachabilityUtil.currentNetworkType.description,
            "client_ntp_time": clientNtpTime,
            "vpn_type": vpnType
        ], isOverwrite: false)
        // 特定Event增加横屏通用参数
        if Display.phone, landscapeParamAllowlist.contains(event.trackName) {
            params.updateParams(["if_landscape_screen": AppInfo.shared.statusBarOrientation.isLandscape], isOverwrite: false)
        }
        event.params = params
    }

    private static var landscapeParamAllowlist: Set<TrackEventName> = [
        .vc_meeting_onthecall_click,
        .vc_meeting_hostpanel_view,
        .vc_meeting_chat_send_message_view,
        .vc_meeting_chat_send_message_click,
        .vc_meeting_chat_reaction_view,
        .vc_meeting_chat_reaction_click
    ]

    private static func findEnvId(_ params: TrackParams) -> String? {
        if let envId = params[.env_id] as? String {
            return envId
        } else if let meetingId = params[.conference_id] as? String {
            return self.meetingEnvMap[meetingId]
        } else {
            return nil
        }
    }
}
