//
//  CommentShowCardsService.swift
//  SpaceKit
//
//  Created by weidong fu on 6/4/2018.
// swiftlint:disable file_length

import Foundation
import WebKit
import SwiftyJSON
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SKUIKit
import LarkEmotionKeyboard
import LarkWebViewContainer
import EENavigator
import SKResource
import UniverseDesignToast
import SpaceInterface
import UniverseDesignDialog
import SKInfra

/// 处理点击文档里黄色浮层，触发的评论
class CommentShowCardsService: BaseJSService {
    
    enum CommentUIStyle: String {
        case card
        case embed
    }
    /// MS场景下，其他地方需要监听commentVC present完成后做后续的UI操作
    var presentCompletions: [PresentCompletion] = []
    
    var suppendCommentNav: SKNavigationController?
    
    var canShowComment: Bool = true
    
    var commentStyle: CommentUIStyle = .card
    
    typealias OriginData = (commentData: CommentData?, params: [String: Any])
    
    var originData: OriginData = (nil, [:])
    
    private(set) var disposeBag = DisposeBag()
    
    var appIsResignActive = false
    
    var conferenceContext: ConferenceContext?
    
    var secretLevelSelectProxy: SecretLevelSelectProxy?
    
    var commentTemplateUrl: String?
    
    lazy var emptyCommentData: CommentData = {
        let emptyData = CommentData(comments: [],
                                    currentPage: nil,
                                    style: .normalV2,
                                    docsInfo: self.commentDocsInfo,
                                    nPercentScreenHeight: nil,
                                    commentType: .card,
                                    commentPermission: CommentPermission(rawValue: 0))
        return emptyData
    }()
    
    var preDynamicOrientationMask: UIInterfaceOrientationMask?

    var _asideCommentModule: AsideCommentModuleType?
    var asideCommentModule: AsideCommentModuleType? {
        if let module = _asideCommentModule {
            return module
        } else {
            let api = CommentWebAPIAdaper(commentService: self)
            let params = CommentModuleParams(dependency: self, apiAdaper: api)
            let module = DocsContainer.shared.resolve(AsideCommentModuleType.self,
                                                      argument: params)
            module?.commentPluginView.isHidden = true
            _asideCommentModule = module
            api.willSendToWeb = { [weak self] action in
                guard let self = self else { return [:] }
                switch action {
                case .switchCard:
                    self.ui?.catalog?.hideCatalog()
                default:
                    return [:]
                }
                return [:]
            }
            return module
        }
     }

    
    var _floatCommentModule: FloatCommentModuleType?
    var floatCommentModule: FloatCommentModuleType? {
        if let module = _floatCommentModule {
            return module
        } else {
            let params = CommentModuleParams(dependency: self, apiAdaper: CommentWebAPIAdaper(commentService: self))
            let module = DocsContainer.shared.resolve(FloatCommentModuleType.self, argument: params)
            _floatCommentModule = module
            return module
        }
     }

    var notiTables = NSHashTable<NSObjectProtocol>(options: .weakMemory)
    
    // 0.3s是showCard动画时间
    let debounceInterval = DispatchQueueConst.MilliSeconds_250
    
    var translateConfig: CommentBusinessConfig.TranslateConfig?
    
    /// 记录点击事件时间戳
    var commentStatsExtra: CommentStatsExtra?

    lazy var dismissDebounce: DebounceProcesser = {
        return DebounceProcesser()
    }()

    enum DataAction {
        case showCard(CommentData)
    }
    lazy var asideDataQueue = CommentUpdateDataQueue<DataAction>()

    // 文档附件权限, 用于决定评论图片的预览和下载权限
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private var docAttachmentPermission: UserPermissionAbility?
    private var attachmentPermissionService: UserPermissionService?
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        EmojiImageService.default?.loadReactions()
        model.browserViewLifeCycleEvent.addObserver(self)
        model.permissionConfig.hostPermissionEventNotifier.addObserver(self)
        addNotification()
    }

    deinit {
        DocsLogger.info("\(editorIdentity) CommentShowCardsService, deinit", component: LogComponents.comment)
        self.ui?.commentPadDisplayer?.removePadCommentView()
        CommentDebugModule.clear()
        
        for noti in notiTables.allObjects {
            NotificationCenter.default.removeObserver(noti)
        }
        notiTables.removeAllObjects()
    }
}

