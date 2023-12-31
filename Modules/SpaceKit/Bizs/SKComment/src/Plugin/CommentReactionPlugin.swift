//
//  CommentReactionPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/27.
//  
//  swiftlint:disable cyclomatic_complexity file_length

import UIKit
import SKFoundation
import SKResource
import UniverseDesignActionPanel
import RxSwift
import RxCocoa
import SKUIKit
import SKCommon
import SKInfra
import LarkContainer

// reaction依赖库...
import LarkReactionView
import LarkMenuController
import LarkReactionDetailController
import LarkEmotion
import LarkEmotionKeyboard
import SpaceInterface

class CommentReactionPlugin: NSObject, CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier = "ReactionPlugin"
    
    var disposeBag = DisposeBag()
    
    var reactionDetailImp: CCMReactionDetailDependencyImpl?
    
    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
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
        case let .showReaction(item, location, cell, trigerView):
            handleShowReaction(item, location, cell, trigerView)
        case let .showBlockReaction( item, location, cell, trigerView):
            handleShowBlockReaction(item, location, cell, trigerView)
            
        case let .clickTranslationIcon(item):
            handleClickTranslationIcon(item)
            context?.scheduler?.dispatch(action: .tea(.showOriginalClick(item)))
            
        case let .clickReaction(item, info, type):
            handleClickReaction(item, info, type)
            
        case let .longPress(item, location, cell, trigerView):
            guard item.permission.contains(.canReaction) else {
                // 部分业务（小程序）不支持长按
                DocsLogger.warning("current don't support reaction", component: LogComponents.comment)
                return
            }
            handleShowReaction(item, location, cell, trigerView)
        default:
            break
        }
    }
    
    func handleIPCAction(action: CommentAction.IPC, callback: CommentAction.IPC.Callback?) {
        switch action {
        case let .showResolveAndCopyMenu(comment, link, ability, trigerView):
            handleShowResolveAndCopyMenu(comment, link, ability, trigerView, callback)
        default:
            break
        }
    }
    
    func dispatchAPI(_ action: CommentAction.API) {
        context?.scheduler?.dispatch(action: .api(action, nil))
    }
}

extension CommentReactionPlugin {
    
    func handleShowReaction(_ item: CommentItem, _ location: CGPoint, _ cell: UIView, _ trigerView: UIView) {
        guard let context = context else {
            DocsLogger.error("docsInfo is nil", component: LogComponents.comment)
            return
        }
        guard let topMostVC = context.topMost else {
            DocsLogger.error("showInVC is nil", component: LogComponents.comment)
            return
        }
        DocsLogger.info("showReaction in VC: \(topMostVC)",
                        component: LogComponents.comment)
        
        let commentAbilities = fetchCommentAbilities(item)
        let sourceRect: CGRect = CGRect(x: cell.center.x, y: cell.frame.origin.y, width: 1, height: cell.frame.size.height)
        let relativeRect = context.commentPluginView.convert(sourceRect, from: cell.superview)
        guard !commentAbilities.isEmpty else {
            DocsLogger.info("commentAbilities is empty", component: LogComponents.comment)
            // 弹Toast提醒用户无可用操作
            let msg = BundleI18n.SKResource.LarkCCM_Workspace_Perms_CommentRestricted_toast_mob
            context.scheduler?.reduce(state: .toast(.failure(msg)))
            return
        }
        var actionItems: [MenuActionItem] = []
        for ab in commentAbilities {
            let item = MenuActionItem(
                name: ab.description,
                image: ab.udImage,
                enable: true,
                action: { [weak self] (_) in
                    self?._handleReactionPanelAction(ab, item, cell, trigerView, relativeRect: relativeRect)
                })
            actionItems.append(item)
        }
        
        let reactionGroups = EmojiImageService.default?.getAllReactions() ?? []
        let reactionEntities = reactionGroups.flatMap { $0.entities }
        let reactions = reactionEntities.map { (reactionItem ) -> MenuReactionItem in
            return MenuReactionItem(reactionEntity: reactionItem, action: { [weak self] (key) in
                self?._clickReactionIcon(item, key: key)
            })
        }

        var recent: [MenuReactionItem] = []

        // 可以操作 Reaction & 可以能评论
        if item.permission.contains([.canReaction, .canComment]) && reactions.count >= 6 {
            let defaultReactions = EmojiImageService.default?.getDefaultReactions() ?? []
            var recentReactions = EmojiImageService.default?.getRecentReactions() ?? defaultReactions
            if recentReactions.count > 6 {
                recentReactions = Array(recentReactions.prefix(6))
            }
            recent = recentReactions.map({ (entity) -> MenuReactionItem in
                return MenuReactionItem(reactionEntity: entity, action: { [weak self] (key) in
                    self?._clickReactionIcon(item, key: key)
                })
            })
        } else {
            DocsLogger.info("can not show reactions:\(reactions.count)", component: LogComponents.comment)
        }

        let vm = MenuViewModel(recentReactionMenuItems: recent,
                               scene: .ccm,
                               allReactionMenuItems: reactions,
                               allReactionGroups: reactionGroups,
                               actionItems: actionItems)

        vm.menuBar.reactionBarAtTop = false
        vm.menuBar.reactionSupportSkinTones = LKFeatureGating.reactionSkinTonesEnable
        vm.menuBar.reactionBar.delegate = self
        vm.menuBar.userReactionBar.delegate = self
        let layout = CommentMenuLayout(recent.isEmpty)
        let menu = DocsReactionMenuViewController(
            viewModel: vm,
            layout: layout,
            trigerView: trigerView,
            trigerLocation: location)
        menu.show(in: topMostVC)

        let wrapper = MenuWeakWrapper(menuVC: menu, identifier: item.menuKey)
        setMenu(with: wrapper)

        context.scheduler?.dispatch(action: .tea(.reactionCommentPanel(item)))

    }
    
