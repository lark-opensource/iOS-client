//
//  MessageCardViewModel+Monitor.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/20.
//

import Foundation
import ECOProbeMeta
import ECOProbe
import LarkModel
import UniversalCardInterface
import LarkMessageCard
import LarkMessageBase

struct MonitorField {
    enum ActionTypeValue: Int {
        case url = 0
        case request = 1
    }
    enum RenderTypeValue: Int {
        case cardInit = 0
        case cardUpdate = 1
    }
    public static let TraceID = "trace_id"
    public static let MessageID = "message_id"
    public static let ImageID = "image_id"
    public static let ContentVersion = "content_version"
    public static let ContentLength = "content_length"
    public static let SetupTiming = "setup_timing"
    public static let ActionID = "action_id"
    public static let RequestID = "request_id"
    public static let ActionType = "action_type"
    public static let UrlLength = "url_length"
    public static let HttpCode = "http_code"
    public static let UnknownTags = "unknown_tags"
    public static let UnknownElements = "unknown_elements"
    public static let Version = "version"
    public static let RenderType = "render_type"
    public static let ElementsCount = "elements_count"
    public static let EventName = "op_open_card"
    public static let ErrorType = "error_type"
    public static let ErrorDomain = "error_domain"
    public static let TemplateVersion = "template_version"
    public static let ErrorStatus = "status"
    public static let CreateTraceID = "create_traceId"
    public static let RenderDuration = "render_duration"
    public static let LynxDuration = "lynx_duration"
    public static let CardDuraton = "card_duraton"
    public static let TTLogId = "log_id"
    public static let RenderBusinessType = "render_business_type"
    public static let Scene = "scene"
    public static let ActionTimestampDetail = "timestamp_detail"
    public static let ActionComponentTag = "component_tag"
    public static let SceneAttribute = "scene_attribute"
    public static let isFromTranslate = "is_from_translate"
    public static let CardID = "card_id"
    public static let BizID = "biz_id"
    public static let ElementType = "element_type"
    public static let IsUniversalCard = "is_universal_card"
    public static let BotID = "bot_id"
    public static let AppID = "app_id"
    public static let ApplicationID = "application_id"
}

typealias MessageCardTiming = (
    // 数据初始化时间点, 包含开始点和结束点, 执行在非主线程
    initCard: Date?, setupFinish: Date?,
    // 渲染时间点, 包含 template lynx 渲染时间, 执行在主线程
    renderStart: Date?, loadStart: Date?, loadFinish: Date?, renderFinish: Date?
)

class MessageCardMonitorCodeV2: OPMonitorCodeBase {
    public static let messagecard_create_view_finish = MessageCardMonitorCodeV2(
        domain: "client.open_platform.card",
        code: 10074,
        level: OPMonitorLevelNormal,
        message: "messagecard_create_view_finish"
    )
    
    public static let messagecard_render_start = MessageCardMonitorCodeV2(
        domain: "client.open_platform.card",
        code: 10078,
        level: OPMonitorLevelNormal,
        message: "messagecard_render_start"
    )
}

extension OPMonitor {
    func setCardError(_ error: MessageCardError) -> OPMonitor {
        return setErrorCode(String(error.errorCode))
            .setErrorMessage(error.errorMessage)
            .addCategoryValue(MonitorField.ErrorType, error.errorType)
            .addCategoryValue(MonitorField.ErrorDomain, error.domain)
   
    }
    
    func addCardTiming(timing: MessageCardTiming) -> OPMonitor {
        // 渲染完整耗时, 从 loadTemplate 开始算
        if let finish = timing.renderFinish, let start = timing.loadStart {
            addCategoryValue(MonitorField.RenderDuration, finish.timeIntervalSince(start) * 1000)
        }
        // lynx 渲染耗费的时间, 不算 loadtemplate
        if let finish = timing.renderFinish, let start = timing.loadFinish {
            addCategoryValue(MonitorField.LynxDuration, finish.timeIntervalSince(start) * 1000)
        }
        // 卡片完整耗时, 从创建 LynxView 开始算
        if let finish = timing.renderFinish, let start = timing.renderStart {
            addCategoryValue(MonitorField.CardDuraton, finish.timeIntervalSince(start) * 1000)
        }
        return self
    }
}

