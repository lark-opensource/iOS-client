//
//  LarkInterface+MyAI.swift
//  LarkMessengerInterface
//
//  Created by 李勇 on 2023/5/10.
//

import Foundation
import RxSwift
import RxCocoa
import ServerPB
import LarkSDKInterface
import RustPB
import LarkAIInfra
import LarkContainer
import LarkModel
import LarkMessageBase

// MARK: - MyAIChatModeMessagesManager
public protocol MyAIChatModeMessagesManager {
    func unfoldMyAIChatModeThread(chatModeId: Int64, threadId: String)
    func foldMyAIChatModeThread(chatModeId: Int64)
    func loadMoreMyAIChatModeThread(chatModeId: Int64, threadId: String)
}

public class MyAIChatModeMessagesManagerEmptyImpl: MyAIChatModeMessagesManager {
    public func unfoldMyAIChatModeThread(chatModeId: Int64, threadId: String) {}
    public func foldMyAIChatModeThread(chatModeId: Int64) {}
    public func loadMoreMyAIChatModeThread(chatModeId: Int64, threadId: String) {}
    public init() {}
}

// MARK: - MyAIQuickActionSendService
public protocol MyAIQuickActionSendService {

    // TODO: @wanghaidong 统一 QuickAction 格式

    /// 处理服务端透传接口的快捷指令
    /// - Parameters:
    ///   - quickAction: 来自 ServerPB 定义的快捷指令
    ///   - sendCallback: 发送完成后的回调（用于业务方埋点）
    func handleAIQuickAction(_ quickAction: ServerPB_Office_ai_QuickAction, sendTracker: QuickActionSendTracker)

    /// 处理 RustSDK 的快捷指令
    /// - Parameters:
    ///   - quickAction: 来自 RustPB 定义的快捷指令
    ///   - sendCallback: 发送完成后的回调（用于业务方埋点）
    /// - NOTE: 目前 QuickAction 格式不统一，ServerPB 和 RustPB 都有定义。RustPB 中返回的暂时只有 Query 类型，暂时先这样
    func handleAIQuickAction(_ quickAction: Im_V1_QuickAction, sendTracker: QuickActionSendTracker)
}

public extension MyAIQuickActionSendService {

    /// 默认实现 RustPB 的快捷指令处理方法，内部将 `Im_V1_QuickAction` 按字段强转为 `ServerPB_Office_ai_QuickAction`
    func handleAIQuickAction(_ quickAction: Im_V1_QuickAction, sendTracker: QuickActionSendTracker) {
        // 目前 QuickAction 格式不统一，ServerPB 和 RustPB 都有定义。暂时先在这里转换类型
        guard let serializedData = try? quickAction.serializedData() else { return }
        guard let serverQuickAction = try? ServerPB_Office_ai_QuickAction(serializedData: serializedData) else { return }
        handleAIQuickAction(serverQuickAction, sendTracker: sendTracker)
    }
}

/// QuickActionSendService 的空实现，作为不依赖键盘的兜底。
/// - NOTE: 如果后期 QuickAction 不再强依赖 NormalChatInputKeyboard 实现，此处可以给一个默认实现
public class MyAIQuickActionSendServiceEmptyImpl: MyAIQuickActionSendService {

    public init() {}

    public func handleAIQuickAction(_ quickAction: ServerPB_Office_ai_QuickAction, sendTracker: QuickActionSendTracker) {}
}

public class QuickActionSendTracker {

    private var sendCallback: (Bool, Chat) -> Void

    public init(sendCallback: @escaping (Bool, Chat) -> Void) {
        self.sendCallback = sendCallback
    }

    public func reportSendEvent(isEdited: Bool, chat: Chat) {
        sendCallback(isEdited, chat)
    }
}

