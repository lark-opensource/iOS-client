//
//  OpenAPINativeAppParams.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/6/22.
//

import Foundation
import LarkOpenAPIModel

public class OpenAPINativeAppParams: OpenAPIBaseParams {
     
    public var params: [AnyHashable: Any]
    
    public required init(with params: [AnyHashable: Any]) throws {
        self.params = params
        try super.init(with: params)
    }
}
