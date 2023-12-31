//
//  GadgetJSServicesManager.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/6.
//  


import SKFoundation
import ThreadSafeDataStructure
import LarkOpenPluginManager
import LarkOpenAPIModel
import SpaceInterface
import SKCommon


class GadgetJSServicesManager: GadgetJSServiceHandlerDelegate {
    
    private var openAPIContext: OpenAPIContext?
    /// token: [handlers]
    public private(set) var handlersMap: [String: [GadgetJSServiceHandlerType]] = [:]
    /// 多token唯一handler
    public private(set) var onceHandlers: [GadgetJSServiceHandlerType] = []
    
    var handlerTypes: [GadgetJSServiceHandlerType.Type] = []
    
    public private(set) var minaSession: Any?
    
    /// 和token无关的bridge
    var onceService: [String] = []
    
    // 用来监听页面销毁和创建，区别于其他service
    var isolatedService: [String] = []
    
    var handleServices: [String] {
        var res: [String] = isolatedService
        for hander in handlerTypes {
            res.append(contentsOf: hander.gadgetJsBridges)
        }
        
        for hander in onceHandlers {
            res.append(contentsOf: hander.gadgetJsBridges)
        }
        return res
    }
    
    public var gadgetJsBridges: [String] {
        return handleServices
    }

    private let handerQueue = DispatchQueue(label: "com.bytedance.gadget.doc.handler")
    
    public var isBusy: Bool = false
    
    init() {
        setupHandlers()
    }
 
    /// 小程序中有三种service
    /// 1.和token绑定的services，每个token对应一组handlers
    /// 2.不和token绑定，每个小程序生命周期内只有一份实例
    /// 3. 生命周期相关的通知，在GadgetJSServicesManager中处理，不需handler处理
    func setupHandlers() {
        
        // 和token绑定的services
        handlerTypes = [GadgetShowCommentJSService.self, // 评论展示
                        CommentInputService.self, // 新建评论
                        CommentRequestNative.self] // RN通信
        
        // 整个小程序生命周期中只有一份实例的services
        onceHandlers = [RNDataService(), SKBaseLogPlugin(), CommentNative2JSService(), CommentTeaService()]
        onceService = []
        for handler in onceHandlers {
            onceService.append(contentsOf: handler.gadgetJsBridges)
        }
        
        // 生命周期相关的通知
        isolatedService = [DocsJSService.commentSetEntity.rawValue, DocsJSService.commentRemoveEntity.rawValue]
    }
    
    public func simulateJSMessage(token: String?, _ msg: String, params: [String: Any] = [:]) {
        guard let token = token else {
            DocsLogger.info("simulateJSMessage token is nil", component: LogComponents.gadgetComment)
            return
        }
        var params = params
        params["token"] = token
        let callback = GadgetCommentCallback(callback: { _ in
            
        })
        handle(message: msg, params, extra: [:], callback: callback)
    }
    
    func fetchServiceInstance<H>(token: String?, _ service: H.Type) -> H? where H: GadgetJSServiceHandlerType {
        if let token = token, let handlers = handlersMap[token] {
            if let handler = handlers.first { return type(of: $0) == service } {
                return handler as? H
            }
        }
        let handler = onceHandlers.first { return type(of: $0) == service }
        return handler as? H
    }
    
    func openURL(url: URL) {
        // 走小程序流程，内部有链接安全校验
        if let context = openAPIContext {
            openAPIContext?.asyncCall(apiName: "openSchema", params: ["schema": url.absoluteString, "external": false], context: context, callback: { respone in
                DocsLogger.info("openSchema \(respone)", component: LogComponents.gadgetComment)
            })
        } else {
            DocsLogger.error("openAPIContext is nil", component: LogComponents.gadgetComment)
        }
    }
    
    func openProfile(id: String) {
        if let context = openAPIContext {
            openAPIContext?.asyncCall(apiName: "enterProfile", params: ["openid": id], context: context, callback: { respone in
                DocsLogger.info("enterProfile \(respone)", component: LogComponents.gadgetComment)
            })
        } else {
            DocsLogger.error("openAPIContext is nil", component: LogComponents.gadgetComment)
        }
    }
    
    deinit {
        DocsLogger.info("GadgetJSServicesManager deinit", component: LogComponents.gadgetComment)
    }
}

// MARK: - CommentOpenPluginHandlerDelegate

extension GadgetJSServicesManager: CommentOpenPluginHandlerDelegate {
    
    func handle(message: String, _ params: [String: Any], extra: [String: Any], callback: GadgetCommentCallback) {
        guard let token = params["token"] as? String else {
            if checkIsOnceService(serviceName: message) {
                handerQueue.async {
                    let cmd = message
                    self.onceHandlers.forEach { (handler) in
                        if handler.gadgetJsBridges.contains(cmd) {
                            DispatchQueue.main.async {
                                DocsLogger.info("dispatch message \(message)", component: LogComponents.gadgetComment)
                                handler.handle(params: params, extra: extra, serviceName: message, callback: callback)
                            }
                        }
                    }
                }
            } else {
                spaceAssertionFailure("token is needed")
            }
            return
        }
        guard let handlers = handlersMap[token] else {
            spaceAssertionFailure("handlers is nil")
            return
        }
        handerQueue.async {
            let cmd = message
            handlers.forEach { (handler) in
                if handler.gadgetJsBridges.contains(cmd) {
                    DispatchQueue.main.async {
                        DocsLogger.info("dispatch message \(message)", component: LogComponents.gadgetComment)
                        handler.handle(params: params, extra: extra, serviceName: message, callback: callback)
                    }
                }
            }
        }
    }
    
    func checkIsOnceService(serviceName: String) -> Bool {
        return onceService.contains(serviceName)
    }
    
    func pluginBeginUpdateEntity(entity: OPPluginEntity) {
        registerHandler(entity: entity)
    }
    
    func pluginEndUpdateEntity(entity: OPPluginEntity) {
        unRegisterHandler(token: entity.token)
    }
    
    func registerHandler(entity: OPPluginEntity) {
        guard handlersMap[entity.token] == nil else {
            entity.callback?(.failure(error: NSError(domain: "setEntity is repeated", code: -1)))
            return
        }
        let docsInfo = DocsInfo(type: DocsType(rawValue: entity.type),
                                objToken: entity.token)
        docsInfo.appId = entity.appId
        let handlers = handlerTypes.map { type -> GadgetJSServiceHandlerType in
            return type.init(gadgetInfo: docsInfo, dependency: CommentOpenPluginDependencyImp(topViewController: entity.controller), delegate: self)
        }
        handlersMap[entity.token] = handlers
        DocsLogger.info("registered handlers count: \(handlers.count) tokenLen: \(entity.token.count)", component: LogComponents.gadgetComment)
        entity.callback?(.success(data: [:]))
        if let session = self.minaSession {
            updateSession(session)
        }
    }
    
    func unRegisterHandler(token: String) {
        // 注意是否需要手动清除资源
        handlersMap[token] = nil
    }
    
    func enviromentTerminate() {
        self.onceHandlers = []
        self.handlersMap.removeAll()
    }
    
    func update(context: OpenAPIContext) {
        self.openAPIContext = context
    }
    
    func updateSession(_ session: Any) {
        let values = handlersMap.flatMap { $0.1 }
        self.minaSession = session
        RNManager.manager.setOpenApiSession(session)
        values.forEach { handler in
            handler.gadegetSessionHasUpdate(minaSession: session)
        }
    }
}