// MARK: - MyAIService
/// user纬度，提供全局的MyAI能力，如果访问不到MyAIService，可以使用LarkAIInfra中的拆分接口
/// 介绍文档：https://bytedance.feishu.cn/docx/MI6ldKJpJoYtwixhScIctA4anph
public protocol MyAIService: MyAIOnboardingService, MyAIInfoService, MyAIChatModeService, MyAIExtensionService, MyAISceneService, MyAIQuickActionService {
    func pageService(userResolver: UserResolver, chatId: String, chatMode: Bool, chatModeConfig: MyAIChatModeConfig, chatFromWhere: ChatFromWhere) -> MyAIPageService
    func imInlineService(delegate: IMMyAIInlineServiceDelegate, scenarioType: InlineAIConfig.ScenarioType) -> IMMyAIInlineService
    func stopGeneratingView(userResolver: UserResolver, chat: Chat, targetVC: UIViewController) -> UIView
}

// MARK: - MyAIPageService
/// 页面纬度，提供当前页面MyAI的信息，用于较低层的渲染层获取到当前页面的MyAI信息
/// 1.目前只在和MyAI的单聊（ChatModuleContext.container容器）注入了实现；不要在全局容器中强取
public protocol MyAIPageService: AfterFirstScreenMessagesRenderDelegate, MyAIPageAbilityProtocol {
    /// 当前是否是和MyAI的分会场
    var chatMode: Bool { get }
    /// 会话 ID
    var chatId: Int64 { get }
    /// AIRoundInfo信息，主分会场最后一轮会话信息，停止生成、重新生成、新话题逻辑使用
    var aiRoundInfo: BehaviorRelay<AIRoundInfo> { get }
    /// 埋点使用，取自InnerChatControllerBody.fromWhere
    var chatFromWhere: ChatFromWhere { get }
    var onQuasiMessageShown: BehaviorRelay<Void> { get }
    /// 唤起Onboard卡片
    /// byUser：是否为用户手动触发的操作
    func showOnboardCard(byUser: Bool, onError: ((Error) -> Void)?)
    /// 通过场景id创建新话题
    func newTopic(with sceneID: Int64) -> Observable<ServerPB_Office_ai_AIChatNewTopicResponse>
    /// ------插件专属属性------
    /// 获取当前选中的插件展示在Banner下方悬浮，进群会pull一次填充此信号，后续靠选插件面板主动赋值MyAIExtensionService.selectedExtension，此信号没有push、多端同步
    var aiSessionInfo: BehaviorRelay<AISessionInfo> { get }
    /// 后面重构为监听aiRoundInfo，不需要refreshExtension信号了，本意就是刷新插件系统消息，判断是否是最后一轮、是否可修改插件
    var refreshExtension: BehaviorRelay<String> { get }
    var aiExtensionConfig: BehaviorRelay<AIExtensionConfig> { get }
    /// 点击了卡片中的选择插件，调起选择插件面板
    func handleExtensionCardApplink(messageId: String, chat: Chat, from: UIViewController)

    /// ------快捷指令专属属性------
    /// 快捷指令跟随消息 FG 是否打开
    var isFollowUpEnabled: Bool { get }
    /// 当前键盘上方所展示的快捷指令
    var aiQuickActions: BehaviorRelay<[AIQuickAction]> { get }
    /// 构建 ServerPB 快捷指令请求
    func createServerQuickActionRequest(withType fetchType: ServerPB_Office_ai_FetchActionType) -> ServerPB_Office_ai_FetchQuickActionsRequest
    /// 构建 RustPB 快捷指令请求
    func createSdkQuickActionRequest(withType fetchType: Im_V1_FetchQuickActionsRequest.FetchActionType) -> Im_V1_GetAIRoundQuickActionRequest
    /// 通过 ID 获取快捷指令详细信息并执行
    func handleQuickActionByApplinkURL(_ applink: URL, service: MyAIQuickActionSendService, onChat: UIViewController)

