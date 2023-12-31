//
//  OpenAPISentryReportModel.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/6.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPISentryReportModel: OpenAPIBaseParams {

    @OpenAPIOptionalParam(jsonKey: "url")
    public var urlString: String?

    @OpenAPIOptionalParam(jsonKey: "method")
    public var methodString: String?

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "data")
    public var data: NSDictionary

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "header")
    public var headerDict: NSDictionary

    public convenience init(urlString: String, methodString: String, data: NSDictionary, headerDict: NSMutableDictionary) throws {
        let dict: [String: Any] = ["urlString": urlString, "methodString": methodString, "data": data, "headerDict": headerDict]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_urlString, _methodString, _data, _headerDict]
    }
}
