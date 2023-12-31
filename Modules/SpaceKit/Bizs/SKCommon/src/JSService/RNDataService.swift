//
//  RNDataService.swift
//  SpaceKit
//
//  Created by Webster on 2018/11/28.
//

import Foundation
import SKFoundation
import LarkWebViewContainer
import SpaceInterface

public final class RNDataService: BaseJSService, GadgetJSServiceHandlerType {
    var rnToWebCallbackScript: String?
    var aggregationTimer: Timer?
    var aggregationCache: [[String: Any]] = [] //RN聚合消息缓存
    lazy var debouncer = DebounceProcesser()

    public override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        RNManager.manager.registerRnEvent(eventNames: [.sendMessageToWebview, .postMessage], handler: self)
        model.browserViewLifeCycleEvent.addObserver(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    var callbacks: [DocsJSService: DocWebBridgeCallback] = [:]
    
    public override init() {
        super.init()
        RNManager.manager.registerRnEvent(eventNames: [.sendMessageToWebview, .postMessage], handler: self)
    }

    required public convenience init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate) {
        self.init()
    }
    
    deinit {
        stopAggregationTimerIfNeed()
    }
    
    func evaluateFunction(function: String, params: [String: Any]?) {
        model?.jsEngine.callFunction(DocsJSCallBack(function), params: params, completion: nil)
    }
}

extension RNDataService: DocsJSServiceHandler {
    
    static var handleServices: [DocsJSService] {
        return [.rnSendMsg, .rnHandleMsg, .rnReload, .commentPostMessage, .commentOnMessage]
    }
    
    public var handleServices: [DocsJSService] {
        return Self.handleServices
    }
    
    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }

    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }

    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        let service = DocsJSService(serviceName)
        if service == .commentOnMessage, let cb = callback {
            callbacks[service] = DocWebBridgeCallback.lark(cb)
        }
        self.handle(params: params, serviceName: serviceName)
    }
    
    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        let service = DocsJSService(serviceName)
        switch service {
        case .commentOnMessage:
            callbacks[service] = DocWebBridgeCallback.gadget(callback)
        default:
            callback(.success(data: [:]))
        }
        self.handle(params: params, serviceName: serviceName)
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .rnSendMsg:
            RNManager.manager.sendSyncData(data: params, responseId: params["callback"] as? String)
        case .commentPostMessage:
            DocsLogger.info("RNDataService commentPostMessage to RN", component: logComponents)
            RNManager.manager.sendSyncData(data: params, responseId: nil)
        case .rnHandleMsg:
            guard let jsMethod = callbackMethod(from: params) else { return }
            rnToWebCallbackScript = jsMethod
            DocsLogger.info("RNDataService set callback:\(jsMethod)")
        case .rnReload:
            DocsLogger.info("RNDataService will reloadBundle")
            RNManager.manager.reloadBundle { (result) in
                guard let jsMethod = self.callbackMethod(from: params) else { return }
                let code = result ? 1 : 0
                self.evaluateFunction(function: jsMethod, params: ["result": code])
            }
        default:
            break
        }
    }

    func callbackMethod(from params: [String: Any]) -> String? {
        return (params["callback"] as? String)
    }
    
    var logComponents: String {
        if self.model != nil {
            return LogComponents.comment
        } else {
            return LogComponents.gadgetComment
        }
    }
}

extension RNDataService: RNMessageDelegate {
    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard let webData = data["data"] as? [String: Any] else { return }
        
        switch eventName {
        case .postMessage:
            guard let callback = callbacks[.commentOnMessage] else {
                DocsLogger.error("RNDataService commentOnMessage to JS callback isEmpty", component: logComponents)
                return
            }
            DocsLogger.info("RNDataService postMessage success", component: logComponents)
            callback.callFunction(action: nil, params: webData)
        default:
            guard let callback = rnToWebCallbackScript else { return }
            if shouleInterceptMsg {
                aggregationCache.append(webData)
                DocsLogger.info("RNDataService Intercept rn Msg when win floating,list:\(aggregationCache.count)")
                return
            }
            evaluateFunction(function: callback, params: webData)
        }
        
    }
}

extension RNDataService: BrowserViewLifeCycleEvent {
    public func browserDidChangeFloatingWindow(isFloating: Bool) {
        self.onChangeToFloatingWindow(isFloating: isFloating)
    }
    
    public func browserWillClear() {
        stopAggregationTimerIfNeed()
        aggregationCache.removeAll()
    }
}

extension RNDataService {
    
    @objc
    private func didEnterBackground(_ notify: NSNotification) {
        guard needAggregationInBackground else { return }
        DocsLogger.info("RNDataService didEnterBackground（\(self.editorIdentity), try start Aggregation")
        self.onAggregationStatusChange(true)
    }

    @objc
    private func willEnterForeground(_ notify: NSNotification) {
        guard needAggregationInBackground else { return }
        DocsLogger.info("RNDataService willEnterForeground（\(self.editorIdentity), try stop Aggregation")
        self.onAggregationStatusChange(false)
    }
}
