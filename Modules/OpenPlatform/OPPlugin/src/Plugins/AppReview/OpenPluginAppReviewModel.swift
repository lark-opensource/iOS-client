//
//  OpenPluginAppReviewModel.swift
//  OPPlugin
//
//  Created by xiangyuanyuan on 2021/12/23.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIEndAppReviewParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "trace", validChecker: OpenAPIValidChecker.notEmpty)
    public var trace: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "app_id", validChecker: OpenAPIValidChecker.notEmpty)
    public var appId: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_appId, _trace]
    }
}
