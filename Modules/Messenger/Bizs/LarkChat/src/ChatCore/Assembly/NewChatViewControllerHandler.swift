//
//  ChatViewControllerHandler.swift
//  Lark
//
//  Created by zc09v on 2018/5/15.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import RxSwift
import Swinject
import LarkAIInfra
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkPerf
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkGuide
import LarkNavigation
import LarkAppConfig
import SuiteAppConfig
import LKCommonsLogging
import LarkInteraction
import AsyncComponent
import LarkOpenChat
import LarkSuspendable
import LarkTracing
import LKLoadable
import LarkOpenFeed
import LarkSendMessage
import LarkCore
import LarkNavigator
import AppContainer

enum ChatSource {
    case chat(Chat)
    case chatId(String, isCrypto: Bool, isMyAI: Bool)
    public var id: String {
        switch self {
        case .chat(let chat):
            return chat.id
        case .chatId(let id, _, _):
            return id
        }
    }

    public var isCrypto: Bool {
        switch self {
        case .chat(let chat):
            return chat.isCrypto
        case .chatId(_, let isCrypto, _):
            return isCrypto
        }
    }

    /// 是否是和MyAI的单聊
    public var isMyAI: Bool {
        switch self {
        case .chat(let chat):
            return chat.isP2PAi
        case .chatId(_, _, let isMyAI):
            return isMyAI
        }
    }
}

private struct MessagePickerConfig {
    var isMessagePicker: Bool
    // Picker是否忽略文档权限
    var ignoreDocAuth: Bool = false
}

//会话页面跳转最终的收敛路由，保证所有页面最终路由url一致，以支持栈内相同url vc pop特性
struct InnerChatControllerBody: Body, HasLocateMessageInfo {

    private static let prefix = "//client/chat/innerChat"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId(\\d+)/:aiChatModeId(\\d+)", type: .path)
    }

    public var _url: URL {
        var urlString = "\(InnerChatControllerBody.prefix)/\(source.id)"
        if let myAIChatModeConfig = self.myAIChatModeConfig, myAIChatModeConfig.aiChatModeId > 0 {
            urlString += "/\(myAIChatModeConfig.aiChatModeId)"
        } else {
            urlString += "/0"
        }
        if let positionStrategy = self.positionStrategy, case .position(let position) = positionStrategy {
            urlString += "#\(position)"
        }
        return URL(string: urlString) ?? .init(fileURLWithPath: "")
    }

    public let source: ChatSource
    public let positionStrategy: ChatMessagePositionStrategy? // 跳转消息的策略
    public let chatSyncStrategy: ChatSyncStrategy // 获取chat的策略
    public let messageId: String?
    public var fromWhere: ChatFromWhere
    public var keyboardStartupState: KeyboardStartupState
    public var showNormalBack: Bool
    /// 如果是和MyAI的分会场，则传递一些业务方信息
    public let myAIChatModeConfig: MyAIChatModeConfig?
    public let extraInfo: [String: Any] //携带一些额外信息，目前建群打点会使用，携带建群耗时及相关信息
    public let controllerService: ChatViewControllerService?

    public var specificSource: SpecificSourceFromWhere? //细化fromWhere的二级来源
    public init(
        source: ChatSource,
        positionStrategy: ChatMessagePositionStrategy? = nil,
        chatSyncStrategy: ChatSyncStrategy = .default,
        messageId: String? = nil,
        fromWhere: ChatFromWhere = .ignored,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState.default(),
        showNormalBack: Bool = false,
        controllerService: ChatViewControllerService? = nil,
        myAIChatModeConfig: MyAIChatModeConfig? = nil,
        extraInfo: [String: Any] = [:],
        specificSource: SpecificSourceFromWhere? = nil
    ) {
        self.source = source
        self.positionStrategy = positionStrategy
        self.chatSyncStrategy = chatSyncStrategy
        self.fromWhere = fromWhere
        self.showNormalBack = showNormalBack
        self.messageId = messageId
        self.keyboardStartupState = keyboardStartupState
        self.controllerService = controllerService
        self.myAIChatModeConfig = myAIChatModeConfig
        self.extraInfo = extraInfo
        self.specificSource = specificSource
    }
}

protocol ChatControllerGenerator: UserResolverWrapper {