extension CommentShowCardsService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.commentShowCards,
                .utilShowPartialLoading,
                .utilHidePartialLoading,
                .commentResultNotify,
                .commentCloseCards,
                .scrollComment,
                .commonEventListener,
                .openImageForComment,
                .simulateCloseCommentImage,
                .simulateSuppendComment,
                .simulateResumeComment,
                .commentHideReaction,
                .commentConferenceInfo,
                .simulateOnRoleChange,
                .notifyEvent,
                .setCopyUrlTemplate,
                .simulateForceCommentPortraint,
                .getTranslationConfig,
                .simulateCommentEntrance,
                .simulateClearCommentEntrance]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        
    }

    // swiftlint:disable cyclomatic_complexity
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {

        DocsLogger.info("\(editorIdentity) CommentShowCardsService handle \(serviceName), active: \(params["active"]) isInVC: \(isInVideoConference)",
                        component: LogComponents.comment,
                        traceId: browserTrace?.traceRootId)
        let service = DocsJSService(serviceName)
        switch service {
        // 在文档中点击黄色浮层，展示卡片
        case .commentShowCards:
            dismissDebounce.endDebounce()
            clearSuspendCommentVC()
            CommentDebugModule.begin()
            showCommentList(params)
            model?.vcFollowDelegate?.follow(onOperate: .vcOperation(value: .selectComments(info: params)))
        case .commentCloseCards:
            clearSuspendCommentVC()
            handleCloseCard(params: params)

        case .scrollComment:
            let commentData = originData.commentData
            guard let currentData = commentData,
                let toCommentID = params["cur_comment_id"] as? String,
                let comment = currentData.comments.first(where: { $0.commentID == toCommentID }),
                let replyId = params["replyId"] as? String else {
                    DocsLogger.error("scrollComment, toCommentID=\(params["cur_comment_id"])", component: LogComponents.comment, traceId: browserTrace?.traceRootId)
                    return
                }
            let currentCommentID = commentData?.currentCommentID ?? ""
            let isActiveComment = (toCommentID == commentData?.currentCommentID)
            currentData.currentCommentID = toCommentID
            var percent = (params["replyPercentage"] as? CGFloat) ?? 0
            var quote = ""
#if BETA || ALPHA || DEBUG
            quote = comment.quote ?? ""
#endif
            let msg = "[comment scroll] receive toCommentID=\(toCommentID), replyId=\(replyId), percent=\(percent) isActiveComment:\(isActiveComment) quote:\(quote)"
            DocsLogger.info(msg, component: LogComponents.comment, traceId: browserTrace?.traceRootId)
            percent = min(max(0, percent), 1.0)
            CommentDebugModule.log(msg)
            if !isActiveComment, !iPadUseNewCommment {
                DocsLogger.error("[comment scroll] fail,cur:\(currentCommentID) to:\(toCommentID)", component: LogComponents.comment, traceId: browserTrace?.traceRootId)
                return
            }
            if iPadUseNewCommment {
                asideCommentModule?.scrollComment(commentId: toCommentID, replyId: replyId, percent: percent)
            } else {
                floatCommentModule?.scrollComment(commentId: toCommentID, replyId: replyId, percent: percent)
            }
        case .commonEventListener:
            guard let cb = callback else {
                DocsLogger.error("CommentShowCardsService commonEventListener callback is nil", component: LogComponents.comment, traceId: browserTrace?.traceRootId)
                return
            }
            let bridgeCallback = DocWebBridgeCallback.lark(cb)
            commentStyle = checkCurrentCommentStyle()
            bridgeCallback.callFunction(action: .switchStyle, params: ["style": commentStyle.rawValue])
            
        case .openImageForComment:
            // 现VC评论图片和评论组件内图片逻辑分开，导致VC图片关闭时未同步到评论组件
            // 需要同步关闭
            if  let active = params["active"] as? Int,
                active == -1 {
                self.closeCommentImage()
            }
        case .simulateCloseCommentImage:
            CommentDebugModule.log("simulateCloseCommentImage")
            self.closeCommentImage()
        case .commentHideReaction:
            hideReaction()
        case .commentConferenceInfo:
            conferenceContext = ConferenceContext(params)
            DocsLogger.info("update conferenceInfo", component: LogComponents.comment, traceId: browserTrace?.traceRootId)
        case .simulateOnRoleChange:
            handleVCFollowOnRoleChange(params: params)
        case .simulateSuppendComment:
            suspendPhoneCommentVC()
        case .simulateResumeComment:
            resumePhoneCommentVC()
        case .notifyEvent:
            guard let eventName = params["event"] as? String, let event = UtilNotifyEventService.Event(rawValue: eventName) else {
                DocsLogger.error("params not valid for \(serviceName), params is \(params)")
                return
            }
            switch event {
            case .delete:
                handleDocsDelete()
            case .keyDelete:
                break
            case .versionRecover:
                break
            case .notFound:
                break
            }
        case .setCopyUrlTemplate:
            guard let templateUrl = params["template"] as? String else {
                DocsLogger.error("comment template url is nil", component: LogComponents.comment)
                return
            }
            DocsLogger.info("set comment url template done", component: LogComponents.comment)
            self.commentTemplateUrl = templateUrl
            _floatCommentModule?.updateCopyTemplateURL(urlString: templateUrl)
            _asideCommentModule?.updateCopyTemplateURL(urlString: templateUrl)
        case .simulateForceCommentPortraint:
            guard let force = params["force"] as? Bool else {
                return
            }
            self.forcePortraint(force: force)
            
        case .getTranslationConfig:
            guard let data = try? JSONSerialization.data(withJSONObject: params, options: []),
                let config = try? JSONDecoder().decode(CommentBusinessConfig.TranslateConfig.self, from: data) else {
                    DocsLogger.error("decode translation config error", extraInfo: params, component: LogComponents.comment)
                    return
            }
            translateConfig = config
            DocsLogger.info("translation config", extraInfo: params, component: LogComponents.comment)

        case .simulateCommentEntrance:
            if let statsExtra: CommentStatsExtra = params.mapModel() {
                commentStatsExtra = statsExtra
            }
            var bothRenderEdit = true
            if let viewOnly = params["viewOnly"] as? Bool {
                bothRenderEdit = !viewOnly
            }
            commentStatsExtra?.updateUtilEdit(utilEdit: bothRenderEdit)
        case .simulateClearCommentEntrance:
            self.commentStatsExtra = nil
        default: break
        }
    }
}

