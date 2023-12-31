//
//  CommentMenuPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/27.
//  


import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import LarkAssetsBrowser
import UniverseDesignActionPanel
import SpaceInterface
import SKCommon

struct MenuWeakWrapper {
    weak var menuVC: UIViewController?
    var identifier: String
}

// 和某个具体某个评论绑定的使用menuKey，其他的可以使用CommentMenuKey作为key
enum CommentMenuKey: String {
    case atList
    case invitePopup
    case mention
    case imagePicker
    case none
}

extension CommentItem {
    var menuKey: String {
        // commentId不存在是异常
        let id = self.commentId ?? CommentMenuKey.none.rawValue
        return "\(id)_\(replyID)"
    }
}

extension Comment {
    var menuKey: String {
        return "\(commentID)_\(CommentMenuKey.none.rawValue)"
    }
}

class CommentMenuPlugin: NSObject, CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier: String = "MenuPlugin"
 
    private var menus: [String: MenuWeakWrapper] = [:]
    
    private var atUserPermissionCache: [String: UserPermissionMask] = [:]
    
    var asideKeyboardHeight: CGFloat = 0

    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case .removeAllMenu:
            dismissAll()
        case let .interaction(ui):
           handleUIAction(action: ui)
        case let .ipc(action, callback):
            handleIPCAction(action: action, callback: callback)
        default:
            break
        }
    }
    
    func handleUIAction(action: CommentAction.UI) {
        switch action {
        case let .mention(atInputTextView, rect):
            handelMention(atInputTextView, rect)
        case let .mentionKeywordChange(keyword):
            handelMentionKeywordChange(keyword)
        case let .insertInputImage(maxCount, callback):
            handelInsertInputImage(maxCount, callback)
        case let .showContentInvite(at, rect, inView):
            handleShowContentInvite(at, rect, inView)
        case let .clickResolve(comment, trigerView):
            handleResolve(comment, trigerView)
        case let .clickQuoteMore(comment, trigerView):
            handleClickQuoteMore(comment, trigerView)
        case .hideMention:
            handleHideMention()
        case let .didShowAtInfo(item, atInfos):
            handleDidShowAtInfo(item, atInfos)
            
        case .hideComment:
            // aside 评论关闭时要清空，否则diff逻辑下次打开不会再请求更新
            if context?.pattern == .aside {
                atUserPermissionCache.removeAll()
            }
        case let .clickSendingDelete(item):
            handleClickSendingDelete(item)
        case .viewWillTransition:
            dismissAll()

        case let .asideKeyboardChange(options, _):
            if options.event == .didShow {
                self.asideKeyboardHeight = options.endFrame.height
            } else if options.event == .willHide, options.event == .didHide  {
                self.asideKeyboardHeight = 0
            }
        default:
            break
        }
    }
    
    func handleIPCAction(action: CommentAction.IPC, callback: CommentAction.IPC.Callback?) {
        switch action {
        case .removeAllMenu:
            dismissAll()
        case let .setMenu(wrapper):
            menus[wrapper.identifier] = wrapper
        case .fetchMenuKeys:
            callback?(Array(menus.keys), nil)
        case let .showTextInvite(at, rect, inView):
            handleShowTextInvite(at, rect, inView)
        case let .dismisMunu(keys):
            for key in keys {
                guard let vc = menus[key]?.menuVC else { continue }
                DocsLogger.info("dismiss menu key:\(key) vc:\(vc)", component: LogComponents.comment)
                if let reactionVC = vc as? DocsReactionMenuViewController {
                    reactionVC.dismiss()
                } else {
                    vc.dismiss(animated: false)
                }
            }
        case let .prepareForAtUid(uids):
            self.requestAtUserPermission(uids)
        default:
            break
        }
    }
    
    func dismissAll() {
        menus.forEach({ (_, value) in
            if let reactionVC = value.menuVC as? DocsReactionMenuViewController {
                reactionVC.dismiss()
            } else {
                value.menuVC?.dismiss(animated: false)
            }
        })
    }
}

// MARK: - mention

extension CommentMenuPlugin {
    