    // swiftlint:disable function_parameter_count
    func generateChatContainerViewController(
        source: ChatSource,
        positionStrategy: ChatMessagePositionStrategy?,
        chatSyncStrategy: ChatSyncStrategy,
        fromWhere: ChatFromWhere,
        keyboardStartupState: KeyboardStartupState,
        showNormalBack: Bool,
        loadTrackInfo: ChatLoadTrakInfo,
        controllerService: ChatViewControllerService?,
        myAIChatModeConfig: MyAIChatModeConfig?,
        specificSource: SpecificSourceFromWhere?) throws -> ChatContainerViewController
    // swiftlint:enable function_parameter_count

    func generateMessagePickerController(
        source: ChatSource,
        cancelHandler: ChatMessagePickerCancelHandler,
        finishHandler: ChatMessagePickerFinishHandler,
        ignoreDocAuth: Bool) throws -> ChatContainerViewController
}

extension ChatControllerGenerator {
    func generateChatContainerViewController(
        source: ChatSource,
        positionStrategy: ChatMessagePositionStrategy?,
        chatSyncStrategy: ChatSyncStrategy,
        fromWhere: ChatFromWhere,
        keyboardStartupState: KeyboardStartupState,
        showNormalBack: Bool,
        loadTrackInfo: ChatLoadTrakInfo,
        controllerService: ChatViewControllerService?,
        myAIChatModeConfig: MyAIChatModeConfig?,
        specificSource: SpecificSourceFromWhere? = nil
    ) throws -> ChatContainerViewController {
        let componentGenerator: ChatViewControllerComponentGeneratorProtocol
        // 密聊不支持URL预览
        let urlPreviewService = source.isCrypto ? nil : try? self.resolver.resolve(type: MessageURLPreviewService.self)
        if source.isCrypto {
            componentGenerator = CryptoChatViewControllerComponentGenerator(resolver: userResolver)
        } else if source.isMyAI {
            if myAIChatModeConfig != nil {
                componentGenerator = MyAIChatModeViewControllerComponentGenerator(resolver: userResolver)
            } else {
                componentGenerator = MyAIMainChatViewControllerComponentGenerator(resolver: userResolver)
            }
        } else {
            componentGenerator = ChatViewControllerComponentGenerator(resolver: userResolver)
        }
        return try tabController(
            source: source,
            positionStrategy: positionStrategy,
            chatSyncStrategy: chatSyncStrategy,
            fromWhere: fromWhere,
            componentGenerator: componentGenerator,
            keyboardStartupState: keyboardStartupState,
            loadTrackInfo: loadTrackInfo,
            messagePickerConfig: MessagePickerConfig(isMessagePicker: false),
            messagePickerCancelHandler: nil,
            messagePickerFinishHandler: nil,
            urlPreviewService: urlPreviewService,
            showNormalBack: showNormalBack,
            controllerService: controllerService,
            myAIChatModeConfig: myAIChatModeConfig,
            specificSource: specificSource
        )
    }

    func generateMessagePickerController(
        source: ChatSource,
        cancelHandler: ChatMessagePickerCancelHandler,
        finishHandler: ChatMessagePickerFinishHandler,
        ignoreDocAuth: Bool = false) throws -> ChatContainerViewController {
        let urlPreviewService = try? self.resolver.resolve(type: MessageURLPreviewService.self)
        return try tabController(
            source: source,
            fromWhere: .singleChatGroup,
            componentGenerator: MessagePickerViewControllerComponentGenerator(resolver: userResolver),
            keyboardStartupState: KeyboardStartupState.default(),
            loadTrackInfo: nil,
            messagePickerConfig: MessagePickerConfig(isMessagePicker: true, ignoreDocAuth: ignoreDocAuth),
            messagePickerCancelHandler: cancelHandler,
            messagePickerFinishHandler: finishHandler,
            urlPreviewService: urlPreviewService,
            showNormalBack: false,
            controllerService: nil,
            myAIChatModeConfig: nil
        )
    }

