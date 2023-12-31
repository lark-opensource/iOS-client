//
//  GadgetCommentService.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/6.
//  


import SKFoundation
import LarkUIKit
import SKCommon
import SpaceInterface

class GadgetCommentService {
    
    typealias ShowCommentCallBack = () -> Void
    
    var commentDocsInfo: CommentDocsInfo
    
    var commentShowing = false
    
    var canSendComment = true
    
    var dependency: CommentPluginDependency?
    
    weak var jsServiceHandler: GadgetJSServiceHandlerType?
    
    weak var delegate: GadgetJSServiceHandlerDelegate?
    
    var commentModule: FloatCommentModule?
    
    var docInfo: DocsInfo? {
        return commentDocsInfo as? DocsInfo
    }
    init(docInfo: CommentDocsInfo,
         dependency: CommentPluginDependency,
         jsServiceHandler: GadgetJSServiceHandlerType,
         delegate: GadgetJSServiceHandlerDelegate?) {
        self.commentDocsInfo = docInfo
        self.dependency = dependency
        self.jsServiceHandler = jsServiceHandler
        self.delegate = delegate
    }
    
    deinit {
        self.hideComment(animated: false, completion: nil)
    }
    
    func setupFloatCommentModule() {
        guard let commentRequest = self.delegate?.fetchServiceInstance(token: commentDocsInfo.objToken, CommentRequestNative.self) else {
            DocsLogger.error("etch commentRequest nil", component: LogComponents.gadgetComment)
            return
        }
        if commentModule == nil {
            let api = CommentRNAPIAdaper(rnRequest: commentRequest,
                                         commentService: self,
                                         dependency: self)
            let module = FloatCommentModule(dependency: self,
                                            apiAdaper: api)
            self.commentModule = module
        }
    }
}

// MARK: 展示评论

extension GadgetCommentService {
    
    func showFloatComment(_ commentData: CommentData, session: Any?) {
        setupFloatCommentModule()
        if commentModule?.isVisiable == false {
            if let topViewController = self.dependency?.topViewController {
                commentModule?.show(with: topViewController)
            } else {
                DocsLogger.error("topViewController is  nil", component: LogComponents.gadgetComment)
            }
        }
        commentModule?.update(commentData)
        if let session = session {
            commentModule?.updateSession(session: session)
        }
        let allowCopy = commentData.commentPermission.contains(.canCopy)
        commentModule?.setCaptureAllowed(allowCopy)
    }
    
    /// 展示或者更新评论UI
    func showComment(_ params: [String: Any], session: Any?) {
        let docsInfo = self.commentDocsInfo as? DocsInfo
        // 小程序的局部评论无图片, 不处理 canDownload 和 canPreviewImg
        let optioanlCommentData = CommentConstructor.constructCommentData(params,
                                                                          docsInfo: docsInfo,
                                                                          canManageDocs: nil,
                                                                          canEdit: nil,
                                                                          chatID: "")
        CommentTranslationTools.shared.docsInfo = docsInfo
        guard let commentData = optioanlCommentData else {
            DocsLogger.info("commentData 转换失败, params\(params)", component: LogComponents.gadgetComment)
            return
        }
        let msg = "showCommentList desc:\(commentData.commentDesc)"
        DocsLogger.info(msg, component: LogComponents.gadgetComment)
        showFloatComment(commentData, session: session)
    }
    
}


// MARK: - 更新/切换评论
extension GadgetCommentService {
    
    func updateCurrentUser(params: [String: Any]) {
        if let user = try? CommentUser(params: params) {
            self.docInfo?.commentUser = user
        } else {
            DocsLogger.error("updateCurrentUser params is invalid", component: LogComponents.comment)
        }
    }
}

// MARK: - 关闭评论

extension GadgetCommentService {
    
    func hideComment(_ needCancel: Bool = true, animated: Bool, completion: ((Bool) -> Void)?) {
        commentModule?.hide()
    }
    
}

// MARK: - 评论非公共部分

extension GadgetCommentService: CommentServiceType {
    
    
    func callFunction(for action: CommentEventListenerAction, params: [String: Any]?) {
        guard let native2JSService = self.delegate?.fetchServiceInstance(token: commentDocsInfo.objToken, CommentNative2JSService.self) else {
            DocsLogger.error("GadgetCommentService native2JSService is nil", component: LogComponents.gadgetComment)
           return
        }
        native2JSService.callFunction(for: action, params: params)
    }
    
    func openDocs(url: URL) {
        self.delegate?.openURL(url: url)
    }
    
    func showUserProfile(userId: String) {
        if docInfo?.commentUser?.useOpenId == true {
            self.delegate?.openProfile(id: userId)
            DocsLogger.info("showUserProfile with openId", component: LogComponents.gadgetComment)
        } else {
            DocsLogger.info("showUserProfile with userId", component: LogComponents.gadgetComment)
            guard let currentVC = commentModule?.commentVC else {
                DocsLogger.info("currentBrowserVC cannot be nil", component: LogComponents.gadgetComment)
                return
            }
            // TODO: - hyf 待测试
            HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: currentVC))
        }
    }
    
    var topMostViewController: UIViewController? {
        return dependency?.topViewController
    }
}
