//
//  GeoLocationStartHandler.swift
//  Lark
//
//  Created by ChalrieSu on 19/03/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import WebBrowser
import Swinject

class GeoLocationStartHandler: JsAPIHandler {

    var needAuthrized: Bool {
        return true
    }
    private let locationHandler: GeoLocationHandler

    var functionName: String = ""
    var callback: WorkaroundAPICallBack?
    private let resolver: Resolver

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let functionName = args["callback"] as? String else {
            GeoLocationHandler.logger.error("GeoLocationStartHandler error, has no callback")
            return
        }
        let useCache = args["useCache"] as? Bool ?? false
        let sceneID = args["sceneId"] as? String ?? ""
        let interval = args["interval"] as? Int ?? 2000

        self.functionName = functionName
        self.callback = callback
        locationHandler.startLocation(shouldUseCache: useCache, interval: interval, sceneID: sceneID)
    }

    init(resolver: Resolver, locationHandler: GeoLocationHandler, api: WebBrowser) {
        self.resolver = resolver
        self.locationHandler = locationHandler
        self.locationHandler.startLocationBlock = { [weak self] result in
            self?.callback?.asyncNotify(event: self?.functionName, data: result)
        }
    }
}
