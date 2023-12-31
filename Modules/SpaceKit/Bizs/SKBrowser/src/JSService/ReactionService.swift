//
//  ReactionService.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/6/6.
//  
// swiftlint:disable file_length cyclomatic_complexity

import Foundation
import LarkMenuController
import LarkEmotion
import LarkReactionDetailController
import RxSwift
import Kingfisher
import SKCommon
import SKFoundation
import SKResource
import LarkEmotionKeyboard
import SKUIKit
import UniverseDesignToast
import SpaceInterface
import UniverseDesignIcon
import SKInfra
import LarkContainer

class ReactionService: BaseJSService {
    private let disposeBag = DisposeBag()
    private var lastReactions: [CommentReaction]?
    private var needLoadMoreReactions: Bool = false
    private var notification: NSObjectProtocol?

    typealias ReactionCallback = ([Reaction]?, Error?) -> Void
    
    var reactionCallback: ReactionCallback?
    weak var reactionController: MenuViewController?
    weak var reactionDetailController: UIViewController?
    private(set) lazy var apiAdaper: CommentWebAPIAdaper? = {
        if let jsService = self.model?.jsEngine.fetchServiceInstance(CommentShowCardsService.self) {
            return CommentWebAPIAdaper(commentService: jsService)
        } else {
            DocsLogger.error("fetch CommentService fail")
            return nil
        }
    }()

    var commentDisableRN: Bool {
        return true
    }
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        model.permissionConfig.permissionEventNotifier.addObserver(self)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(notification as Any)
    }
}

extension ReactionService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.reactionShowDetail, // 展示详情
            .showOperationPanel, // 展示操作面板
            .reactionUpdateRecent, // 更新最近表情
            .reactionClose, // 关闭reaction面板
            .setReactionDetail,
            .sendCommonLinkToIM
        ]
    }

    func handle(params: [String: Any], serviceName: String) {

        let service = DocsJSService(rawValue: serviceName)

        switch service {
        case .reactionShowDetail:
            _showDetail(params)
        case .showOperationPanel:
            _showOperationPanel(params)
        case .reactionUpdateRecent:
            _updateRecentReaction(params)
        case .reactionClose:
            closeReaction()
        case .setReactionDetail:
            setReactionDetail(params)
        case .sendCommonLinkToIM:
            shareURLToIM(params)
        default:
            break
        }
    }
}

private extension ReactionService {
    
    private func closeReaction() {
        
        if let reactionDetailController = self.reactionDetailController {
            reactionDetailController.dismiss(animated: false)
        }

        if let reactionController = self.reactionController {
            reactionController.hiddenMenuBar(animation: true)
            reactionController.dismiss(animated: false, params: nil)
            if reactionController.view.superview != nil {
                reactionController.view.removeFromSuperview()
            }
        }
    }
    
