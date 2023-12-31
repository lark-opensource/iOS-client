//
//  OpenPluginNativeComponent.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/6/30.
//

import Foundation
import TTMicroApp
import OPPluginManagerAdapter
import LarkWebviewNativeComponent
import LarkOpenAPIModel
import OPSDK
import LKCommonsLogging

// MARK: - OpenPluginNativeSubComponent

protocol OpenPluginNativeComponentProtocol: AnyObject {
    
    // MARK: - Public For Override
    
    func insert(context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentInsertResponse) -> Void)
    
    /** 当前组件所在的webview viewDidAppear，包括
     1. 当前页面是首页面时，App进入前台;
     2. 当前页面重新出现，如小程序从悬浮框出现、小程序视图栈退回当前页面。
     @warning 子类需要主动调起addListener()方法来实现事件响应; 若addListener()调用时机晚于viewDidAppear(), 则会错过第一次viewDidAppear()时机
     */
    func viewDidAppear()
    
    /** 当前组件所在的webview viewDidDisappear，包括
     1. 当前页面是首页面时，App进入后台;
     2. 当前页面消失，如当前页面是首页面时，小程序进入悬浮框、小程序视图栈离开当前页面。
     */
    func viewWillDisappear()
    
    func viewDidDisappear()
    
    var needListenAppPageStatus: Bool { get }
    
    var needUniqueCheck: Bool { get } // 组件唯一性检查
    func onUniqueCheckFail() -> OpenAPIErrnoProtocol?
    
    var insertAuth: [String]? { get } // 插入时权限申请
    func onInsertAuthFail(errno: OpenAPIErrnoProtocol)
}

// MARK: - OpenPluginNativeComponent

class OpenPluginNativeComponent: OpenNativeBaseComponent, BDPWebViewLifeCycleProtocol, OpenPluginNativeComponentProtocol {
    fileprivate static let logger = Logger.oplog(OpenPluginNativeComponent.self, category: "LarkWebviewNativeComponent")
    
    // MARK: - API Handle & register
    
    typealias handler<Param: OpenAPIBaseParams, Result: OpenComponentBaseResult> = (
        _ params: Param,
        _ context: Context,
        _ callback: @escaping (OpenComponentBaseResponse<Result>) -> Void
    ) -> Void

    typealias handlerWrapper = handler<OpenAPIBaseParams, OpenComponentBaseResult>

    struct HandleWrapper {
        let paramsType: OpenAPIBaseParams.Type
        let handler: handlerWrapper
        let scopes: [String]
    }
    
