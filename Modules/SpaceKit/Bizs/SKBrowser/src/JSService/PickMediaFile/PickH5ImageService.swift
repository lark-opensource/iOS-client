//
//  PickH5ImageService.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/11/15.
//

import Foundation
import SKCommon
import SKInfra

final class PickH5ImageService: NSObject {

    weak var ui: BrowserUIConfig?

    weak var model: BrowserModelConfig?

    private weak var resolver: DocsResolver?

    lazy private var newCacheAPI: NewCacheAPI = resolver!.resolve(NewCacheAPI.self)!

    private lazy var pickImagePlugin: BasePickH5ImagePlugin = {
        let config = BasePickH5ImagePluginConfig(newCacheAPI)
        let plugin = BasePickH5ImagePlugin(config)
        plugin.objToken = self.model?.browserInfo.docsInfo?.objToken
        plugin.pluginProtocol = self
        return plugin
    }()

    init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, _ resolver: DocsResolver = DocsContainer.shared) {
        self.ui = ui
        self.model = model
        self.resolver = resolver
    }
}

extension PickH5ImageService: DocsJSServiceHandler {

    var handleServices: [DocsJSService] {
        return pickImagePlugin.handleServices
    }

    func handle(params: [String: Any], serviceName: String) {
        pickImagePlugin.handle(params: params, serviceName: serviceName)
    }

}

extension PickH5ImageService: BasePickH5ImagePluginProtocol {

    func pickImagePluginFinishJsInsert(plugin: BasePickH5ImagePlugin) {

    }

    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        self.model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
}