    private func shareURLToIM(_ params: [String: Any]) {
        guard let url = params["url"] as? String else {
            DocsLogger.error("share comment url is nil", component: LogComponents.comment)
            return
        }
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
            guard let self = self else { return }
            HostAppBridge.shared.call(ShareToLarkService(contentType: .text(content: url), fromVC: self.topMostOfBrowserVC(), type: .feishu))
        }
    }
    
    private func _updateRecentReaction(_ params: [String: Any]) {
        if let recentReactionKeys = params["recentReactionKeys"] as? [String] {
            CCMKeyValue.globalUserDefault.set(recentReactionKeys, forKey: UserDefaultKeys.recentReactions)
        }
    }

    private func _showDetail(_ params: [String: Any]) {
        guard let data = params["data"] as? [[String: Any]],
            let referType = params["referType"] as? String,
            let referKey = params["referKey"] as? String else {
                return
        }

        lastReactions = data.map { (reaction) -> CommentReaction? in
            guard let rData = try? JSONSerialization.data(withJSONObject: reaction, options: []) else { return nil }
            return try? JSONDecoder().decode(CommentReaction.self, from: rData)
        }.compactMap { $0 }

        _setDetailPanelStatus(referType: referType, referKey: referKey, status: 1)
        needLoadMoreReactions = _updateReactionDetailIfNeeded()
        _presentToReactionDetailVC(referType, referKey)
        if needLoadMoreReactions {
            let replyId = params["replyId"] as? String
            _getMoreDetail(referType, referKey, replyId)
        }
    }

    private func _getMoreDetail(_ referType: String, _ referKey: String, _ replyId: String?) {
        apiAdaper?.getReactionDetail(CommentAPIContent([.replyId : replyId ?? ""]))
    }

    func setReactionDetail(_ params: [String: Any]) {
        guard let responseModel = ReactionCacllBackData.deserialize(from: params) else {
            DocsLogger.error("ReactionCacllBackData deserialize fail", component: LogComponents.comment)
            return
        }
        notifyReaction(responseModel)
    }
    
    private func notifyReaction(_ model: ReactionCacllBackData) {
        guard let replyId = model.replyId,
              let data = model.data as? [[String: Any]] else {
            return
        }

        let reactions = data.map { (reaction) -> CommentReaction? in
            guard let rData = try? JSONSerialization.data(withJSONObject: reaction, options: []) else { return nil }
            return try? JSONDecoder().decode(CommentReaction.self, from: rData)
        }.compactMap { $0 }
        let userInfo = [
            ReactionNotificationKey.replyId: replyId,
            ReactionNotificationKey.reactions: reactions
            ] as [ReactionNotificationKey: Any]

        // 通知正文详情面板
        NotificationCenter.default.post(name: Notification.Name.ReactionShowDetail,
                                        object: nil,
                                        userInfo: userInfo)
        
        // 全文评论不需要通知，直接设置
        self.lastReactions = reactions
        self.reactionCallback?(self._convertReactions(), nil)
    }
    
    private func _updateReactionDetailIfNeeded() -> Bool {
        if let lastReactions = lastReactions {
            for reaction in lastReactions where reaction.userList.count < reaction.totalCount {
                return true
            }
        }

        return false
    }

    @discardableResult
    private func _presentToReactionDetailVC(_ referType: String, _ referKey: String) -> UIViewController {
        let message = LarkReactionDetailController.Message(id: "FIXME", channelID: "FIXME")
        let controller = ReactionDetailVCFactory.create(message: message, dependency: self)
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        controller.view.backgroundColor = UIColor.clear
        controller.rx.deallocated.subscribe(onNext: { _ in
            self._setDetailPanelStatus(referType: referType, referKey: referKey, status: 0)
        }).disposed(by: disposeBag)
        if let topMost = UIViewController.docs.topMost(of: self.registeredVC) {
            topMost.present(controller, animated: true, completion: nil)
        }
        self.reactionDetailController = controller
        return controller
    }

    private func _setDetailPanelStatus(referType: String, referKey: String, status: Int) {
        let params = [
            "status": status,
            "referType": referType,
            "referKey": referKey
            ] as [String: Any]

        model?.jsEngine.callFunction(DocsJSCallBack.setDetailPanelStatus, params: params, completion: nil)
    }

    // 展示操作面板
    private func _showOperationPanel(_ params: [String: Any]) {

        if let data = try? JSONSerialization.data(withJSONObject: params, options: []),
            let panel = try? JSONDecoder().decode(Panel.self, from: data) {
            self._showMenu(panel)
        } else {
            spaceAssertionFailure("解析前端 Reaction 字段错误 \(params)")
        }
    }

    private func _showMenu(_ panel: Panel) {

        guard let editorView = self.ui?.editorView,
              let scrollProxy = self.ui?.scrollProxy else {
            return
        }

        var reactions: [MenuReactionItem] = []
        var actionItems: [MenuActionItem] = []
        var recent: [MenuReactionItem] = []
        let reactionGroups = EmojiImageService.default?.getAllReactions() ?? []

        for toolbar in panel.toolBar {
            switch toolbar.id {
            case .reaction:
                let reactionEntities = reactionGroups.flatMap { $0.entities }
                reactions = reactionEntities.map { (item) -> MenuReactionItem in
                    return MenuReactionItem(reactionEntity: item, action: { [weak self] (key) in
                        let params = [
                            "id": toolbar.id.rawValue,
                            "value": key
                        ]
                        self?.model?.jsEngine.callFunction(DocsJSCallBack(panel.callback), params: params, completion: nil)
                        // 更新用户最近和最常使用表情
                        EmojiImageService.default?.updateUserReaction(key: key)
                    })
                }
                let defaultReactions = EmojiImageService.default?.getDefaultReactions() ?? []
                var recentReactions = EmojiImageService.default?.getRecentReactions() ?? defaultReactions
                if recentReactions.count > 6 {
                    recentReactions = Array(recentReactions.prefix(6))
                }
                recent = recentReactions.map({ (item) -> MenuReactionItem in
                    return MenuReactionItem(reactionEntity: item, action: { [weak self] (key) in
                        let params = [
                            "id": toolbar.id.rawValue,
                            "value": key
                        ]
                        self?.model?.jsEngine.callFunction(DocsJSCallBack(panel.callback), params: params, completion: nil)
                        // 更新用户最近和最常使用表情
                        EmojiImageService.default?.updateUserReaction(key: key)
                    })
                })

            case .reply, .edit, .delete, .resolve, .sendIM, .copyLink:
                let extractedExpr = MenuActionItem(
                    name: toolbar.text ?? "",
                    image: toolbar.id.transform2Image ?? UIImage(),
                    enable: true,
                    action: { [weak self] (_) in
                        self?.model?.jsEngine.callFunction(DocsJSCallBack(panel.callback), params: ["id": toolbar.id.rawValue], completion: nil)
                    })
                actionItems.append(extractedExpr)
            case .translate:
                let extractedExpr = MenuActionItem(
                    name: toolbar.text ?? "",
                    image: toolbar.id.transform2Image ?? UIImage(),
                    enable: true,
                    action: { [weak self] (_) in
                        guard let self else { return }
                        self.model?.jsEngine.callFunction(DocsJSCallBack(panel.callback), params: ["id": toolbar.id.rawValue, "targetLanguage": self.getTranslateLanguageKey()], completion: nil)
                    })
                actionItems.append(extractedExpr)
            case .copy:
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                        spaceAssertionFailure("get permission service failed in reaction show menu")
                        break
                    }
                    guard permissionService.validate(operation: .copyContent).allow else {
                        break
                    }
                    let action: (LarkMenuController.MenuActionItem) -> Void = { [weak self] (_) in
                        // 再次校验复制权限
                        self?.handleCopy(panel: panel, toolBarItem: toolbar)
                    }
                    let extractedExpr = MenuActionItem(
                        name: toolbar.text ?? "",
                        image: toolbar.id.transform2Image ?? UIImage(),
                        enable: true,
                        action: action)
                    actionItems.append(extractedExpr)
                } else {
                    let ownerAllow = ownerAllowCopyFG()
                    let adminAllow = adminAllowCopyFG()
                    if adminAllow, ownerAllow {
                        let action: (LarkMenuController.MenuActionItem) -> Void = { [weak self] (_) in
                            // 再次校验复制权限
                            self?.handleCopy(panel: panel, toolBarItem: toolbar)
                        }
                        let extractedExpr = MenuActionItem(
                            name: toolbar.text ?? "",
                            image: toolbar.id.transform2Image ?? UIImage(),
                            enable: true,
                            action: action)
                        actionItems.append(extractedExpr)
                    }
                }
            case .cancel:
                break
            }
        }
        
        if recent.isEmpty && reactions.count >= 6 {
            recent = Array(reactions.prefix(6))
        }
        
        if actionItems.isEmpty {
            if let window = ui?.hostView.window {
                // 弹toast提醒用户无可用操作
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_Perms_CommentRestricted_toast_mob, on: window)
            }
        }
        
        let vm = SimpleMenuViewModel(recentReactionMenuItems: recent,
                                     scene: .ccm,
                                     allReactionMenuItems: reactions,
                                     allReactionGroups: reactionGroups,
                                     actionItems: actionItems)

        vm.menuBar.actionBar.actionIconInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        vm.menuBar.reactionSupportSkinTones = LKFeatureGating.reactionSkinTonesEnable
        let layout = CommentMenuLayout()

        let location = CGPoint(x: panel.position.x, y: panel.position.y - Double(scrollProxy.contentOffset.y))
        let menu = DocsReactionMenuViewController(
            viewModel: vm,
            layout: layout,
            trigerView: editorView,
            trigerLocation: location)
        
        menu.dismissBlock = {
            self.model?.jsEngine.callFunction(DocsJSCallBack(panel.callback), params: ["id": ToolBarID.cancel.rawValue], completion: nil)
        }

        if let webVC = navigator?.currentBrowserVC {
            menu.show(in: webVC)
            self.reactionController = menu
        } else {
            DocsLogger.info("获取不了topMost")
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            let tmp = vm.menuBar.actionBar.subviews
            for view in tmp where view is UICollectionView {
                let collectionView = view as? UICollectionView
                guard let visibileCells = collectionView?.subviews else {
                    return
                }
                for (indexs, item) in visibileCells.enumerated() {
                    let identifier = "menuBar_actionBar_\(indexs)"
                    item.accessibilityIdentifier = identifier
                }
            }
        }
    }
    
    private func handleCopy(panel: Panel, toolBarItem: Panel.ToolBarItem) {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard checkCopyPermission() else {
                copyForbiddenReport()
                return
            }
            didCopy(panel: panel, toolBarItem: toolBarItem)
        } else {
            guard let hostDocsInfo else {
                _handleCopy(panel: panel, toolBarItem: toolBarItem)
                return
            }
            guard legacyCheckCopyPermission(docsInfo: hostDocsInfo) else { return }
            _handleCopy(panel: panel, toolBarItem: toolBarItem)
        }
    }

    private func getTranslateLanguageKey() -> String {
        guard let translateService = try? Container.shared.resolve(assert: CCMTranslateService.self) else { return ""}
        return translateService.targetLanguageKey ?? ""
    }

    private func checkCopyPermission() -> Bool {
        guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
            spaceAssertionFailure("permissionService for host document not found")
            return false
        }
        let response = permissionService.validate(operation: .copyContent)
        response.didTriggerOperation(controller: navigator?.currentBrowserVC ?? UIViewController(),
                                     BundleI18n.SKResource.Doc_Doc_CopyFailed)
        return response.allow
    }
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyCheckCopyPermission(docsInfo: DocsInfo) -> Bool {
        let docType = docsInfo.type
        let token = docsInfo.token
        let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: docType, token: token)
        if result.allow {
            return true
        }
        switch result.validateSource {
        case .fileStrategy:
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: docType, token: token)
        case .securityAudit:
            if let view = ui?.editorView {
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: view)
            }
        case .dlpDetecting, .dlpSensitive, .unknown, .ttBlock:
            DocsLogger.info("unknown type or dlp type")
        }
        return false
    }
    
    private func _handleCopy(panel: Panel, toolBarItem: Panel.ToolBarItem) {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                reactionShowToast(.ownerForbidden)
                copyForbiddenReport()
                return
            }
            guard let hostController = navigator?.currentBrowserVC else { return }
            let response = permissionService.validate(operation: .copyContent)
            response.didTriggerOperation(controller: hostController, BundleI18n.SKResource.Doc_Doc_CopyFailed)
            if response.allow {
                didCopy(panel: panel, toolBarItem: toolBarItem)
            } else {
                copyForbiddenReport()
            }
        } else {
            let ownerAllow = ownerAllowCopyFG()
            let adminAllow = adminAllowCopyFG()
            switch (adminAllow, ownerAllow) {
            case (true, true):  // 复制成功
                didCopy(panel: panel, toolBarItem: toolBarItem)
            case (true, false): // owner关闭
                reactionShowToast(.ownerForbidden)
                copyForbiddenReport()
            case (false, _): // admin关闭
                reactionShowToast(.adminForbidden)
                copyForbiddenReport()
            }
        }
    }

    private func didCopy(panel: Panel, toolBarItem: Panel.ToolBarItem) {
        model?.jsEngine.callFunction(DocsJSCallBack(panel.callback), params: ["id": toolBarItem.id.rawValue], completion: nil)
    }
}