// MARK: - PRIVATE METHOD
extension CommentShowCardsService {

    private func showCommentList(_ params: [String: Any]) {
        var optioanlCommentData = self.parseCommentModel(params: params)
        let commentTranslationTool = DocsContainer.shared.resolve(CommentTranslationToolsInterface.self) 
        commentTranslationTool?.update(commentDocsInfo: hostDocsInfo)
        guard let commentData = optioanlCommentData else {
            DocsLogger.error("commentData construct fail, params\(params)", component: LogComponents.comment)
            return
        }
        let role = conferenceInfo.followRole
        let extraMsg = "isInVC:\(isInVideoConference) role:\(role)"
        let msg = "\(editorIdentity) \(ObjectIdentifier(self)) showCommentList desc:\(commentData.commentDesc) \(extraMsg)"
        DocsLogger.info(msg, component: LogComponents.comment)
        CommentDebugModule.log(msg)
        self.originData = (commentData: commentData, params: params)
        if !appIsResignActive {
            // app在后台时宽度检测不准确，不检测当前样式
            self.commentStyle = self.checkCurrentCommentStyle()
        }
        if !commentData.cancelHightLight {
            ui?.uiResponder.resign()
        }
        
        if self.iPadUseNewCommment, !commentData.isInPicture {
            hidePhoneCommentView(false, animated: false, completion: nil)
            innerShowCommentViewiPad(commentData: commentData, params: params)
            // 隐藏覆盖式目录
            ui?.catalog?.hideCatalog()
        } else {
            hidePadCommentView(false)
            innerShowCommentViewiPhone(commentData: commentData, params: params)
        }
        fetchCommentImagePermissionIfNeeded(commentData: commentData)
    }
    
