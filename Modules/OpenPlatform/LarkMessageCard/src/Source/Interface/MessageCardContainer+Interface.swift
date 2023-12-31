//
//  MessageCardInterface.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/9.
//

import Foundation
import LarkModel
import ECOProbe
import UniverseDesignToast
import LarkMessageBase
import EEAtomic
import RustPB
import UniversalCardInterface

public protocol MessageCardActionEventHandler: AnyObject {
    func actionSuccess()
    func actionFail(_ error: Error)
    func actionTimeout()
    func dataSynchronization()
}

public enum MessageCardLinkFromType {
    case cardLink(reason: String? = nil)
    case innerLink(reason: String? = nil)
    case footerLink(reason: String? = nil)
    
    public func reason() -> String? {
        switch self {
        case .cardLink(let reason):
            return reason
        case .innerLink(let reason):
            return reason
        case .footerLink(let reason):
            return reason
        default:
            return nil
        }
    }
}

public enum ActionState: String {
    case actionStart = "ActionStart"
    case actionFinish = "ActionFinish"
}

public struct MessageCardActionContext {
    public var elementTag: String?
    public var elementID: String?
    public var bizContext: Any?
    public var actionFrom: MessageCardLinkFromType?
}

public struct MessageCardPersonInfo {
    public let name: String
    public let avatarKey: String
    public init(name: String, avatarKey: String) {
        self.name = name
        self.avatarKey = avatarKey
    }
}

public enum MessageCardRequestResultType: String {
    case RequestFinished = "requestFinished"
    case FinishedWaitUpdate = "finishedWaitUpdate"
}

// FIXME: 发布前改造, 本文件名字
public protocol MessageCardActionService {
    typealias CardVersion = String
    typealias CardStatus = String
    var handler: MessageCardActionEventHandler? { get }
    // 强业务形态字段, 预期是要删掉的, 改为其他业务属性不那么强的形式
    var chat: () -> Chat { get }
    // 打开链接
    func openUrl(context: MessageCardActionContext, urlStr: String?)
    // TODO: 待优化,这个地方的 updateActionState 和 isMultiAction 都是业务参数. 实际上需要的是个 callback
    func sendAction(
        context: MessageCardActionContext,
        actionID: String,
        params: [String: String]?,
        isMultiAction: Bool,
        updateActionState:((ActionState) -> Void)?,
        callback:((Error?, MessageCardRequestResultType?) -> Void)?
    )
    // 打开用户 profile 页面
    func openProfile(context: MessageCardActionContext, chatterID: String)
    // 存储本地数据
    func updateLocalData(
        context: MessageCardActionContext,
        cardID: String,
        version: String,
        data: String,
        callback: @escaping (Error?, CardVersion?, CardStatus?) -> Void)
    func showToast(context: MessageCardActionContext, type: UDToastType, text: String, on view: UIView?)
    
    func fetchUsers(ids: [String], callback: @escaping (Error?, [String: MessageCardPersonInfo]?) -> Void)
    
    func openCodeBlockDetail(context: MessageCardActionContext, property: Basic_V1_RichTextElement.CodeBlockV2Property)
}

public protocol MessageCardContainerDependency: AnyObject {
    // 消息卡片跳转用的源 VC
    var sourceVC: UIViewController? { get }
    
    // 消息卡片事件服务
    var actionService: MessageCardActionService? { get }
}

public protocol MessageCardContainerLifeCycle: AnyObject {
    // 开始执行渲染流程(切入主线程, 准备 loadTemplate)
    func didStartRender(context: MessageCardContainer.Context)
    // 容器开始准备加载模板 (load_template开始时的回调)
    func didStartLoading(context: MessageCardContainer.Context)
    // 容器加载模板完毕 (load_template 结束后的回调，可认为完全加载完成)
    func didLoadFinished(context: MessageCardContainer.Context)
    // 消息卡片首屏渲染完成 (Lynx 首屏渲染完成)
    func didFinishRender(context: MessageCardContainer.Context, info: [AnyHashable : Any]?)
    // 消息卡片渲染错误(包含 lynx 错误)
    func didReceiveError(context: MessageCardContainer.Context, error: MessageCardError)
    // 收到更新 ContentSize 通知
    func didUpdateContentSize(context: MessageCardContainer.Context, size: CGSize?)
    // 消息卡片渲染刷新
    func didFinishUpdate(context: MessageCardContainer.Context, info: [AnyHashable : Any]?)
}

