//
//  MessageCoreDependency.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/11/26.
//

import Foundation
import RxSwift
import Swinject
import LarkMessengerInterface
import LarkSDKInterface
import EENavigator
import RustPB
import LarkRustClient
import LarkSetting
import LarkCache
import LarkDebugExtensionPoint
import LarkAccountInterface
import LarkModel
import EEAtomic
import UniverseDesignColor
import LarkOpenChat
import ByteWebImage
import LarkMessageBase
import LarkAssembler
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkContainer
import LarkSecurityComplianceInterface
import LarkSendMessage
import LarkNavigator
import LarkAssetsBrowser
import LarkFoundation // FileUtils

public protocol MessageCoreDependency: DocPreviewViewModelContextDependency,
                                       ModelServiceImplDependency,
                                       MessageCoreTodoDependency,
                                       MeegoMenuHandlereDependency,
                                       MutiSelectHandlerDependecy,
                                       NavigationBarSubModuleDependency {
}

enum MessageCore {
    public static var userScopeCompatibleMode: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") // Global
    }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class MessageCoreAssembly: LarkAssemblyInterface {
    public init() { }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(MessageCore.userScope)
        let userGraph = container.inObjectScope(MessageCore.userGraph)

        user.register(ModelService.self) { (r) in
            return ModelServiceImpl(userResolver: r)
        }

        user.register(ChatSecurityAuditService.self) { r in
            let tenantId = try r.resolve(assert: PassportUserService.self).userTenant.tenantID
            return ChatSecurityAuditServiceImp(currentUserID: r.userID, tenantId: tenantId)
        }

        user.register(ChatSecurityControlService.self) { r in
            return ChatSecurityControlServiceImpl(userResolver: r)
        }

        user.register(MultiEditService.self) { r -> MultiEditService in
            return MultiEditServiceImpl(userResolver: r)
        }

        userGraph.register(IMAtUserAnalysisService.self) { r in
            return IMAtUserAnalysisServiceIMP(userResolver: r)
        }

        userGraph.register(IMAnchorAnalysisService.self) { r in
            return IMAnchorAnalysisServiceIMP(userResolver: r)
        }

        userGraph.register(MessageDynamicAuthorityService.self) { r in
            //每个不同的MessageViewModel应该持有不同的MessageDynamicAuthorityServiceImpl，不能写成单例
            let chatSecurityControlService = try r.resolve(assert: ChatSecurityControlService.self)
            return MessageDynamicAuthorityServiceImpl(chatSecurityControlService: chatSecurityControlService, userResolver: r)
        }

        userGraph.register(ChatDurationStatusTrackService.self) { _ in
            return ChatDurationStatusTrackServiceImp()
        }

        userGraph.register(DocPreviewViewModelContextDependency.self) { r -> DocPreviewViewModelContextDependency in
            return try r.resolve(assert: MessageCoreDependency.self)
        }

        userGraph.register(ModelServiceImplDependency.self) { r -> ModelServiceImplDependency in
            return try r.resolve(assert: MessageCoreDependency.self)
        }

        userGraph.register(MessageCoreTodoDependency.self) { r -> MessageCoreTodoDependency in
            return try r.resolve(assert: MessageCoreDependency.self)
        }

        userGraph.register(MeegoMenuHandlereDependency.self) { r -> MeegoMenuHandlereDependency in
            return try r.resolve(assert: MessageCoreDependency.self)
        }

        userGraph.register(MutiSelectHandlerDependecy.self) { r -> MutiSelectHandlerDependecy in
            return try r.resolve(assert: MessageCoreDependency.self)
        }

        userGraph.register(NavigationBarSubModuleDependency.self) { r -> NavigationBarSubModuleDependency in
            return try r.resolve(assert: MessageCoreDependency.self)
        }

        userGraph.register(MergeForwardContentService.self) { _ in
            return MergeForwardContentImpl()
        }

        //swiftlint:disable closure_parameter_position
        userGraph.register(ChatMessageReadService.self) { (
            r,
            scene: PutReadScene,
            forceDisable: Bool,
            audioShowTextEnable: Bool,
            isRemind: Bool,
            isInBox: Bool,
            trackContext: [String: Any],
            currentReadPosition: @escaping () -> Int32,
            putReadAction: @escaping (PutReadInfo) -> Void) -> ChatMessageReadService in
            return ChatMessageReadServiceImpl(scene: scene,
                                              forceDisable: forceDisable,
                                              audioShowTextEnable: audioShowTextEnable,
                                              isRemind: isRemind,
                                              isInBox: isInBox,
                                              trackContext: trackContext,
                                              currentReadPosition: currentReadPosition,
                                              putReadAction: putReadAction,
                                              urgencyCenter: try r.resolve(assert: UrgencyCenter.self),
                                              supportPutReadV2: r.fg.staticFeatureGatingValue(with: "im.chat.readservice.putread"))
        }
        //swiftlint:enable closure_parameter_position

        /// 图片处理
        userGraph.register(SendImageProcessor.self) { (_) -> SendImageProcessor in
            return SendImageProcessorImpl()
        }

        userGraph.register(KeyboardPanelPictureService.self) { r in
            return KeyboardPanelItemPictureServiceIMP(userResolver: r)
        }

        userGraph.register(KeyboardPanelInsertCanvasService.self) { r in
            return KeyboardPanelItemPictureServiceIMP(userResolver: r)
        }

        userGraph.register(KeyboardPanelPictureHandlerService.self) { r in
            return KeyboardPanelItemPictureServiceIMP(userResolver: r)
        }

        // 用户关系的服务
        user.register(UserRelationService.self) { (r) -> UserRelationService in
            let push = try r.userPushCenter.observable(for: PushContactApplicationBannerAffectEvent.self)
            return UserRelationServiceImpl(externalContactsAPI: try r.resolve(assert: ExternalContactsAPI.self),
                                           chatterAPI: try r.resolve(assert: ChatterAPI.self),
                                           pushContactApplicationBannerAffectEvent: push)
        }

        // 联系人控件的服务
        user.register(ContactControlService.self) { (r) -> ContactControlService in
            return ContactControlServiceImpl(userRelationService: try r.resolve(assert: UserRelationService.self))
        }

        user.register(ChatTopNoticeService.self) { r in
            return ChatTopNoticeServiceImp(userResolver: r)
        }

        user.register(TopNoticeUserActionService.self) { r in
            return TopNoticeUserActionServiceImp(chatAPI: try r.resolve(assert: ChatAPI.self))
        }

        user.register(GroupAnnouncementService.self) { r in
            return GroupAnnouncementServiceIMP(userResolver: r)
        }

        user.register(ThumbsupReactionService.self) { r in
            return ThumbReactionServiceIMP(userResolver: r)
        }

        user.register(ReplyInThreadConfigService.self) { _ in
            return ReplyInThreadConfigServiceIMP()
        }

        user.register(FoldApproveDataService.self) { r in
            return FoldApproveDataManager(userResolver: r)
        }

        user.register(ScheduleSendService.self) { r in
            return ScheduleSendManager(userResolver: r)
        }

        user.register(PostMessageErrorAlertService.self) { r in
            return PostMessageErrorAlertServiceIMP(sendSevice: try r.resolve(assert: PostSendService.self), nav: r.navigator)
        }

        user.register(KeyboardPanelEmojiPanelItemService.self) { r in
            return KeyboardPanelEmojiPanelItemServiceIMP(userResolver: r)
        }

        user.register(MenuInteractionABTestService.self) { r in
            return MenuInteractionABTestServiceIMP(fgService: r.fg)
        }

        userGraph.register(ChatAlbumDataSourceImpl.self, factory: { (r, chat: Chat, isMeSend: @escaping (String) -> Bool) -> ChatAlbumDataSourceImpl in
            return ChatAlbumDataSourceImpl(chat: chat, isMeSend: isMeSend, userResolver: r)
        })

        user.register(VideoSaveService.self) { (r) in
            return VideoSaveServiceImpl(
                fileAPI: try r.resolve(assert: SecurityFileAPI.self),
                pushDownloadFile: try r.userPushCenter.driver(for: PushDownloadFile.self),
                pushSaveToSpaceStoreState: try r.userPushCenter.driver(for: PushSaveToSpaceStoreState.self),
                userResolver: r
            )
        }

        userGraph.register(LKVideoDisplayViewProxy.self) { (r, session: String?, isWebVideo: Bool) -> LKVideoDisplayViewProxy in
            let preparedCallBack: (LKVideoDisplayViewProxy) -> Void = { (proxy) in
                guard let currentAsset = proxy.delegate?.currentAsset else {
                    return
                }
                if currentAsset.isLocalVideoUrl {
                    let url = currentAsset.videoUrl
                    let fileName = String(URL(string: url)?.path.split(separator: "/").last ?? "")
                    let fileSize = try? FileUtils.fileSize(url)
                    sendVideoCache(userID: r.userID).saveFileName(
                        fileName,
                        size: max(
                            Int(currentAsset.videoSize * 1024 * 1024),
                            Int(fileSize ?? 0)
                        )
                    )
                }
            }

            let downloadPath = fileDownloadRootPath(userID: r.userID)
            if isWebVideo {
                let proxy = TTWebVideoPlayProxy(
                    videoApi: try r.resolve(assert: VideoAPI.self),
                    downloadPath: downloadPath,
                    userResolver: r)
                proxy.preparedCallBack = preparedCallBack
                return proxy
            } else {
                let proxy = AssetBrowserVideoPlayProxy(
                    session: session,
                    fileAPI: try r.resolve(assert: SecurityFileAPI.self),
                    messageAPI: try r.resolve(assert: MessageAPI.self),
                    downloadPath: downloadPath,
                    userResolver: r)
                proxy.preparedCallBack = preparedCallBack
                return proxy
            }
        }
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(ComposePostBody.self).factory(ComposePostHandler.init(resolver:))

        Navigator.shared.registerRoute.type(LanguagePickerBody.self).factory(LanguagePickerHandler.init)

        Navigator.shared.registerRoute.type(ChatTranslationDetailBody.self).factory(ChatTranslationDetailHandler.init)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushTranslateStates, TranslateStatePushHandler.init(resolver:))
        (Command.pushImageTranslationInfo, ImageTranslationPushHandler.init(resolver:))
    }

    @_silgen_name("Lark.OpenChat.Messenger.MessageCore")
    static public func openChatRegister() {
        /// 普通聊天
        ChatNavigationBarModule.registerLeftSubModule(ChatNavigationBarLeftItemSubModule.self)
        ChatNavigationBarModule.registerLeftSubModule(NavigationBarCloseSceneItemSubModule.self)
        ChatNavigationBarModule.registerLeftSubModule(NavigationCloseDetailOnSearchPadSubModule.self)
        ChatNavigationBarModule.registerContentSubModule(ChatNavgationBarContentSubModule.self)
        ChatNavigationBarModule.registerRightSubModule(ChatNavigationBarRightSubModule.self)
        ChatNavigationBarModule.registerRightSubModule(NavigationBarCancelButtomModule.self)
        /// 单聊拉人界面
        ChatMessagePickerNavigationBarModule.registerLeftSubModule(NavigationBarReturnItemSubModule.self)
        ChatMessagePickerNavigationBarModule.registerLeftSubModule(NavigationBarFullScreenItemSubModule.self)
        ChatMessagePickerNavigationBarModule.registerLeftSubModule(NavigationBarCloseSceneItemSubModule.self)

        ChatMessagePickerNavigationBarModule.registerContentSubModule(ChatMessagePickerNavgationBarContentSubModule.self)

        ThreadNavigationBarModule.registerLeftSubModule(ChatNavigationBarLeftItemSubModule.self)
        ThreadNavigationBarModule.registerLeftSubModule(NavigationBarCloseSceneItemSubModule.self)
        ThreadNavigationBarModule.registerContentSubModule(ThreadNavgationBarContentSubModule.self)
        ThreadNavigationBarModule.registerRightSubModule(ThreadNavigationBarRightSubModule.self)

        /// 话题预览
        TargetPreviewChatNavigationBarModule.registerLeftSubModule(ThreadPreviewReturnItemSubModule.self)
        TargetPreviewChatNavigationBarModule.registerContentSubModule(ThreadPreviewNavgationBarContentSubModule.self)
        TargetPreviewChatNavigationBarModule.registerRightSubModule(ThreadPreviewNavigationBarRightSubModule.self)

        /// IM内部拦截器注册(能力现为有限暴露)
        IMMessageActionInterceptor.registor(interceptor: RecallActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: MyAIActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: CleanedActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: MessageStateActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: EphemeralActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: PrivateModeActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: DLPActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: ServerRestrictedInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: PartialSelectActionInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: ChatFrozenInterceptor.self)
        IMMessageActionInterceptor.registor(interceptor: DecryptedFailedActionInterceptor.self)

        /// 键盘panelItem
        /// 富文本编辑框
        IMChatComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardAtUserPanelSubModule.self)
        IMChatComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardCanvasPanelSubModule.self)
        IMChatComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardEmojiPanelSubModule.self)
        IMChatComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardFontPanelSubModule.self)
        IMChatComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardPictruePanelSubModule.self)
        IMChatComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardBurnTimePanelSubModule.self)

        /// 话题发帖页
        IMTopicComposeKeyboardModule.registerPanelSubModule(TopicKeyboardAtUserPanelSubModule.self)
        IMTopicComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardCanvasPanelSubModule.self)
        IMTopicComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardEmojiPanelSubModule.self)
        IMTopicComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardFontPanelSubModule.self)
        IMTopicComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardPictruePanelSubModule.self)
        IMTopicComposeKeyboardModule.registerPanelSubModule(IMComposeKeyboardBurnTimePanelSubModule.self)
    }

    public func registLarkAppLink(container: Container) {
        //目前没有机制、时机支持UDColor，沟通后确认可放到registLarkAppLink
        UDColor.registerUDBizColor(UDMessageBizColor())
    }

    public func registDebugItem(container: Container) {
        /// reply in thread的实验功能 以ios为实验端，本期实验完成 暂时注释代码
        // ({ ReplyInThreadDebugItem() }, SectionType.debugTool)
        // 长按消息菜单，是否出现CopyMsgId选项，Debug使用
        #if DEBUG || ALPHA || BETA
        ({ MessageMenuDebugItem() }, SectionType.debugTool)
        #endif
    }
}
