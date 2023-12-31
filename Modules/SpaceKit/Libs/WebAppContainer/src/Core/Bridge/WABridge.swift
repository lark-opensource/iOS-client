//
//  WABridge.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation
import LarkWebViewContainer
import LKCommonsLogging

public class WABridge {
    static let logger = Logger.log(WABridge.self, category: WALogger.TAG)

    private(set) var serviceMap: [WABridgeServiceType: [WABridgeService]] = [:]
    
    let dispatcher = WABridgeServiceDispatcher()
    private var lkwAPIHandler: WebAPIHandler?
    private weak var lkwBridge: LarkWebViewBridge?
    public private(set) weak var webview: LarkWebView?
    public private(set) weak var context: WABridgeServiceContext?
    private let lock = NSLock()
    static let logPrefixCount = 20
    
    public init(webview: LarkWebView) {
        self.webview = webview
    }
    
    deinit {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        self.serviceMap.values.forEach {services in
            services.forEach {
                $0.onDettach()
            }
        }
        self.serviceMap.removeAll()
    }
    
    public func setup(context: WABridgeServiceContext) {
        Self.logger.info("setup bridge for:\(context.bizName)")
        self.context = context
        setupBridge()
    }
    
    private func setupBridge() {
        guard let webview else {
            Self.logger.error("webview is nil")
            return
        }
        let lkwBridge = webview.lkwBridge
        lkwBridge.registerBridge()
        let commonHandler = WABridgeAPIHandler(dispatcher: self.dispatcher)
        self.lkwBridge = lkwBridge
        self.lkwAPIHandler = commonHandler
    }
    
    public func register(service: WABridgeService) {
        lock.lock()
        defer {
            lock.unlock()
        }
        var services: [WABridgeService]
        if let list = serviceMap[service.serviceType] {
            services = list
        } else {
            services = []
        }
        services.append(service)
        serviceMap[service.serviceType] = services
        service.onAttach()
        
        let handlers = service.getBridgeHandlers()
        handlers.forEach {
            register(handler: $0)
        }
    }
    
    public func unRegisterService(for serviceType: WABridgeServiceType) {
        lock.lock()
        defer {
            lock.unlock()
        }
        var removeCount = 0
        if let services = serviceMap[serviceType] {
            services.forEach {
                $0.onDettach()
                
            }
            removeCount = services.count
        }
        serviceMap.removeValue(forKey: serviceType)
        Self.logger.info("unRegisterService for type:\(serviceType.rawValue) \(removeCount)")
        
    }
    
    func register(handler: WABridgeHandler) {
        if let lkwAPIHandler = self.lkwAPIHandler {
            lkwBridge?.registerAPIHandler(lkwAPIHandler, name: handler.name.rawValue)
        }
        dispatcher.register(handler: handler)
    }
    
    func unRegister(handler: WABridgeHandler) {
        lkwBridge?.unregisterAPIHandler(handler.name.rawValue)
        dispatcher.unRegister(handlers: handler)
    }
    
    public func eval(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        self.webview?.evaluateJavaScript(script) { (obj ,error) in
            completion?(obj, error)
            if let error {
                Self.logger.error("eval error, script:\(script.prefix(Self.logPrefixCount))", error: error)
            }
        }
    }
    
    public func eval(_ function: String, params: [String: Any]?, completion:((Any?, Error?) -> Void)? = nil) {
        autoreleasepool {
            let paramsStr = params?.toJSONString() ?? ""
            let script =  "\(function)(\(paramsStr))"
            eval(script, completion: completion)
        }
    }
}
