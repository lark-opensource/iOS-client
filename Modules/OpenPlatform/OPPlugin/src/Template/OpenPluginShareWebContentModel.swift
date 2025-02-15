//
//  OpenPluginShareWebContentModel.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE. DO NOT MODIFY!!!
//  TICKETID: 23767
//  

import Foundation
import LarkOpenAPIModel


// MARK: - OpenPluginShareWebContentRequest
final class OpenPluginShareWebContentRequest: OpenAPIBaseParams {
    
    /// description: 分享组件的标题
    @OpenAPIOptionalParam(
            jsonKey: "title")
    public var title: String?
    
    /// description: 需要分享的网页链接
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "url")
    public var url: String
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_title, _url, ];
    }
}

// MARK: - OpenPluginShareWebContentResponse
final class OpenPluginShareWebContentResponse: OpenAPIBaseResult {
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        let result: [AnyHashable : Any] = [:]
        return result
    }
}
