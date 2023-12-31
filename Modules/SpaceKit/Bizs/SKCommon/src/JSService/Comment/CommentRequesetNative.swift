//
//  CommentRequesetNative.swift
//  SpaceKit
//
//  Created by bytedance on 2020/1/6.
//

import SKFoundation
import SwiftyJSON
import LarkWebViewContainer
import Foundation
import SpaceInterface

//public typealias EventKey = String

public final class CommentRequestNative: BaseJSService, GadgetJSServiceHandlerType {
    
    struct SyncInfo {
        var token: String
        var type: Int
    }
    
    static let bussinessKey = "comment"
    public private(set) var commentManager: RNCommentDataManager?
    public private(set) var commonManager: RNCommonDataManager?
    
    var syncInfo: SyncInfo?

    override public init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        initManagerIfNeed()
    }
    
    @discardableResult
    func initManagerIfNeed() -> Bool {
        guard let docsInfo = model?.browserInfo.docsInfo else {
            DocsLogger.error("[request native] init manager fail, docsInfo is nil", component: LogComponents.comment, traceId: editorIdentity)
            return false
        }
        let type = docsInfo.inherentType
        let token = docsInfo.token
        if !token.isEmpty {
            DocsLogger.error("[request native] init manager fail, token is empty", component: LogComponents.comment, traceId: editorIdentity)
            self.initCommentManager(token,
                                    type.rawValue,
                                    nil,
                                    [:])
            return true
        }
        return false
    }

    public func callAction(_ action: CommentEventListenerAction, _ data: [String: Any]?) {
        var native2JSService: CommentNative2JSService?
        if let service = self.model?.jsEngine.fetchServiceInstance(CommentNative2JSService.self) {
            native2JSService = service
        } else if let service = self.delegate?.fetchServiceInstance(token: nil, CommentNative2JSService.self) {
            native2JSService = service
        }
        guard let service = native2JSService else {
            DocsLogger.error("[request native] CommentRequestNative fetchServiceInstance native2JSService error", component: LogComponents.comment, traceId: editorIdentity)
            return
        }
        service.callFunction(for: action, params: data)
    }
    
    // MARK: - 小程序
    
    weak var delegate: GadgetJSServiceHandlerDelegate?
    
    public var gadgetInfo: DocsInfo?
    
    var dependency: CommentPluginDependency?
    
    public required init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate) {
        super.init()
        self.dependency = dependency
        self.gadgetInfo = gadgetInfo as? DocsInfo
        self.delegate = delegate
    }
    
    func initCommentManager(_ token: String, _ type: Int, _ appId: String?, _ options: [String: Any] = [:] ) {
        if let syncInfo = self.syncInfo,
           syncInfo.token == token,
           syncInfo.type == type {
             DocsLogger.info("[request native] syncInfo is equal", component: LogComponents.comment + LogComponents.gadgetComment, traceId: editorIdentity)
             return
        }

        guard token.isEmpty == false else {
            spaceAssertionFailure()
            DocsLogger.error("[request native] initCommentManager token is nil", component: LogComponents.comment + LogComponents.gadgetComment, traceId: editorIdentity)
            return
        }
        DocsLogger.info("[request native] init comment/common manager success", component: LogComponents.comment + LogComponents.gadgetComment, traceId: editorIdentity)
        commentManager = RNCommentDataManager(fileToken: token,
                                              type: type,
                                              appId: appId,
                                              extraId: model?.jsEngine.editorIdentity)
        commentManager?.needEndSync = (appId != nil)
        commonManager = RNCommonDataManager(fileToken: token, type: type, extraId: model?.jsEngine.editorIdentity)
        commentManager?.delegate = self
        self.syncInfo = SyncInfo(token: token, type: type)
    }
    
    private func checkDocsInfo() {
        DocsLogger.info("[request native] begin check docsInfo", component: LogComponents.comment, traceId: editorIdentity)
        guard let docsInfo = model?.browserInfo.docsInfo, docsInfo.token.isEmpty == false else {
            DocsLogger.error("[request native] check docsInfo invalid", component: LogComponents.comment, traceId: editorIdentity)
            return
        }
        let tokenIsEmpty = self.syncInfo?.token.isEmpty == true
        if self.syncInfo == nil || tokenIsEmpty {
            // 初始化时 token为空，没有init成功这时需要再次init
            let isSuccess = initManagerIfNeed()
            DocsLogger.info("[request native] initManagerIfNeed result:\(isSuccess)", component: LogComponents.comment, traceId: editorIdentity)
        } else {
            DocsLogger.info("[request native] managers had inited", component: LogComponents.comment, traceId: editorIdentity)
        }
    }
}

extension CommentRequestNative: DocsJSServiceHandler {
    
    static var handleServices: [DocsJSService] {
       return [.commentRequestNative, .commentSetEntity]
    }
    
    public var handleServices: [DocsJSService] {
        return Self.handleServices
    }
    
    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }

    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }
 
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        var bridgeCallback: DocWebBridgeCallback?
        if let cb = callback {
            bridgeCallback = DocWebBridgeCallback.lark(cb)
        }
        handle(params: params, service: DocsJSService(serviceName), callback: bridgeCallback)
    }
    
    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        let bridgeCallback = DocWebBridgeCallback.gadget(callback)
        handle(params: params, service: DocsJSService(serviceName), callback: bridgeCallback)
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        
    }
    
    func handle(params: [String: Any], service: DocsJSService, callback: DocWebBridgeCallback?) {
        switch service {
        case .commentRequestNative:
            handleCommentRequestNative(with: params, callback: callback)
        case .commentSetEntity:
            handleCommentSetEntity(with: params, callback: callback)
        default:
            break
        }
    }
}