    /// 主会场专属属性
    var myAIMainChatConfig: MyAIMainChatConfig { get }
    /// ------分会场专属属性------
    /// 业务方跳转分会场携带的信息
    var chatModeConfig: MyAIChatModeConfig { get }
    /// 分会场升级为场景FG，用staticFeatureGatingValue的话会存在问题：第一次取为false后，后台开了fg，此时会导致进会会场会看到新话题，点击新话题会报错
    /// 为了减少这种情况，我们每次进分会话重新取一次
    var larkMyAIScenariosThread: Bool { get }
    /// 分会场绑定的场景信息
    var chatModeScene: BehaviorRelay<ServerPB_Office_ai_MyAIScene> { get }
    /// 分会场绑定的Thread信息
    var chatModeThreadMessage: ThreadMessage? { get set }
    var chatModeThreadState: BehaviorRelay<Basic_V1_ThreadState> { get }
    /// My AI场景特化路由跳转
    func onMessageURLTapped(fromVC: UIViewController,
                            url: URL,
                            context: [String: Any],
                            defaultOpenBlock: @escaping () -> Void)
    func onMessageFileTapped(fromVC: UIViewController,
                            message: Message,
                            scene: FileSourceScene,
                            downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                            defaultOpenBlock: @escaping () -> Void)
    func onMessageFolderTapped(fromVC: UIViewController,
                               message: Message,
                               scene: FileSourceScene,
                               downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                               defaultOpenBlock: @escaping () -> Void)

    /// ------场景专属属性-----
    var useNewOnboard: Bool { get }
    func handleSceneSelectByApplink(_ applink: URL, chat: Chat, onChat: UIViewController)
}

public protocol IMMyAIInlineServiceDelegate: AnyObject {
    func getDisplayVC() -> UIViewController
    func getChat() -> Chat
    func getUnreadMessagesInfo() -> (startPosition: Int32, direction: MyAIInlineServiceParamMessageDirection)

    func onInsertInMyAIInline(content: RustPB.Basic_V1_RichText)
}

public extension IMMyAIInlineServiceDelegate {
    func getUnreadMessagesInfo() -> (startPosition: Int32, direction: MyAIInlineServiceParamMessageDirection) {
        assertionFailure("not implement")
        return (0, .down)
    }
}

public enum MyAIInlineServiceParamMessageDirection: String {
    case up
    case down
}

public protocol IMMyAIInlineService: AnyObject {
    func openMyAIInlineMode(source: IMMyAIInlineSource)
    func openMyAIInlineModeWith(quickAction: QuickActionProtocol, params: [String: String], source: IMMyAIInlineSource)
    func generateParamsForMessagesInfo(startPosition: Int32, direction: MyAIInlineServiceParamMessageDirection) -> (key: String, value: String)?
    func trackInlineAIEntranceView(_ source: IMMyAIInlineSource)
    init(userResolver: UserResolver, delegate: IMMyAIInlineServiceDelegate, scenarioType: InlineAIConfig.ScenarioType)

    var alreadySummarizedMessageByMyAI: Bool { get set }
    var alreadyTrackSummarizedMessageByMyAIView: Bool { get set }
}

public protocol QuickActionProtocol {
    var name: String { get }
    var id: String { get }
    var icon: String { get }
    var extraMap: [String: String] { get }
    var params: [String] { get }
    var paramDetailsWhichNeedConfirm: [QuickActionParamDetailProtocol] { get }
}

public protocol QuickActionParamDetailProtocol {
    var name: String { get }
    var displayName: String { get }
    var placeHolder: String { get }
}

//页面打开的入口。仅用于埋点
public enum IMMyAIInlineSource: String {
    case mention
    case scroll_to_unread
}

extension ServerPB_Office_ai_inline_QuickActionParam: QuickActionParamDetailProtocol {}

extension ServerPB_Office_ai_Param: QuickActionParamDetailProtocol {}

extension InlineAIQuickAction: QuickActionProtocol {
    public var paramDetailsWhichNeedConfirm: [QuickActionParamDetailProtocol] {
        return self.paramDetails.compactMap {
            if $0.needConfirm {
                return $0
            }
            return nil
        }
    }
}

extension ServerPB_Office_ai_QuickAction: QuickActionProtocol {
    public var params: [String] {
        return self.paramDetails.compactMap({ return $0.name })
    }

    public var paramDetailsWhichNeedConfirm: [QuickActionParamDetailProtocol] {
        return self.paramDetails.compactMap {
            if $0.needConfirm {
                return $0
            }
            return nil
        }
    }

    public var icon: String {
        return ""
    }
}

