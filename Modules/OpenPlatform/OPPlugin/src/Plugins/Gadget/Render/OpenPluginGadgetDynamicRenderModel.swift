//
//  OpenPluginGadgetDynamicRenderModel.swift
//  OPPluginBiz
//
//  Created by baojianjun on 2023/6/30.
//

import Foundation
import LarkOpenAPIModel


// MARK: getCurrentRoute

final class OpenPluginGetCurrentRouteResult: OpenAPIBaseResult {
    
    let route: String?
    
    init(route: String?) {
        self.route = route
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        [
            "route": route ?? ""
        ]
    }
}
