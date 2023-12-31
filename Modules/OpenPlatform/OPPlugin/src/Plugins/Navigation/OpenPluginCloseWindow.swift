//
//  OpenPluginCloseWindow.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/4/19.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import WebBrowser
import LarkContainer

final class OpenPluginCloseWindow: OpenBasePlugin {
    func closeWindow(context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        let api = context.controller as? WebBrowser
        let result = api?.closeBrowser() ?? false
        let code = result ? OpenAPICommonErrorCode.ok : OpenAPICommonErrorCode.unknown
        callback(.failure(error: OpenAPIError(code: code)))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "closeWindow", pluginType: Self.self) { (this, _, context, callback) in
            
            this.closeWindow(context: context, callback: callback)
        }
    }
}
