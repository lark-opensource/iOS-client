//
//  NotifyClearDoneService.swift
//  SKBrowser
//
//  Created by GuoXinyi on 2022/7/15.
//

import Foundation
import SKCommon
import SKFoundation

class NotifyClearDoneService: BaseJSService { }

extension NotifyClearDoneService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.notifyClearDone]
    }
    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("window.clearDone Call", component: LogComponents.fileOpen)
        model?.setClearDoneFinish(true)
    }
}