    func setMenu(with wrapper: MenuWeakWrapper) {
        context?.scheduler?.dispatch(action: .ipc(.setMenu(wrapper), nil))
    }
    
    func handleShowBlockReaction(_ item: CommentItem, _ location: CGPoint, _ cell: UIView, _ trigerView: UIView) {
        guard item.replyType != nil else {
            DocsLogger.error("block reaction fail replyType is nil", component: LogComponents.comment)
            return
        }

        guard let showInVC = context?.topMost else {
            DocsLogger.info("showInVC is nil", component: LogComponents.comment)
            return
        }
        
        DocsLogger.info("showReaction in VC: \(showInVC), view:\(String(describing: showInVC.view))",
                        component: LogComponents.comment)
        
        guard item.permission.contains(.canReaction) else {
            DocsLogger.info("cannot perform contentReaction",
                            component: LogComponents.comment)
            return
        }
        
        let onItemClicked: ((ReactionMenuAction) -> Void) = { [weak self] in
            guard $0.reactionKey.isEmpty == false else { return }
            self?._clickReactionIcon(item, key: $0.reactionKey)
        }
        
        let from = ContentReactionMenuController.TriggerFrom.reactionCard(trigerView: trigerView, trigerLocation: location)
        let menu = ContentReactionMenuController(triggerFrom: from, onItemClicked: onItemClicked)
        menu.showIn(controller: showInVC)
    
        let wrapper = MenuWeakWrapper(menuVC: menu, identifier: item.menuKey)
        setMenu(with: wrapper)
    }
    
    func handleClickTranslationIcon(_ item: CommentItem) {
        cancelTranslation(item)
    }
    
    /// 点击cell上的icon
    func handleClickReaction(_ item: CommentItem, _ info: ReactionInfo, _ type: ReactionTapType) {
        let commentReaction = item.reactions?.first(where: { $0.reactionKey == info.reactionKey })
        let commentPermission = context?.scheduler?.fastState.commentPermission ?? []
        switch type {
        case .icon:
            guard commentPermission.contains(.canComment), commentPermission.contains(.canReaction) else {
                DocsLogger.warning("canComment or canReaction is false", component: LogComponents.comment)
                return
            }
            _clickReactionIcon(item, key: info.reactionKey)
        case let .name(name):
            _clickName(info, id: name, users: commentReaction?.userList)
        case .more:
            _clickMore(item, reactionInfo: info, commentReaction: commentReaction)
        default:
            break
        }
    }
    
