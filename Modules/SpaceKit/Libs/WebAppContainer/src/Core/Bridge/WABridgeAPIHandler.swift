//
//  WABridgeAPIHandler.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/11/14.
//

import Foundation
import LKCommonsLogging
import LarkWebViewContainer

final class WABridgeAPIHandler: WebAPIHandler {
    static let logger = Logger.log(WABridgeAPIHandler.self, category: WALogger.TAG)

    weak var dispatcher: WABridgeServiceDispatcher?

    override var shouldInvokeInMainThread: Bool {
        false
    }

    init(dispatcher: WABridgeServiceDispatcher?) {
        self.dispatcher = dispatcher
    }

    override func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        guard let dispatcher = dispatcher else {
            Self.logger.error("APIHandler's dispatcher is nil")
            return
        }
        dispatcher.dispatch(message: message.apiName, message.data, callback: callback)
    }
    
    deinit {
        Self.logger.info("WABridgeAPIHandler deinit")
    }
}
