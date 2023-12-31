//
//  SKNotityReadyJsHandler.swift
//  SpaceKit
//
//  Created by Webster on 2019/5/31.
//

import Foundation
import SKCommon

extension DocsJSService {
    static let skNotifyReady = DocsJSService(rawValue: "biz.notify.ready")
}

protocol SKNotifyReadyJsDelegate: AnyObject {
    func hasUpdateJsReady(_ ready: Bool, handler: SKNotifyReadyJsHandler)
}

class SKNotifyReadyJsHandler: JSServiceHandler {
    weak var delegate: SKNotifyReadyJsDelegate?
    var handleServices: [DocsJSService] = [.skNotifyReady]
    func handle(params: [String: Any], serviceName: String) {
        delegate?.hasUpdateJsReady(true, handler: self)
    }
}