    // swiftlint:disable function_parameter_count
    private func tabController<T: ChatContainerViewController>(
        source: ChatSource,
        positionStrategy: ChatMessagePositionStrategy? = nil,
        chatSyncStrategy: ChatSyncStrategy = .default,
        fromWhere: ChatFromWhere,
        componentGenerator: ChatViewControllerComponentGeneratorProtocol,
        keyboardStartupState: KeyboardStartupState,
        loadTrackInfo: ChatLoadTrakInfo?,
        messagePickerConfig: MessagePickerConfig,
        messagePickerCancelHandler: ChatMessagePickerCancelHandler,
        messagePickerFinishHandler: ChatMessagePickerFinishHandler,
        urlPreviewService: MessageURLPreviewService?,
        showNormalBack: Bool,
        controllerService: ChatViewControllerService?,
        myAIChatModeConfig: MyAIChatModeConfig?,
        specificSource: SpecificSourceFromWhere? = nil
    ) throws -> T {
        // swiftlint:enable function_parameter_count
        let chatKeyPointTracker = ChatKeyPointTracker(resolver: userResolver,
                                                      chatInfo: ChatKeyPointTrackerInfo(id: source.id, isCrypto: source.isCrypto, chat: nil))
        chatKeyPointTracker.trackChatLoadTimeStart(trackInfo: loadTrackInfo, pageName: ChatMessagesViewController.pageName)
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
        // 创建ModuleContext
        let moduleContext = ChatModuleContext(
            userStorage: userResolver.storage,
            dragManager: dragManager,
            modelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: userResolver)
        )
        // 获取当前页面的MyAI信息
        var myAIPageService: MyAIPageService?; let myAIService = try? userResolver.resolve(assert: MyAIService.self)
        if source.isMyAI, let config = myAIChatModeConfig {
            myAIPageService = myAIService?.pageService(userResolver: moduleContext.userResolver, chatId: source.id, chatMode: true, chatModeConfig: config, chatFromWhere: fromWhere)
        } else if source.isMyAI {
            myAIPageService = myAIService?.pageService(userResolver: moduleContext.userResolver, chatId: source.id, chatMode: false, chatModeConfig: MyAIChatModeConfig.default, chatFromWhere: fromWhere)
        }
        // 为什么选择在这里进行注册？container是当前页面的，不是全局。理由如下：
        // 1.因为MyAI并不是所有页面都会出现，所以不放到PageContext、PageAPI、DataSourceAPI中，而且MyAIPageService在Messenger，而PageContext等在Infra，层级也不对
        // 2.消息渲染时会用到MyAI信息，所以不放到ChatContext、ChatPageAPI中，消息渲染在LarkMessageCore，访问不到ChatContext
        // 3.单独搞个XxxContentFactory，在里面进行注册？又回到了问题1，Factory中无法知道MyAI信息
        // 4.需要在ChatContainerViewController初始化之前注册MyAIPageService，因为在有Chat实体的情况下跳转Chat，ChatContainerViewController的init中就会使用到
        //   4.1.init会执行self.initialDataAndViewControl.start然后马上回调blockDataFetched，然后执行self.generateComponents，进而访问到MyAIPageService
        if let pageService = myAIPageService { moduleContext.container.register(MyAIPageService.self) { _ in pageService } }

        moduleContext.chatContext.trackParams = [PageContext.TrackKey.sceneKey: fromWhere.rawValue]
        moduleContext.navigaionContext.store.setValue(fromWhere.rawValue, for: IMTracker.Chat.Main.ChatFromWhereKey)
        moduleContext.keyboardContext.store.setValue(fromWhere.rawValue, for: IMTracker.Chat.Main.ChatFromWhereKey)
        if case .team(let teamID) = fromWhere {
            moduleContext.footerContext.store.setValue(teamID, for: ApplyToJoinGroupFooterModule.teamID)
        }
        // 同步消息权重，动态计算一次拉取的消息数量
        let messageAPI = try resolver.resolve(assert: MessageAPI.self)
        setMessageDisplay(messageAPI: messageAPI)

        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let fetchChatSource: FetchChatSource
        switch source {
        case .chat(let chat):
            fetchChatSource = .chat(chat)
        case .chatId(let id, _, _):
            let chatterAPI = try resolver.resolve(assert: ChatterAPI.self)
            fetchChatSource = .chatId(id, chatAPI, chatterAPI, chatSyncStrategy)
        }
        let pushCenter = try resolver.userPushCenter
        let pushHandlerRegister = ChatPushHandlersRegister(channelId: source.id, userResolver: userResolver)
        pushHandlerRegister.startPreObserve()
        let blockPreLoadData = componentGenerator.chatDataProviderType.fetchChat(by: fetchChatSource)
        let otherPreLoadData = try componentGenerator.chatDataProviderType.fetchFirstScreenMessages(chatId: source.id,
                                                                                                    positionStrategy: positionStrategy,
                                                                                                    userResolver: moduleContext.userResolver,
                                                                                                    screenHeight: navigator.navigation?.view.bounds.size.height ?? 0,
                                                                                                    fetchChatData: blockPreLoadData)
        let control = try ChatInitialDataAndViewControl(
            userResolver: userResolver,
            chatID: source.id,
            urlPreviewService: urlPreviewService,
            messagePushObservable: (myAIPageService?.chatMode ?? false) ? nil : pushCenter.observable(for: PushChannelMessages.self), // my ai分会场不需要bufferMessage
            tabsPushObservable: pushCenter.observable(for: PushChatTabs.self),
            blockPreLoadData: blockPreLoadData,
            otherPreLoadData: otherPreLoadData)

