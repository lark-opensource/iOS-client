//
//  MinutesCommentModule.swift
//  SKCommon
//
//  Created by huayufan on 2022/11/9.
//  


import UIKit
import Swinject
import LarkContainer
import SKFoundation
import SKUIKit
import SpaceInterface
import UniverseDesignToast
import SKCommon
import SKInfra

public class DocCommentModuleSDKImpl {
    
    public var docsInfo: DocsInfo
    
    private var rnCommentDataManager: RNCommentDataManager
    private var rnCommonDataManager: RNCommonDataManager
    
    lazy var rnAPI: CommentRNAPIAdaper = {
        return CommentRNAPIAdaper(rnRequest: self,
                                  commentService: self,
                                  dependency: self)
    }()
        
    
    lazy var commentModule: FloatCommentModule = {
        let module = FloatCommentModule(dependency: self, apiAdaper: self.rnAPI)
        return module
    }()
        
    
    private weak var dependency: DocCommentModuleDependency?
    
    private var permission: CommentModulePermission
    
    public var isCanSendComment = true
    public var isShowComment = true
    
    /// 业务方设置的交集
    private var commentMetadata: [String] = []
    
    /// RN全量数据
    private var rnCommentDataDict: [String: Comment] = [:]
    
    private var receiveData = RNCommentData()
    
    /// 根据业务方的交集得到的评论数据
    lazy var commentData: CommentData = CommentData.empty()

    var fakeComment: CommentShowInputModel?
    
    var activeCommentId: String?
    
    let paramsBody: CommentModuleParamsBody
    
    required public init(paramsBody: CommentModuleParamsBody) {
        Self.registerRN()
        self.paramsBody = paramsBody
        self.docsInfo = DocsInfo(type: DocsType(rawValue: paramsBody.type), objToken: paramsBody.token)
        self.dependency = paramsBody.dependency
        self.permission = paramsBody.permission
        // reaction
        self.rnCommonDataManager = RNCommonDataManager(fileToken: docsInfo.objToken, type: docsInfo.type.rawValue)
        
        // comment
        self.rnCommentDataManager = RNCommentDataManager(fileToken: docsInfo.objToken, type: docsInfo.type.rawValue)
        self.rnCommentDataManager.needEndSync = false
        self.rnCommentDataManager.delegate = self
        self.rnCommentDataManager.beginSync()

        _setTranslateLang(paramsBody.translateLang)
        _fetchComment()
        _fetchPermission()
    }

    static private func registerRN() {
        guard RNManager.manager.hadStarSetUp == false else {
            DocsLogger.info("[comment sdk] RN had starSetUp", component: LogComponents.comment)
            return
        }
        DocsLogger.warning("[comment sdk] registerRN has not setup yet", component: LogComponents.comment)
        NotificationCenter.default.post(name: Notification.Name.SetupDocsRNEnvironment, object: nil, userInfo: [:])
    }

    private func _fetchComment() {
        rnCommentDataManager.fetchComment { [weak self] in
            guard let self = self else { return }
            self.saveRNCommentDataDict(with: $0)
            self.dependency?.didReceiveCommentData(commentData: RemoteCommentData.convert(from: $0), action: .fetch)
        }
    }

    // TODO: PermissionSDK 这里没有用到拉取权限的结果，可能只是为了更新缓存，后续移除缓存后直接删除
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func _fetchPermission() {
        guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self) else {
            DocsLogger.error("[comment sdk] resolve permission error", component: LogComponents.comment)
            return
        }
        let type = docsInfo.type.rawValue
        permissionManager.fetchUserPermissions(token: docsInfo.token, type: type) { [weak self] info, error in
            guard let self = self else { return }
            if let error = error {
                DocsLogger.error("[comment sdk] fetch permission error", error: error, component: LogComponents.comment)
                return
            }
            DocsLogger.info("[comment sdk] fetch type:\(type) permission succee", error: error, component: LogComponents.comment)
        }
    }
    
    private func _setTranslateLang(_ translateLang: CommentTranslateLang) {
        self.rnCommentDataManager.setTranslateEnableLang(auto: false, lang: translateLang.rawValue, response: { _ in })
    }
    
    func jsonString(_ obj: Any) -> String {
        guard JSONSerialization.isValidJSONObject(obj) else {
            DocsLogger.error("[comment sdk] isValidJSONObject: false", component: LogComponents.comment)
            spaceAssertionFailure("JSONSerialization, not Valid data")
            return ""
        }
        guard let responseData = try? JSONSerialization.data(withJSONObject: obj, options: []),
              let responseDataStr = String(data: responseData, encoding: String.Encoding.utf8) else {
            DocsLogger.error("[comment sdk] JSON serialization fail", component: LogComponents.comment)
            return ""
        }
        return responseDataStr
    }
    
    enum DisplayMode {
        case newInput
        case float
    }
 
    var displayMode: DisplayMode = .newInput
    
    deinit {
        DocsLogger.info("[comment sdk] deinit", component: LogComponents.comment)
        rnCommentDataManager.endSync()
        CommentTranslationTools.shared.clear()
        if !UserScopeNoChangeFG.HYF.commentTranslateConfig {
            SpaceTranslationCenter.standard.config = nil
        }
    }
}

