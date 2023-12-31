//
//  UtilOpenDocService.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/12/20.
//

import Foundation
import WebKit
import SKCommon
import SKFoundation

public final class UtilOpenDocService: BaseJSService {

}

extension UtilOpenDocService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilBeginEdit, .reload]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilBeginEdit.rawValue:
            ui?.openDocAgent.didBeginEdit()
        case DocsJSService.reload.rawValue:
            if let urlStr = params["docUrl"] as? String, let docUrl = URL(string: urlStr) {
                ui?.displayConfig.rerenderWebview(with: docUrl)
                DocsLogger.info("reload with url: \(urlStr.encryptToShort)")
            } else {
                DocsLogger.error("reload url is nil")
            }
        default:
            return
        }
    }
}
