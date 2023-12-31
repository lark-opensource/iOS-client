//
//  OpenPluginShareAppMessageDirectlyModel.swift
//  OPPlugin
//
//  Created by bytedance on 2021/6/16.
//

import UIKit
import LarkOpenAPIModel

class OpenPluginShareAppMessageDirectlyParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "title", defaultValue: "")
    public var title: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "path", defaultValue: "")
    public var path: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "linkTitle", defaultValue: "")
    public var linkTitle: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "extra", defaultValue: [:])
    public var extra: [String: Any]
    @OpenAPIRequiredParam(userOptionWithJsonKey: "withShareTicket", defaultValue: false)
    public var withShareTicket: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "templateId", defaultValue: "")
    public var templateId: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "desc", defaultValue: "")
    public var desc: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "PCPath", defaultValue: "")
    public var PCPath: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "PCMode", defaultValue: "")
    public var PCMode: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "imageUrl", defaultValue: "")
    public var imageUrl: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "channel", defaultValue: "")
    public var channel: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_title, _path, _linkTitle, _extra, _withShareTicket, _templateId, _desc, _PCPath, _PCMode, _imageUrl]
    }
}
final class OpenPluginShareAppMessageDirectlyResult: OpenAPIBaseResult {
    public let data: [AnyHashable:Any]
    public init(data: [AnyHashable:Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return data
    }
}
