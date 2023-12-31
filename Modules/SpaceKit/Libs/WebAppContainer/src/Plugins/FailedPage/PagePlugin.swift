//
//  PagePlugin.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/28.
//

import Foundation
import WebKit

class PagePlugin: WAPlugin {
    
    override var pluginType: WAPluginType {
        .UI
    }
    
    required init(host: WAPluginHost) {
        super.init(host: host)
        host.lifeCycleObserver.addListener(self)
    }
}

extension PagePlugin: WAContainerLifeCycleListener {
    func container(_ container: WAContainer, didFail navigation: WKNavigation!, withError error: Error) {
        Self.logger.error("container didFaild", error: error)
        self.host?.container.loader?.updateLoadStatus(.error(WALoadError.webError(showPage: false, err: error)))
    }
    
    func containerWebContentProcessDidTerminate(_ container: WAContainer) {
        Self.logger.error("container didTerminate")
        self.host?.container.loader?.updateLoadStatus(.error(WALoadError.blank))
    }
}
