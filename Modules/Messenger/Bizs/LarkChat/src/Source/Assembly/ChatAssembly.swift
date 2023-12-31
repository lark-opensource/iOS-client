//
//  ChatAssembly.swift
//  LarkChat
//
//  Created by liuwanlin on 2018/8/3.
//

import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import LarkRustClient
import LarkCore
import Swinject
import EENavigator
import LarkMessageCore
import LarkSetting
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkAppConfig
import RxSwift
import LarkMessengerInterface
import LarkAttachmentUploader
import LarkAppLinkSDK
import LarkKAFeatureSwitch
import SuiteAppConfig
import LarkShareToken
import LarkPerf
import LarkCache
import LarkSceneManager
import LarkReleaseConfig
import LarkOpenChat
import LKCommonsTracker
import ByteWebImage
import LarkAssembler
import LarkStorage
import UniverseDesignToast
import LKCommonsLogging
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkChatKeyboardInterface
import LarkCustomerService

public final class ChatAssembly: LarkAssemblyInterface {
    public let config: ChatAssemblyConfig
    #if DEBUG
    public static let criticalLeakList: [AnyClass] = [ChatContainerViewController.self,
                                                      MessageDetailViewController.self]
    #endif

    public init(config: ChatAssemblyConfig) {
        self.config = config
    }

    static let logger = Logger.log(ChatAssembly.self, category: "Messenger.ChatAssembly")

