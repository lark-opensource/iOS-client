//
//  LoggerService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/19.
//

import Foundation

final class LoggerService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtUtilLogger]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let message = params["logMessage"] as? String else {
            return
        }
        Logger.info("RichTextView js log: \(message)")
    }
}
