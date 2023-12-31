//
//  MyAIPageServiceImpl.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/22.
//

import Foundation
import LarkFoundation
import RxSwift
import RxCocoa
import LarkAIInfra
import RustPB
import ServerPB
import LarkContainer
import LarkRustClient
import LKCommonsTracker
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import Darwin
import LarkStorage
import LarkAccountInterface
import LarkSceneManager
import LarkUIKit
import LarkModel
import UniverseDesignToast
import CryptoKit
import CommonCrypto
import ThreadSafeDataStructure
import LarkMessageBase
import EEAtomic

/// 本文件只存放轮次、会话等基础信息、逻辑，其他文件逻辑如下：
/// MyAIPageServiceImpl+ChatMode：分会场相关逻辑
/// MyAIPageServiceImpl+QuickAction：快捷指令相关逻辑
/// MyAIPageServiceImpl+Extension：插件相关逻辑
/// MyAIPageServiceImpl+Scene：场景相关逻辑
public class MyAIPageServiceImpl: MyAIPageService {
    public static let logger = Logger.log(MyAIPageServiceImpl.self, category: "Module.LarkAI")
    private let pushCenter: PushNotificationCenter?
    public let chatFromWhere: ChatFromWhere
    public let chatMode: Bool
    public let chatId: Int64
    let disposeBag = DisposeBag()
    let rustClient: RustService?
    /// BehaviorRelay调用accept后立即调用value，发现不是最新accept的值，这里用一个变量代替
    var lastAIRoundInfo: AIRoundInfo = AIRoundInfo.default {
        didSet {
            // 在 RoundInfo 发生变化时，更新 QuickAction
            updateQuickActionsIfNeeded(fromRound: lastAIRoundInfo, isFirstStart: oldValue.roundId == 0)
        }
    }
    public let aiRoundInfo: BehaviorRelay<AIRoundInfo> = BehaviorRelay<AIRoundInfo>(value: AIRoundInfo.default)
    /// 通知各组件当前有假消息上屏
    public let onQuasiMessageShown = BehaviorRelay<Void>(value: ())

    /// 是否开启了「主会话iPad分屏打开资源（文件/文件夹/URL）」
    public let isOpenResourceInNewSceneEnabled: Bool

    // MARK: - 主会场专属属性
    public let myAIMainChatConfig = MyAIMainChatConfig()

    // MARK: - Onboard卡片专属属性
    var myAIAPI: MyAIAPI?

    @AtomicObject var currentOnboardInfo: MyAIOnboardInfo?
    /// 是否使用端上mock消息样式的新引导卡片
    public private(set) lazy var useNewOnboard: Bool = {
        return self.userResolver?.fg.dynamicFeatureGatingValue(with: "lark.myai.onboard.new") ?? false
    }()

    // MARK: - 快捷指令专属属性
    /// 是否开启了快捷指令跟随消息（Follow-Up）
    public var isFollowUpEnabled: Bool
    /// 快捷指令的埋点类，封装上报埋点的方法
    var quickActionTracker: QuickActionTracker
    // 临时方案：follow-up 快捷指令使用，获取消息渲染完成的时机再加载快捷指令，避免消息 offset 错误
    var isFirstRendered: Bool = false
    var onFirstRendered: (() -> Void)?
    public let aiQuickActions: BehaviorRelay<[AIQuickAction]> = BehaviorRelay<[AIQuickAction]>(value: [])
    var lastQuickActionResult: QuickActionResult = .initial

    var myAIQuickActionSendService: MyAIQuickActionSendService? {
        return try? self.userResolver?.resolve(type: MyAIQuickActionSendService.self)
    }

    /// 业务方主动触发的quickAction，会先缓存在这里，等到合适的时机（相关服务/数据初始化完成后）发出。
    private var _cacheQuickAction: SafeAtomic<(quickAction: AIQuickAction, trackParams: [String: Any])?> = nil + .readWriteLock
    var cacheQuickAction: (quickAction: AIQuickAction, trackParams: [String: Any])? {
        get {
            return _cacheQuickAction.value
        }
        set {
            _cacheQuickAction.value = newValue
        }
    }

