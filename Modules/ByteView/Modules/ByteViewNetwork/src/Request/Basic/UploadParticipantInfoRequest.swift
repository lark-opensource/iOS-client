//
//  UploadParticipantInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 上报参会人信息到admin
/// - ServerPB_Videochat_UploadParticipantInfoRequest
public struct UploadParticipantInfoRequest {
    public static let command: NetworkCommand = .server(.uploadParticipantInfo)

    public init(meetingID: String, networkType: NetworkType, internalIP: String, useRtcProxy: Bool) {
        self.meetingID = meetingID
        self.networkType = networkType
        self.internalIp = internalIP
        self.useRtcProxy = useRtcProxy
    }

    public var meetingID: String

    public var networkType: NetworkType

    public var internalIp: String

    public var useRtcProxy: Bool

    /// ServerPB_Videochat_NetworkType
    public enum NetworkType: Int, Hashable, CustomStringConvertible {
        case unknown // = 0
        case wired // = 1
        case wireless // = 2
        case networkType2G // = 3
        case networkType3G // = 4
        case networkType4G // = 5
        case networkType5G // = 6
        case cellular // = 7

        public var description: String {
            switch self {
            case .unknown:
                return "unknown"
            case .wired:
                return "wired"
            case .wireless:
                return "wireless"
            case .networkType2G:
                return "networkType2G"
            case .networkType3G:
                return "networkType3G"
            case .networkType4G:
                return "networkType4G"
            case .networkType5G:
                return "networkType5G"
            case .cellular:
                return "cellular"
            }
        }
    }
}

extension UploadParticipantInfoRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_UploadParticipantInfoRequest

    func toProtobuf() throws -> ServerPB_Videochat_UploadParticipantInfoRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.networkType = .init(rawValue: networkType.rawValue) ?? .unknown
        request.internalIp = internalIp
        request.useRtcProxy = useRtcProxy
        return request
    }
}
