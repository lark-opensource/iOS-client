//
//  TranslateWebXMLRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 描述： 内容翻译接口，可翻译网页和纯文本
/// - 场景： 网页翻译、划词翻译、实时翻译
/// - Im_V1_TranslateWebXMLRequest
public struct TranslateWebXMLRequest {
    public static let command: NetworkCommand = .rust(.translateWebXml)
    public typealias Response = TranslateWebXMLResponse

    public init(srcContents: [String], srcLanguage: String, targetLanguage: String) {
        self.srcContents = srcContents
        self.srcLanguage = srcLanguage
        self.targetLanguage = targetLanguage
    }

    /// 原文, 段落分隔
    public var srcContents: [String]

    public var srcLanguage: String

    public var targetLanguage: String
}

/// - Im_V1_TranslateWebXMLResponse
public struct TranslateWebXMLResponse {

    /// 译文，段落分隔
    public var targetContents: [String]
}

extension TranslateWebXMLRequest: RustRequestWithResponse {
    typealias ProtobufType = Im_V1_TranslateWebXMLRequest
    func toProtobuf() throws -> Im_V1_TranslateWebXMLRequest {
        var request = ProtobufType()
        request.srcContents = srcContents
        request.srcLanguage = srcLanguage
        request.trgLanguage = targetLanguage
        request.contentType = .textContentType
        return request
    }
}

extension TranslateWebXMLResponse: RustResponse {
    typealias ProtobufType = Im_V1_TranslateWebXMLResponse
    init(pb: Im_V1_TranslateWebXMLResponse) throws {
        self.targetContents = pb.trgContents
    }
}