    func callFunction(for action: CommentEventListenerAction, params: [String: Any]?) {
        guard let native2JSService = self.model?.jsEngine.fetchServiceInstance(CommentNative2JSService.self) else {
            return
        }
        native2JSService.callFunction(for: action, params: params)
    }
    
    func handleCloseCard(params: [String: Any]) {
        // 如果是前端主动调用commentCloseCards，是不需要再通过RN触发cancel
        // 但是在VC follow下iOS会主动调用commentCloseCards，这时需要出发cancel
        let json = JSON(params)
        let needCancel = json["needCancel"].boolValue
        let source = json["source"].stringValue
        if json["source"].stringValue == CommentSource.windowFloating.rawValue, isPadCommmentShowing {
            DocsLogger.info("iPad reject to close commentView when source is windowFloating", component: LogComponents.comment)
            return
        }
        let msg = "close card source:\(source)"
        CommentDebugModule.log(msg)
        DocsLogger.info(msg, component: LogComponents.comment)
        dismissCommentView(needCancel: needCancel, animated: needCancel, completion: nil)
    }

    private func handleDocsDelete() {
        guard let token = hostDocsInfo?.token, !token.isEmpty else { return }
        let manager = DocsContainer.shared.resolve(CommentDraftManagerInterface.self)
        manager?.handleDocsDelete(token: token)
        dismissCommentView(animated: false, completion: nil)
    }

    func parseCommentModel(params: [String: Any]) -> CommentData? {
        let userCanDownload: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            userCanDownload = model?.permissionConfig.getPermissionService(for: .hostDocument)?.validate(operation: .download).allow ?? false
        } else {
            userCanDownload = model?.permissionConfig.hostUserPermissions?.canDownload() ?? false
        }
        let canDownload = CommentCACHelper.commentImageCanDownload(userCanDownload: userCanDownload)
        let canPreviewImg = CommentCACHelper.commentImageCanPreview()
        let setting = [CommentPermission.canDownload.rawValue: canDownload,
                       CommentPermission.disableImgPreview.rawValue: !canPreviewImg]
        let canManage = self.canManageDocMeta()
        let canEdit = self.canEdit()
        let model = CommentConstructor.constructCommentData(params,
                                                            docsInfo: self.hostDocsInfo,
                                                            permissionSetting: setting,
                                                            canManageDocs: canManage,
                                                            canEdit: canEdit,
                                                            chatID: self.model?.hostBrowserInfo.chatId)
        return model
    }

    // 有管理权限
    private func canManageDocMeta() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let service = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                return false
            }
            return service.validate(operation: .managePermissionMeta).allow
        } else {
            let canManage: Bool
            if let permission = model?.permissionConfig.hostUserPermissions {
                let isWiki = hostDocsInfo?.isFromWiki ?? false
                canManage = isWiki ? permission.canSinglePageManageMeta() : permission.canManageMeta()
            } else {
                canManage = false
            }
            return canManage
        }
    }
    
    private func canEdit() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let service = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                return false
            }
            return service.validate(operation: .edit).allow
        } else {
            let editable: Bool
            if let permission = model?.permissionConfig.userPermissions {
                editable = permission.canEdit()
            } else {
                editable = false
            }
            return editable
        }
    }
    
    private func fetchCommentImagePermissionIfNeeded(commentData: CommentData) {
        if syncGetCommentImagePermission() != nil || UserScopeNoChangeFG.CS.commentImageUseDocAttachmentPermission == false { return }
        guard let token = findValidCommentImageToken(commentData: commentData) else { return }
        asyncGetCommentImagePermission(token: token, completion: {_ in})
    }
    
    private func findValidCommentImageToken(commentData: CommentData) -> String? {
        for comment in commentData.comments {
            for reply in comment.commentList {
                for image in reply.imageList where !(image.token ?? "").isEmpty {
                    return image.token
                }
            }
        }
        return nil
    }
}

extension CommentShowCardsService {
    /// -needCancel: 当前端触发的时候不需要再主动调cancel
    func dismissCommentView(needCancel: Bool = true, animated: Bool = true, completion: ((Bool) -> Void)?) {
        hidePadCommentView(needCancel)
        hidePhoneCommentView(needCancel, animated: animated, completion: completion)
    }
    