public enum RenderType: String {
    case renderOriginal = "renderOriginal" //不展示翻译效果
    case renderTranslation = "renderTranslation" //只展示译文
    case renderOriginalWithTranslation = "renderOriginalWithTranslation" //展示原文合译文
}

public struct TranslateInfo {
    let localeLanguage: String
    let translateLanguage: String
    let renderType: RenderType
    
    public init(localeLanguage: String, translateLanguage: String, renderType: RenderType) {
        self.localeLanguage = localeLanguage
        self.translateLanguage = translateLanguage
        self.renderType = renderType
    }
    
    public func toDict() -> [String: AnyHashable] {
        [
            "translateLanguage": translateLanguage,
            "renderType": renderType.rawValue
        ]
    }
}

public struct I18nText: Encodable {
    var translationText: String = ""
    var imageTagText: String = ""
    var cancelText: String = ""
    var textLengthError: String = ""
    var inputPlaceholder: String = ""
    var requiredErrorText: String = ""
    var chartLoadError: String = ""
    var chartTagText: String = ""
    var tableTagText: String = ""
    var tableEmptyText: String = ""
    var cardFallbackText: String = ""
    
    public init(
        translationText: String? = nil,
        imageTagText: String? = nil,
        cancelText: String? = nil,
        textLengthError: String? = nil,
        inputPlaceholder: String? = nil,
        requiredErrorText: String? = nil,
        chartLoadError: String? = nil,
        chartTagText: String? = nil,
        tableTagText: String? = nil,
        tableEmptyText: String? = nil,
        cardFallbackText: String? = nil
    ) {
        self.translationText = translationText ?? ""
        self.imageTagText = imageTagText ?? ""
        self.cancelText = cancelText ?? ""
        self.textLengthError = textLengthError ?? ""
        self.inputPlaceholder = inputPlaceholder ?? ""
        self.requiredErrorText = requiredErrorText ?? ""
        self.chartLoadError = chartLoadError ?? ""
        self.chartTagText = chartTagText ?? ""
        self.tableTagText = tableTagText ?? ""
        self.tableEmptyText = tableEmptyText ?? ""
        self.cardFallbackText = cardFallbackText ?? ""
    }
}

public extension MessageCardContainer {
    typealias CardContent = (
        origin: LarkModel.CardContent,
        translate: LarkModel.CardContent?
    )
    
    public static let Tag = "MessageCard"

    //context的数据封装
    public struct ContextData {
        var trace: OPTrace
        let bizContext: [AnyHashable: Any]
        let actionContext: CardActionContextProtocol?
        let dependency: MessageCardContainerDependency?
        let host: String?
        let deliveryType: String?

        public init(trace: OPTrace,
                    bizContext: [AnyHashable: Any],
                    dependency: MessageCardContainerDependency?,
                    actionContext: CardActionContextProtocol? = nil,
                    host: String?,
                    deliveryType: String?) {
            self.trace = trace
            self.bizContext = bizContext
            self.actionContext = actionContext
            self.dependency = dependency
            self.host = host
            self.deliveryType = deliveryType
        }
    }
    //container的数据封装
    public struct ContainerData {
        public var cardID: String
        public var version: String
        public var localStatus: String
        public var content: CardContent
        public var contextData: ContextData
        public var config: Config
        public var translateInfo: TranslateInfo

        public init(
            cardID: String,
            version: String,
            content: CardContent,
            localStatus: String,
            contextData: ContextData,
            config: Config,
            translateInfo: TranslateInfo
        ) {
            self.cardID = cardID
            self.version = version
            self.content = content
            self.localStatus = localStatus
            self.contextData = contextData
            self.config = config
            self.translateInfo = translateInfo
        }
    }

    public final class Context {
        @AtomicObject
        public var key: String
        @AtomicObject
        public var trace: OPTrace
        public private(set) var renderTrace: OPTrace
        public private(set) var cardSDKVersion: String?
        @AtomicObject
        public var dependency: MessageCardContainerDependency?
        @AtomicObject
        public var bizContext: [AnyHashable: Any]
        @AtomicObject
        public var actionContext: CardActionContextProtocol?
        @AtomicObject
        public var host: String?
        @AtomicObject
        public var deliveryType: String?