    private func _clickName(_ reactionInfo: ReactionInfo, id: String, users: [CommentReaction.UserInfo]?) {
        let isGuest = User.current.basicInfo?.isGuest ?? false
        let user = users?.first(where: { $0.userId == id })
        guard !DocsSDK.isInLarkDocsApp, !isGuest, let tempUser = user, tempUser.anonymous == false else {
            // 自己是匿名用户、或者匿名用户发的都屏蔽
            DocsLogger.info("reaction, clickName, isGuest=\(isGuest), item.anonymous=\(String(describing: user?.anonymous))", component: LogComponents.comment)
            return
        }
        DocsLogger.info("click reaction user name", component: LogComponents.comment)
        context?.scheduler?.dispatch(action: .ipc(.clickReactionName(userId: id, from: nil), nil))
    }

    private func _clickMore(_ commentItem: CommentItem, reactionInfo: ReactionInfo, commentReaction: CommentReaction?) {
        let isGuest = User.current.basicInfo?.isGuest ?? false
        guard !isGuest else {
            DocsLogger.info("reaction, clickMore, isGuest=\(isGuest)", component: LogComponents.comment)
            return
        }
        if let commentReaction = commentReaction {
            DocsLogger.info("click reaction more", component: LogComponents.comment)
            dispatchAPI(.setDetailPanel(reaction: commentReaction, show: true))
            let reactions = commentItem.reactions ?? []
            let needLoadMoreReactions = checkNeedLoadMoreReactions(reactions)
            self._presentToReactionDetailVC(needLoadMoreReactions, commentReaction, reactions)
            if needLoadMoreReactions {
                dispatchAPI(.getReactionDetail(commentItem, commentReaction))
            }

            switch commentItem.interactionType {
            case .comment, .none:
                 break
            case .reaction:
                let params1: [String: Any] = ["click": "user_name",
                                              "target": "ccm_reaction_detail_page_view",
                                              "emoji_type": commentReaction.reactionKey]
                DocsTracker.newLog(enumEvent: .contentReactionEvent, parameters: params1)
                let reactionCount = (commentItem.reactions ?? []).count
                let params2: [String: Any] = ["emoji_num": (reactionCount > 1) ? "multiple" : "one",
                                              "reaction_card_id": commentReaction.commentId ?? ""]
                DocsTracker.newLog(enumEvent: .contentReactionDetailView, parameters: params2)
            }
        }
    }
    
    private func checkNeedLoadMoreReactions(_ reactions: [CommentReaction]) -> Bool {
        for reaction in reactions where reaction.userList.count < reaction.totalCount {
            return true
        }

        return false
    }
    
