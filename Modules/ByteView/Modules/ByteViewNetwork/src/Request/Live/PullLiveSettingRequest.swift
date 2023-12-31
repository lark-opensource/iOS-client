//
//  PullLiveSettingResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - LIVE_MEETING_PULL_SETTING = 2393
/// - ServerPB_Videochat_VideoChatPullLiveSettingRequest
public struct PullLiveSettingRequest {
    public static let command: NetworkCommand = .server(.liveMeetingPullSetting)
    public typealias Response = PullLiveSettingResponse

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    public var meetingId: String
}

/// ServerPB_Videochat_VideoChatPullLiveSettingResponse
public struct PullLiveSettingResponse: Equatable {

    public var displayConditionMap: [DisplayConditionKey: LiveSettingElementV2]

    public var privilegeScopeSetting: LiveSettingPrivilegeScope

    public var liveURL: String

    public var isOversea: Bool

    public enum DisplayConditionKey: Int, Hashable {
        case conditionEnableLive // = 0
        case conditionEnableLiveExternal // = 1
        case conditionEnablePlayback // = 2
    }

    public enum I18nKeyKey: Int, Hashable {
        case disableStartLiveKey
        case disablePickerExternalUserKey
        case disablePickerExternalGroupKey
        case disablePlaybackKey
    }

    public enum DisplayStatus: Int, Hashable, Equatable {
        case normal // 展示且可选
        case disabled  // 展示且置灰
        case hidden // 不展示
    }

    public struct LiveSettingElementV2: Equatable {
        public var displayStatus: DisplayStatus
        public var i18nKeyMap: [I18nKeyKey: String] // key:I18nKeyKey
    }
}

extension PullLiveSettingRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_VideoChatPullLiveSettingRequest
    func toProtobuf() throws -> ServerPB_Videochat_VideoChatPullLiveSettingRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}

extension PullLiveSettingResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_VideoChatPullLiveSettingResponse
    init(pb: ServerPB_Videochat_VideoChatPullLiveSettingResponse) throws {
        self.privilegeScopeSetting = LiveSettingPrivilegeScope(pb: pb.privilegeScopeSetting)
        self.liveURL = pb.liveURL
        self.isOversea = pb.isOversea
        var tmpMap: [DisplayConditionKey: LiveSettingElementV2] = [:]
        pb.displayConditionMap.forEach { (key, value) in
            var tmpI18KeyMap: [I18nKeyKey: String] = [:]
            /// i18nKeyMap
            value.i18NKeyMap.forEach { (i18key, i18Value) in
                tmpI18KeyMap[I18nKeyKey(rawValue: Int(i18key)) ?? .disablePlaybackKey] = i18Value
            }
            /// displayConditionKeyMap
            tmpMap[DisplayConditionKey(rawValue: Int(key)) ?? .conditionEnableLive] = LiveSettingElementV2(displayStatus: DisplayStatus(rawValue: value.displayStatus.rawValue) ?? .normal, i18nKeyMap: tmpI18KeyMap)
        }
        self.displayConditionMap = tmpMap
    }
}
