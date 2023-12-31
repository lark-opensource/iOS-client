//
//  GetAdminMediaServerSettings.swift
//  ByteViewNetwork
//
//  Created by liujianlong on 2022/2/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

public struct GetAdminMediaServerSettingsRequest {
    public static let command: NetworkCommand = .rust(.getAdminMediaServerSeetings)
    public typealias Response = GetAdminMediaServerSettingsResponse
    public init() {}
}

public struct GetAdminMediaServerSettingsResponse: Codable, Equatable {
    public init(enablePrivateMedia: Bool) {
        self.enablePrivateMedia = enablePrivateMedia
    }
    public var enablePrivateMedia: Bool
}

extension GetAdminMediaServerSettingsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetAdminMediaServerSettingsRequest
    func toProtobuf() throws -> ProtobufType {
        let request = ProtobufType()
        return request
    }
}


extension GetAdminMediaServerSettingsResponse: RustResponse, ProtobufEncodable {
    typealias ProtobufType = Videoconference_V1_GetAdminMediaServerSettingsResponse

    init(pb: ProtobufType) {
        self.init(enablePrivateMedia: pb.enablePrivateMedia)
    }

    func toProtobuf() -> ProtobufType {
        var pb = ProtobufType()
        pb.enablePrivateMedia = self.enablePrivateMedia
        return pb
    }
}