        let start = CACurrentMediaTime()
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.loadModule, parentName: LarkTracingUtil.chatVCInit)
        // 进行所有Module的加载
        ChatBannerModule.onLoad(context: moduleContext.bannerContext)
        loadTrackInfo?.loadModuleCost = ChatKeyPointTracker.cost(startTime: start)
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.loadModule)

        let backDismissAndCloseSceneItemTapped: (() -> Void)? = { [weak controllerService] in
            controllerService?.backDismissAndCloseSceneItemTapped()
        }
        moduleContext.navigaionContext.store.setValue(backDismissAndCloseSceneItemTapped, for: ChatNavigationBarLeftItemSubModuleStoreKey.backDismissTapped.rawValue)
        moduleContext.navigaionContext.store.setValue(backDismissAndCloseSceneItemTapped, for: NavigationBarCloseSceneItemSubModuleStoreKey.closeSceneTapped.rawValue)
        moduleContext.navigaionContext.store.setValue(!showNormalBack, for: ChatNavigationBarLeftItemSubModuleStoreKey.showUnread.rawValue)

        let controllerDependency = ChatControllerDependency(userResolver: userResolver, pushCenter: pushCenter, pushHandlerRegister: pushHandlerRegister)
        let router = ChatControllerRouterImpl(resolver: userResolver)

        let messageTabDependency = ChatMessageTabDependency(
            positionStrategy: positionStrategy,
            keyboardStartState: keyboardStartupState,
            chatKeyPointTracker: chatKeyPointTracker,
            dragManager: dragManager,
            getChatMessagesResultObservable: control.otherPreLoadDataObservable,
            getBufferPushMessages: control.bufferPushMessages,
            moduleContext: moduleContext,
            componentGenerator: componentGenerator,
            router: router,
            dependency: controllerDependency,
            isMessagePicker: messagePickerConfig.isMessagePicker,
            ignoreDocAuth: messagePickerConfig.ignoreDocAuth,
            messagePickerCancelHandler: messagePickerCancelHandler,
            messagePickerFinishHandler: messagePickerFinishHandler,
            chatFromWhere: fromWhere,
            controllerService: controllerService,
            userResolver: userResolver
        )
        moduleContext.tabContext.store.setValue(messageTabDependency, for: ChatMessageTabModuleStoreKey.chatMessageTabDependency.rawValue)

        let chatVC = T(
            userResolver: userResolver,
            chatId: source.id,
            initialDataAndViewControl: control,
            fromWhere: fromWhere,
            dependency: controllerDependency,
            moduleContext: moduleContext,
            componentGenerator: componentGenerator,
            chatKeyPointTracker: chatKeyPointTracker,
            specificSource: specificSource
        )

        // fix crash：http://t.wtturl.cn/eYwGQfa/，原因：unowned chatVC，fix version：3.47
        moduleContext.container.register(ChatOpenService.self) { [weak chatVC] (_) -> ChatOpenService in
            return chatVC ?? DefaultChatOpenService()
        }
        moduleContext.container.register(ChatMessageBaseDelegate.self) { [weak chatVC] (_) -> ChatMessageBaseDelegate in
            return chatVC ?? DefaultChatMessageBaseDelegate()
        }
        moduleContext.container.register(ChatDocSpaceTabDelegate.self) { [weak chatVC] (_) -> ChatDocSpaceTabDelegate in
            return chatVC ?? DefaultChatDocSpaceTabDelegate()
        }
        moduleContext.container.register(ChatCloseDetailLeftItemService.self) { [weak chatVC] (_) -> ChatCloseDetailLeftItemService in
            return chatVC ?? DefaultChatCloseDetailLeftItemService()
        }
        if let myAIPageService = myAIPageService {
            // 有的业务方打开分会场，需要感知分会场的生命周期
            myAIPageService.chatModeConfig.callBack?(MyAIChatModeConfig.PageService(vc: chatVC, pageAbility: myAIPageService))
        }
        return chatVC
    }
}

