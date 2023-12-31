//
//  OpenAPIBase64ToTempFilePathParams.swift
//  OPPlugin
//
//  Created by xiangyuanyuan on 2021/11/29.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel

final class OpenAPIBase64ToTempFilePathParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "base64Data", validChecker: { !$0.isEmpty })
    var base64Data: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_base64Data]
    }
}

final class OpenAPIBase64ToTempFilePathResult: OpenAPIBaseResult {
    public var tempFilePath: String
    
    public init(tempFilePath: String){
        self.tempFilePath = tempFilePath
    }
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["tempFilePath": tempFilePath]
    }
}

