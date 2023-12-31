//
//  BTAdPermJSService.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/14.
//

import SKFoundation
import SKCommon
import SKUIKit
import SKInfra

final class BTAdPermJSService: BaseJSService {
}

extension BTAdPermJSService: DocsJSServiceHandler {
    
    var container: BTContainer? {
        get {
            return (registeredVC as? BitableBrowserViewController)?.container
        }
    }
    
    var handleServices: [DocsJSService] {
        return [
            .upgradeBaseCompleted,
            .showProModal]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        switch DocsJSService(serviceName) {
        case .upgradeBaseCompleted:
            if let container = container {
                container.getOrCreatePlugin(BTContainerAdPermPlugin.self).handleAdPermUpdateCompletion(params: params)
            } else {
                DocsLogger.error("invalid container")
            }
            break
        case .showProModal:
            if let container = container {
                container.getOrCreatePlugin(BTContainerAdPermPlugin.self).handleShowProModel(params)
            } else {
                DocsLogger.error("invalid container")
            }
            break
        default:
            ()
        }
    }
}