protocol InnerChatControllerProtocol: UIViewController {
    var sourceID: String { get set }
    var pushChatVC: (() -> Void)? { get set }
}

final class DefaultChatDocSpaceTabDelegate: ChatDocSpaceTabDelegate {
    var contentTopMargin: CGFloat { return 0 }
    func jumpToChat(messagePosition: Int32) {}
}

final class InnerChatControllerHandler: UserTypedRouterHandler, ChatControllerGenerator {

    var routeing: Bool = false
    weak var response: Response?
    weak var viewController: UIViewController?
    var pushChatVC: (() -> Void)?
    private static let logger = Logger.log(InnerChatControllerHandler.self, category: "LarkChat")

    public func handle(_ body: InnerChatControllerBody, req: EENavigator.Request, res: Response) throws {
        guard !routeing else {
            InnerChatControllerHandler.logger.info("chatTrace is routeing \(body.source.id)")
            res.end(error: nil)
            return
        }
        let feedAPI = try userResolver.resolve(assert: FeedAPI.self)
        feedAPI.markChatLaunch(feedId: body.source.id, entityType: .chat)
        InnerChatControllerHandler.logger.info("<IOS_RECENT_VISIT> markChatLaunch feedID: \(body.source.id), type: .chat")
        LarkTracingUtil.startRootSpan(spanName: LarkTracingUtil.enterChat)
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.firstRender, parentName: LarkTracingUtil.enterChat)
        InnerChatControllerHandler.logger.info("chatTrace in body handler \(body.source.id)")
        routeing = true
        response = res

        var start = CACurrentMediaTime()
        let loadTrackInfo = ChatLoadTrakInfo(fromWhere: body.fromWhere, extraInfo: body.extraInfo)
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.chatVCInit, parentName: LarkTracingUtil.firstRender)

        let vc: InnerChatControllerProtocol = try self.generateChatContainerViewController(
            source: body.source,
            positionStrategy: body.positionStrategy,
            chatSyncStrategy: body.chatSyncStrategy,
            fromWhere: body.fromWhere,
            keyboardStartupState: body.keyboardStartupState,
            showNormalBack: body.showNormalBack,
            loadTrackInfo: loadTrackInfo,
            controllerService: body.controllerService,
            myAIChatModeConfig: body.myAIChatModeConfig,
            specificSource: body.specificSource
        )

        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.chatVCInit)

        // 从多任务浮窗打开的页面，context 中会带 suspendSourceID，用于标记来源
        if let sourceID = req.context[SuspendManager.sourceIDKey] as? String {
            vc.sourceID = sourceID
        }
        self.viewController = vc
        loadTrackInfo.chatVCInitCost = ChatKeyPointTracker.cost(startTime: start)
        // 100ms用于数据拉取及组件生成
        start = CACurrentMediaTime()
        /*
         如果100ms之内完成了数据拉取和组件生成，在组件生成之后主动执行push操作。
         如果100ms没有完成数据拉取和组件生成，在延时100ms之后执行push操作，这个时候会显示中间态。
         */
        //主动执行push操作
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.preLoadDataBuffer, parentName: LarkTracingUtil.firstRender)
        self.pushChatVC = {
            DispatchQueue.main.async { [weak self] in
                if let res = self?.response, self?.routeing == true, let vc = self?.viewController {
                    self?.routeing = false
                    res.end(resource: vc)
                    LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.preLoadDataBuffer)
                }
            }
        }
        vc.pushChatVC = self.pushChatVC
        //延时执行push
        DispatchQueue.main.asyncAfter(deadline: .now() + ChatContainerViewController.preLoadDataBufferTime) { [weak self] in
            loadTrackInfo.preLoadDataBufferCost = ChatKeyPointTracker.cost(startTime: start)
            if self?.routeing == true {
                res.end(resource: vc)
                self?.routeing = false
                LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.preLoadDataBuffer)
            }
        }
        res.wait()
    }
}

