//
//  GetAdminSettingsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_GetAdminSettingsRequest
public struct GetAdminSettingsRequest: Equatable {
    public static let command: NetworkCommand = .rust(.getAdminSettings)
    public typealias Response = GetAdminSettingsResponse

    public init(tenantID: Int64?, meetingID: String? = nil, uniqueID: String? = nil) {
        if let id = tenantID, id != 0 {
            self.tenantID = id
        } else {
            self.tenantID = nil
        }
        if let id = meetingID, !id.isEmpty {
            self.meetingID = id
        } else {
            self.meetingID = nil
        }
        if let id = uniqueID, !id.isEmpty {
            self.uniqueID = id
        } else {
            self.uniqueID = nil
        }
    }

    public var tenantID: Int64?
    public var meetingID: String?
    public var uniqueID: String?
}

/// Videoconference_V1_GetAdminSettingsResponse
public struct GetAdminSettingsResponse: Equatable {

    /// 是否开启录制功能
    public var enableRecord: Bool

    /// 是否开启字幕翻译功能
    public var enableSubtitle: Bool

    /// PSTN 是否允许电话邀请参会人(呼出)
    public var pstnEnableOutgoingCall: Bool

    /// PSTN 是否允电话呼叫参会(呼入)
    public var pstnEnableIncomingCall: Bool

    /// PSTN是否支持会中外呼拨打任意号码
    public var enablePSTNCalloutScopeAny: Bool

    /// PSTN 呼入默认国家
    public var pstnIncomingCallCountryDefault: [String]

    /// PSTN 呼入号码列表
    public var pstnIncomingCallPhoneList: [PSTNPhone]

    /// PSTN 呼出默认国家
    public var pstnOutgoingCallCountryDefault: [String]

    /// PSTN 呼出国家列表
    public var pstnOutgoingCallCountryList: [String]

    /// 是否启用会中虚拟背景
    public var enableMeetingBackground: Bool

    /// 是否支持用户上传自定义会中虚拟背景
    public var enableCustomMeetingBackground: Bool

    /// 虚拟背景列表
    public var meetingBackgroundList: [MeetingBackground]

    /// 是否支持用户使用虚拟头像
    public var enableVirtualAvatar: Bool

    /// 是否允许用户安装应用
    public var canPersonalInstall: Bool

    /// 是否需要投屏二次确认
    public var enableCheckScreenShare: Bool

    /// rtc proxy 配置
    public var rtcProxy: RTCProxy?

    ///是否开启了声纹识别
    public var enableVoiceprint: Bool

    /// 是否允许开启直播
    public var enableLive: Bool

    /// 投屏是否需要二次确认
    public var shareScreenConfirm: ShareScreenConfirm

    public enum ShareScreenConfirm: Int {
        /// 不需要
        case none // = 0

        /// 仅在跨租户时需要
        case crossTenantOnly // = 1

        /// 始终需要
        case always // = 2
    }

    /// Videoconference_V1_MeetingBackground
    public struct MeetingBackground: Equatable {

        /// 类型
        public var type: MeetingBackground.TypeEnum

        /// 名称
        public var name: String

        /// 地址
        public var url: String

        public var portraitURL: String

        public var source: VirtualBackgroundInfo.MaterialSource

        public enum TypeEnum: Int, Hashable {
            case unknown // = 0

            /// 图片
            case image // = 1

            /// 视频
            case video // = 2
        }
    }

    public var speedupNodes: [String]

    public var bandwidth: Bandwidth?

    /// Videoconference_V1_Bandwidth
    public struct Bandwidth: Equatable {
        /// 带宽限制状态
        public var bandwidthStatus: Bool

        /// 上行带宽限速 kbps
        public var upstreamBandwidth: Int64

        /// 下行带宽限速 kbps
        public var downstreamBandwidth: Int64
    }

    /// “智能会议”
    public var enableRecordAiSummary: Bool
}

public extension GetAdminSettingsResponse {
    init() {
        self.enableRecord = false
        self.enableSubtitle = false
        self.pstnEnableOutgoingCall = false
        self.pstnEnableIncomingCall = false
        self.enablePSTNCalloutScopeAny = true
        self.pstnIncomingCallCountryDefault = []
        self.pstnIncomingCallPhoneList = []
        self.pstnOutgoingCallCountryDefault = []
        self.pstnOutgoingCallCountryList = []
        self.enableMeetingBackground = false
        self.enableCustomMeetingBackground = false
        self.meetingBackgroundList = []
        self.enableVirtualAvatar = false
        self.canPersonalInstall = false
        self.enableCheckScreenShare = false
        self.enableVoiceprint = false
        self.rtcProxy = nil
        self.enableLive = true
        self.speedupNodes = []
        self.shareScreenConfirm = .none
        self.bandwidth = nil
        self.enableRecordAiSummary = false
    }
}

extension GetAdminSettingsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetAdminSettingsRequest
    func toProtobuf() throws -> Videoconference_V1_GetAdminSettingsRequest {
        var request = ProtobufType()
        if let id = tenantID {
            request.tenantID = id
        }
        if let id = meetingID {
            request.meetingID = id
        }
        if let id = uniqueID {
            request.uniqueID = id
        }
        return request
    }
}


