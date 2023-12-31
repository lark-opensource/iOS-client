//
//  CommentInputService.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/4/25.
//  

import Foundation
import RxSwift
import RxRelay
import SKFoundation
import SKResource
import SKUIKit
import UIKit
import SpaceInterface
import LarkWebViewContainer
import SKInfra

/// 监听 WebView 触发新建评论的事件
public final class CommentInputService: BaseJSService, GadgetJSServiceHandlerType {
    
    public var isShowingComment: Bool {
        return commentModule?.isVisiable ?? false
    }
    
    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }
    
    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }

    var disposeBag = DisposeBag()
    
    /// 前端触发评论的参数
    var showInputModel: CommentInputModelType?
    
    var commentModule: FloatCommentModuleType?

    var keyboardShow = false
    
    weak var loadingToast: CommentToastViewType?
    
    typealias CommentCacheType = (MountComment, [String: Any])
    /// 保存起来用于重试
    var addCommentCache: [String: CommentCacheType] = [:]
    
    var callbacks: [DocsJSService: APICallbackProtocol] = [:]
    
    /// 记录点击事件时间戳
    var commentStatsExtra: CommentStatsExtra?
    
    private var userUseOpenId = false

    public override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)

        model.browserViewLifeCycleEvent.addObserver(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(closeCommentNoti),
                                               name: Notification.Name.CommentVCDismiss,
                                               object: nil)
        if SKDisplay.pad {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(showDocNewInputComment(noti:)),
                                                   name: Notification.Name.ShowDocNewInputComment,
                                                   object: nil)
        }
    }

    @objc
    func showDocNewInputComment(noti: Notification) {
        guard SKDisplay.pad, let identifier = noti.object as? String, identifier != self.editorIdentity else {
            return
        }
        commentModule?.manualHide()
    }


    @objc
    func closeCommentNoti() {
        
    }
    
    func closeFromCommentViewController() {
        commentModule?.hide()
        
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
    
    var hostWindow: UIView {
        guard let hostWindow = ui?.editorView.window else {
            DocsLogger.error("current hostWindow is nil", component: LogComponents.comment)
            return UIView()
        }
        return hostWindow
    }
    
    deinit {
        loadingToast?.remove()
    }
}

extension CommentInputService: BrowserViewLifeCycleEvent {
    public func browserWillTransition(from: CGSize, to: CGSize) {
        // 是支持横屏评论的文档类型，旋转屏幕的时候不关闭输入框
        if model?.browserInfo.docsInfo?.inherentType.supportCommentWhenLandscape ?? false {
            return
        }
        DocsLogger.info("CommentInputService, browserWillTransition")
        closeFromCommentViewController()
    }
}

extension CommentInputService: DocsJSServiceHandler {

    public static var handleServices: [DocsJSService] {
        return [
            .commentShowInput,
            .commentHideInput,
            .commentResultNotify,
            .commentShowToast,
            .commentShowCards,
            .simulateCommentEntrance,
            .simulateClearCommentEntrance,
            .updateCurrentUser
        ]
    }
    
