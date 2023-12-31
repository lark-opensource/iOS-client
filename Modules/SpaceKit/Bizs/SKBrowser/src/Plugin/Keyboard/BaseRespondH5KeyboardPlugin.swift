//
//  BaseRespondH5KeyboardService.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/19.
//  

import Foundation
import SKCommon

struct SKBaseRespondH5KeyboardPluginConfig {
    weak var responder: SKBrowserUIResponder?
    var trigger: String
}

class SKBaseRespondH5KeyboardPlugin: JSServiceHandler {
    var logPrefix: String = ""
    var config: SKBaseRespondH5KeyboardPluginConfig
    init(config: SKBaseRespondH5KeyboardPluginConfig) {
        self.config = config
    }
    var handleServices: [DocsJSService] {
        return [.utilKeyboard]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard serviceName == DocsJSService.utilKeyboard.rawValue else {
            skAssertionFailure("can not handle \(serviceName)")
            return
        }
        config.responder?.becomeFirst(trigger: config.trigger)
    }

}
