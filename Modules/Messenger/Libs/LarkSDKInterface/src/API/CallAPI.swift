//
//  CallAPI.swift
//  Lark
//
//  Created by lichen on 2017/12/7.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public typealias VCJoinMeetingCheckIDType = RustPB.Videoconference_V1_JoinMeetingPreCheckRequest.JoinMeetingCheckIDType
public typealias VCJoinMeetingCheckType = RustPB.Videoconference_V1_JoinMeetingPreCheckResponse.JoinMeetingCheckType

public enum PullSourceType {
    case longConnectionLoss
    case startup
    case voIPPush

    public func toRequestSourceType() -> RustPB.Videoconference_V1_GetE2EEVoiceCallsRequest.SourceType {
        switch self {
        case .longConnectionLoss, .voIPPush:
            return .longConnectionLoss
        case .startup:
            return .startup
        }
    }
}

public protocol CallAPI {
    func createCall(userID: String, secureChatId: String?, ntpTime: Int64, publicKey: Data) -> Observable<RustPB.Videoconference_V1_E2EEVoiceCall>

    func requestJoinMeetingPreCheck(_ identifier: String,
                                    idType: VCJoinMeetingCheckIDType) -> Observable<VCJoinMeetingCheckType>

    func patchCall(callId: String, status: RustPB.Videoconference_V1_E2EEVoiceCall.Status, ntpTime: Int64, publicKey: Data?) -> Observable<Void>

    func pullCallStatus(sourceType: PullSourceType) -> Observable<RustPB.Videoconference_V1_E2EEVoiceCall?>

    func feedback(callId: String, feedback: RustPB.Videoconference_V1_E2EEVoiceFeedback) -> Observable<Void>

    func getRtcDNS() -> Observable<[String: [String]]>

    func startPolling(callId: String)

    func stopPolling()

}

public typealias CallAPIProvider = () -> CallAPI