    func closeCommentImage() {
        _floatCommentModule?.removeAllMenu()
        _asideCommentModule?.removeAllMenu()
    }
    
    func hideReaction() {
        _floatCommentModule?.removeAllMenu()
        _asideCommentModule?.removeAllMenu()
    }
    
    func handleVCFollowOnRoleChange(params: [String: Any]) {
        if let role = params["role"] as? FollowRole {
            DocsLogger.info("change role:\(role)", component: LogComponents.comment)
            if iPadUseNewCommment {
                asideCommentModule?.vcFollowOnRoleChange(role: role)
            } else {
                floatCommentModule?.vcFollowOnRoleChange(role: role)
            }
        }
    }

}

extension CommentShowCardsService {
    
    func cancelHightLight() {
        // 隐藏覆盖式目录
        ui?.catalog?.hideCatalog()
    }

  

    public func hideCommentView(completion: @escaping (() -> Void)) {
        ui?.commentPadDisplayer?.dismissCommentView(animated: true, complete: completion)
    }

    public func scanQR(code: String) {
        DocsLogger.info("scanQR, code=\(code.count)", component: LogComponents.commentPic)
        if let fromVC = UIViewController.docs.topMost(of: self.registeredVC) {
            DocsLogger.info("scanQR, code=\(code.count)", component: LogComponents.commentPic)
            ScanQRManager.openScanQR(code: code,
                                  fromVC: fromVC,
                                  vcFollowDelegateType: .browser(self.model?.vcFollowDelegate))
        }
    }

    func keyboardChange(didTrigger event: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        let keyBoardheight = options.endFrame.height
        var isShow: Bool = false
        if event == .willShow || event == .didShow {
            isShow = true
        } else if event == .willHide || event == .didHide {
            isShow = false
        }

        // 88是inputAccessoryView，44是工具栏高度
        let realKeyBoardHeight = keyBoardheight - 88 + 44
        var visibleHeight: CGFloat = 400.5 //默认值，不会用到
        if let browserView = ui?.hostView as? BrowserView {
            visibleHeight = browserView.frame.size.height - realKeyBoardHeight
        }
        let info = SimulateKeyboardInfo(height: visibleHeight, isShow: isShow, trigger: DocsKeyboardTrigger.comment.rawValue)
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        self.model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
    
    public var isPadCommentEmbeddedStyle: Bool {
        return iPadUseNewCommment
    }

    var conferenceInfo: CommentConference {
        guard let baseVC = navigator?.currentBrowserVC as? BrowserViewController,
              let spaceFollowAPIDelegate = baseVC.spaceFollowAPIDelegate else {
                  return CommentConference(inConference: false, followRole: nil, context: conferenceContext)
        }
        return CommentConference(inConference: baseVC.isInVideoConference, followRole: spaceFollowAPIDelegate.followRole, context: conferenceContext)
    }
    
    var isWindowFloating: Bool {
        guard let baseVC = navigator?.currentBrowserVC as? BrowserViewController else {
           // 如果VC为nil，表示被移除了，默认为浮窗下
           return true
        }
        return baseVC.isWindowFloating
    }
}

extension CommentShowCardsService {
    
    func notificateFrontendToHideFeed() {
        self.model?.jsEngine.callFunction(.hideMessages, params: ["commentPanelOpen": true], completion: nil)
    }
}

// MARK: - DocsCommentDependency
extension CommentShowCardsService: CommentServiceType, DocsCommentDependency {
    var businessConfig: CommentBusinessConfig {
        let hostObjType = hostDocsInfo?.inherentType
        let canCopyCommentLink = UserScopeNoChangeFG.HYF.commentAnchorLinkEnable && (hostObjType == .docX || hostObjType == .slides)
        DocsLogger.info("can copy commentLink:\(canCopyCommentLink) type:\(hostObjType)", component: LogComponents.comment)
        let config = SettingConfig.commentPerformanceConfig
        let monitorConfig = CommentBusinessConfig.MonitorConfig(fpsEnable: config?.fpsEnable ?? false,
                                                 editEnable: config?.editable ?? false,
                                                 loadedEnable: config?.loadEnable ?? false)
        let canShare: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canShare = model?.permissionConfig.getPermissionService(for: .hostDocument)?.validate(operation: .manageCollaborator).allow ?? false
        } else {
            canShare = model?.permissionConfig.hostUserPermissions?.canShare() ?? false
        }
        var bizConfig = CommentBusinessConfig(canOpenURL: false,
                                              canOpenProfile: false,
                                              canCopyCommentLink: canCopyCommentLink,
                                              monitorConfig: monitorConfig,
                                              translateConfig: translateConfig,
                                              canShowDarkName: canShare)
        bizConfig.imagePermissionDataSource = self
        let statisticService = model?.jsEngine.fetchServiceInstance(CommentSendStatisticService.self)
        bizConfig.sendResultReporter = statisticService?.reporter
        return bizConfig
    }