extension ReactionService: ReactionDetailViewModelDelegate {
    func reactionDetailImage(_ reaction: String, callback: @escaping (UIImage) -> Void) {
        if let image = EmotionResouce.shared.imageBy(key: reaction) {
            callback(image)
        } else {
            var imageView: UIImageView? = UIImageView()
            // 尽量用imageKey发起请求
            var isEmojis: Bool = false; var key: String = reaction
            if let imageKey = EmotionResouce.shared.imageKeyBy(key: reaction) {
                isEmojis = true; key = imageKey
            }
            imageView?.bt.setLarkImage(with: .reaction(key: key, isEmojis: isEmojis),
                                       completion: { result in
                                        if let reactionIcon = try? result.get().image {
                                            callback(reactionIcon)
                                        }
                                        imageView = nil
                                       })
        }
    }

    func reactionDetailFetchReactions(message: LarkReactionDetailController.Message, callback: @escaping ([Reaction]?, Error?) -> Void) {
        if needLoadMoreReactions { // 需要更新数据等待通知刷新
            reactionCallback = callback
        } else { // 直接刷新
            callback(_convertReactions(), nil)
        }
    }

    private func _convertReactions() -> [Reaction]? {
        guard let lastReactions = lastReactions else {
            return nil
        }

        let reactions = lastReactions.map({
            return Reaction(
                type: $0.reactionKey,
                chatterIds: $0.userList.map({ $0.userId })
            )
        })

        return reactions
    }

