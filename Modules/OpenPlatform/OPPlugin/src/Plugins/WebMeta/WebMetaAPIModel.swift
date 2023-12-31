//
//  WebMetaAPIModel.swift
//  OPPlugin
//
//  Created by luogantong on 2022/5/15.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIWebMetaParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "metas",
                          defaultValue: [])
    public var metas: [Dictionary<String, Any>]
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_metas]
    }
}
