//
//  BaseLoadingPlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/15.
//  

import Foundation
import SKCommon

protocol SKLoadingPluginProtocol: AnyObject {
    func hidLoading(params: [String: Any])
}

class SKLoadingPlugin: JSServiceHandler {
    weak var pluginProtocol: SKLoadingPluginProtocol?
    var logPrefix: String = ""

    var handleServices: [DocsJSService] = [.utilHideLoading]
    func handle(params: [String: Any], serviceName: String) {
        guard serviceName == DocsJSService.utilHideLoading.rawValue else {
            skAssertionFailure("can not handler \(serviceName)")
            return
        }
        skInfo(logPrefix + "did receive hide loading")
        pluginProtocol?.hidLoading(params: params)
    }
}