    func reactionDetailFetchChatters(message: LarkReactionDetailController.Message, reaction: Reaction, callback: @escaping ([Chatter]?, Error?) -> Void) {

        guard let lastReactions = lastReactions else {
            return
        }

        var chatterSet = Set<Chatter>()

        let convertDescriptionType: (CommentReaction.UserDescriptionType?) -> Chatter.DescriptionType = {
            switch $0 {
            case .defaultType, .none:
                return .onDefault
            case .business:
                return .onBusiness
            case .leave:
                return .onLeave
            case .meeting:
                return .onMeeting
            }
        }

        lastReactions.forEach { (r) in
            r.userList.forEach({ (user) in
                chatterSet.insert(
                    Chatter(id: user.userId,
                            avatarKey: user.avatarUrl,
                            // TODO: displayName 待后续接入
//                            displayName: user.displayName,
                            displayName: user.userName,
                            descriptionText: user.description ?? "",
                            descriptionType: convertDescriptionType(user.descType))
                )
            })
        }

        var chattersMap: [String: Chatter] = [:]
        chatterSet.forEach { (c) in
            chattersMap[c.id] = c
        }

        let chatters = reaction.chatterIds.compactMap { (id) -> Chatter? in
            return chattersMap[id]
        }

        callback(chatters, nil)
    }

