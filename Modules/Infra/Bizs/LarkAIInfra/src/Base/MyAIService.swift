//
//  MyAIService.swift
//  LarkAIInfra
//
//  Created by 李勇 on 2023/7/7.
//

import Foundation
import EENavigator
import RxSwift
import RxCocoa
import ServerPB
import RustPB
import ThreadSafeDataStructure
import LarkModel

// # MARK: - MyAIOnboardingService
/// AIOnboarding 服务, 由LarkAI注入实现
public protocol MyAIOnboardingService {
    /// 用于Onboarding流程，用于：Feed Mock MyAI；CCM打开inline Mode前判断是否onboarding过
    var needOnboarding: BehaviorRelay<Bool> { get }
    /// 打开onboarding。（在打开单聊/打开profile时不需要额外判断是否跳onboarding，打开单聊/打开profile的接口内部已经检查了是否需要跳onboarding）
    func openOnboarding(from: NavigatorFrom,
                        onSuccess: ((_ chatID: Int64) -> Void)?,
                        onError: ((_ error: Error?) -> Void)?,
                        onCancel: (() -> Void)?)
    /// 判断是否需要 onboarding，如果需要，先自动完成 onboarding 后再执行后续逻辑
    func checkOnboardingAndThen(from: NavigatorFrom, exec: @escaping () -> Void)
}

// # MARK: - MyAIInfoService
public struct MyAIInfo {
    public let id: String
    public let name: String
    public let avatarKey: String
    public var avatarImage: UIImage?

    public init(id: String, name: String, avatarKey: String, avatarImage: UIImage?) {
        self.id = id
        self.name = name
        self.avatarKey = avatarKey
        self.avatarImage = avatarImage
    }
}
public struct MyAIResource {
    /// 用于在一些场景（如mention组件）识别mock的“MyAI”chatter
    public let mockID: String = "myai"
    /// "MyAI" 未初始化前所使用的默认名称
    public let name: String
    /// "MyAI" 未初始化前所使用的默认头像（根据场景，小于 32pt 使用该头像）
    public let iconSmall: UIImage
    /// "MyAI" 未初始化前所使用的默认头像（根据场景，大于 32pt 使用该头像）
    public let iconLarge: UIImage

    public init(name: String, iconSmall: UIImage, iconLarge: UIImage) {
        self.name = name
        self.iconSmall = iconSmall
        self.iconLarge = iconLarge
    }
    
    /// 获取兜底 AI 品牌名
    public static func getFallbackName(isFeishu: Bool) -> String {
        return isFeishu ? BundleI18n.LarkAIInfra.MyAI_Common_Faye_AiNameFallBack : BundleI18n.LarkAIInfra.MyAI_Common_MyAI_AiNameFallBack
    }
}
/// MyAI一些信息，由LarkAI注入实现
public protocol MyAIInfoService {
    var canOpenOthersAIProfile: Bool { get }
    /// 后台是否开启MyAI功能，如果没有开启，则主导航、联系人tab、Feed、大搜等处不应该显示MyAI入口
    var enable: BehaviorRelay<Bool> { get }
    /// MyAI的头像等信息，用户可以修改MyAI的头像；用于联系人tab实时更新入口
    var info: BehaviorRelay<MyAIInfo> { get }
    /// MyAI 的默认资源，包括默认名称、小头像、大头像
    var defaultResource: MyAIResource { get }

    /// 用于联系人tab MyAI、大搜出Mock MyAI人，跳转到MyAI的Profile；内部会根据是否Onboarding先进入Onboarding流程
    func openMyAIProfile(from: NavigatorFrom)
}

// # MARK: - MyAIChatModeService
public typealias AIQuickAction = ServerPB_Office_ai_QuickAction
/// Onboard卡片数据
/// notShow: 不展示卡片
/// loading: 卡片数据正在加载中
/// success: 卡片数据加载成功,onboard卡片上屏
public enum MyAIOnboardCardStatus {
    case notShow(newMessage: Message? = nil)
    case loading
    case success(MyAIOnboardInfo, Bool)
    case willDismiss
}

/// 如果在MyAI的主会场，一些MyAI的状态信息
public class MyAIMainChatConfig {
    public var onBoardInfoSubject: BehaviorRelay<MyAIOnboardCardStatus> = .init(value: .notShow())
    public let firstScreenAnchorRelay = BehaviorRelay<(String, Int32)>(value: ("", -1))
    public init() {
    }
}

