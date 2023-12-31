//
//  CCMAIServiceDependency.swift
//  SpaceInterface
//
//  Created by ByteDance on 2023/6/6.
//

import Foundation
import RxSwift
import RxCocoa
import ServerPB
import EENavigator
import ThreadSafeDataStructure
import LarkAIInfra

public class CCMAIChatModeConfig {

    /// AI 主会话 ID. 当且仅当需要onboarding的时候，chatID会为nil
    public var chatId: Int64?
    /// AI 分会话 ID
    public var aiChatModeId: Int64
    /// 本次 AI 分会话中每条MyAI回复的文本、富文本消息上自带的操作按钮
    public var actionButtons: [ActionButton] = []
    /// 本次 AI 分会话的问候语，默认使用 “Start working with you on here”
    public var greetingMessageType: GreetingMessageType = .default
    /// 本次 AI 分会话期间，MyAI 向业务实时获取上下文信息（如当前选区内容）
    public var appContextDataProvider: AppContextDataProvider?
    /// 当前场景操作的对象ID
    public var objectId: String
    /// 当前场景操作的对象Type。e.g. IM DOC SHEET BASE VC CALENDAR EMAIL MEEGO
    public var objectType: String
    /// 获取分会场业务所提供的流量特征
    public var triggerParamsProvider: (() -> [String: String])?
    /// 获取分会场业务执行快捷指令携带的额外参数
    public var quickActionsParamsProvider: ((ServerPB_Office_ai_QuickAction) -> [String: String])?
    /// 分会场toolIds
    public var toolIds = [String]()
    /// 存放不通用的业务参数（如埋点等），方便扩展
    public var extra: SafeDictionary<String, Any> = [:] + .readWriteLock
    
    public weak var delegate: MyAIChatModeConfigDelegate?

    public var callBack: ((CCMAIChatModePageService) -> Void)?
    
    public init(chatId: Int64?,
                aiChatModeId: Int64,
                objectId: String,
                objectType: String,
                actionButtons: [ActionButton] = [],
                greetingMessageType: GreetingMessageType = .default,
                callBack: ((CCMAIChatModePageService) -> Void)? = nil) {
        self.chatId = chatId
        self.aiChatModeId = aiChatModeId
        self.objectId = objectId
        self.objectType = objectType
        self.actionButtons = actionButtons
        self.greetingMessageType = greetingMessageType
        self.callBack = callBack
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

    public typealias AppContextDataProvider = () -> [String: String]
}

extension CCMAIChatModeConfig: CustomStringConvertible {
    
    public var description: String {
        return [
            "chatId: \(String(describing: chatId))",
            "aiChatModeId: \(aiChatModeId)",
            "objectId: \(objectId)",
            "objectType: \(objectType)",
            "toolIds: \(toolIds)",
            "actionButtons: \(actionButtons)",
            "greetingMessageType: \(greetingMessageType)"
        ].joined(separator: ",\n")
    }
}

public protocol CCMAIChatModePageService {
    /// 分会话是否在展示
    var isActive: Bool { get }
    /// 关闭分会话
    func closeMyAIChatMode(needShowAlert: Bool)
    /// 刷新快捷指令
    func updateQuickActions()
}

public extension CCMAIChatModePageService {
    func closeMyAIChatMode() {
        self.closeMyAIChatMode(needShowAlert: false)
    }
}

public struct CCMBasicAIChatModeInfo {
    public let chatID: Int64
    public let chatModeID: Int64
    
    public init(chatID: Int64, chatModeID: Int64) {
        self.chatID = chatID
        self.chatModeID = chatModeID
    }
}

/// user纬度，提供全局的MyAI能力
/// 介绍文档：https://bytedance.feishu.cn/docx/MI6ldKJpJoYtwixhScIctA4anph
public protocol CCMAIService {
    
    /// 后台是否开启MyAI功能，如果没有开启，则主导航、联系人tab、Feed、大搜等处不应该显示MyAI入口
    var enable: BehaviorRelay<Bool> { get }
    
    /// 用于Onboarding流程，用于：Feed Mock MyAI；CCM打开inline Mode前判断是否onboarding过
    var needOnboarding: BehaviorRelay<Bool> { get }

    /// 用于主导航，跳转到MyAI的分会场；内部会根据是否Onboarding先进入Onboarding流程
    func openMyAIChatMode(config: CCMAIChatModeConfig, from: UIViewController)
    
    /// 打开onboarding界面
    func openOnboarding(from: NavigatorFrom,
                        onSuccess: ((_ chatID: Int64) -> Void)?,
                        onError: ((_ error: Error?) -> Void)?,
                        onCancel: (() -> Void)?)
    
    func getAIChatModeInfo(scene: String, link: String?, appData: String?, complete: @escaping (_ basicChatInfo: CCMBasicAIChatModeInfo?) -> Void)
}

/// AI主导航服务，打开分会话的入口
public protocol CCMAILaunchBarService {
    
    func getQuickLaunchBarAIItemInfo() -> BehaviorRelay<UIImage>
    
}


public struct CCMTranslateConfig {
    // 翻译的目标语言
    public let targetLanguage: String
    // 翻译的目标语言文案
    public let targetLanguageKey: String
    // CCM 文档自动翻译是否启用
    public let enableAutoTranslate: Bool

    public init(targetLanguage: String, targetLanguageKey: String, enableAutoTranslate: Bool) {
        self.targetLanguage = targetLanguage
        self.targetLanguageKey = targetLanguageKey
        self.enableAutoTranslate = enableAutoTranslate
    }
}

public protocol CCMTranslateService {

    var config: CCMTranslateConfig? { get }

    var configUpdated: Driver<CCMTranslateConfig> { get }

    var targetLanguage: String? { get }
    
    var targetLanguageKey: String? { get }
}
