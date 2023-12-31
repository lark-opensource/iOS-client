//
//  GetJoinedDeviceInfoRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2023/9/12.
//

import Foundation
import RustPB

/// - Videoconference_V1_GetJoinedDevicesInfoRequest
/// 该请求走的是Rust缓存，所以速度理论上很快（测试在2ms左右）
public struct GetJoinedDeviceInfoRequest {
    public static let command: NetworkCommand = .rust(.getJoinedDevicesInfo)
    public typealias Response = GetJoinedDeviceInfoResponse

    public init() {}
}

/// - Videoconference_V1_GetJoinedDevicesInfoResponse
public struct GetJoinedDeviceInfoResponse {
    public var devices: [JoinedDeviceInfo] = []

    public var changeTime: String
}

extension GetJoinedDeviceInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetJoinedDevicesInfoRequest
    func toProtobuf() throws -> Videoconference_V1_GetJoinedDevicesInfoRequest {
        return ProtobufType()
    }
}

extension GetJoinedDeviceInfoResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetJoinedDevicesInfoResponse
    init(pb: Videoconference_V1_GetJoinedDevicesInfoResponse) throws {
        self.devices = pb.devices.map { JoinedDeviceInfo(pb: $0) }
        self.changeTime = pb.changeTime
    }
}

public struct JoinedDeviceInfo {
    public var meetingID: String
    public var userID: String
    public var deviceID: String
    public var deviceName: String
    public var osType: OsType
    public var joinTime: String

    public enum OsType: Int {
        case unknown // = 0
        case mac // = 1
        case windows // = 2
        case android // = 3
        case iphone // = 4
        case ipad // = 5
        case web // = 6
        case linux // = 7
        case webMobile // = 8
    }

    public var pbType: Videoconference_V1_JoinedDeviceInfo {
        var pbType = Videoconference_V1_JoinedDeviceInfo()
        pbType.meetingID = meetingID
        pbType.userID = userID
        pbType.deviceID = deviceID
        pbType.deviceName = deviceName
        pbType.osType = .init(rawValue: osType.rawValue) ?? .unknown
        pbType.joinTime = joinTime
        return pbType
    }

    public init(meetingID: String,
                userID: String,
                deviceID: String,
                deviceName: String,
                osType: OsType,
                joinTime: String) {
        self.meetingID = meetingID
        self.userID = userID
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.osType = osType
        self.joinTime = joinTime
    }

    public init(pb: Videoconference_V1_JoinedDeviceInfo) {
        self.meetingID = pb.meetingID
        self.userID = pb.userID
        self.deviceID = pb.deviceID
        self.deviceName = pb.deviceName
        self.osType = .init(rawValue: pb.osType.rawValue) ?? .unknown
        self.joinTime = pb.joinTime
    }
}

public extension JoinedDeviceInfo {
    public var defaultDeviceName: String {
        switch osType {
        case .mac: return "Mac"
        case .windows: return "Windows"
        case .android: return "Android"
        case .iphone: return "iPhone"
        case .ipad: return "iPad"
        case .web: return "Web"
        case .linux: return "Linux"
        case .webMobile: return "WebMobile"
        default: return ""
        }
    }
}
