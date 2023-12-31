//
//  PullVideoChatConfigRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 拉取VC配置
/// - PULL_VIDEO_CHAT_CONFIG = 2213
/// - Videoconference_V1_PullVideoChatConfigRequest
public struct PullVideoChatConfigRequest {
    public static let command: NetworkCommand = .rust(.pullVideoChatConfig)
    public typealias Response = PullVideoChatConfigResponse

    public init() {}
}

/// Videoconference_V1_PullVideoChatConfigResponse
public struct PullVideoChatConfigResponse: Equatable {
    public init(enableUpgradePlanNotice: [Int32: Bool],
                meetingSupportInterpretationLanguage: [InterpreterSetting.LanguageType],
                subtitleLanguages: [SubtitleLanguage],
                spokenLanguages: [SubtitleLanguage],
                inMeetingCountdownPermissionThreshold: Int32,
                largeMeetingSuggestThreshold: Int32,
                largeMeetingShareNoticeThreshold: Int32,
                largeMeetingSecurityNoticeThreshold: Int32
    ) {
        self.enableUpgradePlanNotice = enableUpgradePlanNotice
        self.meetingSupportInterpretationLanguage = meetingSupportInterpretationLanguage
        self.subtitleLanguages = subtitleLanguages
        self.spokenLanguages = spokenLanguages
        self.inMeetingCountdownPermissionThreshold = inMeetingCountdownPermissionThreshold
        self.largeMeetingSuggestThreshold = largeMeetingSuggestThreshold
        self.largeMeetingShareNoticeThreshold = largeMeetingShareNoticeThreshold
        self.largeMeetingSecurityNoticeThreshold = largeMeetingSecurityNoticeThreshold
    }

    /// 是否可以被通知升级
    public var enableUpgradePlanNotice: [Int32: Bool]

    /// 会议可选择配置的传译语言
    public var meetingSupportInterpretationLanguage: [InterpreterSetting.LanguageType]

    /// 会议字幕语言
    public var subtitleLanguages: [SubtitleLanguage]

    /// 会议口说语言
    public var spokenLanguages: [SubtitleLanguage]

    /// 倒计时权限放缩人数阈值
    public var inMeetingCountdownPermissionThreshold: Int32

    /// 大方数会议谨慎共享提示人数阈值
    public var largeMeetingShareNoticeThreshold: Int32

    /// 大方数会议安全设置提示人数阈值
    public var largeMeetingSecurityNoticeThreshold: Int32

    /// 大方会议安全管控建议人数阈值
    public var largeMeetingSuggestThreshold: Int32

    public struct SubtitleLanguage: Equatable {
        public init(language: String, desc: String) {
            self.language = language
            self.desc = desc
        }

        public var language: String

        public var desc: String
    }
}

extension PullVideoChatConfigRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PullVideoChatConfigRequest
    func toProtobuf() throws -> Videoconference_V1_PullVideoChatConfigRequest {
        ProtobufType()
    }
}

extension PullVideoChatConfigResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PullVideoChatConfigResponse

    init(pb: Videoconference_V1_PullVideoChatConfigResponse) {
        self.enableUpgradePlanNotice = pb.enableUpgradePlanNotice
        self.meetingSupportInterpretationLanguage = pb.meetingSupportInterpretationLanguage.map({ $0.vcType })
        self.subtitleLanguages = pb.subtitleLanguages.map({ .init(pb: $0) })
        self.spokenLanguages = pb.spokenLanguages.map({ .init(pb: $0) })
        self.largeMeetingShareNoticeThreshold = pb.largeMeetingShareNoticeThreshold
        self.largeMeetingSecurityNoticeThreshold = pb.largeMeetingSecurityNoticeThreshold
        self.largeMeetingSuggestThreshold = pb.largeMeetingSuggestThreshold
        self.inMeetingCountdownPermissionThreshold = pb.inMeetingCountdownPermissionThreshold
    }
}

extension PullVideoChatConfigResponse.SubtitleLanguage: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_PullVideoChatConfigResponse.SubtitleLanguage

    init(pb: Videoconference_V1_PullVideoChatConfigResponse.SubtitleLanguage) {
        self.language = pb.language
        self.desc = pb.description_p
    }
}