    func reactionDetailFetchChatterAvatar(message: LarkReactionDetailController.Message, chatter: Chatter, callback: @escaping (UIImage) -> Void) {
        if let avaterURL = URL(string: chatter.avatarKey) {
            let downloader = ImageDownloader.default
            downloader.downloadImage(with: avaterURL, completionHandler: { result in
                switch result {
                case .success(let value):
                    callback(value.image)
                case .failure(let error):
                    DocsLogger.info("download avater error:\(error)")
                }
            })
        }
    }

    func reactionDetailClickChatter(message: LarkReactionDetailController.Message, chatter: Chatter, controller: UIViewController) {

    }
}

private enum ToolBarID: String, Codable {

    case reaction = "REACTION"
    case copy = "COPY"
    case edit = "EDIT"
    case delete = "DELETE"
    case resolve = "RESOLVE"
    case translate = "TRANSLATE"
    case reply = "REPLY"
    case cancel = "CANCEL"
    case sendIM = "SEND_IM"
    case copyLink = "COPY_LINK" // 拷贝评论链接

    var transform2Image: UIImage? {
        switch self {
        case .reaction:
            return nil // 找不到图片资源："ReactionPanelREACTION"了
        case .copy:
            return UDIcon.copyOutlined
        case .edit:
            return UDIcon.editOutlined
        case .delete:
            return UDIcon.deleteTrashOutlined
        case .resolve:
            return UDIcon.yesOutlined
        case .translate:
            return UDIcon.translateOutlined
        case .cancel:
            return nil // 找不到图片资源："ReactionPanelCANCEL"了
        case .reply:
            if DocsSDK.currentLanguage == .zh_CN {
                return UDIcon.replyCnOutlined
            } else {
                return UDIcon.replyOutlined
            }
        case .copyLink:
            return UDIcon.linkCopyOutlined
        case .sendIM:
            return UDIcon.shareOutlined
        }
    }
}

