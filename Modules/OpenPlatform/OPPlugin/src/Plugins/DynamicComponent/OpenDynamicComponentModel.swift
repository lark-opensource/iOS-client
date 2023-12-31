//
//  OpenDynamicComponentModel.swift
//  OPPlugin
//
//  Created by laisanpin on 2022/5/31.
//

import Foundation
import LarkOpenAPIModel
final class OpenLoadPluginParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "pluginId", defaultValue: "", validChecker: {
        !$0.isEmpty
    })
    public var pluginId: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "version", defaultValue: "", validChecker: {
        !$0.isEmpty
    })
    public var version: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "webviewId", defaultValue: 0, validChecker: nil)
    public var webviewId: Int

    public convenience init(pluginId: String,
                            version: String,
                            webviewId: Int) throws {
        let dict: [String: Any] = ["pluginId" : pluginId,
                                   "version" : version,
                                   "webviewId" : webviewId]
        // init dict here
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // set checkable properties here
        return [_pluginId, _version, _webviewId]
    }
}

final class OpenAPILoadPluginResult: OpenAPIBaseResult {
    public let version: String

    public init(version: String) {
        self.version = version
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["version" : self.version]
    }
}