    // MARK: - 分会场专属属性
    public let chatModeConfig: MyAIChatModeConfig
    public let larkMyAIScenariosThread: Bool
    private lazy var defaultScene: ServerPB_Office_ai_MyAIScene = { var scene = ServerPB_Office_ai_MyAIScene(); scene.sceneID = -1; return scene }()
    public lazy var chatModeScene = BehaviorRelay<ServerPB_Office_ai_MyAIScene>(value: self.defaultScene)
    private var threadMessageLock = pthread_rwlock_t()
    private var _chatModeThreadMessage: ThreadMessage?
    public var chatModeThreadMessage: ThreadMessage? {
        get {
            pthread_rwlock_rdlock(&threadMessageLock)
            defer {
                pthread_rwlock_unlock(&threadMessageLock)
            }
            return _chatModeThreadMessage
        }
        set {
            pthread_rwlock_wrlock(&threadMessageLock)
            _chatModeThreadMessage = newValue
            defer {
                pthread_rwlock_unlock(&threadMessageLock)
            }
            if let state = newValue?.thread.stateInfo.state,
               state != chatModeThreadState.value {
                chatModeThreadState.accept(state)
            }
        }
    }
    private var chatModelThread: RustPB.Basic_V1_Thread? {
        get {
            pthread_rwlock_rdlock(&threadMessageLock)
            defer {
                pthread_rwlock_unlock(&threadMessageLock)
            }
            return _chatModeThreadMessage?.thread
        }
        set {
            guard let newValue = newValue else { return }
            pthread_rwlock_wrlock(&threadMessageLock)
            defer {
                pthread_rwlock_unlock(&threadMessageLock)
            }
            _chatModeThreadMessage?.thread = newValue
            let state = newValue.stateInfo.state
            if state != chatModeThreadState.value {
                chatModeThreadState.accept(state)
            }
        }
    }
    public var chatModeThreadState: BehaviorRelay<Basic_V1_ThreadState> = BehaviorRelay<Basic_V1_ThreadState>(value: Basic_V1_ThreadState.unknownState)

    // MARK: - 插件专属属性
    var userStore: KVStore?
    var messageAPI: MessageAPI?
    weak var userResolver: UserResolver?
    public let aiSessionInfo: BehaviorRelay<AISessionInfo> = BehaviorRelay<AISessionInfo>(value: AISessionInfo.default)
    public let refreshExtension: BehaviorRelay<String> = BehaviorRelay<String>(value: "")
    public let aiExtensionConfig: BehaviorRelay<AIExtensionConfig> = BehaviorRelay<AIExtensionConfig>(value: AIExtensionConfig.default)

    public init(userResolver: UserResolver, chatId: String, chatMode: Bool, chatModeConfig: MyAIChatModeConfig, chatFromWhere: ChatFromWhere) {
        self.userResolver = userResolver
        self.chatId = Int64(chatId) ?? 0
        self.chatMode = chatMode
        self.pushCenter = try? userResolver.userPushCenter
        self.rustClient = try? userResolver.resolve(assert: RustService.self)
        self.messageAPI = try? userResolver.resolve(assert: MessageAPI.self)
        self.myAIAPI = try? userResolver.resolve(assert: MyAIAPI.self)
        self.chatModeConfig = chatModeConfig
        self.chatFromWhere = chatFromWhere
        self.isOpenResourceInNewSceneEnabled = userResolver.fg.dynamicFeatureGatingValue(with: "lark.my_ai.resource_split_view")
        self.larkMyAIScenariosThread = userResolver.fg.dynamicFeatureGatingValue(with: "lark.myai.scenarios.thread")
        self.isFollowUpEnabled = userResolver.fg.dynamicFeatureGatingValue(with: "lark.myai.quickaction.followup")
        if !userResolver.userID.isEmpty { self.userStore = KVStores.MyAITool.build(forUser: userResolver.userID) }
        pthread_rwlock_init(&threadMessageLock, nil)
        self.quickActionTracker = QuickActionTracker(
            chatId: chatId,
            shadowId: (try? userResolver.resolve(assert: MyAIService.self))?.info.value.id ?? "0",
            chatMode: chatMode,
            chatFromWhere: chatFromWhere,
            chatModeConfig: chatModeConfig
        )
        self.onInitialize()
    }

    /// 将要进页面时，提前拉取AIRoundInfo，让重新生成按钮能在首屏直接刷出来
    private func onInitialize() {
        MyAIPageServiceImpl.logger.info("my ai page service on initialize")

        // 请求会话最后一轮消息状态
        var request = Im_V1_GetMyAIInfoRequest()
        request.strategy = .local
        request.chatID = self.chatId
        // 如果是MyAI的分会场，需要传AIChatModeID
        if self.chatMode { request.aiChatModeID = self.chatModeConfig.aiChatModeId }
        self.rustClient?.sendAsyncRequest(request).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (response: Im_V1_GetMyAIInfoResponse) in
            guard let `self` = self else { return }
            MyAIPageServiceImpl.logger.info("my ai get last round info, begin handle")
            self.handleAIRoundInfo(aiRoundInfo: AIRoundInfo.from(rustPB: response.aiLastRoundInfo))
            MyAIPageServiceImpl.logger.info("my ai get last round info, finish handle")
        }, onError: { error in
            MyAIPageServiceImpl.logger.info("my ai get last round info error, error: \(error)")
        }).disposed(by: self.disposeBag)

        // 主对话需要上报进会话时机，根据FG，服务端按需做自动new topic逻辑/通知端上展示Mock消息版引导卡片
        // v7.9暂时不主动推送onboard卡片