/// 如果跳转到MyAI的分会场，需要接入MyAI的业务方信息
/// 介绍文档：https://bytedance.feishu.cn/docx/MI6ldKJpJoYtwixhScIctA4anph
public class MyAIChatModeConfig {
    /// AI 主会话 ID. 当且仅当需要onboarding的时候，chatID会为nil
    public var chatId: Int64?
    /// AI 分会话 ID
    public var aiChatModeId: Int64
    /// 当前场景操作的对象ID
    public var objectId: String
    /// 当前场景操作的对象Type。e.g. IM DOC SHEET BASE VC CALENDAR EMAIL MEEGO
    // TODO: 改为 String 类型？
    public var objectType: Scenario
    /// 本次 AI 分会话中每条MyAI回复的文本、富文本消息上自带的操作按钮
    public var actionButtons: [ActionButton] = []
    /// 本次 AI 分会话的问候语，默认使用 “Start working with you on here”
    public var greetingMessageType: GreetingMessageType = .default

    //TODO: 贾潇 下面三个Provider未来考虑重构到delegate里
    /// 本次 AI 分会话期间，MyAI 向业务实时获取上下文信息（如当前选区内容）
    public var appContextDataProvider: AppContextDataProvider?
    /// 获取分会场业务所提供的流量特征
    public var triggerParamsProvider: TriggerParamsProvider?
    /// 获取分会场业务执行快捷指令携带的额外参数
    public var quickActionsParamsProvider: QuickActionsParamsProvider?

    public weak var delegate: MyAIChatModeConfigDelegate?

    /// 存放不通用的业务参数（如埋点等），方便扩展，目前有以下key需要业务方关心：
    /// 1.app_name：用于im_chat_main_view等埋点，需要业务方传，取值见https://bytedance.feishu.cn/sheets/FujLsgluIh83sStuhVIcm9IFnOh
    /// 2.
    public var extra: SafeDictionary<String, Any> = [:] + .readWriteLock

    // TODO: @jiaxiao 这种回调方式的持有关系非常绕，提测完重新理一下
    // Config 对象是从业务获取数据的单向数据流，向业务方发送通知考虑用其他方式
    public var callBack: ((PageService) -> Void)?

    /// 分会场toolIds
    public var toolIds: [String]

    public init(chatId: Int64?,
                aiChatModeId: Int64,
                objectId: String,
                objectType: Scenario,
                actionButtons: [ActionButton] = [],
                greetingMessageType: GreetingMessageType = .default,
                appContextDataProvider: AppContextDataProvider? = nil,
                triggerParamsProvider: TriggerParamsProvider? = nil,
                quickActionsParamsProvider: QuickActionsParamsProvider? = nil,
                callBack: ((PageService) -> Void)? = nil,
                toolIds: [String] = []) {
        self.chatId = chatId
        self.aiChatModeId = aiChatModeId
        self.actionButtons = actionButtons
        self.greetingMessageType = greetingMessageType
        self.appContextDataProvider = appContextDataProvider
        self.triggerParamsProvider = triggerParamsProvider
        self.quickActionsParamsProvider = quickActionsParamsProvider
        self.objectId = objectId
        self.objectType = objectType
        self.callBack = callBack
        self.toolIds = toolIds
    }

    public struct ActionButton {
        /// 按钮标识，业务方自己维护
        public var key: String
        /// 按钮显示的title，业务方直接传国际化后的文案，MyAI不做处理
        public var title: String
        /// 按钮的点击回调
        public var callback: (ActionButtonData) -> Void

        public init(key: String, title: String, callback: @escaping (ActionButtonData) -> Void) {
            self.key = key
            self.title = title
            self.callback = callback
        }
    }

    /// Action时MyAI回传给各业务方的数据
    public struct ActionButtonData {
        public var type: ActionButtonDataType
        public var content: String

        public init(type: ActionButtonDataType, content: String) {
            self.type = type
            self.content = content
        }
    }

    public enum ActionButtonDataType {
        case raw
        case markdown
        case jsonString
    }

    public enum GreetingMessageType {
        case `default`
        case plainText(_ text: String)
        case iconText(_ icon: UIImage, text: String)
        case url(_ urlString: String)
    }

    public enum Scenario: String {
        case IM
        case DOC
        case SHEET
        case BASE
        case MEETING
        case CALENDAR
        case EMAIL
        case MEEGO
        case PDF
        case WIKISpace = "WIKI"
        case GroupChat
        case P2PChat
        case WEB_LINK

        //TODO: @方俊 临时处理，后期Scenario类型会变更为String,可直接透传
        public func getScenarioID() -> String {
            switch self {
            case .IM:       return "IM"
            case .DOC:      return "Doc"
            case .SHEET:    return "Sheet"
            case .BASE:     return "Base"
            case .MEETING:  return "VC"
            case .CALENDAR: return "Calendar"
            case .EMAIL:    return "Email"
            case .MEEGO:    return "Meego"
            case .PDF:    return "PDFView"
            case .WIKISpace: return "WikiSpace"
            case .GroupChat: return "GroupChat"
            case .P2PChat: return "P2PChat"
            case .WEB_LINK: return "OpenWebContainer"
            }
        }
    }