    func handleClickSendingDelete(_ commentItem: CommentItem) {
        let actionSheet = UDActionSheet.actionSheet()
        actionSheet.addItem(text: BundleI18n.SKResource.Doc_Facade_Ok) { [weak self] in
            self?.context?.scheduler?.dispatch(action: .api(.delete(commentItem), nil))
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        context?.topMost?.present(actionSheet, animated: true, completion: nil)
        menus[commentItem.menuKey] = MenuWeakWrapper(menuVC: actionSheet, identifier: commentItem.menuKey)
    }
    
    func handelInsertInputImage(_ maxCount: Int, _ callback: @escaping (CommentImagePickerResult) -> Void) {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: maxCount),
                                               isOriginal: true,
                                               isOriginButtonHidden: false,
                                               sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload,
                                               takePhotoEnable: true)
        picker.modalPresentationStyle = .formSheet
        picker.showMultiSelectAssetGridViewController()
        picker.navigationBar.isTranslucent = false
        picker.navigationBar.tintColor = UIColor.ud.bgBody
        picker.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]
        picker.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBody), for: .default)
        picker.navigationBar.shadowImage = UIImage()
        picker.imagePickerFinishSelect = { viewController, res in
            viewController.dismiss(animated: true, completion: nil)
            callback(.pickPhoto(selectedAssets: res.selectedAssets, isOriginal: res.isOriginal))
        }
        picker.imagePickerFinishTakePhoto = { viewController, image in
            viewController.dismiss(animated: true, completion: nil)
            callback(.takePhoto(image))
        }
        context?.topMost?.present(picker, animated: true, completion: nil)
        let key = CommentMenuKey.imagePicker.rawValue
        menus[key] = MenuWeakWrapper(menuVC: picker, identifier: key)
    }
    
    func handelMentionKeywordChange(_ keyword: String) {
        let key = CommentMenuKey.mention.rawValue
        guard let atListVC = menus[key]?.menuVC as? AtListContainerViewController else {
            DocsLogger.error("atListVC not found", component: LogComponents.comment)
            return
        }
        var filter: Set<AtDataSource.RequestType> = AtDataSource.RequestType.atViewFilter
        if context?.docsInfo?.type == .minutes, keyword.isEmpty {
            filter = AtDataSource.RequestType.userTypeSet
        }
        atListVC.atListView.refresh(with: keyword, filter: filter, animated: false)
    }
    
    func handelMention(_ atInputTextView: AtInputTextView, _ rect: CGRect) {
        let mentionKey = CommentMenuKey.mention.rawValue
        let atListVC = menus[mentionKey]?.menuVC as? AtListContainerViewController
        if atListVC != nil {
            guard atListVC?.isBeingDismissed == true else {
                return
            }
            atListVC?.dismiss(animated: false, completion: { [weak self] in
                self?._handelMention(atInputTextView, rect)
                self?.handelMentionKeywordChange("")
            })
        } else {
            _handelMention(atInputTextView, rect)
        }
    }

    func _handelMention(_ atInputTextView: AtInputTextView, _ rect: CGRect) {
        guard let context = context, let docsInfo = context.docsInfo else { return }
        let mentionKey = CommentMenuKey.mention.rawValue
        AtTracker.expose(parameter: [:], docsInfo: atInputTextView.docsInfo)
        
        var interfaceOrientation: UIInterfaceOrientation?
        if #available(iOS 13.0, *) {
            interfaceOrientation = context.commentPluginView.window?.windowScene?.interfaceOrientation
        } else {
            interfaceOrientation = UIApplication.shared.statusBarOrientation
        }
        // iPad分屏+软键盘，mention有可能会被键盘覆盖
        let isLandscape = interfaceOrientation == .landscapeLeft || interfaceOrientation == .landscapeRight
        let minHeight: CGFloat = 150
        var directions: UIPopoverArrowDirection = [.up, .down]
        if SKDisplay.pad,
           isLandscape,
           SKDisplay.isInSplitScreen,
           asideKeyboardHeight > minHeight {
            directions = [.down]
        }
        let config = AtDataSource.Config(chatID: nil,
                                         sourceFileType: docsInfo.type,
                                         location: docsInfo.isInCCMDocs ? .comment : .gadget,
                           token: docsInfo.objToken)
        let atDataSource = AtDataSource(config: config)
        let vc = AtListContainerViewController(atDataSource,
                                               type: atDataSource.location,
                                               requestType: AtDataSource.RequestType.atViewFilter,
                                               showCancel: false)
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.backgroundColor = UDColor.bgFloat
        vc.popoverPresentationController?.sourceView = atInputTextView.inputTextView?.textView
        vc.popoverPresentationController?.sourceRect = rect
        vc.popoverPresentationController?.popoverLayoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 30, right: 16)
        vc.popoverPresentationController?.permittedArrowDirections = directions
        context.topMost?.present(vc, animated: true, completion: nil)
        menus[mentionKey] = MenuWeakWrapper(menuVC: vc, identifier: mentionKey)
        vc.atListView.selectAction = { [weak self] atInfo, _, _ in
            if let self = self, let atInfo = atInfo {
                // 1. 处理@信息
                atInputTextView.onAtListViewSelected(atInfo)
                let atListVC = self.menus[mentionKey]?.menuVC as? AtListContainerViewController
                atListVC?.dismiss(animated: true, completion: nil)
                var mentionId = atInfo.id ?? ""
                if atInfo.type != .user {
                    mentionId = atInfo.token
                }
                AtTracker.mentionReport(type: atInfo.type.strForMentionType,
                                        mentionId: mentionId,
                                        isSendNotice: false,
                                        domain: .partComment,
                                        docsInfo: docsInfo,
                                        extra: CommentTracker.commonParams)
            }
        }
        vc.dismissCallBack = { [weak self, weak atInputTextView, weak vc] in
            let atListVC = self?.menus[mentionKey]?.menuVC as? AtListContainerViewController
            if atListVC == nil || atListVC == vc {
                atInputTextView?.markAtListViewHide()
            }
        }
    }
    
    func handleHideMention() {
        let mentionKey = CommentMenuKey.mention.rawValue
        menus[mentionKey]?.menuVC?.dismiss(animated: true)
    }
    
    func handleDidShowAtInfo(_ item: CommentItem, _ atInfos: [AtInfo]) {
        guard !atInfos.isEmpty, canSupportInviteUser(context?.docsInfo) else { return }
        var requestUids: Set<String> = Set()
        for atInfo in atInfos where atInfo.type == .user {
            let uid = atInfo.token
            if atUserPermissionCache[uid] == nil {
                requestUids.insert(uid)
            }
        }
        requestAtUserPermission(requestUids)
    }
    
    fileprivate func requestAtUserPermission(_ requestUids: Set<String>) {
        if !requestUids.isEmpty {
            let action = CommentAction.api(.requestAtUserPermission(requestUids)) { [weak self] (value, _) in
                if let self = self, let masks = value as? [String: UserPermissionMask] {
                    self.atUserPermissionCache.merge(other: masks)
                }
            }
            context?.scheduler?.dispatch(action: action)
        }
    }
}

