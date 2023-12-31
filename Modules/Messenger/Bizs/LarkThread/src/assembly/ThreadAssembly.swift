//
//  ThreadAssembly.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/13.
//

import Foundation
import Swinject
import LarkCore
import LarkModel
import LarkUIKit
import EENavigator
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkNavigation
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import BootManager
import LarkTab
import LarkAppLinkSDK
import LarkAttachmentUploader
import ByteWebImage
import LarkAssembler
import LarkAI
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkOpenIM
import LarkOpenKeyboard
import LarkContainer
import LarkSetting

public typealias ThreadDependency = ThreadContainerViewModelDependency & ThreadDetailControllerDependency

public final class ThreadAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(ThreadChatByChatBody.self)
        .factory(cache: true, ThreadChatHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadChatByIDBody.self)
        .factory(cache: true, ThreadChatByIDHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ThreadPreviewByIDBody.self)
        .factory(cache: true, ThreadChatPreviewByIDHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadDetailUniversalIDBody.self)
        .factory(cache: true, ThreadDetailUniversalHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadDetailByIDBody.self)
        .factory(cache: true, ThreadDetailHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadDetailPreviewByIDBody.self)
        .factory(cache: true, ThreadDetailPreviewHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MsgThreadDetailPreviewByIDBody.self)
        .factory(cache: true, MsgThreadDetailPreviewHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ReplyInThreadByModelBody.self)
        .factory(cache: true, ReplyInThreadByModelHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ReplyInThreadByIDBody.self)
        .factory(cache: true, ReplyInThreadHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadChatComposePostBody.self)
        .factory(cache: true, ThreadChatComposePostHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadDetailByModelBody.self)
        .factory(cache: true, ThreadDetailByModelHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadPostForwardDetailBody.self)
        .factory(cache: true, ThreadPostForwardDetailHander.init(resolver:))

        Navigator.shared.registerRoute.type(OpenShareThreadTopicBody.self)
        .factory(cache: true, OpenShareThreadTopicHandler.init(userResolver:))
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(Thread.userScope)
        let userGraph = container.inObjectScope(Thread.userGraph)
        userGraph.register(ThreadKeyboardRouter.self) { (r) -> ThreadKeyboardRouter in
            return ThreadChatRouterImpl(userResolver: r)
        }

        userGraph.register(ThreadChatRouter.self) { (r) -> ThreadChatRouter in
            return ThreadChatRouterImpl(userResolver: r)
        }

        userGraph.register(TopicGroupPushWrapper.self) { (r, topicGroup: TopicGroup) -> TopicGroupPushWrapper in
            return TopicGroupPushWrapperImp(topicGroup: topicGroup, pushCenter: try r.userPushCenter)
        }

        //swiftlint:disable closure_parameter_position
        userGraph.register(ThreadKeyboard.self) {(
            r,
            delegate: ThreadKeyboardDelegate & ThreadKeyboardViewModelDelegate,
            chatPushWrapper: ChatPushWrapper,
            threadPushWrapper: ThreadPushWrapper,
            isReplyInThread: Bool
            ) -> ThreadKeyboard in

            let draftCache = try r.resolve(assert: DraftCache.self)
            let pushCenter = try r.userPushCenter
            let viewModel: ThreadKeyboardViewModel
            let keyboardView: ThreadKeyboardView
            let keyboard: ThreadKeyboard
            let keyboardNewStyleEnable = KeyboardDisplayStyleManager.isNewKeyboadStyle()

            // audioToTextEnable: 判断FeatureSwitch && FG
            let keyboardConfig = ThreadKeyboardConfig(keyboardNewStyleEnable: keyboardNewStyleEnable)
            viewModel = NewThreadKeyboardViewModel(
                userResolver: r,
                chatWrapper: chatPushWrapper,
                threadWrapper: threadPushWrapper,
                draftCache: draftCache,
                chatterAPI: try r.resolve(assert: ChatterAPI.self),
                chatAPI: try r.resolve(assert: ChatAPI.self),
                docAPI: try r.resolve(assert: DocAPI.self),
                stickerService: try r.resolve(assert: StickerService.self),
                pushChannelMessage: pushCenter.driver(for: PushChannelMessage.self),
                router: try r.resolve(assert: ThreadKeyboardRouter.self),
                delegate: delegate)
            viewModel.isReplyInThread = isReplyInThread
            let token = isReplyInThread ? "LARK-PSDA-messenger-message-thread-keyboard-input-permission" :
            "LARK-PSDA-messenger-thread-keyboard-input-permission"
            let keyBoardModule: IMKeyboardModule
            let context: KeyboardContext
            if isReplyInThread {
                context = KeyboardContext(parent: Container(parent: container), store: Store(),
                                          userStorage: r.storage, compatibleMode: r.compatibleMode)
                IMMessageThreadKeyboardModule.onLoad(context: context)
                IMMessageThreadKeyboardModule.registGlobalServices(container: context.container)
                keyBoardModule = IMMessageThreadKeyboardModule(context: context)

            } else {
                context = KeyboardContext(parent: Container(parent: container), store: Store(),
                                          userStorage: r.storage, compatibleMode: r.compatibleMode)
                IMThreadKeyboardModule.onLoad(context: context)
                IMThreadKeyboardModule.registGlobalServices(container: context.container)
                keyBoardModule = IMThreadKeyboardModule(context: context)
            }
            keyboardView = NewThreadKeyboardView(chatWrapper: chatPushWrapper,
                                                 viewModel: IMKeyboardViewModel(module: keyBoardModule,
                                                                                chat: chatPushWrapper.chat),
                                                 pasteboardToken: token,
                                                 keyboardNewStyleEnable: keyboardNewStyleEnable)

            context.container.register(OpenKeyboardService.self) { [weak keyboardView] (_) -> OpenKeyboardService in
                return keyboardView ?? OpenKeyboardServiceEmptyIMP()
            }

            // audioToTextEnable: 判断FeatureSwitch && FG
            if isReplyInThread {
                keyboard = ReplyInThreadNewThreadboard(
                    viewModel: viewModel,
                    delegate: delegate,
                    draftCache: draftCache,
                    keyBoardView: keyboardView,
                    sendImageProcessor: try r.resolve(assert: SendImageProcessor.self),
                    keyboardConfig: keyboardConfig
                )
            } else {
                keyboard = NewThreadKeyboard(
                    viewModel: viewModel,
                    delegate: delegate,
                    draftCache: draftCache,
                    keyBoardView: keyboardView,
                    sendImageProcessor: try r.resolve(assert: SendImageProcessor.self),
                    keyboardConfig: keyboardConfig
                )
            }
            return keyboard
        }
        //swiftlint:enable closure_parameter_position

        user.register(ThreadMenuService.self) { (resolver) -> ThreadMenuService in
            return ThreadMenuServiceImp(
                userResolver: resolver,
                messageAPI: try resolver.resolve(assert: MessageAPI.self),
                threadAPI: try resolver.resolve(assert: ThreadAPI.self),
                pinAPI: try resolver.resolve(assert: PinAPI.self),
                adminService: try resolver.resolve(assert: ThreadAdminService.self),
                todoDependency: try resolver.resolve(assert: MessageCoreTodoDependency.self),
                modelService: try resolver.resolve(assert: ModelService.self),
                tenantUniversalSettingService: try? resolver.resolve(type: TenantUniversalSettingService.self),
                topNoticeService: try? resolver.resolve(type: ChatTopNoticeService.self),
                navigationService: try? resolver.resolve(type: NavigationService.self)
            )
        }

        user.register(ThreadAdminService.self) { (resolver) -> ThreadAdminService in
            return ThreadAdminServiceImpl(userResolver: resolver, chatterAPI: try resolver.resolve(assert: ChatterAPI.self))
        }
        userGraph.register(TheadInputAtManager.self) { r in
            return TheadInputAtManager(userResolver: r)
        }
    }

    public func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: "/client/thread/open") { (applink: AppLink) in
            guard let from = applink.context?.from() else {
                assertionFailure("Missing applink from")
                return
            }

            let queryParameters = applink.url.queryParameters
            guard let threadId = queryParameters["threadid"] else {
                return
            }
            let threadPosition = Int32(queryParameters["thread_position"] ?? "")

            let body = ThreadDetailByIDBody(threadId: threadId, loadType: .position, position: threadPosition)
            Navigator.shared.push(body: body, from: from) // foregroundUser
        }

        /// TODO: 李洛斌 跳转APPLink MVP后续版本支持 暂时不打开,后续打开后需要增加参数的log