    private func _presentToReactionDetailVC(_ needLoadMoreReactions: Bool, _ commentReaction: CommentReaction, _ reactions: [CommentReaction]) {
        let message = LarkReactionDetailController.Message(id: "FIXME", channelID: "FIXME")
        let dependency = CCMReactionDetailDependencyImpl(needLoadMore: needLoadMoreReactions, reaction: commentReaction, lastReactions: reactions)
        reactionDetailImp = dependency
        reactionDetailImp?.clickAvatar = { [weak self] (id, nav) in
            guard let self = self else { return }
            self.context?.scheduler?.dispatch(action: .ipc(.clickReactionName(userId: id, from: nav), nil))
        }
        let controller = ReactionDetailVCFactory.create(message: message, dependency: dependency)
        let navVC = SKNavigationController(rootViewController: controller)
        navVC.modalPresentationStyle = .overCurrentContext
        navVC.modalTransitionStyle = .crossDissolve
        navVC.view.backgroundColor = UIColor.clear
        context?.topMost?.present(navVC, animated: true, completion: nil)
        navVC.rx.deallocated.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.dispatchAPI(.setDetailPanel(reaction: commentReaction, show: false))
            self.reactionDetailImp?.onReactionDetailDismissed()
        }).disposed(by: disposeBag)
    }

    func handleShowResolveAndCopyMenu(_ comment: Comment,
                                      _ link: String,
                                      _ ability: [CommentAbility],
                                      _ trigerView: UIView,
                                      _ callback: CommentAction.IPC.Callback?) {
        guard let context = context,
              let topMostVC = context.topMost else {
            DocsLogger.error("showInVC is nil", component: LogComponents.comment)
            return
        }
        let sourceRect = CGRect(x: trigerView.center.x, y: trigerView.frame.origin.y, width: 1, height: trigerView.frame.size.height)
        let location = context.commentPluginView.convert(sourceRect, from: trigerView.superview).origin
        let actionItems = ability.map { ability in
            MenuActionItem(
                name: ability.description,
                image: ability.udImage,
                enable: true,
                action: { [weak self] (_) in
                    self?.resolveAndCopyMenuAction(ability, comment, link, trigerView, callback)
                })
        }
        let vm = MenuViewModel(recentReactionMenuItems: [],
                               scene: .ccm,
                               allReactionMenuItems: [],
                               allReactionGroups: [],
                               actionItems: actionItems)

        vm.menuBar.reactionBarAtTop = false
        vm.menuBar.reactionSupportSkinTones = LKFeatureGating.reactionSkinTonesEnable
        let layout = CommentMenuLayout(true)
        let menu = DocsReactionMenuViewController(
            viewModel: vm,
            layout: layout,
            trigerView: context.commentPluginView,
            trigerLocation: location)
        menu.show(in: topMostVC)
        let wrapper = MenuWeakWrapper(menuVC: menu, identifier: comment.menuKey)
        setMenu(with: wrapper)
    }
    
    func resolveAndCopyMenuAction(_ ability: CommentAbility,
                                  _ comment: Comment,
                                  _ link: String,
                                  _ trigerView: UIView,
                                  _ callback: CommentAction.IPC.Callback?) {
        let commentLink = link.replacingOccurrences(of: "{commentId}", with: "\(comment.commentID)")
        switch ability {
        case .resolve:
            callback?((comment, trigerView), nil)
        case .copyAnchorLink:
            let isSuccess = SKPasteboard.setString(commentLink,
                                   psdaToken: PSDATokens.Pasteboard.docs_comment_anchor_link_do_copy,
                              shouldImmunity: true)
            let msg = BundleI18n.SKResource.LarkCCM_DocxIM_SharePart_Copied_Toast
            if isSuccess {
                context?.scheduler?.reduce(state: .toast(.success(msg)))
                context?.scheduler?.dispatch(action: .tea(.copyAnchorLink(comment)))
                context?.scheduler?.dispatch(action: .api(.copyAnchorLink(comment), nil))
            } else {
                DocsLogger.warning("copyAnchorLink setString error", component: LogComponents.comment)
            }

        case .shareAnchorLink:
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard let self = self else { return }
                HostAppBridge.shared.call(ShareToLarkService(contentType: .text(content: commentLink), fromVC: self.context?.topMost, type: .feishu))
            }
            context?.scheduler?.dispatch(action: .tea(.shareAnchorLink(comment)))
            context?.scheduler?.dispatch(action: .api(.shareAnchorLink(comment), nil))
        default:
            break
        }
    }
}


extension CommentReactionPlugin {
    
