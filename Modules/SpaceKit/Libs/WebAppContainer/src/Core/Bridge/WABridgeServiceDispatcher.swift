//
//  WABridgeServiceDispatcher.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation
import LarkWebViewContainer
import ThreadSafeDataStructure
import LKCommonsLogging

class WABridgeServiceDispatcher {
    
    static let logger = Logger.log(WABridgeServiceDispatcher.self, category: WALogger.TAG)

    private let logBlackList: Set<String> = [
        WABridgeName.logger.rawValue
    ]
    
    private let handlers: SafeDictionary<String, WABridgeHandler> = [:] + .readWriteLock
    private let handerQueue = DispatchQueue(label: "webapp.\(UUID().uuidString)")
    
    func dispatch(message: String, _ params: [String: Any], callback: APICallbackProtocol? = nil, isSimulate: Bool = false) {
        if !logBlackList.contains(message) {
            Self.logger.info("receive js call:\(message)")
        }
        handerQueue.async {
            self.handlers.safeRead(for: message) { handler in
                guard let handler else { return }
                DispatchQueue.main.async {
                    let invocation = WABridgeInvocation(name: message,
                                                        params: params,
                                                        callback: callback)
                    handler.handle(invocation: invocation)
                }
            }
        }
    }
    
    @discardableResult
    func register(handler: WABridgeHandler) -> WABridgeHandler {
        self.handlers.updateValue(handler, forKey: handler.name.rawValue)
        return handler
        
    }

    func unRegister(handlers:  WABridgeHandler) {
        self.handlers.removeValue(forKey: handlers.name.rawValue)
    }
    
    func resolve<H: WABridgeHandler>(_ service: H.Type) -> H? {
        let handler = handlers.first { type(of: $0) == service }
        return handler as? H
    }
}
