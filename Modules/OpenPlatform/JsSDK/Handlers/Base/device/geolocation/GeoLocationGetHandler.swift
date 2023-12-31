//
//  GeoLocationGetHandler.swift
//  Lark
//
//  Created by ChalrieSu on 19/03/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import WebBrowser
import Swinject

class GeoLocationGetHandler: JsAPIHandler {

    var needAuthrized: Bool {
        return true
    }
    private let locationHandler: GeoLocationHandler
    var functionName: String = ""
    var callback: WorkaroundAPICallBack?

    private let resolver: Resolver

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let functionName = args["callback"] as? String else {
            GeoLocationHandler.logger.error("GeoLocationGetHandler error, has no callback")
            return
        }
        let useCache = args["useCache"] as? Bool ?? false
        self.functionName = functionName
        self.callback = callback
        locationHandler.getLocation(shouldUseCache: useCache)
    }

    init(resolver: Resolver, locationHandler: GeoLocationHandler, api: WebBrowser) {
        self.resolver = resolver
        self.locationHandler = locationHandler
        self.locationHandler.getLocationBlock = { [weak self] result in
            self?.callback?.asyncNotify(event: self?.functionName, data: result)
        }
    }
}
