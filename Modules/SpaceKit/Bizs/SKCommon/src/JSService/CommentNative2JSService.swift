//
//  CommentNative2JSService.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/18.
//  


import LarkWebViewContainer
import ThreadSafeDataStructure
import SKFoundation
import SpaceInterface

public final class CommentNative2JSService: BaseJSService, JSServiceHandler, GadgetJSServiceHandlerType {
    
    public  static var handleServices: [DocsJSService] {
        return [.commonEventListener]
    }
    
    public var handleServices: [DocsJSService] {
        return Self.handleServices
    }
    
    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }
    
    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }
    
    public var callback: DocWebBridgeCallback?
    
    typealias MessageType = (CommentEventListenerAction, [String: Any])
    
    private var messageQueue: [MessageType] = []
    
    public override init() {
        super.init()
    }
    
    public override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
    
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        var bridgeCallback: DocWebBridgeCallback?
        if let cb = callback {
            bridgeCallback = DocWebBridgeCallback.lark(cb)
        }
        handle(params: params, serviceName: serviceName, callback: bridgeCallback)
    }
    
    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        handle(params: params, serviceName: serviceName, callback: DocWebBridgeCallback.gadget(callback))
    }
    
    func handle(params: [String: Any], serviceName: String, callback: DocWebBridgeCallback?) {
        guard let bridgeCallback = callback else {
            return
        }
        self.callback = bridgeCallback
        DocsLogger.info("save commonEventListener callback", component: LogComponents.comment)
        callIfNeed()
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        
    }
    
    // MARK: - 小程序
    
    weak var delegate: GadgetJSServiceHandlerDelegate?
    
    public var gadgetInfo: DocsInfo?
    
    var dependency: CommentPluginDependency?
    
    required public init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate) {
        super.init()
        self.dependency = dependency
        self.gadgetInfo = gadgetInfo as? DocsInfo
        self.delegate = delegate
    }
}

extension CommentNative2JSService: CommentServiceType {
    
    public func callFunction(for action: CommentEventListenerAction, params: [String: Any]?) {
        guard let callback = callback else {
           messageQueue.append((action, params ?? [:]))
           DocsLogger.info("callFunction action: \(action.rawValue) callback is nil", component: LogComponents.comment)
           return
        }
        DocsLogger.info("callFunction action: \(action.rawValue) success", component: LogComponents.comment)
        switch action {
        case .anchorLinkSwitch: // 这个交互比较特殊，复用前端已有的交互
            let commentId = (params?["commentId"] as? String) ?? ""
            activeComment(commentId: commentId)
        default:
            callback.callFunction(action: action, params: params)
        }
    }

    public func activeComment(commentId: String) {
        if commentId.isEmpty {
            DocsLogger.error("activeComment commentId is ni", component: LogComponents.comment)
        }
        DocsLogger.info("active comment by link:\(commentId)", component: LogComponents.comment)
        model?.jsEngine.callFunction(.activeComment,
                                     params: ["commentId": commentId,
                                              "replyId": "",
                                              "from": "anchor"],
                                     completion: nil)
    }
    
    func callIfNeed() {
        // 先发送队列里面的
        for message in messageQueue {
            DocsLogger.info("messageQueue callFunction: \(message.0.rawValue) ", component: LogComponents.comment)
            callFunction(for: message.0, params: message.1)
        }
        // 清空队列
        messageQueue = []
    }
}