// MARK: invite
extension CommentMenuPlugin {
    
    /// 文本内容上展示授权提示
    func handleShowContentInvite(_ at: AtInfo, _ rect: CGRect?, _ rectInView: UIView?) {
        guard let context = context else {
            return
        }
        let key = CommentMenuKey.invitePopup.rawValue
        menus[key]?.menuVC?.dismiss(animated: false)
        let permStatistics = PermissionStatistics.getReporterWith(docsInfo: context.docsInfo)
        permStatistics?.reportPermissionShareAtPeopleView()
        var controller: UIViewController?
        let config = BottomPopupViewUtil.config4AtInfo(at)
        if context.pattern == .aside {
            guard let rect = rect, let rectInView = rectInView else {
                skAssertionFailure()
                return
            }
            let rectInSelf = context.commentPluginView.convert(rect, from: rectInView)
            let alertVC = BottomPopupViewUtil.getPopupMenuViewInPoperOverStyle(delegate: self,
                                                                               config: config,
                                                                               permStatistics: permStatistics,
                                                                               rectInView: rectInSelf,
                                                                               soureViewHeight: context.commentPluginView.frame.height)
            alertVC.popoverPresentationController?.delegate = self
            alertVC.popoverPresentationController?.sourceView = context.commentPluginView
            context.topMost?.present(alertVC, animated: true, completion: nil)
            controller = alertVC
        } else {
            let vc = BottomPopupViewController(config: config, permStatistics: permStatistics)
            vc.delegate = self
            context.topMost?.present(vc, animated: false, completion: nil)
            controller = vc
        }
        menus[key] = MenuWeakWrapper(menuVC: controller, identifier: key)
    }

    /// 在输入框上面弹授权提示
    func handleShowTextInvite(_ at: AtInfo, _ rect: CGRect, _ inView: UIView) {
        guard let context = context, canSupportInviteUser(context.docsInfo) else {
            return
        }
        let key = CommentMenuKey.invitePopup.rawValue
        menus[key]?.menuVC?.dismiss(animated: false)
        let rectInSelf = context.commentPluginView.convert(rect, from: inView)
        let alertVC = CustomContainerAlert.getInviteTipsViewInPopoverStyle(delegate: self, at: at, docsInfo: context.docsInfo, rectInView: rectInSelf)
        alertVC.popoverPresentationController?.delegate = self
        alertVC.popoverPresentationController?.sourceView = context.commentPluginView
        let topVc = context.topMost
        let mentionKey = CommentMenuKey.mention.rawValue
        let atListVC = menus[mentionKey]?.menuVC as? AtListContainerViewController
        if topVc == atListVC {
            topVc?.dismiss(animated: false, completion: {
                self.context?.topMost?.present(alertVC, animated: true, completion: nil)
            })
        } else {
            topVc?.present(alertVC, animated: true, completion: nil)
        }
        menus[key] = MenuWeakWrapper(menuVC: alertVC, identifier: key)
    }
}