    public var handleServices: [DocsJSService] {
        return Self.handleServices
    }

    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        callback(.success(data: [:]))
        self.handle(params: params, serviceName: serviceName)
    }
    
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        callbacks[DocsJSService(rawValue: serviceName)] = callback
        self.handle(params: params, serviceName: serviceName)
    }
        
    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(rawValue: serviceName)
        DocsLogger.info("CommentInputService, serviceName=\(serviceName) \(self.editorIdentity)", component: LogComponents.comment)
        switch service {
        case .commentShowInput:
            handleShowInput(params: params)
            commentModule?.update(useOpenID: userUseOpenId) // 放在 showInput 后面确保 commentModule 非空
        case .commentHideInput:
            if let isCloseByClient = params["needCancel"] as? Bool {
                DocsLogger.info("CommentInputService, commentHideInput closeByClient", component: LogComponents.comment)
            }
            closeFromCommentViewController()
//        case .commentResultNotify:
//            handleSendCommendResult(params: params)
        case .commentShowToast:
            showToast(params: params)
        case .commentShowCards:
            if SKDisplay.pad {
                commentModule?.hide()
            }
        case .simulateCommentEntrance:
            if let statsExtra: CommentStatsExtra = params.mapModel() {
                commentStatsExtra = statsExtra
            }
        case .simulateClearCommentEntrance:
            self.commentStatsExtra = nil
        case .updateCurrentUser:
            let useOpenId = (try? CommentUser(params: params))?.useOpenId ?? false
            userUseOpenId = useOpenId
            commentModule?.update(useOpenID: useOpenId)
        default:
            spaceAssertionFailure()
        }
    }
    
    func handleShowInput(params: [String: Any]) {
        let isDoc = ( self.docsInfo?.inherentType == .doc ||  self.docsInfo?.inherentType == .docX)
        if let browserVC = navigator?.currentBrowserVC as? BaseViewController, isDoc {
            //前端要求在评论输入框弹出时由native下掉工具栏，与安卓逻辑保持统一
            //https://meego.feishu.cn/larksuite/issue/detail/7343573
            browserVC.keyboardWillHide()
        }
        if SKDisplay.isInSplitScreen {
            NotificationCenter.default.post(name: Notification.Name.ShowDocNewInputComment, object: editorIdentity)
        }
        self.showFloatComment(params: params)
        showFloatComment(params: params)
    }
    
    public func gadegetSessionHasUpdate(minaSession: Any) {
        self.commentModule?.updateSession(session: minaSession)
    }
    
    func showToast(params: [String: Any]) {
        DocsLogger.info("showToast:\(params)", component: LogComponents.comment)
        self.reportSendFinish(params: params)
        let toastView = DocsContainer.shared.resolve(AddCommentToastView.self)
        toastView?.show(on: hostWindow, params: params, delay: 4, onClick: { [weak self] (info) in
            guard let self = `self` else { return }
            let result = info.result
            if result.action == .showDetail {
                DocsLogger.info("click show showDetail commentId:\(info.commentId) commentUUID:\(info.commentUUID)", component: LogComponents.comment)
                self.callbacks[.commentShowToast]?.callbackSuccess()
            } else {
                DocsLogger.info("click retry add comment commentUUID:\(info.commentUUID)", component: LogComponents.comment)
                self.commentModule?.retryAddNewComment(commentId: info.commentUUID ?? "")
            }
        })
    }

    private func reportSendFinish(params: [String: Any]) {
        let data = try? JSONSerialization.data(withJSONObject: params, options: [])
        let model = try? JSONDecoder().decode(CommentToastInfo.self, from: data ?? Data())
        let uuid = model?.commentUUID ?? ""
        let isSuccess = model?.result == .success
        var code: String?
        if let codeStr = params["code"] as? String {
            code = codeStr
        } else if let codeInt = params["code"] as? Int {
            code = "\(codeInt)"
        }
        let errorCode = isSuccess ? nil : code
        self.commentModule?.addNewCommentFinished(commentUUID: uuid, isSuccess: isSuccess, errorCode: errorCode)
    }
}

extension CommentInputService: CommentServiceType {
    public func callFunction(for action: SpaceInterface.CommentEventListenerAction, params: [String : Any]?) {
        if let jsService = model?.jsEngine.fetchServiceInstance(CommentNative2JSService.self) {
            jsService.callFunction(for: action, params: params)
        } else if let delegate = delegate,
                  let jsService = delegate.fetchServiceInstance(token: gadgetInfo?.objToken, CommentNative2JSService.self) {
            jsService.callFunction(for: action, params: params)
        } else {
            DocsLogger.error("callFunction js service is nil", component: LogComponents.comment)
        }
    }
    
    public var callback: DocWebBridgeCallback? {
        // 不需要回调
        return nil
    }
    
}


extension Notification.Name {
    
    public static let ShowDocNewInputComment: Notification.Name = Notification.Name("Comment.vc.ShowDocNewInputComment")
}