//        if !self.chatMode, let responseOB = myAIAPI?.enterMyAIChat(chatID: self.chatId) {
//            responseOB.subscribe(onNext: { [weak self] resp in
//                guard let self = self else { return }
//                MyAIPageServiceImpl.logger.info("my ai enter myai chat success, needOnboard:  \(resp.needOnboard)")
//                if useNewOnboard, resp.needOnboard {
//                    showOnboardCard(byUser: false, onError: nil)
//                }
//            }, onError: { error in
//                MyAIPageServiceImpl.logger.info("my ai enter myai chat error: \(error)")
//            }).disposed(by: self.disposeBag)
//        }

        // 初次进入会话，请求快捷指令
        if chatMode {
            updateQuickActionsIfNeeded(fromRound: lastAIRoundInfo, isFirstStart: true)
        }
    }

    /// 首屏渲染完成，可以拉取一些必要的信息了
    public func afterMessagesRender() {
        MyAIPageServiceImpl.logger.info("my ai page service after messages render")

        self.performCacheQuickAction()

        // 请求会话最后一轮消息状态
        var request = Im_V1_GetMyAIInfoRequest()
        request.strategy = .forceServer
        request.chatID = self.chatId
        // 如果是MyAI的分会场，需要传AIChatModeID
        if self.chatMode { request.aiChatModeID = self.chatModeConfig.aiChatModeId }
        self.rustClient?.sendAsyncRequest(request).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (response: Im_V1_GetMyAIInfoResponse) in
            guard let `self` = self else { return }
            MyAIPageServiceImpl.logger.info("my ai pull last round info, begin handle")
            /// 如果不是第一次进入Myai会话，则首屏渲染后更新firstScreenAnchor的信息
            if response.hasAiSessionInfo, response.aiSessionInfo.hasSessionFirstMessageID, response.aiLastRoundInfo.hasRoundIDPosition {
                myAIMainChatConfig.firstScreenAnchorRelay.accept((String(response.aiSessionInfo.sessionFirstMessageID), response.aiLastRoundInfo.roundIDPosition))
            }
            self.handleAIRoundInfo(aiRoundInfo: AIRoundInfo.from(rustPB: response.aiLastRoundInfo))
            MyAIPageServiceImpl.logger.info("my ai pull hasAiSessionInfo: \(response.hasAiSessionInfo) hasAiSessionInfo: \(response.hasAiSessionInfo)")
            if response.hasAiSessionInfo {
                self.handleAISessionInfo(aiSessionInfo: AISessionInfo.from(rustPB: response.aiSessionInfo))
            }
            if response.hasMode {
                self.handleAIExtensionConfig(aiExtensionConfig: AIExtensionConfig.from(mode: response.mode))
            }
            MyAIPageServiceImpl.logger.info("my ai pull last round info, finish handle")
        }, onError: { error in
            MyAIPageServiceImpl.logger.info("my ai pull last round info error, error: \(error)")
        }).disposed(by: self.disposeBag)

        // 监听AIRoundInfoPush
        self.pushCenter?.observable(for: PushAIRoundInfo.self).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] pushAIRoundInfo in
            guard let `self` = self else { return }
            MyAIPageServiceImpl.logger.info("my ai last round info push, begin handle")
            pushAIRoundInfo.aiRoundInfos.forEach({ self.handleAIRoundInfo(aiRoundInfo: $0) })
            MyAIPageServiceImpl.logger.info("my ai last round info push, finish handle")
        }).disposed(by: self.disposeBag)

        // 监听ThreadPush
        if self.chatMode {
            self.pushCenter?.observable(for: PushThreads.self)
                .compactMap({ $0.threads.first(where: { $0.aiChatModeID == self.chatModeConfig.aiChatModeId }) })
                .subscribe(onNext: { [weak self] newThread in
                    guard let `self` = self else { return }
                    self.chatModelThread = newThread
                    // 监听Scene变化，实时更新导航title
                    var scene = ServerPB_Office_ai_MyAIScene(); scene.sceneName = newThread.sceneInfo.sceneName
                    MyAIPageServiceImpl.logger.info("my ai navgation bar push threads, scene name change: \(scene.sceneName)")
                    self.chatModeScene.accept(scene)
                }).disposed(by: self.disposeBag)
        }

        // 监听消息上屏
        self.pushCenter?.observable(for: PushChannelMessage.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] channel in
                guard let `self` = self else { return }
                if self.chatMode,
                   self.chatModelThread?.rootMessageID == channel.message.id {
                    self.chatModeThreadMessage?.rootMessage = channel.message
                }

                // 通过fakeSuccess、process判断是否为假消息
                guard channel.message.localStatus == .fakeSuccess ||
                        channel.message.localStatus == .process else { return }
                // 如果是主会场，通过chatid判断是否是同一会话的假消息
                if !self.chatMode, channel.message.channel.id != String(self.chatId) { return }
                // 如果是分会场，通过aiChatModeID判断是否是同一分会场的假消息
                if self.chatMode, channel.message.aiChatModeID != self.chatModeConfig.aiChatModeId { return }
                self.onQuasiMessageShown.accept(())
            }).disposed(by: self.disposeBag)

        // 长链建立时重新拉取轮次信息，filter：只关心断网重连的情况，debounce：测试了一下，重连时SDK会短时间内连续Push多次
        self.pushCenter?.observable(for: PushWebSocketStatus.self).filter({ $0.status == .success })
            .debounce(.milliseconds(1000), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                self?.updateAIRoundInfo()
            }).disposed(by: self.disposeBag)

        if !isFirstRendered {
            isFirstRendered.toggle()
            onFirstRendered?()
        }
    }

    private func updateAIRoundInfo() {
        MyAIPageServiceImpl.logger.info("my ai update ai round info")

        // 请求会话最后一轮消息状态
        var request = Im_V1_GetMyAIInfoRequest()
        request.strategy = .forceServer
        request.chatID = self.chatId
        // 如果是MyAI的分会场，需要传AIChatModeID
        if self.chatMode { request.aiChatModeID = self.chatModeConfig.aiChatModeId }
        self.rustClient?.sendAsyncRequest(request).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (response: Im_V1_GetMyAIInfoResponse) in
            guard let `self` = self else { return }
            MyAIPageServiceImpl.logger.info("my ai update ai round info, begin handle")
            self.handleAIRoundInfo(aiRoundInfo: AIRoundInfo.from(rustPB: response.aiLastRoundInfo))
            MyAIPageServiceImpl.logger.info("my ai update ai round info, finish handle")
        }, onError: { error in
            MyAIPageServiceImpl.logger.info("my ai update ai round info error, error: \(error)")
        }).disposed(by: self.disposeBag)
    }

    /// 处理从push、pull来的AIRoundInfo信息
    private func handleAIRoundInfo(aiRoundInfo: AIRoundInfo) {
        // 只处理当前会话对应的AIRoundInfo
        guard aiRoundInfo.chatId == self.chatId else { return }

        // 如果是主会场，则aiChatModeId需要为0
        if !self.chatMode, aiRoundInfo.aiChatModeId != 0 { return }
        // 如果是分会场，则aiChatModeId需要是业务方传入的
        if self.chatMode, aiRoundInfo.aiChatModeId != self.chatModeConfig.aiChatModeId { return }

        // 如果是历史轮的对话，不做处理
        if aiRoundInfo.roundIdPosition < self.lastAIRoundInfo.roundIdPosition { return }
        // 如果是新一轮的对话，则直接更新
        if aiRoundInfo.roundIdPosition > self.lastAIRoundInfo.roundIdPosition {
            self.lastAIRoundInfo = aiRoundInfo
            self.aiRoundInfo.accept(self.lastAIRoundInfo)
            MyAIPageServiceImpl.logger.info("my ai last round info old: \(aiRoundInfo)")
            MyAIPageServiceImpl.logger.info("my ai last round info update roundIdPosition: \(self.lastAIRoundInfo)")
            return
        }

        // 如果是当前轮的旧消息，不做处理
        if aiRoundInfo.roundLastPosition < self.lastAIRoundInfo.roundLastPosition { return }
        // 如果是当前轮的新消息，则直接更新
        if aiRoundInfo.roundLastPosition > self.lastAIRoundInfo.roundLastPosition {
            self.lastAIRoundInfo = aiRoundInfo
            self.aiRoundInfo.accept(self.lastAIRoundInfo)
            MyAIPageServiceImpl.logger.info("my ai last round info old: \(aiRoundInfo)")
            MyAIPageServiceImpl.logger.info("my ai last round info update roundLastPosition: \(self.lastAIRoundInfo)")
            return
        }

        // 如果是当前轮的最后消息的旧状态，不做处理
        if aiRoundInfo.updateTime < self.lastAIRoundInfo.updateTime { return }
        // 如果是当前轮的最后消息的新状态，则直接更新
        if aiRoundInfo.updateTime > self.lastAIRoundInfo.updateTime {
            self.lastAIRoundInfo = aiRoundInfo
            self.aiRoundInfo.accept(self.lastAIRoundInfo)
            MyAIPageServiceImpl.logger.info("my ai last round info old: \(aiRoundInfo)")
            MyAIPageServiceImpl.logger.info("my ai last round info update updateTime: \(self.lastAIRoundInfo)")
            return
        }
    }
}