extension GetAdminSettingsResponse: RustResponse, ProtobufEncodable {
    typealias ProtobufType = Videoconference_V1_GetAdminSettingsResponse

    init(pb: Videoconference_V1_GetAdminSettingsResponse) {
        self.enableRecord = pb.enableRecord
        self.enableSubtitle = pb.enableSubtitle
        self.pstnEnableOutgoingCall = pb.pstnEnableOutgoingCall
        self.pstnEnableIncomingCall = pb.pstnEnableIncomingCall
        self.enablePSTNCalloutScopeAny = pb.enablePstnCalloutScopeAny
        self.pstnIncomingCallCountryDefault = pb.pstnIncomingCallCountryDefault
        self.pstnIncomingCallPhoneList = pb.pstnIncomingCallPhoneList.map({ .init(pb: $0) })
        self.pstnOutgoingCallCountryDefault = pb.pstnOutgoingCallCountryDefault
        self.pstnOutgoingCallCountryList = pb.pstnOutgoingCallCountryList
        self.enableMeetingBackground = pb.enableMeetingBackground
        self.enableCustomMeetingBackground = pb.enableCustomMeetingBackground
        self.meetingBackgroundList = pb.meetingBackgroundList.map({ .init(pb: $0) })
        self.enableVirtualAvatar = pb.enableVirtualAvatar
        self.canPersonalInstall = pb.canPersonalInstall
        self.enableCheckScreenShare = pb.enableCheckScreenShare
        self.enableVoiceprint = pb.enableVoiceprint
        self.rtcProxy = pb.hasRtcProxy ? pb.rtcProxy.vcType : nil
        self.enableLive = pb.enableLive
        self.speedupNodes = pb.speedUpNodes
        self.shareScreenConfirm = .init(rawValue: pb.shareScreenConfirm.rawValue) ?? .none
        self.bandwidth = pb.hasBandwidth ? .init(pb: pb.bandwidth) : nil
        self.enableRecordAiSummary = pb.enableRecordAiSummary
    }

    func toProtobuf() -> Videoconference_V1_GetAdminSettingsResponse {
        var pb = ProtobufType()
        pb.enableRecord = enableRecord
        pb.enableSubtitle = enableSubtitle
        pb.pstnEnableOutgoingCall = pstnEnableOutgoingCall
        pb.pstnEnableIncomingCall = pstnEnableIncomingCall
        pb.enablePstnCalloutScopeAny = enablePSTNCalloutScopeAny
        pb.pstnIncomingCallCountryDefault = pstnIncomingCallCountryDefault
        pb.pstnIncomingCallPhoneList = pstnIncomingCallPhoneList.map({ $0.toProtobuf() })
        pb.pstnOutgoingCallCountryDefault = pstnOutgoingCallCountryDefault
        pb.pstnOutgoingCallCountryList = pstnOutgoingCallCountryList
        pb.enableMeetingBackground = enableMeetingBackground
        pb.enableCustomMeetingBackground = enableCustomMeetingBackground
        pb.meetingBackgroundList = meetingBackgroundList.map({ $0.toProtobuf() })
        pb.enableVirtualAvatar = enableVirtualAvatar
        pb.canPersonalInstall = canPersonalInstall
        pb.enableCheckScreenShare = enableCheckScreenShare
        pb.enableVoiceprint = enableVoiceprint
        pb.speedUpNodes = speedupNodes
        if let rtc = rtcProxy {
            pb.rtcProxy = rtc.pbType
        }
        pb.enableLive = enableLive
        pb.shareScreenConfirm = .init(rawValue: shareScreenConfirm.rawValue) ?? .none
        if let bandwidth = bandwidth {
            pb.bandwidth = bandwidth.toProtobuf()
        }
        pb.enableRecordAiSummary = enableRecordAiSummary
        return pb
    }
}

extension GetAdminSettingsResponse.MeetingBackground: ProtobufDecodable, ProtobufEncodable {
    typealias ProtobufType = Videoconference_V1_MeetingBackground
    init(pb: Videoconference_V1_MeetingBackground) {
        self.type = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.name = pb.name
        self.url = pb.url
        self.portraitURL = pb.portraitURL
        self.source = .init(rawValue: pb.source.rawValue) ?? .unknown
    }

    func toProtobuf() -> Videoconference_V1_MeetingBackground {
        var pb = ProtobufType()
        pb.type = .init(rawValue: type.rawValue) ?? .unknown
        pb.name = name
        pb.url = url
        pb.portraitURL = portraitURL
        pb.source = .init(rawValue: source.rawValue) ?? .unknownSource
        return pb
    }
}

extension GetAdminSettingsResponse.Bandwidth: ProtobufDecodable, ProtobufEncodable {
    typealias ProtobufType = Videoconference_V1_Bandwidth
    init(pb: Videoconference_V1_Bandwidth) {
        self.bandwidthStatus = pb.bandwidthStatus
        self.upstreamBandwidth = pb.mobileUpstreamBandwidth
        self.downstreamBandwidth = pb.mobileDownstreamBandwidth
    }

    func toProtobuf() -> Videoconference_V1_Bandwidth {
        var pb = ProtobufType()
        pb.bandwidthStatus = bandwidthStatus
        pb.mobileUpstreamBandwidth = upstreamBandwidth
        pb.mobileDownstreamBandwidth = downstreamBandwidth
        return pb
    }
}
