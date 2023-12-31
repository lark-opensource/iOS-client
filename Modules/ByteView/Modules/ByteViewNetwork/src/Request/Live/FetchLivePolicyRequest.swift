//
//  FetchLivePolicyResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - LIVE_MEETING_FETCH_LIVE_POLICY = 2385
/// - ServerPB_Videochat_VideoChatFetchLivePolicyRequest
public struct FetchLivePolicyRequest {
    public static let command: NetworkCommand = .server(.liveMeetingFetchLivePolicy)
    public typealias Response = FetchLivePolicyResponse

    public init() {}
}

/// ServerPB_Videochat_VideoChatFetchLivePolicyResponse
public struct FetchLivePolicyResponse {

    public var policyWithoutSetting: MegaI18n

    public var policyOverseaWithoutSettingForCall: MegaI18n

    public var policyOverseaWithoutSettingForMeeting: MegaI18n

    /// pc 1v1 发起直播时的文案
    public var policyOverseaForCallPc: MegaI18n

    /// pc 多人会议发起直播时的文案
    public var policyOverseaForMeetingPc: MegaI18n

    /// 实名认证弹窗文案
    public var certificationPopup: MegaI18n

    /// 实名认证用户确认文案
    public var certificationCheckbox: MegaI18n
}

extension FetchLivePolicyRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_VideoChatFetchLivePolicyRequest
    func toProtobuf() throws -> ServerPB_Videochat_VideoChatFetchLivePolicyRequest {
        ProtobufType()
    }
}

extension FetchLivePolicyResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_VideoChatFetchLivePolicyResponse
    init(pb: ServerPB_Videochat_VideoChatFetchLivePolicyResponse) throws {
        self.policyWithoutSetting = pb.policyWithoutSetting.vcType
        self.policyOverseaWithoutSettingForCall = pb.policyOverseaWithoutSettingForCall.vcType
        self.policyOverseaWithoutSettingForMeeting = pb.policyOverseaWithoutSettingForMeeting.vcType
        self.policyOverseaForCallPc = pb.policyOverseaForCallPc.vcType
        self.policyOverseaForMeetingPc = pb.policyOverseaForMeetingPc.vcType
        self.certificationPopup = pb.certificationPopup.vcType
        self.certificationCheckbox = pb.certificationCheckbox.vcType
    }
}