    public typealias AppContextDataProvider = () -> [String: String]
    public typealias TriggerParamsProvider = () -> [String: String]
    public typealias QuickActionsParamsProvider = (AIQuickAction) -> [String: String]

    public class PageService {
        private weak var vc: MyAIChatModeViewControllerProtocol?
        private weak var pageAbility: MyAIPageAbilityProtocol?
        private var disposeBag: DisposeBag = DisposeBag()
        
        public func closeMyAIChatMode(needShowAlert: Bool) {
            self.vc?.closeMyAIChatMode(needShowAlert: needShowAlert)
        }
        
        public func closeMyAIChatMode() {
            self.vc?.closeMyAIChatMode()
        }
        public func refreshQuickActions() {
            self.pageAbility?.updateQuickActions()
        }
        public func sendQuickAction(_ quickAction: AIQuickAction, trackParmas: [String: Any]) throws {
            guard let pageAbility = self.pageAbility else {
                throw MyAIChatModeDestroyedError()
            }
            pageAbility.sendQuickAction(quickAction, trackParmas: trackParmas)
        }
        public var isActive: BehaviorRelay<Bool> = BehaviorRelay(value: true)

        @available(iOS 13.0, *)
        public func getCurrentSceneState() -> UIScene.ActivationState? {
            return vc?.getCurrentSceneState()
        }

        public init(vc: MyAIChatModeViewControllerProtocol,
                    pageAbility: MyAIPageAbilityProtocol) {
            self.vc = vc
            self.pageAbility = pageAbility
            vc.isActive
                .subscribe(onNext: { [weak self] (value) in
                    self?.isActive.accept(value)
                }).disposed(by: self.disposeBag)
        }
    }

    public func shouldInteractWithURL(_ url: URL) -> Bool {
        //判断url是否是该applink。目前applink没有现成的接口，只好先用正则匹配了。
        if url.withoutQueryAndFragment.isMatch(for: "/client/myai/link$"),
           let type = url.queryParameters["type"],
           type == "link",
           let value = url.queryParameters["value"],
           let valueURL = try? URL.forceCreateURL(string: value) {
            return delegate?.shouldInteractWithURL(valueURL) ?? true
        }
        return true
    }

    public struct MyAIChatModeDestroyedError: Error {}
}

public protocol MyAIChatModeConfigDelegate: AnyObject {
    func getObjectId(_ chatModeConfig: MyAIChatModeConfig) -> String
    func getObjectType(_ chatModeConfig: MyAIChatModeConfig) -> String
    func getChatContextExtraMap(_ chatModeConfig: MyAIChatModeConfig) -> [String: String]

    /// 在My AI分会话点击富文本/卡片上的url都会走到这里。返回值bool表示是否响应该url自身的点击事件。
    /// 通常来说，业务方可以在这里判断url种类，如果命中页面通信，则在该方法中执行对应的逻辑（然后通常返回false，拦截掉url自身事件）；若没有命中页面通信 则返回true响应默认事件。
    func shouldInteractWithURL(_ url: URL) -> Bool
}

public extension MyAIChatModeConfigDelegate {
    func getObjectId(_ chatModeConfig: MyAIChatModeConfig) -> String {
        return chatModeConfig.objectId
    }

    func getObjectType(_ chatModeConfig: MyAIChatModeConfig) -> String {
        return chatModeConfig.objectType.rawValue
    }

    func getChatContextExtraMap(_ chatModeConfig: MyAIChatModeConfig) -> [String: String] {
        return chatModeConfig.appContextDataProvider?() ?? [:]
    }

    func shouldInteractWithURL(_ url: URL) -> Bool {
        return true
    }
}

public protocol MyAIChatModeViewControllerProtocol: AnyObject {
    func closeMyAIChatMode(needShowAlert: Bool)
    @available(iOS 13.0, *)
    func getCurrentSceneState() -> UIScene.ActivationState?
    var isActive: BehaviorRelay<Bool> { get }
}

public protocol MyAIPageAbilityProtocol: AnyObject {
    /// 业务方主动调用，更新键盘上方快捷指令
    func updateQuickActions()
    /// 业务方主动触发的quickAction的接口
    func sendQuickAction(_ quickAction: AIQuickAction, trackParmas: [String: Any])
}

