//
//  OpenAPITextAreaModel.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/5/7.
//

import Foundation
import TTMicroApp
import LarkOpenAPIModel
import OPPluginManagerAdapter

class OpenAPITextAreaBaseParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "inputId")
    public var componentID: String

    // declare your properties here
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // add your checkable properties here
        return [_componentID]
    }

}

final class OpenAPIUpdateTextAreaParams: OpenAPITextAreaBaseParams {

    public let dict: [AnyHashable: Any]

    public required init(with params: [AnyHashable : Any]) throws {
        self.dict = params
        try super.init(with: params)
    }
}

final class OpenAPIShowTextAreaKeyBoardParams: OpenAPITextAreaBaseParams {

    @OpenAPIRequiredParam(userOptionWithJsonKey: "cursor", defaultValue: 0)
    public var cursor: Int

    @OpenAPIRequiredParam(userOptionWithJsonKey: "selectionStart", defaultValue: 0)
    public var selectionStart: Int

    @OpenAPIRequiredParam(userOptionWithJsonKey: "selectionEnd", defaultValue: 0)
    public var selectionEnd: Int

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // add your checkable properties here
        var properties = super.autoCheckProperties
        properties.append(contentsOf: [_cursor, _selectionEnd, _selectionStart])
        return properties
    }
}

final class OpenAPIInsertTextAreaParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "_inputId")
    public var componentID: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "frameId", defaultValue: 0)
    public var webViewID: Int

    public let model: BDPTextAreaModel

    public required init(with params: [AnyHashable : Any]) throws {
        var model: BDPTextAreaModel?
        do {
            model = try BDPTextAreaModel(dictionary: params)
        } catch {
            OpenAPIInsertTextAreaParams.logger.error("model init failed", tag: "OpenAPIInsertTextAreaParams", additionalData: nil, error: error)
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setError(error)
            .setOuterMessage("model init failed")
        }
        guard let model = model else {
            throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
            .setOuterMessage("model init failed")
        }
        self.model = model
        try super.init(with: params)
    }

    // declare your properties here

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // add your checkable properties here
        return [_componentID, _webViewID]
    }

}

final class OpenAPITextAreaResult: OpenAPIBaseResult {
    public let componentID: String

    public init(componentID: String) {
        self.componentID = componentID
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["inputId": componentID]
    }
}