extension DocCommentModuleSDKImpl: DocCommentModuleSDK {
    
    public func setCommentMetadata(body: CommentMetadataParamsBody) {
        DocsLogger.info("[comment sdk] set metadata count:\(body.commentIds.count)", component: LogComponents.comment)
        self.commentMetadata = body.commentIds
        filterComments()
    }
    
    /// 和业务方评论取交集
    private func filterComments() {
        let rnData = RNCommentData()
        // 重新序列化的原因是：comment为内存引用，确保间隔的数据更新不会相互影响
        rnData.serialize(data: self.receiveData.rawData ?? [:])
        self.saveRNCommentDataDict(with: rnData)
        var containFakeComment = false
        var successCommentId: String?
        let comments = commentMetadata.compactMap {
            let comment = self.rnCommentDataDict[$0]
            comment?.addHeader()
            
            // 正在发送评论
            if let fake = fakeComment, fake.localCommentID == $0 {
                containFakeComment = true
            }
            // 发送评论成功
            if let fake = fakeComment, fake.localCommentID == comment?.commentUUID {
                successCommentId = comment?.commentID
            }
            
            return comment
        }
        let permission = self.permission.toInnerPermission()
        let commentData = CommentData(comments: comments,
                    currentPage: nil,
                    style: .normalV2,
                    docsInfo: docsInfo,
                    commentType: .card,
                    commentPermission: permission)
        self.commentData = commentData
        updatePermission(permission: self.permission)
        for comment in self.commentData.comments {
            CommentConstructor.updatePermission(comment: comment, canManageDocs: false, canEdit: false)
        }
        
        if containFakeComment, let fake = fakeComment {
            let activeCommentId = fake.localCommentID ?? ""
            self.activeCommentId = activeCommentId
            self.commentData.setActiveComment(activeCommentId)
            DocsLogger.info("[comment sdk] show loading comment",
                             component: LogComponents.comment)
            showCommentCards(body: CommentShowCardParamsBody(commentId: activeCommentId))
        } else if let commentId = successCommentId {
            self.activeCommentId = commentId
            self.commentData.setActiveComment(commentId)
            rnCommentDataDict[self.fakeComment?.localCommentID ?? ""] = nil
            self.fakeComment = nil
            self.displayMode = .float
            DocsLogger.info("[comment sdk] show success comment",
                             component: LogComponents.comment)
            showCommentCards(body: CommentShowCardParamsBody(commentId: commentId))
            self.displayMode = .float
        } else if commentModule.isVisiable, self.displayMode != .newInput {
            self.commentData.setActiveComment(activeCommentId ?? "")
            DocsLogger.info("[comment sdk] update comment visiable",
                             component: LogComponents.comment)
            showCommentCards(body: CommentShowCardParamsBody(commentId: activeCommentId ?? ""))
        } else {
            DocsLogger.info("[comment sdk] no commentId found or comment is invisible", component: LogComponents.comment)
        }
        var commenIdArray: [[String: String]] = []
        self.commentMetadata.forEach { commenIdArray.append(["commentId": $0]) }
        self.rnCommentDataManager.addTranslateComments(commentIds: commenIdArray, response: { _ in })
    }
    
    public func fetchComment() {
        _fetchComment()
    }
    