// MARK: - resolve
extension CommentMenuPlugin {
    
    func handleClickQuoteMore(_ comment: Comment, _ trigerView: UIView) {
        let fastState = context?.scheduler?.fastState
        if let copyAnchorLink = fastState?.copyAnchorLink,
           !copyAnchorLink.isEmpty {
            showResolveAndCopyMenu(comment, copyAnchorLink, [.shareAnchorLink, .copyAnchorLink], trigerView)
        } else {
            DocsLogger.error("copyAnchorLink is nil when click quote more", component: LogComponents.comment)
        }
    }

    func handleResolve(_ comment: Comment, _ trigerView: UIView) {
        let fastState = context?.scheduler?.fastState
        let isFloatModule = context?.pattern == .float
        let canCopyCommentLink = self.context?.businessDependency?.businessConfig.canCopyCommentLink ?? false
        let copyAnchorLink = fastState?.copyAnchorLink ?? ""
        var ability: [CommentAbility] = [.shareAnchorLink, .copyAnchorLink]
        if !copyAnchorLink.isEmpty,
           isFloatModule,
           canCopyCommentLink {
            if comment.permission.contains(.canResolve) {
                ability.append(.resolve)
            }
            showResolveAndCopyMenu(comment, copyAnchorLink, ability, trigerView)
        } else {
            DocsLogger.info("innerResolve canCopyCommentLink:\(canCopyCommentLink) linkIsEmpty: \(copyAnchorLink.isEmpty)", component: LogComponents.comment)
            innerResolve(comment, trigerView)
        }
    }
    
    private func innerResolve(_ comment: Comment, _ trigerView: UIView) {
        guard let context = context else {
            return
        }
        let fastState = context.scheduler?.fastState
        // float、drive如果正在输入，更改为浏览模式
        if let mode = fastState?.mode {
            switch mode {
            case .reply, .edit:
                var action: CommentAction = .ipc(.setFloatCommentMode(mode: .browseMode), nil)
                if context.pattern == .drive {
                    action = .ipc(.setDriveCommentMode(mode: .browseMode), nil)
                }
                context.scheduler?.dispatch(action: action)
            default:
                break
            }
        }
        let sourceRect = CGRect(x: trigerView.center.x, y: trigerView.frame.origin.y, width: 1, height: trigerView.frame.size.height)
        let rectInSelf = context.commentPluginView.convert(sourceRect, from: trigerView.superview)
        let alertTitle: String
        let interactionType = comment.interactionType
        switch interactionType {
        case .comment, .none:
            alertTitle = BundleI18n.SKResource.LarkCCM_Mobile_Comments_Resolve_Tooltip
        case .reaction:
            alertTitle = BundleI18n.SKResource.LarkCCM_Docx_emojiReaction_Resolve_Button_Mob
        }
        let commentId = comment.commentID
        let resolveModel = AlertActionModel(title: alertTitle) { [weak self] in
            //
            let activeCommentId = self?.context?.scheduler?.fastState.activeCommentId ?? ""
            self?.context?.scheduler?.dispatch(action: .api(.resolveComment(commentId: commentId, activeCommentId: activeCommentId), nil))
            switch interactionType {
            case .comment, .none:
                break
                // 这里不需要判断关闭评论了 https://meego.bytedance.net/larksuite/story/detail/2820520
            case .reaction:
                let params: [String: Any] = ["click": "solve_and_hide",
                                             "target": "none"]
                DocsTracker.newLog(enumEvent: .contentReactionEvent, parameters: params)
            }
        }
        let isPadRegularSize = SKDisplay.pad && context.commentPluginView.isMyWindowRegularSize()
        if context.pattern == .aside || isPadRegularSize {
            let alertVC = CommentConfirmAlertVC()
            alertVC.construct {
                $0.preferredContentSize = CGSize(width: 351, height: 112)
                $0.setConfirmTitle(resolveModel.title) {
                    let handler = resolveModel.handler
                    handler?()
                }

                $0.modalPresentationStyle = .popover
                $0.popoverPresentationController?.delegate = self
                $0.popoverPresentationController?.sourceView = context.commentPluginView
                var arrowDirection: UIPopoverArrowDirection = .up
                if rectInSelf.minY > 100 {
                    arrowDirection = .down
                }
                $0.popoverPresentationController?.sourceRect = rectInSelf
                $0.popoverPresentationController?.permittedArrowDirections = arrowDirection
            }
            menus[comment.menuKey] = MenuWeakWrapper(menuVC: alertVC, identifier: comment.menuKey)
            context.topMost?.present(alertVC, animated: true, completion: nil)
        } else {
            var cancel = AlertActionModel(title: BundleI18n.SKResource.Doc_Facade_Cancel, handler: nil)
            cancel.isCancel = true
            let models = [resolveModel, cancel]
            let alertVC = UDActionSheet.actionSheet(backgroundColor: UIColor.ud.bgFloatOverlay)
            models.forEach { (model) in
                guard !model.isDefault else { return }
                if model.isCancel {
                    alertVC.addItem(text: model.title, style: .cancel)
                } else {
                    alertVC.addItem(text: model.title, action: model.handler)
                }
            }
            context.topMost?.present(alertVC, animated: true, completion: nil)
            menus[comment.menuKey] = MenuWeakWrapper(menuVC: alertVC, identifier: comment.menuKey)
        }
    }
    