// MARK: - MyAIToolInterface
public struct MyAIToolsPanelConfig {
    public typealias SelectToolsSureCallBack = (_ selectItems: [MyAIToolInfo]) -> Void

    /// 已选toolIds
    public var selectedToolIds: [String]
    /// 场景，默认为IM
    public var scenario: String
    public var completionHandle: SelectToolsSureCallBack?
    public var closeHandler: (() -> Void)?
    public var maxSelectCount: Int?
    public var aiChatModeId: Int64
    public var myAIPageService: MyAIPageService?
    public var extra: [AnyHashable: Any]

    public init(selectedToolIds: [String] = [],
                scenario: String,
                completionHandle: SelectToolsSureCallBack? = nil,
                closeHandler: (() -> Void)? = nil,
                maxSelectCount: Int? = nil,
                aiChatModeId: Int64 = 0,
                myAIPageService: MyAIPageService? = nil,
                extra: [AnyHashable: Any] = [:]) {
        self.selectedToolIds = selectedToolIds
        self.scenario = scenario
        self.completionHandle = completionHandle
        self.closeHandler = closeHandler
        self.maxSelectCount = maxSelectCount
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.extra = extra
    }
}

public struct MyAIToolsSelectedPanelConfig {
    public var userResolver: UserResolver
    public var toolItems: [MyAIToolInfo]
    public var toolIds: [String]
    public var aiChatModeId: Int64
    public var myAIPageService: MyAIPageService?
    public var extra: [AnyHashable: Any]
    public var startNewTopicHandler: (() -> Void)?
    public init(userResolver: UserResolver,
                toolItems: [MyAIToolInfo] = [],
                toolIds: [String] = [],
                aiChatModeId: Int64 = 0,
                myAIPageService: MyAIPageService? = nil,
                extra: [AnyHashable: Any] = [:],
                startNewTopicHandler: (() -> Void)? = nil) {
        self.toolItems = toolItems
        self.toolIds = toolIds
        self.aiChatModeId = aiChatModeId
        self.userResolver = userResolver
        self.myAIPageService = myAIPageService
        self.extra = extra
        self.startNewTopicHandler = startNewTopicHandler
    }
}

public protocol MyAIToolsService {
    func generateAIToosPanel(with panelCofig: MyAIToolsPanelConfig, userResolver: UserResolver, chat: Chat) -> MyAIToolsPanelInterface

    func generateAIToosSelectedPanel(with panelCofig: MyAIToolsSelectedPanelConfig, userResolver: UserResolver, chat: Chat) -> MyAIToolsPanelInterface

    func generateAIToolSelectedUDPanel(panelConfig: MyAIToolsSelectedPanelConfig, chat: Chat) -> MyAIToolsPanelInterface
}

public protocol MyAIToolsPanelInterface: UIViewController {
    // 展示
    func show(from vc: UIViewController?)
}

public protocol MyAIToolsSelectStatusInterface: UIView {
    typealias MyAIToolCloseComplete = (() -> Void)
    typealias TapCloseToolAction = (() -> Void)
    func sizeToFit(toolCount: Int) -> CGSize

    func update(toolIds: [String])

    func update(tools: [MyAIToolInfo])

    func update(aiChatModeID: Int64, isSingleMode: Bool, tapCloseTool: TapCloseToolAction?)
}

public protocol MyAIToolsWorkingStatusInterface: UIView { }

// swiftlint:disable all
public protocol RustMyAIToolServiceAPI {
    /// 无quary为默认插件列表，默认场景为IM 主会场
    func getMyAIToolList(_ keyWord: String, pageNum: Int, pageSize: Int, _ scenario: String) -> Observable<([MyAIToolInfo], Bool)>

    func getMyAIToolsInfo(toolIds: [String]) -> Observable<[MyAIToolInfo]>

    func sendMyAITools(toolIds: [String],
                       messageId: String,
                       aiChatModeID: Int64,
                       toolInfoList: [MyAIToolInfo]) -> Observable<Void>

    func getMyAIToolConfig() -> Observable<MyAIToolConfig>
}
// swiftlint:enable all