    private func _clickReactionIcon(_ item: CommentItem, key: String) {
        DocsLogger.info("handle click reaction: \(key) replyID:\(item.replyID)", component: LogComponents.comment)

        // TODO: - hyf 是否需要埋点？
//        actionHandler?.comment(self, didClickReaction: item, key: key, response: nil)
        var userId = context?.docsInfo?.commentUser?.id
        if userId == nil {
            DocsLogger.info("didClickReaction commentUser id is nil", component: LogComponents.comment)
            userId = User.current.info?.userID
        }
        guard let id = userId else {
            return DocsLogger.error("user id nil", component: LogComponents.comment)
        }
        var isCurUserInUsers = false
        if let commentReaction = item.reactions?.first(where: { $0.reactionKey == key }) {
            isCurUserInUsers = commentReaction.userList.contains { $0.userId == id }
        }
        let blockReaction = item.interactionType == .reaction
        if isCurUserInUsers {
            if blockReaction {
                dispatchAPI(.removeContentReaction(reactionKey: key, item: item))
            } else {
                dispatchAPI(.removeReaction(reactionKey: key, item: item))
            }
        } else {
            if blockReaction {
                dispatchAPI(.addContentReaction(reactionKey: key, item: item))
            } else {
                dispatchAPI(.addReaction(reactionKey: key, item: item))
            }
            // 更新用户最近和最常使用表情
            EmojiImageService.default?.updateUserReaction(key: key)
        }
    }
    
    private func _handleReactionPanelAction(_ ability: CommentAbility, _ item: CommentItem, _ cell: UIView, _ trigerView: UIView, relativeRect: CGRect) {
        // 处理用户点击了reaction面板中的各个按钮（比如复制）之后的动作
        switch ability {
        case .copy: // 区分admin / owner禁用
            if case let .denied(msg) = context?.businessDependency?.externalCopyPermission {
                context?.scheduler?.reduce(state: .toast(.failure(msg)))
                DocsTracker.newLog(enumEvent: .permissionCopyForbiddenToastView,
                                   parameters: ["forbidden_location": "part_comments",
                                                "is_history": "false"])
                PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
            } else if let cell = cell as? CommentTableViewCell {
                let pointId = context?.commentPluginView.getEncryptId()
                let isSuccess = SKPasteboard.setString(cell.contentLabel.text,
                                       pointId: pointId,
                                     psdaToken: PSDATokens.Pasteboard.docs_comment_reaction_panel_action_do_copy)
                let msg = BundleI18n.SKResource.Doc_Doc_CopySuccess
                if isSuccess {
                    context?.scheduler?.reduce(state: .toast(.success(msg)))
                    PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
                } else {
                    DocsLogger.error("cell copy err: \(cell)", component: LogComponents.comment)
                    PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
                }
            } else {
                PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
                DocsLogger.error("cell is convert err: \(cell)", component: LogComponents.comment)
            }
        case .delete:
            _deleteComment(item, for: trigerView, relativeRect: relativeRect)

        case .resolve:
            if let commentId = item.commentId, !commentId.isEmpty {
                let activeCommentId = context?.scheduler?.fastState.activeCommentId ?? ""
                dispatchAPI(.resolveComment(commentId: commentId, activeCommentId: activeCommentId))
            } else {
                DocsLogger.error("resolve commentId is nil or empty", component: LogComponents.comment)
            }
        case .edit:
            context?.scheduler?.dispatch(action: .interaction(.edit(item)))

        case .reply:
            context?.scheduler?.dispatch(action: .interaction(.reply(item)))
            
            
        case .translate:
            translateComment(item)

        case .showOriginContent:
            cancelTranslation(item)

        case .closseTranslation:
            cancelTranslation(item)
            context?.scheduler?.dispatch(action: .tea(.cancelTranslateClick(item)))
        case .copyAnchorLink: // 不在这里处理
            break
        case .shareAnchorLink: // 不在这里处理
            break
        }
    }
    
    func cancelTranslation(_ item: CommentItem) {
        CommentTranslationTools.shared.add(store: item)
        guard let commentId = item.commentId else { return }
        context?.scheduler?.dispatch(action: .ipc(.refresh(commentId: commentId, replyId: item.replyID), nil))
    }