private struct Panel: Codable {
    struct ToolBarItem: Codable {
        let id: ToolBarID
        let text: String?
    }

    struct Position: Codable {
        let x: Double
        let y: Double
    }

    let position: Position
    let toolBar: [ToolBarItem]
    let callback: String
}

// MARK: - 权限Observer
extension ReactionService: DocsPermissionEventObserver {
    func onCopyPermissionUpdated(canCopy: Bool) {
        
    }
}

// MARK: - CCMCopyPermissionDataSource
@available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
extension ReactionService {
    func adminAllowCopyFG() -> Bool {
        return AdminPermissionManager.adminCanCopy()
    }

    func ownerAllowCopyFG() -> Bool {
        return model?.permissionConfig.hostCanCopy ?? false
    }
}

// MARK: - Toast

enum ReactionShowToastType {
    case success
    case ownerForbidden
    case adminForbidden
    
    var description: String {
        switch self {
        case .success:
            return BundleI18n.SKResource.Doc_Doc_CopySuccess
        case .ownerForbidden:
            return BundleI18n.SKResource.Doc_Doc_CopyFailed
        case .adminForbidden:
            return BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast
        }
    }
}

extension ReactionService {
    private func reactionShowToast(_ type: ReactionShowToastType) {
        if let window = ui?.hostView.window {
            switch type {
            case .success:
                UDToast.showSuccess(with: type.description, on: window)
            case .ownerForbidden, .adminForbidden:
                UDToast.showFailure(with: type.description, on: window)
            }
        } else {
            DocsLogger.info("can not get window")
        }
    }
}

// MARK: - 埋点
extension ReactionService {
    private func copyForbiddenReport() {
        let location = "global_comments"
        let isHistory = "false"
        let params: [String: Any] = ["forbidden_location": location,
                                     "is_history": isHistory]
        DocsTracker.newLog(enumEvent: .permissionCopyForbiddenToastView, parameters: params)
    }
}

extension ReactionService: BrowserViewLifeCycleEvent {
    
    func browserDidSplitModeChange() {
        closeReaction()
    }
    func browserWillTransition(from: CGSize, to: CGSize) {
        closeReaction()
    }
}