extension MessageCardFactory {
    func reportStart(message: Message, trace: OPTrace) {
        _createMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_initdata_prepare,
            trace: trace,
            message: message,
            content: nil,
            startTime: nil
        ).flush()
    }
}

extension MessageCardViewModel {
    func createMonitor(code: OPMonitorCodeProtocol,
                       context: MessageCardContainer.Context? = nil,
                       trace: OPTrace? = nil,
                       startTime: Date? = nil,
                       renderBusinessType: RenderBusinessType? = nil) -> OPMonitor {
        return _createMonitor(
                code: code,
                trace: trace ?? context?.trace ?? self.trace,
                message: message,
                content: content,
                startTime: startTime,
                renderBusinessType: renderBusinessType,
                scene: getMonitorScene(self.context.scene)
            ).addCategoryValue(MonitorField.TemplateVersion, context?.cardSDKVersion)
    }

    func createRenderMonitor(
        code: OPMonitorCodeProtocol,
        context: UniversalCardContext? = nil,
        startTime: Date? = nil
    ) -> OPMonitor {
        return _createMonitor(
                code: code,
                trace: context?.renderingTrace ?? context?.trace ?? self.trace,
                message: message,
                content: content,
                startTime: startTime,
                renderBusinessType: .message,
                scene: getMonitorScene(self.context.scene)
            )
        .addCategoryValue(MonitorField.TemplateVersion, context?.cardSDKVersion)
        .addCategoryValue(MonitorField.CardID, context?.sourceData?.cardID)
        .addCategoryValue(MonitorField.IsUniversalCard, true)
    }
    
    func trackUniversalCardRender(context: UniversalCardContext?) {
        let teaEventName = "openplatform_universal_card_view"
        let monitor = OPMonitor(teaEventName)
            .addCategoryValue(MonitorField.BizID, context?.sourceData?.bizID)
            .addCategoryValue(MonitorField.Scene, UniversalCardTrackScene.message.rawValue)
            .addCategoryValue(MonitorField.ApplicationID, context?.sourceData?.appInfo?.appID)
            .setPlatform(.tea)
        if let cardID = context?.sourceData?.cardID, let version = context?.sourceData?.version {
            monitor.addCategoryValue(MonitorField.CardID, "\(cardID)#\(version)")
        }
        monitor.flush()
    }

}

extension MessageCardActionServiceImpl {
    func createMonitor(
        code: OPMonitorCodeProtocol,
        trace: OPTrace?,
        startTime: Date? = nil,
        componentTag: String? = nil
    ) -> OPMonitor {
        _createMonitor(
            code: code,
            trace: trace ?? self.trace,
            message: message,
            content: cardContent,
            startTime: startTime,
            renderBusinessType: .message,
            scene: getMonitorScene(self.scene),
            componentTag: componentTag
        )
    }
}

extension MessageUniversalCardActionService: UniversalCardActionServiceMonitor {
    func createMonitor(
        code: OPMonitorCodeProtocol,
        trace: OPTrace,
        cardID: String? = nil,
        startTime: Date? = nil,
        componentTag: String? = nil
    ) -> OPMonitor {
        _createMonitor(
            code: code,
            trace: trace,
            message: message,
            content: message?.content as? CardContent,
            startTime: startTime,
            renderBusinessType: .message,
            scene: getMonitorScene(self.scene),
            componentTag: componentTag
        )
        .addCategoryValue(MonitorField.CardID, cardID)
        .addCategoryValue(MonitorField.IsUniversalCard, true)
    }
    