    func forcePortraint(force: Bool) {
        guard let vc = navigator?.currentBrowserVC as? BrowserViewController else {
            DocsLogger.error("can not find browser vc", component: LogComponents.comment)
            return
        }
        if force {
            vc.orientationDirector?.dynamicOrientationMask = .portrait
        } else {
            vc.orientationDirector?.dynamicOrientationMask = preDynamicOrientationMask
        }
        if #available(iOS 16.0, *) {
            vc.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    var browserVCTopMost: UIViewController? {
        return self.isInVideoConference ? self.navigator?.currentBrowserVC : nil
    }

    var vcFollowDelegate: CommentVCFollowDelegateType? { .browser(model?.vcFollowDelegate) }
    
    var commentDocsInfo: CommentDocsInfo {
        return hostDocsInfo ?? DocsInfo(type: .docX, objToken: "")
    }

    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        guard _floatCommentModule?.isVisiable == true else {
            return nil
        }
        if let supportLandscape = hostDocsInfo?.inherentType.landscapeWhenEnteringVCFollow,
            supportLandscape {
            return .allButUpsideDown
        }
        return nil
    }

    // TODO: PermissionSDK: 这里没有正常用安全 SDK 的弹窗管控，需要确认是否漏接了
    var externalCopyPermission: ExternalCopyPermission {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let service = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                return .denied(BundleI18n.SKResource.Doc_Doc_CopyFailed)
            }
            let response = service.validate(operation: .copyContent)
            switch response.result {
            case .allow:
                return .permit
            case let .forbidden(denyType, _):
                switch denyType {
                case .blockByFileStrategy, .blockBySecurityAudit:
                    return .denied(BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
                default:
                    return .denied(BundleI18n.SKResource.Doc_Doc_CopyFailed)
                }
            }
        } else {
            let userCanCopy = ownerAllowCopyFG()
            let cacAllow: Bool
            if let docsInfo = hostDocsInfo {
                cacAllow = CommentCACHelper.commentContentCanCopy(userCanCopy: userCanCopy, docsInfo: docsInfo)
            } else {
                cacAllow = true
            }
            switch (cacAllow, userCanCopy) {
            case (true, true):
                return .permit
            case (true, false):
                return .denied(BundleI18n.SKResource.Doc_Doc_CopyFailed)
            case (false, _):
                return .denied(BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
            }
        }
    }
    
