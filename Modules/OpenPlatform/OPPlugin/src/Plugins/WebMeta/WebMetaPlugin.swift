//
//  WebMetaPlugin.swift
//  OPPlugin
//
//  Created by luogantong on 2022/5/15.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import WebBrowser
import LarkContainer

final class OpenWebMetaPlugin : OpenBasePlugin {
    
    func updateMeta(params: OpenAPIWebMetaParams, context: OpenAPIContext, callback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)) {
        if let browser = context.controller as? WebBrowser {
            browser.updateMetas(metas: params.metas)
        }
        callback(.success(data: nil))
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "updateMeta", pluginType: Self.self, paramsType: OpenAPIWebMetaParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.updateMeta(params: params, context: context, callback: callback)
        }
    }
}