    private func _deleteComment(_ item: CommentItem, for trigerView: UIView, relativeRect: CGRect) {
        let delectAction = AlertActionModel(title: BundleI18n.SKResource.Doc_Doc_Delete) { [weak self] in
            guard let self = self else { return }
            self.context?.scheduler?.dispatch(action: .api(.delete(item), nil))
        }
        var cancelAction = AlertActionModel(title: BundleI18n.SKResource.Doc_Facade_Cancel, handler: nil)
        cancelAction.isCancel = true
        var alertSheet: UIViewController
        if context?.pattern == .aside {
            let uiAlertSheet = CommentConfirmAlertVC()
            uiAlertSheet.construct {
                $0.preferredContentSize = CGSize(width: 351, height: 112)
                $0.setConfirmTitle(delectAction.title) {
                    let handler = delectAction.handler
                    handler?()
                }
                $0.modalPresentationStyle = .popover
                $0.popoverPresentationController?.delegate = self
                $0.popoverPresentationController?.sourceView = context?.commentPluginView
                $0.popoverPresentationController?.sourceRect = relativeRect
                $0.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            }
            alertSheet = uiAlertSheet
        } else {
            let actionSheet = UDActionSheet.actionSheet()
            actionSheet.addItem(text: delectAction.title, action: delectAction.handler)
            actionSheet.addItem(text: BundleI18n.SKResource.Doc_Facade_Cancel, style: .cancel)
            alertSheet = actionSheet
        }
        context?.topMost?.present(alertSheet, animated: true, completion: nil)
        let wrapper = MenuWeakWrapper(menuVC: alertSheet, identifier: item.menuKey)
        setMenu(with: wrapper)
    }

    func translateComment(_ item: CommentItem) {
        if UserScopeNoChangeFG.HYF.commentTranslateConfig {
            guard context?.businessDependency?.businessConfig.translateConfig != nil else {
                DocsLogger.info("tcranslation config is nil", component: LogComponents.comment)
                return
            }
        } else {
            guard SpaceTranslationCenter.standard.config != nil else {
                DocsLogger.info("tcranslation config is nil", component: LogComponents.comment)
                return
            }
        }

        if UserScopeNoChangeFG.WWJ.translateLangRecognitionEnable {
            let targetLanguage = getTranslateLanguageKey()
            if targetLanguage != item.targetLanguage, !targetLanguage.isEmpty {
                //targetLanguage变更时应该重新走翻译流程
                item.translateContent = nil
                item.targetLanguage = targetLanguage
            }
        }

        var translationed = false
        if let transltionStr = item.translateContent, !transltionStr.isEmpty {
            translationed = true
            CommentTranslationTools.shared.remove(store: item)
            context?.scheduler?.dispatch(action: .ipc(.refresh(commentId: item.commentId ?? "", replyId: item.replyID), nil))
        }

        DocsLogger.info("comment--- hasLocalTranslation=\(translationed)", component: LogComponents.comment)

        if !translationed {
            CommentTranslationTools.shared.remove(store: item)
            dispatchAPI(.translate(item))
        } else {
            // 命中缓存时，不会走到前端，需要端上补充上报一下
            context?.scheduler?.dispatch(action: .tea(.translateClick(item)))
        }
    }

    func getTranslateLanguageKey() -> String {
        guard let translateService = try? Container.shared.resolve(assert: CCMTranslateService.self) else { return ""}
        return translateService.targetLanguageKey ?? ""
    }

    func reportCommentEvent(action: ClientCommentAction,
                            docsInfo: DocsInfo?,
                            cardId: String?,
                            id: String?,
                            isFullComment: Bool?,
                            extra: [String: Any] = [:]) {
        
        CommentTracker.commentReport(action: action,
                                     docsInfo: docsInfo,
                                     cardId: cardId,
                                     id: id,
                                     isFullComment: isFullComment,
                                     extra: extra)
    }
}


// MARK: - config
extension CommentReactionPlugin {
    
