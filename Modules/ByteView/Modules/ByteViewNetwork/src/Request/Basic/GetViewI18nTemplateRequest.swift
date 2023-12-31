//
//  GetViewI18nTemplateRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 客户端从rust-sdk拉取i18n模版
/// - GET_VIEW_I18N_TEMPLATE = 2326
/// - Videoconference_V1_GetViewI18nTemplateRequest
public struct GetViewI18nTemplateRequest {
    public static let command: NetworkCommand = .rust(.getViewI18NTemplate)
    public typealias Response = GetViewI18nTemplateResponse

    public init(keys: [String]) {
        self.keys = keys
    }

    public var keys: [String]
}

/// Videoconference_V1_GetViewI18nTemplateResponse
public struct GetViewI18nTemplateResponse {
    ///map<key,template>
    public var templates: [String: String]
}

extension GetViewI18nTemplateRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetViewI18nTemplateRequest
    func toProtobuf() throws -> Videoconference_V1_GetViewI18nTemplateRequest {
        var request = ProtobufType()
        request.keys = keys
        return request
    }
}

extension GetViewI18nTemplateResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetViewI18nTemplateResponse
    init(pb: Videoconference_V1_GetViewI18nTemplateResponse) throws {
        self.templates = pb.templates
    }
}
