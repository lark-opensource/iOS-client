//
//  GeoLocationStopHandler.swift
//  Lark
//
//  Created by ChalrieSu on 19/03/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import WebBrowser
import Swinject

class GeoLocationStopHandler: JsAPIHandler {

    var needAuthrized: Bool {
        return true
    }
    private let locationHandler: GeoLocationHandler
    var functionName: String = ""
    var callback: WorkaroundAPICallBack?

    private let resolver: Resolver

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let functionName = args["callback"] as? String else {
            GeoLocationHandler.logger.error("GeoLocationStopHandler error, has no callback")
            return
        }
        self.functionName = functionName
        self.callback = callback
        let sceneID = args["sceneId"] as? String ?? ""
        locationHandler.stopLocation(sceneID: sceneID)
    }

    init(resolver: Resolver, locationHandler: GeoLocationHandler, api: WebBrowser) {
        self.resolver = resolver
        self.locationHandler = locationHandler
        self.locationHandler.stopLocactionBlock = { [weak self] result in
            self?.callback?.asyncNotify(event: self?.functionName, data: result)
        }
    }
}