    public func showCommentCards(body: CommentShowCardParamsBody) {
        DocsLogger.info("[comment sdk] showCards commentId:\(body.commentId) replyId:\(body.replyId ?? "")",
                         component: LogComponents.comment)
        
        commentData.setActiveComment(body.commentId)
        if commentMetadata.isEmpty {
            DocsLogger.error("[comment sdk] metadata is empty",
                             component: LogComponents.comment)
        }
        if !commentModule.isVisiable {
            guard let topMostVC = topMost else {
                DocsLogger.error("[comment sdk] topMost is nil",
                                 component: LogComponents.comment)
                return
            }
            commentModule.show(with: topMostVC)
            commentModule.update(commentData)
        } else {
            commentModule.update(commentData)
        }
        let canCopy = commentData.commentPermission.contains(.canCopy)
        let canTranslate = commentData.commentPermission.contains(.canTranslate)
        if canTranslate, !UserScopeNoChangeFG.HYF.commentTranslateConfig {
            let config = SpaceTranslationCenter.Config(autoTranslate: false,
                                                       displayType: .init(rawValue: paramsBody.translateMode.rawValue) ?? .onlyShowTranslation,
                                                       enableCommentTranslate: true)
            SpaceTranslationCenter.standard.config = config
        }
        commentModule.setCaptureAllowed(canCopy)
        self.displayMode = .float
    }
    
    
    public func updatePermission(permission: CommentModulePermission) {
        self.permission = permission
        let innerPermission = permission.toInnerPermission()
        commentData.commentPermission = innerPermission
        commentData.comments.forEach {
            $0.permission = innerPermission
        }
    }
    
    public func showCommentInput(body: CommentInputParamsBody) {
        DocsLogger.info("[comment sdk] showInpu commentId:\(body.tmpCommentId)",
                         component: LogComponents.comment)
        if let topViewController = topMost {
            self.displayMode = .newInput
            commentModule.show(with: topViewController)
            let model = CommentShowInputModel(isWhole: false,
                                              token: docsInfo.token,
                                              type: .new,
                                              docsInfo: docsInfo,
                                              localCommentId: body.tmpCommentId,
                                              quote: body.quote)
            commentModule.setCaptureAllowed(permission.canCopy)
            commentModule.update(model)
            self.fakeComment = model
        } else {
            DocsLogger.info("[comment sdk] show commentId:\(body.tmpCommentId) found topMost is nil", component: LogComponents.comment)
        }
    }
    
    public func updateTranslateLang(translateLang: CommentTranslateLang) {
        _setTranslateLang(translateLang)
    }
    
    public func dismiss() {
        fakeComment = nil
        commentModule.hide()
    }
    
    public var isVisiable: Bool {
        commentModule.isVisiable
    }
    
    var topMost: UIViewController? {
        guard let dependency = self.dependency else {
            DocsLogger.error("[comment sdk] topMost is nil", component: LogComponents.comment)
            return nil
        }
        guard let topViewController = dependency.topViewController else {
            DocsLogger.error("[comment sdk] topViewController is nil", component: LogComponents.comment)
            return nil
        }
        DocsLogger.info("[comment sdk] topMost:\(topViewController)", component: LogComponents.comment)
        return topViewController
    }
}



// MARK: - CommentDataDelegate
extension DocCommentModuleSDKImpl: CommentDataDelegate {
    public func didReceiveCommentData(response: RNCommentData, eventType: RNCommentDataManager.CommentReceiveOperation) {
        // change
        switch eventType {
        case .sendCommentsData:
            self.receiveData = response
            DocsLogger.info("[comment sdk] change count:\(response.comments.count)", component: LogComponents.comment)
            self.dependency?.didReceiveCommentData(commentData: RemoteCommentData.convert(from: response), action: .change)
        default:
            break
        }
    }
    
    public func didReceiveUpdateFeedData(response: Any) {
        
    }
    
    func saveRNCommentDataDict(with rnCommentData: RNCommentData) {
        rnCommentData.comments.forEach {
            self.rnCommentDataDict[$0.commentID] = $0
        }
    }
}

extension DocCommentModuleSDKImpl: DocsCommentDependency {

    public var commentDocsInfo: CommentDocsInfo {
        docsInfo
    }

    public func dismissCommentView() {
        // do nothing
    }

    public func keyboardChange(didTrigger event: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions, textViewHeight: CGFloat) {
        guard let event = CommentKeyboardOptions.KeyboardEvent.convertKeyboardEvent(event) else {
            return
        }
        let opetions = CommentKeyboardOptions(event: event,
                                              beginFrame: options.beginFrame,
                                              endFrame: options.endFrame,
                                              animationCurve: options.animationCurve,
                                              animationDuration: options.animationDuration)
        dependency?.keyboardChange(options: opetions, textViewHeight: textViewHeight)
    }
    
    public func showUserProfile(userId: String, from: UIViewController?) {
        if !paramsBody.canOpenProfile {
            dependency?.showUserProfile(userId: userId)
        } else {
            DocsLogger.error("[comment sdk] can not show profile externally", component: LogComponents.comment)
        }
    }
    
    public func openDocs(url: URL) {
        if !paramsBody.canOpenURL {
            dependency?.openURL(url: url)
        } else {
            DocsLogger.error("[comment sdk] can not opendocs externally", component: LogComponents.comment)
        }
    }
    
