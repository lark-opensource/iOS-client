//
//  GetSettingsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Settings V3
/// - Settings_V1_GetSettingsRequest
public struct GetSettingsRequest {
    public static let command: NetworkCommand = .rust(.getSettings)
    public typealias Response = GetSettingsResponse

    public init(fields: [String]) {
        self.fields = fields
    }

    /// !!! 拿到的FG都是不走AB实验的值
    /// lark_features 获取当前数据库中的FG
    /// initialized_lark_features 获取初始化 SDK FG 的 FG
    public var fields: [String]
}

/// - Settings_V1_GetSettingsResponse
public struct GetSettingsResponse {

    public var fieldGroups: [String: String]
}

extension GetSettingsRequest: RustRequestWithResponse {
    typealias ProtobufType = Settings_V1_GetSettingsRequest

    func toProtobuf() throws -> Settings_V1_GetSettingsRequest {
        var request = Settings_V1_GetSettingsRequest()
        request.fields = fields
        return request
    }
}

extension GetSettingsResponse: RustResponse {
    typealias ProtobufType = Settings_V1_GetSettingsResponse
    init(pb: Settings_V1_GetSettingsResponse) throws {
        self.fieldGroups = pb.fieldGroups
    }
}
