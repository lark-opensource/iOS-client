//
//  OpenAPIKeyboardParams.swift
//  LarkOpenAPIModel
//
//  Created by Nicholas Tau on 2021/5/7.
//

import Foundation
import TTMicroApp
import OPPluginManagerAdapter
import LarkOpenAPIModel

final class OpenAPIKeyboardParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userOptionWithJsonKey: "inputId", defaultValue: 0)
    public var inputId: Int
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "inputId", defaultValue: "")
    public var stringInputId: String
    
    public let model: BDPInputViewModel?
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "frameId", defaultValue: 0)
    public var frameId: Int
    
    public let originalParams: [AnyHashable : Any]
    
    public required init(with params: [AnyHashable : Any]) throws {
        model = try BDPInputViewModel(dictionary: params)
        originalParams = params
        try super.init(with: params)
        
        if OpenAPIUtils.useNewParamsValidation {
            let id = params["inputId"]
            inputId = id as? Int ?? 0
            stringInputId = id as? String ?? ""
        }
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        if OpenAPIUtils.useNewParamsValidation {
            return [_frameId]
        } else {
            return [_inputId, _frameId, _stringInputId]
        }
    }

}

final class OpenAPISetKeyboardParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "inputId")
    public var inputId: Int
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "cursor", defaultValue: 0)
    public var cursor: Int
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "value", defaultValue: "")
    public var value: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_inputId, _value, _cursor]
    }
}

final class OpenAPIKeyboardResult: OpenAPIBaseResult {
    public var inputId: Int

    public init(inputId: Int) {
        self.inputId = inputId
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["inputId": inputId]
    }
}

