//
//  NotifyService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/19.
//

import Foundation

final class NotifyService {
    weak var jsEngine: RichTextViewJSEngine?
    init(jsEngine: RichTextViewJSEngine) {
        self.jsEngine = jsEngine
    }
}

extension NotifyService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtNotifyReady]
    }

    func handle(params: [String: Any], serviceName: String) {
        jsEngine?.jsContextDidReady()
    }
}