    public func registContainer(container: Container) {
        let user = container.inObjectScope(M.userScope)
        let userGraph = container.inObjectScope(M.userGraph)

        userGraph.register(AttachmentUploader.self) { (r, name: String) in
            let cache = try r.resolve(assert: AttachmentDataStorage.self)
            let progressService = try r.resolve(assert: ProgressService.self)
            return AttachmentUploader.getDefaultHandler(name: name,
                                                        cache: cache,
                                                        progressService: progressService,
                                                        resolver: r)
        }

        user.register(AttachmentDataStorage.self) { r -> AttachmentDataStorage in
            let draftDomain = Domain.biz.messenger.child("Draft")
            let rootPath = IsolateSandbox(space: .user(id: r.userID), domain: draftDomain).rootPath(forType: .document)
            try? rootPath.createDirectoryIfNeeded()
            return AttachmentDataStorage(root: rootPath)
        }

        user.register(ChatP2PBotMenuConfigService.self, factory: ChatP2PBotMenuConfigServiceImp.init)

        user.register(SecretChatService.self) { r in
            return SecretChatServiceImp(userAppConfig: try r.resolve(assert: UserAppConfig.self),
                                        fgService: try r.resolve(assert: FeatureGatingService.self))
        }

        user.register(MessageBurnService.self) { r in
            return MessageBurnServiceImp(ntpServer: try r.resolve(assert: ServerNTPTimeService.self))
        }

        user.register(StickerService.self, factory: StickerServiceImpl.init)

        userGraph.register(ComposePostRouter.self) { r -> ComposePostRouter in
            return ChatRouterImpl(resolver: r)
        }

        userGraph.register(NormalChatKeyboardRouter.self) { r -> NormalChatKeyboardRouter in
            return ChatRouterImpl(resolver: r)
        }

        // groupcard
        userGraph.register(GroupCardJoinRouter.self) { r -> GroupCardJoinRouter in
            return ChatRouterImpl(resolver: r)
        }

        user.register(MessageContentService.self) { r -> MessageContentService in
            return try MessageContentServiceImpl(userResolver: r)
        }

        userGraph.register(ChatDocDependency.self) { (r) -> ChatDocDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        userGraph.register(ChatCalendarDependency.self) { (r) -> ChatCalendarDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        userGraph.register(ChatByteViewDependency.self) { (r) -> ChatByteViewDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        userGraph.register(ChatMicroAppDependency.self) { (r) -> ChatMicroAppDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        userGraph.register(ChatTodoDependency.self) { (r) -> ChatTodoDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        userGraph.register(ChatCellViewModelFactoryDependency.self) { (r) -> ChatCellViewModelFactoryDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        userGraph.register(ChatMessageCellVMDependency.self) { (r) -> ChatMessageCellVMDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        userGraph.register(ChatTabsDataSourceService.self, factory: ChatTabsDataSourceImp.init)
        userGraph.register(GroupGuideAddTabProvider.self, factory: GroupGuideAddTabProviderImp.init)

        userGraph.register(ChatInputKeyboardService.self) { (_) -> ChatInputKeyboardService in
            return ChatKeyboardServiceIMP()
        }
        userGraph.register(ChatOpenKeyboardService.self) { (_) -> ChatOpenKeyboardService in
            return ChatKeyboardServiceIMP()
        }
        user.register(ChatTabsGuideService.self) { (_) -> ChatTabsGuideService in
            return ChatTabsGuideServiceImp()
        }
        user.register(ChatDocsService.self) { (r) -> ChatDocsService  in
            return try ChatDocsServiceImp(userResolver: r)
        }

        userGraph.register(ChatLinkedPageService.self, factory: { (r) -> ChatLinkedPageService in
            let rustClient = try r.resolve(assert: RustService.self)
            return ImPluginForWebImp(client: rustClient, userResolver: r)
        })

        userGraph.register(ChatWAContainerDependency.self) { (r) -> ChatWAContainerDependency in
            return try r.resolve(assert: ChatDependency.self)
        }

        user.register(ChatWAContainerService.self) { (r) -> ChatWAContainerService in
            return try ChatWAContainerServiceImp(userResolver: r)
        }

    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(SendLocationBody.self)
        .factory(SendLocationHandler.init)

        Navigator.shared.registerRoute.type(LocationNavigateBody.self)
        .factory(cache: true, LocationNavigateHandler.init)

        let wrapperRegisterOpenLocationBody: () -> Router = {
            Navigator.shared.registerRoute.type(OpenLocationBody.self)
            .factory(OpenLocationHandler.init)

            Navigator.shared.registerRoute.type(ChooseLocationBody.self)
            .factory(ChooseLocationHandler.init)
            return Router()
        }
        wrapperRegisterOpenLocationBody()

        Navigator.shared.registerRoute.type(MergeForwardDetailBody.self)
        .factory(cache: true, MergeForwardDetailHandler.init)

        Navigator.shared.registerRoute.type(MessageForwardContentPreviewBody.self)
        .factory(cache: true, MessageForwardContentPreviewHandler.init)
        Navigator.shared.registerRoute.type(ForwardChatMessagePreviewBody.self)
        .factory(cache: true, ForwarChatMessagesPreviewHandler.init)

        Navigator.shared.registerRoute.type(MessageLinkDetailBody.self)
        .factory(cache: true, MessageLinkDetailHandler.init)

        Navigator.shared.registerRoute.type(FavoriteMergeForwardDetailBody.self)
        .factory(cache: true, FavoriteMergeForwardDetailHandler.init)

        // 通过点击系统消息中的人名进群群卡片
        Navigator.shared.registerRoute.type(GroupCardSystemMessageJoinBody.self)
        .factory(cache: true, GroupCardSystemMessageJoinHandler.init)

        Navigator.shared.registerRoute.type(RecommendGroupJoinBody.self)
        .factory(cache: true, RecommendGroupJoinHandler.init)

        // 通过团队群进入群卡片
        Navigator.shared.registerRoute.type(GroupCardTeamJoinBody.self)
        .factory(cache: true, GroupCardTeamJoinHandler.init)

        Navigator.shared.registerRoute.type(PreviewChatCardByLinkPageBody.self)
        .factory(cache: true, PreviewChatCardByLinkPageHandler.init)

        Navigator.shared.registerRoute.type(AtPickerBody.self)
        .factory(AtPickerHandler.init)

        let wrapperShouldRegisterChatBody: () -> Router = {
            // 聊天页面
            if self.config.shouldRegisterChatBody {
                return Navigator.shared.registerRoute.type(ChatControllerByIdBody.self)
                .factory(cache: true, ChatControllerByChatIdHandler.init)
            }
            return Router()
        }
        wrapperShouldRegisterChatBody()

        Navigator.shared.registerRoute.type(ChatControllerByBasicInfoBody.self)
        .factory(ChatControllerByBasicInfoBodyHandler.init)

        Navigator.shared.registerRoute.type(ChatControllerByChatterIdBody.self)
        .factory(cache: true, ChatControllerByUserIdHandler.init)

        Navigator.shared.registerRoute.type(CustomServiceChatBody.self)
        .factory(cache: true, CustomServiceChatHandler.init)

        Navigator.shared.registerRoute.type(ReactionDetailBody.self)
        .factory(cache: true, ReactionDetailHandler.init)

        Navigator.shared.registerRoute.type(OncallChatBody.self)
        .factory(cache: true, OncallChatHandler.init)

        // 已读状态
        Navigator.shared.registerRoute.type(ReadStatusBody.self)
        .factory(cache: true, ReadStatusHandler.init)

        // 检查自动翻译引导
        Navigator.shared.registerRoute.type(CheckAutoTranslateGuideBody.self)
        .factory(CheckAutoTranslateGuideHandler.init)

        // Pin action
        Navigator.shared.registerRoute.type(DeletePinAlertBody.self)
        .factory(PinAlertHandler.init)

        // 号码查询限制
        Navigator.shared.registerRoute.type(PhoneQueryLimitBody.self)
        .factory(PhoneQueryLimitControllerHandler.init)

        // 翻译效果
        Navigator.shared.registerRoute.type(TranslateEffectBody.self)
        .factory(TranslateEffectHandler.init)

        // Chat Detail
        Navigator.shared.registerRoute.type(MessageDetailBody.self)
        .factory(MessageDetailHandler.init)

        // Chat Detail
        Navigator.shared.registerRoute.type(FoldMessageDetailBody.self)
        .factory(FoldMessageDetailHander.init)

        // 群卡片
        Navigator.shared.registerRoute.type(PreviewChatBody.self)
        .factory(cache: true, PreviewChatHandler.init)

        // 根据chat进入群卡片
        Navigator.shared.registerRoute.type(PreviewChatCardWithChatBody.self)
        .factory(cache: true, PreviewChatCardWithChatHandler.init)

        // Doc消息 修改权限
        Navigator.shared.registerRoute.type(DocChangePermissionBody.self)
        .factory(DocChangePermissionHandler.init)

        //收藏列表
        Navigator.shared.registerRoute.type(FavoriteListBody.self)
        .factory(cache: true, FavoriteListHandler.init)

        //收藏详情
        Navigator.shared.registerRoute.type(FavoriteDetailBody.self)
        .factory(cache: true, FavoriteDetailHander.init)

        //群内查看忙闲
        Navigator.shared.registerRoute.type(GroupFreeBusyBody.self)
        .factory(GroupFreeBusyHandler.init)

        // Call
        Navigator.shared.registerRoute.type(CallByChannelBody.self)
        .factory(cache: true, CallByChannelHandler.init)

        // 自动翻译引导
        Navigator.shared.registerRoute.type(AutoTranslateGuideBody.self)
        .factory(AutoTranslateGuideHandler.init)

        //添加标签页
        Navigator.shared.registerRoute.type(ChatAddTabBody.self)
        .factory(ChatAddTabHandler.init)

        // 添加 New Pin
        Navigator.shared.registerRoute.type(ChatAddPinBody.self)
        .factory(ChatAddPinHandler.init)

        // New Pin 列表页
        Navigator.shared.registerRoute.type(ChatPinCardListBody.self)
        .factory(ChatPinCardListHandler.init)

        Navigator.shared.registerRoute.type(GroupCardQRCodeJoinBody.self)
        .factory(cache: true, GroupCardQRCodeJoinHandler.init)

        let wrapperCanJoinGroupByQRCode: () -> Router = {
            if self.config.canJoinGroupByQRCode {
                var groupRegexp: NSRegularExpression?
                return Navigator.shared.registerRoute.match({ (url) -> Bool in
                    do {
                        let pattern = "^http(s)?\\://([^.]+\\.)?/?[^?]+\\?share_chat_token=.+"
                        let tmpGroupRegexp = try groupRegexp ?? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                        groupRegexp = tmpGroupRegexp
                        let urlStr = url.absoluteString
                        let range = NSRange(location: 0, length: urlStr.count)
                        return !tmpGroupRegexp.matches(in: urlStr, options: [], range: range).isEmpty
                    } catch {
                        return false
                    }
                }).factory(cache: true, GroupCardQRCodeJoinByURLHandler.init)
            }
            return Router()
        }
        wrapperCanJoinGroupByQRCode()
    }

    public func registLarkAppLink(container: Container) {
        // 群设置 -> 清空聊天记录
        #if DEBUG || BETA || ALPHA
        LarkAppLinkSDK.registerHandler(path: "/client/qa/chat/message/clear", handler: { (applink) in
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let queryParameters = applink.url.queryParameters
            guard let chatId = queryParameters["chatId"], let mainSceneWindow = userResolver.navigator.mainSceneWindow else { return }
            UDToast.showLoading(with: "begin clear \(chatId) messages", on: mainSceneWindow)
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
            _ = chatAPI?.clearChatMessages(chatId: chatId).observeOn(MainScheduler.instance).subscribe(onNext: {_ in
                UDToast.showSuccess(with: "clear success", on: mainSceneWindow)
            }, onError: { error in
                UDToast.showFailure(with: "clear error", on: mainSceneWindow, error: error)
            })
        })
        #endif

        // 系统消息点击跳转”隐私设置“
        LarkAppLinkSDK.registerHandler(path: PrivacySettingBody.appLinkPattern, handler: { (appLink) in
            guard let from = appLink.context?.from() else { return }
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let body = PrivacySettingBody()
            userResolver.navigator.push(body: body, from: from)
        })

        // 添加标签页
        LarkAppLinkSDK.registerHandler(path: "/client/chat/add_tab", handler: { (applink) in
            let queryParameters = applink.url.queryParameters
            guard let chatId = queryParameters["chatId"], let from = applink.context?.from() else {
                Self.logger.error("/client/chat/add_tab applink jump failed, chatId is nil!")
                return
            }
            let fromVC = from.fromViewController
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
            if userResolver.fg.staticFeatureGatingValue(with: ChatNewPinConfig.pinnedUrlKey) {
                /// 添加 New Pin
                let appLinkJumpAction: (_ chat: Chat) -> Void = { [weak fromVC] chat in
                    guard let fromVC = fromVC else { return }
                    let body = ChatAddPinBody(chat: chat, completion: nil)
                    userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: fromVC,
                        prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                    )
                }

                _ = chatAPI?.fetchChat(by: chatId, forceRemote: false)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak fromVC] chat in
                        guard let chat = chat, let fromVC = fromVC else { return }
                        if chat.isFrozen {
                            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_CantCompleteActionBecauseGrpDisbanded_Toast, on: fromVC.view)
                            return
                        } else if !ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: userResolver.userID, featureGatingService: userResolver.fg) {
                            let errorMessage = BundleI18n.LarkChat.Lark_IM_OnlyOwnerAdminCanManagePinnedItems_Toast
                            UDToast.showFailure(with: errorMessage, on: fromVC.view)
                        } else {
                            appLinkJumpAction(chat)
                        }
                    })
            } else {
                /// 添加群 tab
                let appLinkJumpAction: (_ chat: Chat) -> Void = { [weak fromVC] chat in
                    guard let fromVC = fromVC else { return }
                    let body = ChatAddTabBody(
                        chat: chat,
                        completion: { [weak fromVC] _ in
                            guard let fromVC = fromVC else { return }
                            fromVC.presentedViewController?.dismiss(animated: true)
                        })
                    userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: fromVC,
                        prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                    )
                }

                _ = chatAPI?.fetchChat(by: chatId, forceRemote: false)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak fromVC] chat in
                        guard let chat = chat, let fromVC = fromVC else { return }
                        if !ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: userResolver.userID, featureGatingService: userResolver.fg) {
                            let errorMessage = BundleI18n.LarkChat.Lark_IM_OnlyOwnerAdminCanManageTabs_Toast
                            UDToast.showFailure(with: errorMessage, on: fromVC.view)
                        } else {
                            appLinkJumpAction(chat)
                        }
                    })
            }
        })

        LarkAppLinkSDK.registerHandler(path: "/client/chat/open_doc_template", handler: { (applink) in
            let queryParameters = applink.url.queryParameters
            guard let chatId = queryParameters["chatId"], let from = applink.context?.from() else {
                Self.logger.error("/client/chat/add_tab applink jump failed, chatId is nil!")
                return
            }
            let fromVC = from.fromViewController
            let urlStr = applink.url.absoluteString.replacingOccurrences(of: "/client/chat/open_doc_template", with: "/client/docs/open_doc_template")
            guard let url = URL(string: urlStr) else {
                return
            }
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
            _ = chatAPI?.fetchChat(by: chatId, forceRemote: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak fromVC] chat in
                    guard let chat = chat, let fromVC = fromVC else { return }
                    if userResolver.fg.staticFeatureGatingValue(with: ChatNewPinConfig.pinnedUrlKey) {
                        if chat.isFrozen {
                            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_CantCompleteActionBecauseGrpDisbanded_Toast, on: fromVC.view)
                            return
                        } else if !ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: userResolver.userID, featureGatingService: userResolver.fg) {
                            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_OnlyOwnerAdminCanManagePinnedItems_Toast, on: fromVC.view)
                        } else {
                            userResolver.navigator.present(url, from: fromVC)
                        }
                    } else {
                        if !ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: userResolver.userID, featureGatingService: userResolver.fg) {
                            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_OnlyOwnerAdminCanManageTabs_Toast, on: fromVC.view)
                        } else {
                            userResolver.navigator.present(url, from: fromVC)
                        }
                    }
                })
        })

        // 群公告
        LarkAppLinkSDK.registerHandler(path: "/client/chat/open_group_announcement", handler: { (applink) in
            let queryParameters = applink.url.queryParameters
            guard let chatId = queryParameters["chatId"], let from = applink.context?.from() else {
                Self.logger.error("/client/chat/open_group_announcement applink jump failed, chatId is nil!")
                return
            }
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let fromVC = from.fromViewController
            let appLinkJumpAction: (_ chatId: String) -> Void = { [weak fromVC] chatId in
                guard let fromVC = fromVC else { return }
                let body = ChatAnnouncementBody(chatId: chatId)
                userResolver.navigator.push(body: body, from: fromVC)
                if userResolver.fg.staticFeatureGatingValue(with: ChatNewPinConfig.pinnedUrlKey) {
                    _ = (try? userResolver.resolve(assert: ChatAPI.self))?
                        .createAnnouncementChatPin(chatId: Int64(chatId) ?? 0)
                        .subscribe()
                }
            }
            let authEdit = queryParameters["authEdit"]
            Self.logger.info("/client/chat/open_group_announcement applink, chatId=\(chatId), authEdit=\(authEdit)!")
            if authEdit == "true" {
                let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
                _ = chatAPI?.fetchChat(by: chatId, forceRemote: false)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak fromVC] chat in
                        guard let chat = chat, let fromVC = fromVC else { return }
                        if chat.offEditGroupChatInfo == true,
                           userResolver.userID != chat.ownerId,
                           !chat.isGroupAdmin {
                            let errorMessage = BundleI18n.LarkChat.Lark_IM_OnlyOwnerAdminCanEditAnnouncement_Toast
                            UDToast.showFailure(with: errorMessage, on: fromVC.view)
                        } else {
                            appLinkJumpAction(chat.id)
                        }
                    })
            } else {
                appLinkJumpAction(chatId)
            }
        })

        // 群信息
        LarkAppLinkSDK.registerHandler(path: "/client/chat/open_group_info", handler: { (applink) in
            let queryParameters = applink.url.queryParameters
            guard let chatId = queryParameters["chatId"], let from = applink.context?.from() else {
                Self.logger.error("/client/chat/open_group_announcement applink jump failed, chatId is nil!")
                return
            }
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let fromVC = from.fromViewController
            let appLinkJumpAction: (_ chatId: String) -> Void = { [weak fromVC] chatId in
                guard let fromVC = fromVC else { return }
                let body = GroupInfoBody(chatId: chatId)
                userResolver.navigator.push(body: body, from: fromVC)
            }
            let authEdit = queryParameters["authEdit"]
            Self.logger.info("/client/chat/open_group_announcement applink, chatId=\(chatId), authEdit=\(authEdit)!")
            if authEdit == "true" {
                let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
                _ = chatAPI?.fetchChat(by: chatId, forceRemote: false)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak fromVC] chat in
                        guard let chat = chat, let fromVC = fromVC else { return }
                        if chat.offEditGroupChatInfo == true,
                           userResolver.userID != chat.ownerId,
                           !chat.isGroupAdmin {
                            let errorMessage = BundleI18n.LarkChat.Lark_IM_OnlyOwnerAdminCanEditInfo_Toast
                            UDToast.showFailure(with: errorMessage, on: fromVC.view)
                        } else {
                            appLinkJumpAction(chat.id)
                        }
                    })
            } else {
                appLinkJumpAction(chatId)
            }
        })

        // 红包通用弹窗，只在Chat场景使用
        LarkAppLinkSDK.registerHandler(path: "/client/virtual_hongbao/popup", handler: { (appLink) in
            guard appLink.from == .card else { return }
            guard let from = appLink.context?.from() else { return }
            guard let params = try? URL.createURL3986(string: appLink.url.absoluteString).queryParameters else { return }
            guard let title = params["title"], let desc = params["desc"], let amount = params["amount"] else { return }
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let content = HongBaoAlertContent(title: title, desc: desc, amount: amount)
            let vc = HongBaoAlertController(content: content)
            vc.modalPresentationStyle = .overCurrentContext
            userResolver.navigator.present(vc, from: from, animated: false)

            // 点击红包打点，有type才进行
            guard let type = params["type"], !type.isEmpty else { return }
            ChatTracker.trackOpenFakeHongbao(type: type)
        })

        LarkAppLinkSDK.registerHandler(path: GroupViaLinkJoinHandler.Link.Path, handler: { (applink) in
            GroupViaLinkJoinHandler(resolver: container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode))
            .handle(applink: applink)
        })

        LarkAppLinkSDK.registerHandler(path: "/client/chat/chatter/add") { (applink) in
            let queryParameters = applink.url.queryParameters
            guard let chatId = queryParameters["chatId"] else {
                return
            }
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let body = JoinGroupApplyBody(chatId: chatId, way: .viaSearch)
            if let from = applink.context?.from() {
                userResolver.navigator.push(body: body, from: from)
            }
        }

        ShareTokenManager.shared.registerHandler(source: "join_chat_by_share_kouling") { (map) in
            JoinChatViaKoulingHandler(resolver: container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode))
            .handle(map: map)
        }

        //群设置申请成员上限页面
        LarkAppLinkSDK.registerHandler(path: GroupApplyForLimitBody.appLinkPattern) { (applink: AppLink) in
            guard let from = applink.context?.from(),
                  let chatId = applink.url.queryParameters["chat_id"] else { return }
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            Tracker.post(TeaEvent("im_chat_main_click", params: [
                "click": "apply_permission",
                "target": "im_chat_member_toplimit_apply_view"
            ]))
            let body = GroupApplyForLimitBody(chatId: chatId)
            userResolver.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() },
                                     animated: true)
        }

        // 新飞书客服
        LarkAppLinkSDK.registerHandler(path: "/client/csc/open") { (applink: AppLink) in
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            guard userResolver.fg.dynamicFeatureGatingValue(with: "messenger.customer.service.bot") else {
                UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_MessageLink_NotWithinFG_Toast,
                                 on: applink.context?.from()?.fromViewController?.view ?? UIView())
                return
            }
            guard let from = applink.context?.from()?.fromViewController,
                  let customerService = try? userResolver.resolve(assert: LarkCustomerServiceAPI.self) else {
                Self.logger.error("csc applink handler dependency is nil")
                return
            }
            let queryParameters = applink.url.queryParameters
            Self.logger.info("csc applink handler queryParameters is \(queryParameters)")
            guard let botAppId = queryParameters["AppId"], let extInfo = queryParameters["ExtInfo"] else {
                Self.logger.error("csc applink handler queryParameters is wrong")
                return
            }
            _ = DelayLoadingObservableWraper.wraper(observable: customerService.getNewCustomerInfo(botAppId: botAppId, extInfo: extInfo),
                                                    delay: 1,
                                                    showLoadingIn: from.view)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak from] res in
                    guard let from = from else { return }
                    // 跳chat
                    switch res {
                    case .chatId(let chatId):
                        let body = ChatControllerByIdBody(chatId: chatId)
                        userResolver.navigator.push(body: body, from: from)
                    case .fallbackLink(let url):
                        userResolver.navigator.push(url, from: from)
                    case .fail(desc: let desc):
                        if let view = from.fromViewController?.view {
                            UDToast.showFailure(with: desc ?? BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip,
                                                on: view)
                        }
                    default:
                        break
                    }
                }, onError: { [weak from] error in
                    Self.logger.error("csc applink handler getNewCustomerInfo is error", error: error)
                    guard let view = from?.view else { return }
                    UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: view)
                })
        }

        // 消息链接化，点击消息链接
        LarkAppLinkSDK.registerHandler(path: "/client/message/link/open") { appLink in
            guard let fromVC = appLink.context?.from()?.fromViewController,
                  let token = appLink.url.queryParameters["token"],
                  !token.isEmpty else {
                Self.logger.error("MessageLink: failed to open \(appLink.url)")
                return
            }
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            guard userResolver.fg.staticFeatureGatingValue(with: "im.messenger.message_link") else {
                UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_MessageLink_NotWithinFG_Toast, on: fromVC.view)
                return
            }
            guard let messageAPI = try? userResolver.resolve(assert: MessageAPI.self) else {
                return
            }
            Self.logger.info("MessageLink: start get permission: \(token)")
            _ = DelayLoadingObservableWraper.wraper(
                observable: messageAPI.getMessageLinkPermission(token: token),
                showLoadingIn: fromVC.view
            ).observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak fromVC] response in
                    guard let fromVC = fromVC else { return }
                    switch response.permission {
                    case .none:
                        UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_MessageLink_NoPermissionToAccess_Toast, on: fromVC.view)
                    case .allowPreview:
                        if !response.applinkURL.isEmpty,
                           let url = URL(string: response.applinkURL) {
                            userResolver.navigator.open(url, from: fromVC)
                        }
                    @unknown default:
                        break
                    }
                }, onError: { [weak fromVC] error in
                    Self.logger.error("MessageLink: permission error", error: error)
                    if let view = fromVC?.view {
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: view)
                    }
                })
        }

        LarkAppLinkSDK.registerHandler(path: "/client/favorite/open_detail") { (applink) in
            let queryParameters = applink.url.queryParameters
            Self.logger.info("MessageLink: start jump to Favorite Detail \(queryParameters["favorite_id"])")
            guard let favoriteId = queryParameters["favorite_id"] else {
                return
            }
            let favoriteType = queryParameters["favorite_type"]
            let userResolver = container.getCurrentUserResolver(compatibleMode: M.userScopeCompatibleMode)
            let body = FavoriteDetailBody(favoriteId: favoriteId, favoriteType: favoriteType)
            if let from = applink.context?.from() {
                userResolver.navigator.push(body: body, from: from)
            }
        }

        LarkAppLinkSDK.registerHandler(path: MyAIToolsBody.applinkPattern, handler: { (appLink) in
            guard let aiService = try? container.getCurrentUserResolver().resolve(assert: MyAIService.self) else { return }
            // MyAI FG 关闭情况下，不响应 AppLink
            guard aiService.enable.value else {
                Self.logger.error("appLink my aiService not enabled.")
                return
            }
            guard let from = appLink.context?.from(), let fromVC = from.fromViewController, let chatMessageVc = fromVC as? HasMyAIPageService else {
                Self.logger.error("appLink get chatVc failure")
                return
            }
            guard let msgId = appLink.url.queryParameters["msg_id"] else { return }
            chatMessageVc.myAIPageService?.handleExtensionCardApplink(messageId: msgId, chat: chatMessageVc.chat.value, from: fromVC)
        })

        // 通过 MyAI new topic 卡片的 AppLink 执行快捷指令
        LarkAppLinkSDK.registerHandler(path: "/client/myai/quickaction/exec") { appLink in
            // 判断 MyAI 的开关
            guard let aiService = try? container.getCurrentUserResolver().resolve(assert: MyAIService.self), aiService.enable.value else {
                Self.logger.error("[MyAI.QuickAction][AppLink] MyAI not enabled.")
                return
            }
            // 判断功能的 FG
            guard container.getCurrentUserResolver().fg.dynamicFeatureGatingValue(with: "lark.my_ai.card_swich_extension") else {
                Self.logger.error("[MyAI.QuickAction][AppLink] FG not opened.")
                return
            }
            // 获取分会话上下文
            guard let from = appLink.context?.from(),
                  let fromVC = from.fromViewController,
                  let pageService = (fromVC as? HasMyAIPageService)?.myAIPageService,
                  let quickActionSendService = (fromVC as? HasMyAIQuickActionSendService)?.myAIQuickActionSendService else {
                Self.logger.error("[MyAI.QuickAction][AppLink] Parsing service context failed.")
                return
            }
            pageService.handleQuickActionByApplinkURL(appLink.url, service: quickActionSendService, onChat: fromVC)
        }

        // 新人进群，MyAI总结最近消息
        LarkAppLinkSDK.registerHandler(path: "/client/chat/myai_chatmode/open_and_summary") { (appLink) in
            // 没有onboarding也需要继续处理
            guard let from = appLink.context?.from(),
                  let fromVC = from.fromViewController else { return }
            // 判断功能的 FG
            guard let aiService = try? container.getCurrentUserResolver().resolve(assert: MyAIService.self),
                  aiService.enable.value == true,
                  container.getCurrentUserResolver().fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_chat_mode") else {
                UDToast.showTips(with: BundleI18n.AI.Lark_Group_AiSummaryNoPermission_Toast, on: fromVC.view)
                Self.logger.error("[MyAI.QuickAction][AppLink] FG not opened.")
                return
            }

            guard let actionId = appLink.url.queryParameters["action_id"] else {
                Self.logger.error("applink /client/chat/myai_chatmode/open_and_summary on action_id")
                return
            }

            guard let chatID = appLink.url.queryParameters["chat_id"] else {
                Self.logger.error("applink /client/chat/myai_chatmode/open_and_summary on chat_Id")
                return
            }

            // 获取分会话上下文
            guard let handler = fromVC as? IMMyAIChatModeOpenServiceDelegate else {
                Self.logger.error("[MyAI.QuickAction][AppLink] Parsing service context failed.")
                return
            }
            handler.handleAIAddNewMemberSytemMessage(actionID: actionId, chatID: chatID, fromVC: fromVC)
        }
        // 通过 MyAI 卡片的 AppLink 开启场景
        LarkAppLinkSDK.registerHandler(path: "/client/myai/scene/select") { appLink in
            guard let from = appLink.context?.from(),
                  let fromVC = from.fromViewController else { return }
            // 判断 MyAI 的开关
            guard let aiService = try? container.getCurrentUserResolver().resolve(assert: MyAIService.self), aiService.enable.value else { return }
            // 执行开启行为
            guard let chatVC = fromVC as? HasMyAIPageService, let service = chatVC.myAIPageService else { return }
            service.handleSceneSelectByApplink(appLink.url, chat: chatVC.chat.value, onChat: fromVC)
        }

        IMChatKeyboardPanelModule.getkeyboardNewStyleEnable = {
            return KeyboardDisplayStyleManager.isNewKeyboadStyle()
        }

        IMCryptoChatKeyboardPanelModule.getkeyboardNewStyleEnable = {
            return KeyboardDisplayStyleManager.isNewKeyboadStyle()
        }

        LarkPasteboardConfig.useRedesignAbility = {
            return FeatureGatingManager.shared.featureGatingValue(with: "im.pasteboard.redesign") // foregroundUser
        }
    }

    @available(iOS 13.0, *)
    public func registLarkScene(container: Container) {
        /// 注册 Messenger Scene handler
        MessengerSceneRegister.registerMessengerScene()
    }
}

/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
enum M {
    private static var userScopeFG: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") // Global
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