    func trackUniversalCardClick(
        actionType: UniversalCardTrackActionType,
        elementTag: String?,
        cardID: String?,
        url: String? = nil
    ) {
        let teaEventName = "openplatform_universal_card_click"
        let monitor = OPMonitor(teaEventName)
            .addCategoryValue(MonitorField.ActionType, actionType.rawValue)
            .addCategoryValue(MonitorField.ElementType, elementTag)
            .addCategoryValue(MonitorField.Scene, UniversalCardTrackScene.message.rawValue)
            .addCategoryValue(MonitorField.BizID, messageID)
        
            .setPlatform(.tea)
        
        if let cardID = cardID, let version = message?.contentVersion {
            monitor.addCategoryValue(MonitorField.CardID, "\(cardID)#\(version)")
        }
        if let url = url {
            url.setUrlMonitorCategoryValue(monitor: monitor)
        }
        monitor.flush()
    }
}

fileprivate func _createMonitor(
    code: OPMonitorCodeProtocol,
    trace: OPTrace,
    message: Message?,
    content: CardContent?,
    startTime: Date?,
    renderBusinessType: RenderBusinessType? = nil,
    scene: CardScene? = nil,
    componentTag: String? = nil
) -> OPMonitor {
    let monitor = OPMonitor(name: MonitorField.EventName, code: code)
        .tracing(trace)
        .addCategoryValue(MonitorField.MessageID, message?.id)
        .addCategoryValue(MonitorField.ContentLength, content?.jsonBody?.count)
        .addCategoryValue(MonitorField.ContentVersion, message?.contentVersion)
    if let start = startTime {
        monitor.setDuration(Date().timeIntervalSince(start))
    }
    if let renderBusinessType = renderBusinessType {
        monitor.addCategoryValue(MonitorField.RenderBusinessType, renderBusinessType.rawValue)
    }
    if let sceneStr = scene?.rawValue {
        monitor.addCategoryValue(MonitorField.Scene, sceneStr)
    }
    if let componentTag = componentTag {
        monitor.addCategoryValue(MonitorField.ActionComponentTag, componentTag)
    }
    monitor.addCategoryValue(MonitorField.BotID, content?.appInfo?.botID)
    monitor.addCategoryValue(MonitorField.AppID, content?.appInfo?.appID)

    return monitor
}

func getMonitorScene(_ messageScene: ContextScene?) -> CardScene {
    switch messageScene {
    case .newChat:
        return .chat
    case .messageDetail:
        return .quoteDetail
    case .replyInThread:
        return .replyInThread
    case .threadChat:
        return .threadChat
    case .threadDetail:
        return .threadDetail
    case .pin:
        return .pin
    default:
        return .defaultScene
    }
}

enum CardScene: String {
    case chat = "chat"
    case quoteDetail = "quoteDetail"
    case replyInThread = "replyInThread"
    case threadChat = "threadChat"
    case threadDetail = "threadDetail"
    case pin = "pin"
    case sendMessageCardPreview = "sendMessageCardPreview"
    case unPinPreview = "unPinPreview"
    case defaultScene = "default"
}


enum RenderBusinessType: String {
    case message = "message"
    case workspace = "workspace"
    case urlPreview = "url_preview"
}

struct SceneAttribute {
    var isEphemeral: Bool
    var isForward: Bool
    var translateState: String
    var isConfigCardLink: Bool
    var isMergeForward: Bool

    init(isEphemeral: Bool = false,
         isForward: Bool = false,
         translateState: String = "renderOriginal",
         isConfigCardLink: Bool = false,
         isMergeForward: Bool = false) {
        self.isEphemeral = isEphemeral
        self.isForward = isForward
        self.translateState = translateState
        self.isConfigCardLink = isConfigCardLink
        self.isMergeForward = isMergeForward
    }

    func toDic() -> [String: Any] {
        return ["is_ephemeral": isEphemeral.intValue,
                "is_forward": isForward.intValue,
                "is_config_card_link": isConfigCardLink.intValue,
                "is_merge_forward": isMergeForward.intValue,
                "translate_state": translateState]
    }
}