    var textViewShouldBeginEditing: Bool {
        let docsInfo = hostDocsInfo
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                return true
            }
            // 密级强制打标需求，当FA用户被admin设置强制打标时，不可发表评论，这里就不让输入框键盘弹起
            if SecretBannerCreater.checkForcibleSL(canManageMeta: permissionService.validate(operation: .managePermissionMeta).allow,
                                                   level: docsInfo?.secLabel) {
                showForcibleWarning()
                return false
            }
        } else {
            let userPermission = model?.permissionConfig.hostUserPermissions
            // 密级强制打标需求，当FA用户被admin设置强制打标时，不可发表评论，这里就不让输入框键盘弹起
            if SecretBannerCreater.checkForcibleSL(canManageMeta: userPermission?.isFA ?? false,
                                                   level: docsInfo?.secLabel) {
                showForcibleWarning()
                return false
            }
        }
        return true
    }
    
    private func showForcibleWarning() {
        var commentView = UIView()
        if _floatCommentModule?.isVisiable == true,
           let commentPluginView = _floatCommentModule?.commentPluginView {
            commentView = commentPluginView
        } else if _asideCommentModule?.isVisiable == true,
                  let commentPluginView = _asideCommentModule?.commentPluginView {
            commentView = commentPluginView
        } else {
            DocsLogger.error("can not find commentView show warning", component: LogComponents.comment)
            return
        }
        UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requird_Toast,
                            operationText: BundleI18n.SKResource.LarkCCM_Workspace_Security_Button_Set,
                            on: commentView.window ?? commentView) { [weak self, weak commentView] _ in
            guard let self = self, let commentView = commentView else { return }
            if let docsInfo = self.hostDocsInfo,
               let userPermission = self.model?.permissionConfig.hostUserPermissions,
               self.secretLevelSelectProxy == nil {
                self.secretLevelSelectProxy = SecretLevelSelectProxy(docsInfo: docsInfo, userPermission: userPermission, topVC: commentView.btd_viewController())
            }
            self.secretLevelSelectProxy?.toSetSecretVC()
        }
    }
    
    public func openDocs(url: URL) {
        if self.isInVideoConference {
            if !iPadUseNewCommment {
               dismissCommentView(needCancel: true, animated: false, completion: nil)
            }
        }
        
        if OperationInterceptor.interceptUrlIfNeed(url.absoluteString,
                                                   from: self.navigator?.currentBrowserVC,
                                                   followDelegate: self.model?.vcFollowDelegate) {
            DocsLogger.info("intercept Url", component: LogComponents.comment)
            return
        }
        
        let isInPicture = originData.commentData?.isInPicture ?? false
        let floatVisible = _floatCommentModule?.isVisiable ?? false
        if iPadUseNewCommment,
           !isInPicture,
           !floatVisible {
            navigator?.requiresOpen(url: url)
        } else {
            let topMostVC = self.topMostOfBrowserVC()
            guard let fromVC = topMostVC else {
                DocsLogger.error("openDocs fromVC cannot be nil", component: LogComponents.comment)
                return
            }
            let fragmentIsEmpty = url.fragment?.isEmpty ?? true
            if navigator?.pageIsExistInStack(url: url) == false {
                model?.userResolver.navigator.push(url, from: fromVC)
            } else if fragmentIsEmpty {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Normal_SamePageTip, on: fromVC.view.window ?? UIView())
            } else {
                DocsLogger.info("url fragment is empty", component: LogComponents.comment)
            }
        }
    }
    
    public func showUserProfile(userId: String) {
        showUserProfile(userId: userId, from: nil)
    }
    
    public func showUserProfile(userId: String, from: UIViewController?) {
        
        if iPadUseNewCommment {
            navigator?.showUserProfile(token: userId)
        } else {
            if OperationInterceptor.interceptShowUserProfileIfNeed(userId,
                                                                   from: self.navigator?.currentBrowserVC,
                                                                   followDelegate: model?.vcFollowDelegate) {
                DocsLogger.info("showUserProfile has been intercept",component: LogComponents.comment)
            } else if let nav = from { // 优先使用指定了的导航
                HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: nav))
            } else if let topMost = self.topMostOfBrowserVC() {
                HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: topMost))
            } else {
                DocsLogger.error("showUserProfile nav cannot be nil inVC:\(isInVideoConference)", component: LogComponents.comment)
            }
        }
    }
    
    func dismissCommentView() {
        dismissCommentView(completion: nil)
    }
    
    public func didCopyCommentContent() {
        PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
    }
}

extension CommentShowCardsService: DocsPermissionEventObserver {
    
    func onCaptureAllowedUpdated() {
        let canCopy = model?.permissionConfig.hostCaptureAllowed ?? false
        _floatCommentModule?.setCaptureAllowed(canCopy)
        _asideCommentModule?.setCaptureAllowed(canCopy)
    }

    func onCopyPermissionUpdated(canCopy: Bool) {
        // 暂不需要
    }
    
    func onViewPermissionUpdated(oldCanView: Bool, newCanView: Bool) {
        if oldCanView, !newCanView { // 由'可阅读'变为'不可阅读',需要关掉评论
            dismissCommentView(completion: nil)
        }
    }
}

@available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
extension CommentShowCardsService {
    func ownerAllowCopyFG() -> Bool {
        return model?.permissionConfig.hostCanCopy ?? false
    }
}