private extension CommentRequestNative {

    private func handleCommentRequestNative(with params: [String: Any], callback: DocWebBridgeCallback?) {
        do {
            let data = try JSONSerialization.data(withJSONObject: params, options: [])
            let request = try JSONDecoder().decode(RequestNative.self, from: data)
            DocsLogger.info("[request native] requestNative action=\(request.action)", component: LogComponents.comment + LogComponents.gadgetComment, traceId: editorIdentity)
            switch request.action {
            case .beginSync:
                DocsLogger.info("[request native] beginSyn for token=\(request.token.encryptToken), type=\(request.type)",
                                component: LogComponents.comment + LogComponents.gadgetComment,
                                traceId: editorIdentity)
                var param: [String: Any] = [:]
                if let op = params["options"] as? String {
                    param["options"] = op
                }
                beginSync(request.token, request.type, request.bizType ?? 0, param)
            case .fetchComment:
                var op: [String: Any] = ["options": "{}"]
                if let option = params["options"] as? String {
                    op["options"] = option
                }
                commentManager?.fetchComment(extra: op, response: { [weak self] (commentData) in
                    guard let callback = callback else {
                        DocsLogger.error("commentRequestNative callback is nil", component: LogComponents.comment, traceId: self?.editorIdentity)
                        return
                    }
                    guard let rawData = commentData.rawData else {
                        DocsLogger.error("commentRequestNative commentData rawData is nil", component: LogComponents.comment, traceId: self?.editorIdentity)
                        return
                    }
                    callback.callFunction(action: nil, params: rawData)
                })
            case .addTranslateComments:
                guard let options = params["options"] as? String else {
                    return
                }
                commentManager?.addTranslateComments(options: options, response: { (_) in

                })
            case .setTranslateEnableLang:
                guard let options = params["options"] as? String else {
                    return
                }
                commentManager?.setTranslateEnableLang(options: options, response: { (_) in

                })
            case .translate:
                guard let options = params["options"] as? String else {
                   return
                }
                commentManager?.translateComment(commentID: "", replyID: "", options: options, response: { (_) in
                })
            default:
                DocsLogger.info("[request native] commentRequestNative action:\(request.action) is unsupported", component: LogComponents.comment, traceId: editorIdentity)
            }
        } catch {
            DocsLogger.error("[request native] request native error \(error)", component: LogComponents.comment, traceId: editorIdentity)
        }
    }

    // beginSync在Docs业务中由native编辑器调，其他都由前端通过公共通道调用
    private func beginSync(_ token: String, _ type: Int, _ bizType: Int, _ options: [String: Any]) {
        DocsLogger.info("[request native] commentManager, init", component: LogComponents.comment + LogComponents.gadgetComment, traceId: editorIdentity)
        initCommentManager(token, type, nil, options)
        commentManager?.beginSync(options)
    }
    
    private func handleCommentSetEntity(with params: [String: Any], callback: DocWebBridgeCallback?) {
        let json = JSON(params)
        let type = json["type"].intValue
        let token = json["token"].stringValue
        let appId = json["appId"].string
        DocsLogger.info("[request native] handleCommentSetEntity type:\(type) token: \(token.encryptToken)", component: LogComponents.comment, traceId: editorIdentity)
        initCommentManager(token, type, appId)
    }
}

extension CommentRequestNative: CommentDataDelegate {
    public func didReceiveUpdateFeedData(response: Any) { }

    public func didReceiveCommentData(response: RNCommentData, eventType: RNCommentDataManager.CommentReceiveOperation) {
        DocsLogger.info("[request native] didReceiveCommentData change type \(eventType)", component: LogComponents.comment, traceId: editorIdentity)
        switch eventType {
        case .sendCommentsData:
            // sendCommentsData 对应调前端的 change 接口
            callAction(.change, response.rawData)
        default:
            break
        }
    }
}

private struct RequestNative: Codable {

    enum Action: String, Codable {
        case beginSync
        case endSync
        case fetchComment
        case addTranslateComments
        case setTranslateEnableLang
        case translate
    }

    let action: Action
    let type: Int
    let token: String
    let options: String?
    let callback: String?
    let bizType: Int?
}

// MARK: - 小程序能力

extension CommentRequestNative: CommentServiceType {
    public func callFunction(for action: SpaceInterface.CommentEventListenerAction, params: [String : Any]?) {
        
    }

    public var commentDocsInfo: DocsInfo? {
        if let gadgetInfo = gadgetInfo {
            return gadgetInfo
        } else {
            return model?.browserInfo.docsInfo
        }
    }
}


extension CommentRequestNative: BrowserViewLifeCycleEvent {
    
    public func browserDidUpdateDocsInfo() {
        checkDocsInfo()
    }
    
    public func browserViewControllerDidLoad() {
        checkDocsInfo()
    }

    public func browserWillClear() {
        self.commentManager?.endSync()
    }
    
    public func browserWillRerender() {
        self.commentManager?.endSync()
    }
}

extension CommentRequestNative: CommentRNRequestType {}
