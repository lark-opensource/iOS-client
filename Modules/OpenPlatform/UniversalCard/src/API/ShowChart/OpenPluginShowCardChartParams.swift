//
//  OpenPluginShowCardChartParams.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation
import LarkOpenAPIModel

final class OpenPluginShowCardChartParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "elementID")
    var elementID: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "isTranslateElement")
    var isTranslateElement: Bool
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_elementID, _isTranslateElement]
    }
}
