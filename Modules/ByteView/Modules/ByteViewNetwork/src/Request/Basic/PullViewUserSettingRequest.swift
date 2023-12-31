//
//  File.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/3/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_PullViewUserSettingRequest
public struct PullViewUserSettingRequest {
    public static let command: NetworkCommand = .rust(.pullViewUserSetting)
    public typealias Response = PullViewUserSettingResponse

    public init() {}
}

public struct PullViewUserSettingResponse {
    public init(userSetting: ViewUserSetting, deviceSetting: ViewDeviceSetting) {
        self.userSetting = userSetting
        self.deviceSetting = deviceSetting
    }

    public var userSetting: ViewUserSetting

    public var deviceSetting: ViewDeviceSetting
}

extension PullViewUserSettingRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PullViewUserSettingRequest
    func toProtobuf() throws -> Videoconference_V1_PullViewUserSettingRequest {
        ProtobufType()
    }
}

extension PullViewUserSettingResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PullViewUserSettingResponse

    init(pb: Videoconference_V1_PullViewUserSettingResponse) {
        self.userSetting = .init(pb: pb.userSetting)
        self.deviceSetting = .init(pb: pb.deviceSetting)
    }
}