final class ChatControllerByChatHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: ChatControllerByChatBody, req: EENavigator.Request, res: Response) throws {
        let positionStrategy: ChatMessagePositionStrategy?
        if let position = body.position {
            positionStrategy = .position(position)
        } else {
            positionStrategy = nil
        }
        if body.chat.chatMode == .threadV2 {
            let body = ThreadChatByChatBody(chat: body.chat, position: body.position, fromWhere: body.fromWhere)
            res.redirect(body: body)
            return
        }
        let body = InnerChatControllerBody(source: .chat(body.chat),
                                           positionStrategy: positionStrategy,
                                           messageId: body.messageId,
                                           fromWhere: body.fromWhere,
                                           keyboardStartupState: body.keyboardStartupState,
                                           showNormalBack: body.showNormalBack,
                                           controllerService: body.controllerService,
                                           extraInfo: body.extraInfo,
                                           specificSource: body.specificSource)
        res.redirect(body: body)
    }
}

final class MessagePickerHandler: UserTypedRouterHandler, ChatControllerGenerator {
    var resolver: Resolver { userResolver }

    public func handle(_ body: MessagePickerBody, req: EENavigator.Request, res: Response) throws {
        let picker = try self.generateMessagePickerController(
            source: .chatId(body.chatId, isCrypto: false, isMyAI: false),
            cancelHandler: body.cancel,
            finishHandler: body.finish,
            ignoreDocAuth: !body.needDocAuth
        )
        res.end(resource: picker)
    }
}

final class CodeDetailHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: CodeDetailBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = CodeDetailViewModel(property: body.property, userResolver: self.userResolver)
        let viewController = CodeDetailViewController(viewModel: viewModel)
        viewController.modalPresentationStyle = .fullScreen
        res.end(resource: viewController)
    }
}

/// 自动翻译引导
final class AutoTranslateGuideHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: AutoTranslateGuideBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = AutoTranslateGuideViewModel(userGeneralSettings: try self.resolver.resolve(assert: UserGeneralSettings.self))
        let vc = AutoTranslateGuideController(userResolver: userResolver, viewModel: viewModel)
        vc.modalPresentationStyle = .overCurrentContext
        res.end(resource: vc)
    }
}

final class ChatAddTabHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: ChatAddTabBody, req: EENavigator.Request, res: Response) throws {
        let addTabViewModel = try ChatAddTabViewModel(userResolver: userResolver, chat: body.chat, addCompletion: body.completion)
        let addTabController = ChatAddTabController(viewModel: addTabViewModel)
        res.end(resource: addTabController)
    }
}

final class ChatAddPinHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    func handle(_ body: ChatAddPinBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let chatWrapper = try userResolver.resolve(assert: ChatPushWrapper.self, argument: body.chat)
        let searchVM = ChatAddPinSearchViewModel(chatWrapper: chatWrapper, userResolver: self.userResolver)
        let searchVC = ChatAddPinSearchViewController(viewModel: searchVM, addCompletion: body.completion)
        res.end(resource: searchVC)
    }
}

final class ChatPinCardListHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    func handle(_ body: ChatPinCardListBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let pinCardContainer = Container(parent: BootLoader.container)
        let pinCardUserResolver = pinCardContainer.getUserResolver(storage: userResolver.storage, compatibleMode: M.userScopeCompatibleMode)
        let context = ChatPinCardContext(parent: pinCardContainer,
                                         store: Store(),
                                         userStorage: pinCardUserResolver.storage,
                                         compatibleMode: pinCardUserResolver.compatibleMode)
        ChatPinCardModule.onLoad(context: context)
        ChatPinCardModule.registGlobalServices(container: pinCardContainer)
        let module = ChatPinCardModule(context: context)
        let pinAndTopNoticeViewModel = ChatPinAndTopNoticeViewModel(userResolver: pinCardUserResolver, chatId: body.chat.id)
        let viewModel = ChatNewPinCardListViewModel(userResolver: pinCardUserResolver,
                                                    module: module,
                                                    chatPushWrapper: try userResolver.resolve(assert: ChatPushWrapper.self, argument: body.chat),
                                                    pinAndTopNoticeViewModel: pinAndTopNoticeViewModel)
        pinCardContainer.register(ChatOpenPinCardService.self) { [weak viewModel] (_) -> ChatOpenPinCardService in
            return viewModel ?? DefaultChatOpenPinCardServiceImp()
        }
        let controller = ChatNewPinCardListViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}