        // bizContext 多线程安全
        let lock: NSLock = NSLock()
        public func getBizContext(key: AnyHashable) -> Any {
            lock.lock()
            defer { lock.unlock() }
            return  bizContext[key]
        }
        public func setBizContext(key: AnyHashable, value: Any) {
            lock.lock()
            defer { lock.unlock() }
            bizContext[key] = value
        }
        
        // 消息卡片支持复制组件的baseKey
        let msgCardCopyableBaseKey = "msgCardCopyableBaseKey"
        var copyNum = 0
        
        public func getCopyableComponentKey() -> String{
            copyNum += 1
            return msgCardCopyableBaseKey + String(copyNum)
        }
        
        public init(
            trace: OPTrace,
            dependency: MessageCardContainerDependency?,
            bizContext: [AnyHashable: Any],
            actionContext: CardActionContextProtocol? = nil,
            host: String? = nil,
            deliveryType: String? = nil
        ) {
            self.key = trace.traceId
            self.trace = trace
            self.bizContext = bizContext
            self.actionContext = actionContext
            self.dependency = dependency
            self.renderTrace = trace.subTrace()
            self.host = host
            self.deliveryType = deliveryType
        }

        public convenience init(_ contextData: ContextData) {
            self.init(trace: contextData.trace,
                      dependency: contextData.dependency,
                      bizContext: contextData.bizContext,
                      actionContext: contextData.actionContext,
                      host:contextData.host,
                      deliveryType: contextData.deliveryType)
        }

        public func update(_ contextData: ContextData) {
            self.key = contextData.trace.traceId
            self.trace = contextData.trace
            self.bizContext = contextData.bizContext
            self.actionContext = contextData.actionContext
            self.dependency = contextData.dependency
            self.host = contextData.host
            self.deliveryType = contextData.deliveryType
        }
        
        func updateRnederTrace() {
            renderTrace = trace.subTrace()
        }
        
        func updateSDKVersion(_ version: String) {
            cardSDKVersion = version
        }
    }
    
    public struct Config {
        var perferWidth: CGFloat
        var perferHeight: CGFloat?
        var maxHeight: CGFloat?
        let isWideMode: Bool
        let showTranslateMargin: Bool
        let showCardBGColor: Bool
        let showCardBorderRadius: Bool
        let actionEnable: Bool
        // FIXME: 二期改造
        // 这个属于业务字段, 要放在这吗
        let isForward: Bool
        let i18nText: I18nText
        
        public init(
            perferWidth: CGFloat,
            perferHeight: CGFloat? = nil,
            maxHeight: CGFloat? = nil,
            isWideMode: Bool,
            actionEnable: Bool,
            showCardBGColor: Bool = true,
            showCardBorderRadius: Bool = false,
            showTranslateMargin: Bool = false,
            isForward: Bool,
            i18nText: I18nText
        ) {
            self.perferWidth = perferWidth
            self.perferHeight = perferHeight
            self.maxHeight = maxHeight
            self.isWideMode = isWideMode
            self.actionEnable = actionEnable
            self.showTranslateMargin = showTranslateMargin
            self.showCardBorderRadius = showCardBorderRadius
            self.showCardBGColor = showCardBGColor
            self.isForward = isForward
            self.i18nText = i18nText
        }
    }
    
    
    static func create(
        cardID: String,
        version: String,
        content: CardContent,
        localStatus: String,
        config: Config,
        context: Context,
        lifeCycleClient: MessageCardContainerLifeCycle? = nil,
        translateInfo: TranslateInfo,
        targetElement: [String: Any]? = nil
    ) -> MessageCardContainer {
        return MessageCardContainer(
            cardID: cardID,
            version: version,
            content: content,
            localStatus: localStatus,
            config: config,
            context: context,
            lifeCycleClient: lifeCycleClient,
            translateInfo: translateInfo,
            targetElement: targetElement
        )
    }

    public static func create(_ cardContainerData: MessageCardContainer.ContainerData) -> MessageCardContainer {
        return MessageCardContainer(
            cardID: cardContainerData.cardID,
            version: cardContainerData.version,
            content: cardContainerData.content,
            localStatus: cardContainerData.localStatus,
            config: cardContainerData.config,
            context: Context(cardContainerData.contextData),
            lifeCycleClient: nil,
            translateInfo: cardContainerData.translateInfo
        )
    }
}