    private func showResolveAndCopyMenu(_ comment: Comment, _ copyAnchorLink: String, _ ability: [CommentAbility], _ trigerView: UIView) {
        let action = CommentAction.ipc(.showResolveAndCopyMenu(comment: comment,
                                                  link: copyAnchorLink,
                                                  ability: ability,
                                                  trigerView: trigerView)) { [weak self] _, error in
            guard error == nil else {
                DocsLogger.error("show resolve error", component: LogComponents.comment)
                return
            }
            self?.innerResolve(comment, trigerView)
        }
        context?.scheduler?.dispatch(action: action)
    }
}


// MARK: - BottomPopupViewControllerDelegate
extension CommentMenuPlugin: BottomPopupViewControllerDelegate {
    func bottomPopupViewControllerDidConfirm(_ bottomPopupViewController: BottomPopupViewController) {
        self.menuDidConfirm(bottomPopupViewController.getMenuView())
    }

    func bottomPopupViewControllerClosed(_ bottomPopupViewController: BottomPopupViewController) {
        
    }
    
    func bottomPopupViewControllerOnClick(_ bottomPopupViewController: BottomPopupViewController, at url: URL) -> Bool {
        return self.menuOnClick(bottomPopupViewController.getMenuView(), at: url)
    }
    
}


// MARK: - BottomPopupVCMenuDelegate
extension CommentMenuPlugin: BottomPopupVCMenuDelegate {
    
    func menuDidConfirm(_ menu: BottomPopupMenuView) {
        guard let atInfo = menu.config.extraInfo as? AtInfo else { return }
        let mentionKey = CommentMenuKey.invitePopup.rawValue
        menus[mentionKey]?.menuVC?.dismiss(animated: false, completion: nil)
        context?.scheduler?.dispatch(action: .api(.inviteUserRequest(atInfo: atInfo, sendLark: menu.config.sendLark), nil))
    }
    
    func menuOnClick(_ menu: BottomPopupMenuView, at url: URL) -> Bool {
        let mentionKey = CommentMenuKey.invitePopup.rawValue
        menus[mentionKey]?.menuVC?.dismiss(animated: false, completion: nil)
        guard let atInfo = menu.config.extraInfo as? AtInfo else { return true }
        context?.scheduler?.dispatch(action: .interaction(.clickAtInfoDirectly(atInfo: atInfo)))
        return false
    }
}



// MARK: 输入框授权提示
extension CommentMenuPlugin: AtUserInviteViewDelegate {
    
    func clickConfirmButton(_ view: AtUserInviteView) {
        guard let atInfo = view.atUserInfo else { return }
        context?.scheduler?.dispatch(action: .api(.inviteUserRequest(atInfo: atInfo, sendLark: false), nil))
    }
}


// MARK: - UIPopoverPresentationControllerDelegate

extension CommentMenuPlugin: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        let vc = controller.presentedViewController
        if context?.pattern == .aside, (vc is CommentConfirmAlertVC) || (vc is CustomContainerAlert) {
            return .none
        } else {
            return controller.presentedViewController.modalPresentationStyle
        }
    }
}