    public func handle(
        apiName: String,
        data: [AnyHashable : Any],
        context: Context,
        callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void
    ) {
        if let handler = handlers[apiName] {
            context.trace.info("async call api \(apiName) by async handler")
            do {
                let params = try handler.paramsType.init(with: data)
                handler.handler(params, context, callback)
            } catch let err as OpenAPIError {
                context.trace.error("params invalid for \(apiName), error: \(err)")
                callback(.failure(error: err))
            } catch {
                context.trace.error("params invalid for \(apiName), error: \(error)")
                // TODO: baojianjun - 待API errno适配完成后，follow
                let err = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setOuterMessage(error.localizedDescription)
                    .setError(error)
                callback(.failure(error: err))
            }
        } else {
            context.trace.error("can not find handler for async call api \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setMonitorMessage("can not find handler for async call api \(apiName)")
            callback(.failure(error: error))
        }
    }
    
    public func authCheck(apiName: String, trace: OPTrace) -> [String] {
        if let handler = handlers[apiName] {
            let scopes = handler.scopes
            trace.info("auth check api \(apiName), scopes: \(scopes)")
            return scopes
        } else {
            trace.error("can not find handler for async call api \(apiName)")
            return []
        }
    }
    
    
    public func registerHandler<Param, Result>(
        for apiName: String,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping handler<Param, Result>,
        authScopes: [String] = []
    ) where Param: OpenAPIBaseParams, Result: OpenComponentBaseResult {
        guard !handlers.keys.contains(apiName) else {
            return // 同一个API Name只允许注册一次
        }
        
        let wrappedHandler: handlerWrapper = { params, context, callback in
            guard let realParam = params as? Param else {
                context.trace.error("can not convert \(params.self) to \(paramsType) for api \(apiName)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("can not convert \(params.self) to \(paramsType) for api \(apiName)")
                callback(.failure(error: error))
                return
            }
            handler(realParam, context, { response in
                switch response {
                case let .failure(error):
                    callback(.failure(error: error))
                case let .success(data):
                    callback(.success(data: data))
                @unknown default:
                    callback(.failure(error: OpenAPIError(errno: OpenNativeInfraErrnoDispatchAction.internalError)))
                }
            })
        }
        let wrapper = HandleWrapper(paramsType: paramsType.self, handler: wrappedHandler, scopes: authScopes)
        self.handlers[apiName] = wrapper
    }
    
    internal var handlers: [String : HandleWrapper] = [:]
    
    final class Context {
        let params: [AnyHashable: Any]
        let trace: OPTrace
        let uniqueID: OPAppUniqueID
        
        public init(
            params: [AnyHashable: Any],
            trace: OPTrace,
            uniqueID: OPAppUniqueID) {
                self.params = params
                self.trace = trace
                self.uniqueID = uniqueID
            }
    }
    
    public internal(set) weak var bdpWebView: BDPWebView?
    
    internal func preInsert(bdpWebView: BDPWebView) {
        self.bdpWebView = bdpWebView
        if needListenAppPageStatus {
            self.addListener()
        }
    }
    
    // MARK: - OpenPluginNativeComponentProtocol
    
    func insert(context: Context, callback: @escaping (OpenComponentInsertResponse) -> Void) {
        if let view = insert(params: context.params, trace: context.trace) {
            callback(.success(view: view))
        } else {
            let error = OpenAPIError(errno: OpenNativeInfraErrnoInsert.internalError)
                    .setNativeComponentError(OpenNativeComponentBridgeAPIError.bizError)
            callback(.failure(error: error))
        }
    }
    
    func viewDidAppear() { }
    
    func viewWillDisappear() { }
    
    func viewDidDisappear() { }
    
    var needListenAppPageStatus: Bool { false }
    
    var needUniqueCheck: Bool { false }
    
    func onUniqueCheckFail() -> OpenAPIErrnoProtocol? { nil }
    
    var insertAuth: [String]? { nil }
    func onInsertAuthFail(errno: OpenAPIErrnoProtocol) { }
    
    // MARK: - LifeCycle
    
    private var isListening = false
    
    private var isForePage = true {
        didSet {
            guard appInForeground else {
                return
            }
            guard isForePage != oldValue else {
                return
            }
            if isForePage {
                self.viewDidAppear()
            } else {
                self.viewWillDisappear()
            }
        }
    }
    private var appInForeground = true {
        didSet {
            guard isForePage else {
                return
            }
            guard appInForeground != oldValue else {
                return
            }
            if appInForeground {
                self.viewDidAppear()
            } else {
                self.viewWillDisappear()
            }
        }
    }
    
    private var isBackgroundPage = false {
        didSet {
            guard appInForeground else {
                return
            }
            guard isBackgroundPage != oldValue else {
                return
            }
            if isBackgroundPage {
                self.viewDidDisappear()
            }
        }
    }
    
    /// 最小化监听原则, 监听方法放在各个NativePlugin内，如有必要，子类各自调用; 只可在insert链路上调用
    func addListener() {
        guard !isListening else {
            Self.logger.error("addListener repeat")
            return
        }
        isListening = true
        bdpWebView?.registerLifeCycle(component: self)
        addObserver()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func didEnterBackground() {
        appInForeground = false
    }
    
    @objc private func didBecomeActive() {
        appInForeground = true
    }
    
    // MARK: - BDPWebViewLifeCycleProtocol
    
    func webviewWillAppear() {
        Self.logger.info("webviewWillAppear")
    }
    
    func webviewDidAppear() {
        isForePage = true
        isBackgroundPage = false
        Self.logger.info("webviewDidAppear")
    }
    
    func webviewWillDisappear() {
        isForePage = false
        Self.logger.info("webviewWillDisappear")
    }
    
    func webviewDidDisappear() {
        isBackgroundPage = true
        Self.logger.info("webviewDidDisappear")
    }
    
    // MARK: - OpenNativeBaseComponentProtocol
    
    override func getNativeView(dealedData: [AnyHashable : Any], trace: OPTrace, webView: LarkWebView, callback: @escaping (OpenComponentInsertResponse) -> Void) {
        guard let webview = webView as? BDPWebView else {
            super.getNativeView(dealedData: dealedData, trace: trace, webView: webView, callback: callback)
            return
        }
        
        guard let auth = webview.authorization as? BDPAuthorization else {
            // auth 类型错误, 代码错误类型
            let errno = OpenNativeInfraErrnoInsert.internalError
            callback(.failure(error: OpenAPIError(errno: errno)))
            return
        }
        
        if needUniqueCheck {
            let componentMap = webview.op_nativeComponentManager()
            guard componentMap.checkComponentUnique(component: self) else {
                let errno = onUniqueCheckFail() ?? OpenNativeInfraErrnoInsert.internalError
                callback(.failure(error: OpenAPIError(errno: errno)))
                return
            }
        }
        
        let context = OpenPluginNativeComponent.Context(params: dealedData, trace: trace, uniqueID: webview.uniqueID)
        preInsert(bdpWebView: webview)
        
        if let scopes = insertAuth {
            let provider = BDPAuthModuleControllerProvider()
            provider.controller = webview.bridgeController
            auth.requestUserPermissionQeueued(forScopeList: scopes, uniqueID: webview.uniqueID, authProvider: auth, delegate: provider) {
                [weak self] result in
                
                guard let self = self else {
                    let errno = OpenNativeCameraErrnoFireEvent.internalError
                    callback(.failure(error: OpenAPIError(errno: errno)))
                    return
                }
                
                if let errno = Self.checkAuth(result: result) {
                    self.onInsertAuthFail(errno: errno)
                    callback(.failure(error: OpenAPIError(errno: errno)))
                    return
                }
                
                self.insert(context: context, callback: callback)
            }
        } else {
            self.insert(context: context, callback: callback)
        }
    }
    
    override func dispatchAction(methodName: String, data: [AnyHashable : Any], trace: OPTrace, webView: LarkWebView, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        guard let bdpWebview = webView as? BDPWebView else {
            super.dispatchAction(methodName: methodName, data: data, trace: trace, webView: webView, callback: callback)
            return
        }
        
        guard let auth = bdpWebview.authorization as? BDPAuthorization else {
            // auth 类型错误, 代码错误类型
            let errno = OpenNativeInfraErrnoDispatchAction.internalError
            callback(.failure(error: OpenAPIError(errno: errno)))
            return
        }
        
        // insert所需授权, 如果
        if let insertScopes = insertAuth,
           let errno = Self.preCheckApplied(scopes: insertScopes, auth: auth) {
            callback(.failure(error: OpenAPIError(errno: errno)))
            return
        }
        
        let scopes = authCheck(apiName: methodName, trace: trace)
        
        let context = OpenPluginNativeComponent.Context(params: data, trace: trace, uniqueID: bdpWebview.uniqueID)
        let provider = BDPAuthModuleControllerProvider()
        provider.controller = bdpWebview.bridgeController
        auth.requestUserPermissionQeueued(forScopeList: scopes, uniqueID: bdpWebview.uniqueID, authProvider: auth, delegate: provider) { [weak self] result in
            
            guard let self = self else {
                let errno = OpenNativeInfraErrnoDispatchAction.internalError
                callback(.failure(error: OpenAPIError(errno: errno)))
                return
            }
            
            if let errno = Self.checkAuth(result: result) {
                callback(.failure(error: OpenAPIError(errno: errno)))
                return
            }
            
            self.handle(apiName: methodName, data: data, context: context, callback: callback)
        }
    }
}

extension OpenPluginNativeComponent {
    
    private class func preCheckApplied(scopes: [String], auth: BDPAuthorization) -> OpenAPICommonErrno? {
        // 如果没有权限访问记录, 走请求权限的逻辑
        // 如果已经权限校验过, 但是失败了, 直接走回调
        // 如果已经权限校验过, 且成功了, 继续API调用流程
        // 这里做鉴权的原因: 避免组件插入时未授权，后续每次调用API时弹授权弹窗，用户即使手动授权也无法使该组件重新恢复。
        for scope in scopes {
            if let history = auth.status(forScope: scope), !history.boolValue {
                return .userAuthDeny
            }
        }
        return nil
    }
    
    private class func checkAuth(result: BDPAuthorizationPermissionResult) -> OpenAPIErrnoProtocol? {
        var errno: OpenAPIErrnoProtocol? = nil
        switch result {
        case .systemDisabled: // 系统
            errno = OpenAPICommonErrno.systemAuthDeny
        case .userDisabled: // 用户未授权
            errno = OpenAPICommonErrno.userAuthDeny
        case .enabled: // 通过
            break
        case .platformDisabled: fallthrough
        case .invalidScope: fallthrough // 非法scope或平台禁止
        @unknown default:
            errno = OpenAPICommonErrno.authenFail
        }
        return errno
    }
}