    private func fetchCommentAbilities(_ item: CommentItem) -> [CommentAbility] {
        guard let context = context, let docsInfo = context.docsInfo else {
            DocsLogger.error("docsInfo is nil", component: LogComponents.comment)
            return []
        }
        
        var userID: String? = docsInfo.commentUser?.id
        if userID == nil {
            userID = User.current.info?.userID
        }
        let permission = item.permission
        let isGuest = User.current.basicInfo?.isGuest ?? false
        let emptyText = (item.translateContent?.isEmpty ?? true) && (item.content?.isEmpty ?? true)

        var res: [CommentAbility] = []

        // 1. 自己发送的卡片评论显示
        // [复制、编辑、删除]
        if item.userID == userID {
            res = [.reply, .copy, .edit, .translate, .delete]
        } else {
            if docsInfo.isInCCMDocs, docsInfo.type != .minutes {
                res = [.reply, .copy, .translate, .delete] // 他人评论也加上`删除`，构造评论数据时判断userId后指定canNotDelete
            } else {
                res = [.reply, .copy, .translate] // 小程序场景，仍然保持逻辑`不能删除他人评论`
            }
        }

        if isGuest {
            res.removeAll(where: { ab -> Bool in
                ab == CommentAbility.reply
            })
        }

        // Sheet 特殊处理
        let type = docsInfo.type
        if type == .sheet {
            if !permission.contains(.canShowMore) { // sheet 的 showMore 其实代表了能不能编辑和删除的意思
                res = res.filter { ab -> Bool in
                    return ab != .edit && ab != .delete && ab != .reply
                }
            }
        }

        let hasBeenTranslated = !CommentTranslationTools.shared.contain(store: item)
        let isTranslateEmpty = item.translateContent?.isEmpty ?? true
        var translateConfig: CommentBusinessConfig.TranslateConfig? = context.businessDependency?.businessConfig.translateConfig
        if !UserScopeNoChangeFG.HYF.commentTranslateConfig {
            translateConfig = SpaceTranslationCenter.standard.commentConfig
        }
        let displayType = translateConfig?.displayType ?? .unKnown
        // 翻译选项
        switch displayType {
            //仅译文
            case .onlyShowTranslation:
                res = res.map({ ab -> CommentAbility in
                    // 如果在原文位置展示了译文。那么需要把选项”翻译“改成”原文“
                    if ab == CommentAbility.translate, hasBeenTranslated, !isTranslateEmpty {
                        return CommentAbility.showOriginContent
                    } else {
                        return ab
                    }
                })
            //可以同时展示”原文+译文“
            case .bothShow:
                res = res.map({ ab -> CommentAbility in
                    if ab == CommentAbility.translate, hasBeenTranslated, !isTranslateEmpty {
                        return CommentAbility.closseTranslation
                    }
                    return ab
                })
            default: break
        }
        let enableCommentTranslate = translateConfig?.enableCommentTranslate ?? false
        // 翻译配置关了，移除翻译选项
        if !enableCommentTranslate {
            res.removeAll(where: { ab -> Bool in
                ab == CommentAbility.translate || ab == CommentAbility.showOriginContent
            })
        }

        // 如果文字内容为空，移除翻译选项及复制选项
        if emptyText {
            res.removeAll(where: { ab -> Bool in
                ab == CommentAbility.translate ||
                ab == CommentAbility.showOriginContent ||
                ab == CommentAbility.copy
            })
        }


        // 不可以评论的移除编辑权限
        if !permission.contains(CommentPermission.canComment) {
            res.removeAll(where: { ab -> Bool in
                ab == .edit || ab == .reply
            })
        }

        // 不支持删除的移除删除权限
        if permission.contains(.canNotDelete) {
            res.removeAll(where: { ab -> Bool in
                ab == .delete
            })
        }
        
        // 处理复制权限
        if case .denied = context.businessDependency?.externalCopyPermission {
            res.removeAll(where: { $0 == .copy })
            DocsLogger.info("NO copy ability",
                            component: LogComponents.comment)
        }
        
        if context.banCanComment == true {
            res.removeAll(where: { $0 == .reply || $0 == .edit })
        }
        
        return res
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension CommentReactionPlugin: UIPopoverPresentationControllerDelegate {
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

extension CommentReactionPlugin: ReactionBarDelegate, RecentReactionsBarDelegate {
    func reactionsBarDidClickMoreButton(_ bar: ReactionBar) {
        context?.commentVC?.view.endEditing(true)
    }
    func recentReactionsBarDidClickMoreButton(_ bar: RecentReactionsBar) {
        context?.commentVC?.view.endEditing(true)
    }
}