// MARK: - MS 场景兼容

extension CommentShowCardsService: CommentImageContainerType {
    
    class PresentCompletion {
        
        typealias CallbackType = ((UIViewController?) -> Void)
        var callback: (CallbackType)
        
        init(callback: @escaping CallbackType) {
            self.callback = callback
        }
    }
    
     func isLegal(for currentController: UIViewController) -> Bool {
         return true
    }
    
    func safePresent(callback: @escaping PresentCompletion.CallbackType) {
        self.presentCompletions.append(.init(callback: callback))
    }
}
// MARK: - 评论图片 预览&下载 权限
extension CommentShowCardsService: CommentImagePermissionDataSource {

    func syncGetCommentImagePermission() -> CommentImagePermission? {
        // 优先复用上次请求结果,因为附件权限不需要协同,每次打开文档只请求一次
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard let service = attachmentPermissionService,
               service.ready else {
                return nil
            }
            let canPreview = service.validate(operation: .preview).allow
            // TODO: PermissionSDK 确认下 download or downloadAttachment
            let canDownload = service.validate(operation: .download).allow
            return CommentImagePermission(canPreview: canPreview, canDownload: canDownload)
        } else {
            if let permission = docAttachmentPermission {
                return CommentImagePermission(canPreview: permission.canPreview(),
                                              canDownload: permission.canDownload())
            }
            return nil
        }
    }
    
    func asyncGetCommentImagePermission(token: String, completion: @escaping (CommentImagePermission) -> Void) {
        guard UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation else {
            legacyAsyncGetCommentImagePermission(attachmentToken: token, completion: completion)
            return
        }
        let permissionService: UserPermissionService
        if let attachmentPermissionService {
            permissionService = attachmentPermissionService
        } else {
            guard let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) else {
                completion(CommentImagePermission(canPreview: false, canDownload: false))
                return
            }
            var parentMeta: SpaceMeta?
            if let hostDocsInfo {
                parentMeta = SpaceMeta(objToken: hostDocsInfo.token, objType: hostDocsInfo.inherentType)
            }
            permissionService = permissionSDK.userPermissionService(for: .document(token: token, type: .file, parentMeta: parentMeta))
            attachmentPermissionService = permissionService
        }
        permissionService.updateUserPermission().subscribe { [weak self, weak permissionService] _ in
            guard let self, let permissionService else { return }
            let canPreview = permissionService.validate(operation: .preview).allow
            // TODO: PermissionSDK 确认下 download or downloadAttachment
            let canDownload = permissionService.validate(operation: .download).allow
            let model = CommentImagePermission(canPreview: canPreview, canDownload: canDownload)
            completion(model)
            self._floatCommentModule?.reloadData()
            self.asideCommentModule?.reloadData()
        } onError: { error in
            DocsLogger.info("fetch docAttachmentPermission error", error: error)
            completion(CommentImagePermission(canPreview: false,
                                              canDownload: false))
        }
        .disposed(by: disposeBag)

    }
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyAsyncGetCommentImagePermission(attachmentToken: String,
                                                      completion: @escaping (CommentImagePermission) -> Void) {
        guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self) else {
            completion(CommentImagePermission(canPreview: false,
                                              canDownload: false))
            return
        }

        var parent: (String, Int)?
        if let docsInfo = hostDocsInfo {
            parent = (docsInfo.token, docsInfo.type.rawValue)
        }
        permissionManager.fetchUserPermissions(token: attachmentToken,
                                               type: DocsType.file.rawValue,
                                               parent: parent) { [weak self] info, error in
            if let permission = info?.mask {
                self?.docAttachmentPermission = permission
                let model = CommentImagePermission(canPreview: permission.canPreview(),
                                                   canDownload: permission.canDownload())
                completion(model)
                self?._floatCommentModule?.reloadData()
                self?._asideCommentModule?.reloadData()
            } else {
                let errDesc = String(describing: error)
                let codeDesc = String(describing: info?.code)
                DocsLogger.info("fetch docAttachmentPermission error:\(errDesc), code: \(codeDesc)")
                completion(CommentImagePermission(canPreview: false,
                                                  canDownload: false))
            }
        }
    }
}
