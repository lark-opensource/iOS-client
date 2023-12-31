//
//  JSServiceManager.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/11.


import SKFoundation
import ThreadSafeDataStructure
import LarkWebViewContainer
import LarkContainer

open class JSServicesManager {
    public let userResolver: UserResolver
    public var isBusy: Bool = false
    public private(set) var isResponsive: Bool = false //只要收到WebView调用就算Responsive
    
    private var handlers_v1: SafeArray<JSServiceHandler> = [] + .semaphore
    
    // value不使用SafeArray的原因是: 注册与反注册时,均没有原地修改数组的操作。如果后续修改了数据结构，需要关注多线程安全性
    private let handlers_v2: SafeDictionary<String, [HandlerWrapper]> = [:] + .readWriteLock
    private static var _isNewDispatchFeatureEnabled = SafeAtomic<Bool?>(nil, with: .readWriteLock)

    private let handerQueue = DispatchQueue(label: "com.bytedance.doc.handler.\(UUID().uuidString)")

    private let logBlackList: Set<String> = [
        "biz.util.logger",
        "biz.vcfollow.sendToNative",
        "biz.util.batchLogger"
    ]
    
    // TODO.chensi 用户态改造
    public init(userResolver: UserResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)) {
        self.userResolver = userResolver
    }

    public func handle(message: String, _ params: [String: Any], isSimulate: Bool = false, callback: APICallbackProtocol? = nil) {
        if isNewDispatchFeatureEnabled() {
            handle_v2(message: message, params, callback: callback)
        } else {
            handle_v1(message: message, params, callback: callback)
        }
        if !isSimulate {
            isResponsive = true
        }
    }

    public func simulateJSMessage(_ msg: String, params: [String: Any] = [:]) {
        handle(message: msg, params, isSimulate: true)
    }

    @discardableResult
    open func register(handler: JSServiceHandler) -> JSServiceHandler {
        if isNewDispatchFeatureEnabled() {
            return register_v2(handler: handler)
        } else {
            return register_v1(handler: handler)
        }
    }

    public func unRegister(handlers toRemove: [JSServiceHandler]) {
        if isNewDispatchFeatureEnabled() {
            return unRegister_v2(handlers: toRemove)
        } else {
            return unRegister_v1(handlers: toRemove)
        }
    }
    
    public func fetchServiceInstance<H: JSServiceHandler>(_ service: H.Type) -> H? {
        if isNewDispatchFeatureEnabled() {
            let wrappersList = handlers_v2.values.getImmutableCopy()
            for wrappers in wrappersList {
                for wrapper in wrappers {
                    if type(of: wrapper.handler) == service {
                        DocsLogger.debug("find service instance:\(service) SUCCEED")
                        return wrapper.handler as? H
                    }
                }
            }
            DocsLogger.debug("find service instance:\(service) FAILED")
            return nil
        } else {
            let handler = handlers_v1.first { type(of: $0) == service }
            return handler as? H
        }
    }
}

// MARK: V1实现
extension JSServicesManager {
    
    private func handle_v1(message: String, _ params: [String: Any], callback: APICallbackProtocol? = nil) {
        if !logBlackList.contains(message) {
            DocsLogger.debug("收到前端调用\(message)")
        }
        handerQueue.async {
            let cmd = DocsJSService(rawValue: message)
            self.handlers_v1.forEach { (handler) in
                if handler.handleServices.contains(cmd) {
                    DispatchQueue.main.async {
                        handler.handle(params: params, serviceName: message, callback: callback)
                    }
                }
            }
        }
    }
    
    @discardableResult
    private func register_v1(handler: JSServiceHandler) -> JSServiceHandler {
        handlers_v1.append(handler)
        return handler
    }

    // 需要优化性能
    private func unRegister_v1(handlers toRemove: [JSServiceHandler]) {
        DocsLogger.debug("before remove \(handlers_v1.count) handlers")
        self.handlers_v1.safeWrite { handlers in
            handlers.removeAll { handler in
                return toRemove.contains(where: {
                    Set($0.handleServices) == Set(handler.handleServices)
                })
            }
        }
        DocsLogger.debug("after remove \(self.handlers_v1.count) handlers")
    }
}

// MARK: V2实现
extension JSServicesManager {
    
    /// 新的分发方式是否可用，FG控制
    private func isNewDispatchFeatureEnabled() -> Bool {
        if let value = Self._isNewDispatchFeatureEnabled.value { // 使用静态值缓存,降低消耗
            return value
        }
        let newValue = UserScopeNoChangeFG.CS.jsbDispatchOptimizationEnabled
        Self._isNewDispatchFeatureEnabled.value = newValue
        return newValue
    }
    
    private func handle_v2(message: String, _ params: [String: Any], callback: APICallbackProtocol? = nil) {
        if !logBlackList.contains(message) {
            DocsLogger.debug("did receive front-end call:\(message)")
        }
        handerQueue.async {
            self.handlers_v2.safeRead(for: message) { optionalArray in
                guard let array = optionalArray, !array.isEmpty else { return }
                DispatchQueue.main.async {
                    array.forEach { item in
                        item.handler.handle(params: params, serviceName: message, callback: callback)
                    }
                }
            }
        }
    }
    
    @discardableResult
    private func register_v2(handler: JSServiceHandler) -> JSServiceHandler {
        var handleServices = handler.handleServices
        if handleServices.isEmpty {
            handleServices = [DocsJSService("@_placeholder_@")] // 如果handler不处理任何jsb,则统一放到这个key下进行引用
        }
        for service in handleServices {
            let serviceName = service.rawValue
            let item = HandlerWrapper(handler)
            if var array = self.handlers_v2[serviceName] {
                array.append(item)
                self.handlers_v2.updateValue(array, forKey: serviceName)
            } else {
                self.handlers_v2.updateValue([item], forKey: serviceName)
            }
        }
        return handler
    }
    
    private func unRegister_v2(handlers toRemove: [JSServiceHandler]) {
        DocsLogger.debug("before remove, \(handlers_v2.count) handlers")
        
        let jsbSetArray = toRemove.map { (handler: JSServiceHandler) in
            Set(handler.handleServices.map { $0.rawValue })
        }
        let serviceNamesToRemove = Set(jsbSetArray) // 将要移除的jsb集合的集合

        let allKeys = handlers_v2.keys
        allKeys.forEach { key in
            guard let oldWrappers = handlers_v2[key] else { return } // 退出本次循环
            var newWrappers = [HandlerWrapper]()
            oldWrappers.forEach { oldWrapper in
                let nameSet = oldWrapper.serviceNames
                if serviceNamesToRemove.contains(nameSet) == false { // 不在移除范围内的jsb集合，则保留
                    newWrappers.append(oldWrapper)
                }
            }
            if newWrappers.isEmpty {
                handlers_v2.removeValue(forKey: key)
            } else {
                handlers_v2.updateValue(newWrappers, forKey: key)
            }
        }
        DocsLogger.debug("after remove, \(handlers_v2.count) handlers")
    }
}

private class HandlerWrapper { // register时先算好serviceNames, 均摊unRegister操作的时间复杂度
    
    let handler: JSServiceHandler
    
    let serviceNames: Set<String>
    
    init(_ handler: JSServiceHandler) {
        self.handler = handler
        self.serviceNames = Set(handler.handleServices.map { $0.rawValue })
    }
}