    public var businessConfig: CommentBusinessConfig {
        var translateConfig: CommentTranslateConfig?
        if permission.canTranslate {
            translateConfig = CommentTranslateConfig(autoTranslate: false,
                                                     displayType: .init(rawValue: paramsBody.translateMode.rawValue) ?? .onlyShowTranslation,
                                                     enableCommentTranslate: true)
        }
        return CommentBusinessConfig(canOpenURL: paramsBody.canOpenURL,
                                     canOpenProfile: paramsBody.canOpenProfile,
                                     translateConfig: translateConfig)
    }
}


// MARK: - CommentRNRequestType

extension DocCommentModuleSDKImpl: CommentRNRequestType {
    public var commentManager: RNCommentDataManager? {
        rnCommentDataManager
    }
    
    public var commonManager: RNCommonDataManager? {
        rnCommonDataManager
    }
    
    public func callAction(_ action: CommentEventListenerAction, _ data: [String: Any]?) {
        guard let params = data else {
            DocsLogger.error("[comment sdk] callFunction params is nil", component: LogComponents.comment)
            return
        }
        let commentData = RNCommentData()
        commentData.serialize(data: params)
        let data = RemoteCommentData.convert(from: commentData)
        switch action {
        case .change:
            DocsLogger.error("[comment sdk] change should not be here", component: LogComponents.comment)
            
        case .publish:
            dependency?.didReceiveCommentData(commentData: data, action: .publish)
            
        case .delete:
            dependency?.didReceiveCommentData(commentData: data, action: .delete)
            
        case .resolve:
            dependency?.didReceiveCommentData(commentData: data, action: .resolve)
            
        case .edit:
            dependency?.didReceiveCommentData(commentData: data, action: .edit)
            
        case .cancel:
            guard let typeStr = params["type"] as? String,
                  let type = CancelType(rawValue: typeStr)  else {
                DocsLogger.error("[comment sdk] cancel params error", component: LogComponents.comment)
                return
            }
            var cancelType: CommentModuleCancelType
            switch type {
            case .newInput:
                cancelType = .newInput
            default:
                if self.displayMode == .newInput {
                    cancelType = .close(.inputView)
                    fakeComment = nil
                } else {
                    cancelType = .close(.floatCard)
                }
            }
            dependency?.cancelComment(type: cancelType)
        default:
            break
        }
    }
}


// MARK: - CommentServiceType
extension DocCommentModuleSDKImpl: CommentServiceType {

    public var chatId: String? {
        nil
    }
    
    public var shouldShowWatermark: Bool {
        true
    }
    
    public func callFunction(for action: CommentEventListenerAction, params: [String: Any]?) {
        guard let params = params else {
            DocsLogger.error("[comment sdk] callFunction params is nil", component: LogComponents.comment)
            return
        }
        switch action {
        case .change:
            DocsLogger.error("[comment sdk] change should not be here", component: LogComponents.comment)
        case .switchCard:
            guard let height = params["height"] as? CGFloat,
                  let commentId = params["comment_id"] as? String else {
                DocsLogger.error("[comment sdk] switchCard params error", component: LogComponents.comment)
                return
            }
            self.activeCommentId = commentId
            dependency?.didSwitchCard(commentId: commentId, height: height)
        case .cancel:
            guard let typeStr = params["type"] as? String,
                  let type = CancelType(rawValue: typeStr)  else {
                DocsLogger.error("[comment sdk] cancel params error", component: LogComponents.comment)
                return
            }
            var cancelType: CommentModuleCancelType
            switch type {
            case .newInput:
                cancelType = .newInput
                fakeComment = nil
            default:
                if self.displayMode == .newInput {
                    cancelType = .close(.inputView)
                } else {
                    cancelType = .close(.floatCard)
                }
            }
            self.activeCommentId = nil
            dependency?.cancelComment(type: cancelType)
        default:
            break
        }
    }
    
    public func simulateJSMessage(_ function: DocsJSService, params: [String: Any]) {
        // do nothing
    }
    
    public func fetchServiceInstance<H>(_ service: H.Type) -> H? where H: JSServiceHandler {
        // do nothing
        return nil
    }
    
    public func showUserProfile(userId: String) {
        // do nothing
    }
    
    public var topMostViewController: UIViewController? {
        // do nothing
        return dependency?.topViewController
    }
    
    
}


extension DocCommentModuleSDKImpl: CommentRNAPIAdaperDependency {
    
    public var docInfo: DocsInfo? { docsInfo }

    public func showError(msg: String) {
        let onView = commentModule.commentPluginView.window ?? commentModule.commentPluginView
        UDToast.showFailure(with: msg, on: onView)
    }  
}