public extension MyAIChatModeViewControllerProtocol {
    func closeMyAIChatMode() {
        self.closeMyAIChatMode(needShowAlert: false)
    }
}
extension MyAIChatModeConfig {
    public static let `default` = MyAIChatModeConfig(chatId: nil, aiChatModeId: 0, objectId: "", objectType: .IM)
}
/// MyAI主分会场，由LarkAI注入实现
public protocol MyAIChatModeService {
    /// 用于主导航，跳转到MyAI的分会场；内部会根据是否Onboarding先进入Onboarding流程
    func openMyAIChatMode(config: MyAIChatModeConfig, from: UIViewController, isFullScreenWhenPresent: Bool)
    /// 获取MyAI分会场对应的Body。不建议业务方直接用这个方式跳转。
    func getMyAIChatModeBody(config: MyAIChatModeConfig) -> Body
    /// 用于Feed Mock MyAI，大搜出Mock MyAI群，跳转到MyAI的主会场，内部会先进行Onboarding再进入主会场；此时一定没有进行过Onboarding
    func openMyAIChat(from: UIViewController)
    /// 业务方获取MyAIChatModeID和ChatID
    func getAIChatModeId(appScene: String?, link: String?, appData: String?) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeInitResponse>
    /// 通知IM服务端关闭对应话题。场景示例：CCM场景用户关闭云文档；VC场景会议关闭；
    func closeChatMode(aiChatModeID: String) -> Observable<ServerPB.ServerPB_Office_ai_AIChatModeThreadCloseResponse>
    /// 检查分会话对应thread的状态，以免thread已触发超时关闭。若返回的是.close，则需要重新getAIChatModeId，打开一个新的分会话。可选入参chatID如果业务方已经拿到了 则最好传入，没有传的话服务内部可能会另外调接口来获取。
    //TODO: 贾潇 因接口实现变更，chatID不需要传了，aiChatModeID最好也改成String类型
    func getChatModeState(aiChatModeID: Int64, chatID: Int64?) -> Observable<Basic_V1_ThreadState>
}

public extension MyAIChatModeService {
    func openMyAIChatMode(config: MyAIChatModeConfig, from: UIViewController) {
        self.openMyAIChatMode(config: config, from: from, isFullScreenWhenPresent: false)
    }
}

// # MARK: - MyAIExtensionService
/// MyAI插件，由LarkAI注入实现
public protocol MyAIExtensionService {
    /// 获取当前选中的插件展示在Banner下方悬浮，选插件面板时主动赋值，此信号没有Push、多端同步，首屏插件获取靠MyAIPageService.aiSessionInfo
    var selectedExtension: BehaviorRelay<MyAIExtensionCallBackInfo> { get }
}

public struct MyAIExtensionCallBackInfo {
    public static let `default` = MyAIExtensionCallBackInfo(extensionList: [], fromVc: nil)


    public let extensionList: [MyAIExtensionInfo]
    public weak var fromVc: UIViewController?


    public init(extensionList: [MyAIExtensionInfo], fromVc: UIViewController?) {
        self.extensionList = extensionList
        self.fromVc = fromVc
    }
}

public struct MyAIExtensionInfo {
    public let id: String
    public let name: String
    public let avatarKey: String


    public init(id: String, name: String, avatarKey: String) {
        self.id = id
        self.name = name
        self.avatarKey = avatarKey
    }
}

// # MARK: - MyAISceneService
/// MyAI场景，由LarkAI注入实现
public protocol MyAISceneService {
    /// 目前的拉取是透传接口，这里做一层内存缓存，提升进入我的场景时的体验
    var cacheScenes: [ServerPB_Office_ai_MyAIScene] { get set }
    /// 场景创建成功：本设备，非多端同步
    var createSceneSubject: PublishSubject<ServerPB_Office_ai_MyAIScene> { get }
    /// 更新某个场景：本设备，非多端同步
    var editSceneSubject: PublishSubject<ServerPB_Office_ai_MyAIScene> { get }

    /// 调起我的场景界面
    func openSceneList(from: NavigatorFrom, chat: Chat, selected: @escaping ((_ sceneId: Int64) -> Void))
    /// 调起场景创建界面
    func openCreateScene(from: NavigatorFrom, chat: Chat)
    /// 调起场景编辑界面
    func openEditScene(from: NavigatorFrom, chat: Chat, scene: ServerPB_Office_ai_MyAIScene)
    /// 添加某个场景到我的场景列表
    func handleSceneAddByApplink(_ applink: URL, from: NavigatorFrom)
}


// # MARK: - MyAIExtensionService
/// MyAI插件，由LarkAI注入实现
public protocol MyAIQuickActionService {
    // chatID + aiChatModeID 作为缓存的 key；messagePosition 作为缓存的 version
    func putAuickActions(chatID: Int64, aiChatModeID: Int64, messagePosition: Int64, quickActions: [AIQuickActionModel])
    // 获取 chatID + aiChatModeID 对应的 QuickActions。若 messagePosition > 缓存的 messagePosition，返回空数组
    func getAuickActions(chatID: Int64, aiChatModeID: Int64, messagePosition: Int64) -> [AIQuickActionModel]
}