//        LarkAppLinkSDK.registerHandler(path: "/client/reply/in/thread/open") { (applink: AppLink) in
//            guard let from = applink.context?.from() else {
//                assertionFailure("Missing applink from")
//                return
//            }
//
//            let queryParameters = applink.url.queryParameters
//            guard let threadId = queryParameters["threadid"] else {
//                return
//            }
//            let threadPosition = Int32(queryParameters["thread_position"] ?? "")
//            let body = ReplyInThreadByIDBody(threadId: threadId, loadType: .position, position: threadPosition, sourceType: .applink)
//            Navigator.shared.push(body: body, from: from) // foregroundUser
//        }
    }

    public func registURLInterceptor(container: Container) {
        // thread详情页
        (ThreadDetailByIDBody.patternConfig.pattern, {(url, from) in
            Navigator.shared.showDetailOrPush(url: url, tab: .feed, from: from) // foregroundUser
        })
        /// replyInthread详情页
        (ReplyInThreadByIDBody.patternConfig.pattern, {(url, from) in
            Navigator.shared.showDetailOrPush(url: url, tab: .feed, from: from) // foregroundUser
        })
    }

    @_silgen_name("Lark.ChatCellFactory.Messenger.Thread")
    static public func cellFactoryRegister() {
        ThreadChatSubFactoryRegistery.register(PinComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(DlpTipComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(FileNotSafeComponentFactory.self)
        // 暂时去掉转发提示
//        ThreadChatSubFactoryRegistery.register(ForwardComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(RecalledContentFactory.self)
        ThreadChatSubFactoryRegistery.register(MultiEditComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadChatTextPostContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadChatMergeForwardContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadChatVideoContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadChatImageContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadChatStickerContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadFileContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadFolderContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadShareGroupContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadChatAudioContentFactory.self)
        ThreadChatSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)
        ThreadChatSubFactoryRegistery.register(TCPreviewContainerComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(ReactionComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(FlagComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(PinComponentFactory.self)
        ThreadChatSubFactoryRegistery.register(SelectTranslateFactory.self)
        // 暂时去掉转发提示
//        ThreadDetailSubFactoryRegistery.register(ForwardComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadDetailVideoContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadDetailImageContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(RecalledContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(MultiEditComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadDetailStickerContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadDetailMessageTextPostContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadChatMergeForwardContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadFileContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadFolderContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ReactionComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(FlagComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadShareGroupContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadDetailAudioContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)
        ThreadDetailSubFactoryRegistery.register(SelectTranslateFactory.self)
        ThreadDetailSubFactoryRegistery.register(TCPreviewContainerComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(DlpTipComponentFactory.self)
        ThreadDetailSubFactoryRegistery.register(FileNotSafeComponentFactory.self)

        ReplyInThreadSubFactoryRegistery.register(MessageDetailLocationContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(PinComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadDetailImageContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(RecalledContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(MultiEditComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadDetailStickerContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ReplyInThreadTextPostContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadChatMergeForwardContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadFileContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadFolderContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ChatReactionComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadShareGroupContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadDetailVideoContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadDetailAudioContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ChatterStatusLabelFactory.self)
        ReplyInThreadSubFactoryRegistery.register(UrgentTipsComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(UrgentComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(MessageDetailVoteContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(MessageDetailNewVoteContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(MessageDetailRedPacketContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DocPreviewComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(URLPreviewComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(TCPreviewContainerComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ReplyInThreadDeletedContentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(FileNotSafeComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(RestrictComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(DlpTipComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ChatPinComponentFactory.self)
        ReplyInThreadSubFactoryRegistery.register(ThreadSyncToChatComponentFactory.self)

        ReplyInThreadForwardDetailSubFactoryRegistery.register(LocationContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(PinComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadDetailImageContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(RecalledContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(MultiEditComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadDetailStickerContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ReplyInThreadTextPostContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadChatMergeForwardContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadFileContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadFolderContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ReactionComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadShareGroupContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadDetailVideoContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadDetailAudioContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ChatterStatusLabelFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(UrgentTipsComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(UrgentComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(BaseVoteContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(NewVoteContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(RedPacketContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DocPreviewComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(URLPreviewComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(TCPreviewContainerComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ReplyInThreadDeletedContentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(FileNotSafeComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(RestrictComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(DlpTipComponentFactory.self)
        ReplyInThreadForwardDetailSubFactoryRegistery.register(ChatPinComponentFactory.self)
    }
}

/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
enum Thread {
    private static var userScopeFG: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") // Global
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
