//
//  MessageCardActionServiceImpl.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2022/11/15.
//

import Foundation
import RustPB
import LarkOpenPluginManager
import RxSwift
import LarkSDKInterface
import LarkContainer
import LarkModel
import LKCommonsLogging
import LarkMessageBase
import ByteViewInterface
import EEAtomic
import RoundedHUD
import EENavigator
import LarkNavigator
import LarkAccountInterface
import EEMicroAppSDK
import LarkAppLinkSDK
import LarkOPInterface
import LarkMessageCard
import NewLarkDynamic
import LarkRustClient
import LarkMessengerInterface
import LarkUIKit
import ECOProbe
import LarkSetting
import UniverseDesignToast

enum ActionError: Error {
    case urlInvalid
    case urlUnsupport
    case microAppWithoutTriggercode
    case internalError(String)
    case actionNotAllow
    case lastActionNotFinished
    case actionIDNil
    case requestError(Error)
    case requestTimeout
}

enum ActionErrorCode: Int {
    case networkError = 1
    case unKnownError = 2
    case customError = 100
}

typealias ActionToastCode = Openplatform_V1_PutUniversalCardActionResponse.Toast.TypeEnum

final class MessageCardActionServiceImpl: MessageCardActionService {
    
    private struct Config {
        static let openLinkInterval: TimeInterval = 0.5
    }
    
    static private let logger = Logger.oplog(MessageCardActionServiceImpl.self, category: "MessageCardActionServiceImpl")
    private let disposeBag = DisposeBag()
    
    @Injected private var microAppService: MicroAppService
    @Injected private var opService: OpenPlatformService
    @Injected private var rustService: RustService
    @InjectedOptional private var chatterAPI: ChatterAPI?

    @FeatureGatingValue(key: "universalcard.updatemessagelocaldata.enable")
    var enableUpdateLocalData: Bool

    private var urlAppendTriggerCode: (
        (String, String, @escaping (String) -> Void) -> Void
    )? { opService.urlWithTriggerCode }
    private var disposable: Disposable?
    
    public var trace: OPTrace
    public var actioningTrace: OPTrace?
    public var message: LarkModel.Message
    public var messageID: String { message.id }
    public var cardContent: LarkModel.CardContent? { message.content as? CardContent }
    private var cardType: LarkModel.CardContent.TypeEnum? { cardContent?.type }
    private var contextExtra: LarkModel.CardContent.ExtraType? { cardContent?.extra }
    private let pageContext: PageContext
    internal var scene: ContextScene {
        return pageContext.scene
    }
    private var actionFinished: Bool = true
    private var lastOpenLinkTime: Date?
    
    public let chat: () -> LarkModel.Chat
    public weak var handler: MessageCardActionEventHandler?

    // MARK: LifeCycle
    
    public init(
        message: LarkModel.Message,
        trace: OPTrace,
        pageContext: PageContext,
        chat: @escaping () -> LarkModel.Chat,
        handler: MessageCardActionEventHandler
    ) {
        self.message = message
        self.trace = trace
        self.pageContext = pageContext
        self.chat = chat
        self.handler = handler
        self.registerPushCmd()
    }
    
    private func registerPushCmd() {
        disposable = rustService.register(pushCmd: Basic_V1_Command.pushCardActionUpdateTimeout) {
            [weak self] data, _ in
            guard let self = self else {
                Self.logger.error("Action timeout but self is release ")
                return
            }
            guard let notify = try? Im_V2_CardActionUpdateTimeoutNotify(serializedData: data),
                  notify.messageID == self.messageID && notify.contentVersion == self.message.contentVersion else { return }
            self.handler?.actionTimeout()
            Self.logger.info("SendAction timeout", additionalData: ["messageID": self.messageID, "traceID": self.trace.traceId])
            self.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_time_out, trace: self.actioningTrace)
                .setError(ActionError.requestTimeout)
                .flush()
        }
    }
    
    
    public func update(message: LarkModel.Message) {
        self.message = message
    }
    
    // MARK: Message Card Action
    
    
    public func fetchUsers(ids: [String], callback: @escaping (Error?, [String: MessageCardPersonInfo]?) -> Void) {
        var personInfos: [String : MessageCardPersonInfo] = [:]
        chatterAPI?.getChatters(ids: ids).subscribe(
            onNext: { chatters in
                chatters.forEach { (key: String, value: Chatter) in
                    personInfos[key] = MessageCardPersonInfo(
                        name: value.name,
                        avatarKey: value.avatarKey
                    )
                }
                callback(nil, personInfos)
            },
            onError: { error in
                callback(error, nil)
            }
        ).disposed(by: disposeBag)
    }

    // opeurl 类 Action
    public func openUrl(context: MessageCardActionContext, urlStr: String?) {
        let trace = trace.subTrace()
        guard let urlStr = urlStr, let url = self.possibleURL(urlStr) else {
            Self.logger.error("OpenUrl with invalid urlStr", additionalData: ["messageID": messageID, "traceID": trace.traceId])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: trace,
                          componentTag: context.elementTag)
                .setError(ActionError.urlInvalid)
                .flush()
            return
        }
        guard !url.absoluteString.lowercased().hasPrefix("lark://msgcard/unsupported_action") else {
            showToast(context: context, type: .info, text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardUnsupportedActionMobile)
            Self.logger.info("OpenUrl with unsupported link", additionalData: ["messageID": messageID, "traceID": trace.traceId])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: trace,
                          componentTag: context.elementTag)
                .setError(ActionError.urlUnsupport)
                .flush()
            return
        }
        
        if microAppService.canOpen(url: url.absoluteString){
            openMicroApp(trace: trace, context: context, url: url)
        } else {
            openLink(trace: trace, context: context, url: url)
        }
        
    }
    
    public func updateLocalData(
        context: MessageCardActionContext,
        cardID: String,
        version: String,
        data: String,
        callback: @escaping (Error?, CardVersion?, CardStatus?) -> Void) {
            let trace = trace.subTrace()
            Self.logger.info("UpdateLocalData with cardID: \(cardID) version: \(version)", additionalData: ["traceID": trace.traceId])
            var request = Openplatform_V1_UpdateMessageCardLocalDataRequest()
            request.messageID = cardID
            request.version = version
            request.jsonDeltaData = data
            if enableUpdateLocalData {
                updateMessageLocalStatus(version: version, data: data)
                handler?.dataSynchronization()
            }
            rustService.sendAsyncRequest(request).subscribe(
                onNext: { (res: Openplatform_V1_UpdateMessageCardLocalDataResponse) in
                    Self.logger.info("UpdateLocalData success cardVersion:\(res.version), jsonData: \(res.jsonData)", additionalData: ["traceID": trace.traceId])
                    callback(nil, res.version, res.jsonData)
                },
                onError: { error in
                    var errorInfo: BusinessErrorInfo?
                    if case let .businessFailure( info) = error as? RCError {
                        errorInfo = info
                    }
                    Self.logger.info("UpdateLocalData fail error code:\(errorInfo?.errorCode) debugMessage: \(errorInfo?.debugMessage)", additionalData: ["traceID": trace.traceId])
                    callback(error, nil, nil)
                }).disposed(by: self.disposeBag)
    }
    
    // Request 类 Action
    public func sendAction(
        context: MessageCardActionContext,
        actionID: String,
        params: [String: String]? = nil,
        isMultiAction: Bool,
        updateActionState:((ActionState) -> Void)?,
        callback:((Error?, MessageCardRequestResultType?) -> Void)?
    ) {
        let trace = trace.subTrace()
        actioningTrace = trace
        Self.logger.info("SendAction with actionID: \(actionID)", additionalData: ["messageID": messageID, "traceID": trace.traceId])
        guard !(isMe(message.fromId) && contextExtra == .senderCannotClick) else {
            showToast(context: context, type: .info, text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardUnsupportedActionMobile)
            Self.logger.error("SendAction fail: action not allow", additionalData: ["messageID": messageID, "actionID": actionID])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_not_allow, trace: trace)
                .setError(ActionError.actionNotAllow)
                .flush()
            return
        }
        
        guard self.actionFinished else {
            Self.logger.info(
                "SendAction fail: last action not finished, skip send action",
                additionalData: ["messageID": messageID, "actionID": actionID]
            )
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_not_allow, trace: trace)
                .setError(ActionError.lastActionNotFinished)
                .flush()
            return
        }
        
        guard !actionID.isEmpty else {
            Self.logger.info("SendAction fail: actionID is nil", additionalData: ["messageID": messageID, "actionID": actionID])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_data_error, trace: trace)
                .setError(ActionError.actionIDNil)
                .flush()
            return
        }
        let startTime = Date()
        Self.logger.info("SendAction will send rust request")
        actionFinished = false
        
        var request = RustPB.Im_V2_PutActionRequest()
        request.actionID = actionID
        request.messageID = messageID
        request.isEphemeral = message.isEphemeral
        if let params = params { request.params = params }
        request.contentVersion = message.contentVersion
        
        let actionService = self
        rustService.async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<Im_V2_PutActionResponse>) in
            switch responsePacket.result {
            case .success(let res):
                actionService.handler?.actionSuccess()
                actionService.actionFinished = true
                actionService.dealWithActionResponseToast(context: context, res: res)
                if res.method != .none {
                    updateActionState?(.actionFinish)
                }
                callback?(nil, res.method == .none ? .FinishedWaitUpdate : .RequestFinished)
                Self.logger.info("SendAction success", additionalData: ["messageID": actionService.messageID, "actionID": actionID])
                actionService.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_success,
                                            trace: trace,
                                            startTime: startTime,
                                            componentTag: context.elementTag)
                .addCategoryValue(MonitorField.ActionID, [actionID])
                .addCategoryValue(MonitorField.ActionTimestampDetail, res.timestampDetail)
                .flush()
                actionService.reportAction(actionType: .interaction, elementTag: context.elementTag)
            case .failure(let error):
                actionService.handler?.actionFail(error)
                actionService.actionFinished = true
                //复合交互action忽略失败
                if !isMultiAction {
                    actionService.showToast(context: context, type: .error, text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardFail)
                }
                Self.logger.error(
                    "recived send action callback",
                    additionalData: [ "messageID": actionService.messageID, "actionID": actionID],
                    error: error
                )
                var errorInfo: BusinessErrorInfo?
                if case let .businessFailure( info) = error as? RCError {
                    errorInfo = info
                }
                callback?(error, .RequestFinished)
                updateActionState?(.actionFinish)
                actionService.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_network_error,
                                            trace: trace,
                                            startTime: startTime,
                                            componentTag: context.elementTag)
                .setErrorCode(String(errorInfo?.errorCode ?? 0))
                .setErrorMessage(errorInfo?.debugMessage ?? error.localizedDescription)
                .addCategoryValue(MonitorField.ActionID, [actionID])
                .addCategoryValue(MonitorField.ErrorStatus, errorInfo?.errorStatus)
                .addCategoryValue(MonitorField.TTLogId, errorInfo?.ttLogId)
                .flush()
            }
        }
    }
    
    // 打开用户个人信息页面
    public func openProfile(context: MessageCardActionContext, chatterID: String) {
        guard let targetVC = pageContext.pageAPI else {
            Self.logger.error("openProfile with wrong PageContext, pageAPI is nil")
            return
        }
        
        let body = PersonCardBody(chatterId: chatterID, chatId: chat().id, source: .chat)
        Navigator.shared.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }
    
    public func openCodeBlockDetail(context: MessageCardActionContext, property: Basic_V1_RichTextElement.CodeBlockV2Property) {
        guard let targetVC = pageContext.pageAPI else {
            Self.logger.error("openCodeBlockDetail with wrong PageContext, pageAPI is nil")
            return
        }
        
        let body = CodeDetailBody(property: property)
        Navigator.shared.present(body: body, from: targetVC)
    }
    
    // MARK: Private
    
    // 打开小程序
    private func openMicroApp(trace: OPTrace, context: MessageCardActionContext, url: URL) {
        Self.logger.info("openMicroApp url with type: \(context)")
        guard let urlAppendTriggerCode = urlAppendTriggerCode else {
            Self.logger.info("openMicroApp url fail: urlAppendTriggerCode is nil")
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_without_triggercode,
                          trace: trace,
                          componentTag: context.elementTag)
                .setError(ActionError.microAppWithoutTriggercode)
                .flush()
            self.openLink(trace: trace, context: context, url: url)
            return
        }
        
        urlAppendTriggerCode(url.absoluteString, self.messageID) { [weak self] (urlWithCodeStr) in
            guard let self = self else {
                Self.logger.error("openMicroApp url fail self is nil")
                return
            }
            
            self.openLink(trace: trace, context: context, url: url)
            
            // 拼接后的字符串与处理前一样,则证明拼接失败(这个设计不好, 从老逻辑照搬, 待重构)
            if urlWithCodeStr == url.absoluteString {
                self.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_without_triggercode,
                                   trace: trace,
                                   componentTag: context.elementTag)
                    .setError(ActionError.microAppWithoutTriggercode)
                    .flush()
            }
        }
    }
    
    // 打开链接
    private func openLink(trace: OPTrace, context: MessageCardActionContext, url: URL) {
        Self.logger.info("openLink with url: \(String(describing: url.host)), context: \(context)")
        guard let httpUrl = url.lf.toHttpUrl() else {
            Self.logger.error("openLink open link with invalid url \(url.safeURLString)")
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: trace,
                          componentTag: context.elementTag)
                .setError(ActionError.urlInvalid)
                .flush()
            return
        }
        guard let targetVC = self.pageContext.pageAPI else {
            Self.logger.error("openLink fail because pageAPI is nil")
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_unsupport,
                          trace: trace,
                          componentTag: context.elementTag)
                .setError(ActionError.internalError("pageAPI is nil"))
                .flush()
            return
        }
        
        if let lastOpenTime = lastOpenLinkTime, Date().timeIntervalSince(lastOpenTime) < Self.Config.openLinkInterval {
            Self.logger.info("openLink interval limit", additionalData: ["url": url.safeURLString])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_url_open_url_limt_interval,
                          trace: trace,
                          componentTag: context.elementTag)
                .setError(ActionError.internalError("interval limit"))
                .flush()
            return
        }
        
        let fromContext = linkFromContext(type: context.actionFrom)
        Self.logger.info("openLink success", additionalData: ["url": url.safeURLString])
        createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_open_url_success,
                      trace: trace,
                      componentTag: context.elementTag)
            .flush()
        DispatchQueue.main.async { Navigator.shared.push(httpUrl, context: fromContext, from: targetVC) }
        lastOpenLinkTime = Date()
        reportAction(actionType: .openLink, elementTag: context.elementTag, url: url.absoluteString)
    }
    
    // Link 的 Context 生成逻辑
    // 此代码抄自 CardContext, 存在历史包袱请勿随意修改
    private func linkFromContext(type: MessageCardLinkFromType?) -> [String: String] {
        let chatInfo = chat()
        var fromContext = [String: String]()
        
        switch type {
        case .cardLink:
            if chatInfo.chatMode == .threadV2 {
                fromContext = [FromSceneKey.key: FromScene.topic_cardlink.rawValue]
            } else {
                switch chatInfo.type {
                case .p2P:
                    fromContext = [FromSceneKey.key: FromScene.single_cardlink.rawValue]
                case .group, .topicGroup:
                    fromContext = [FromSceneKey.key: FromScene.multi_cardlink.rawValue]
                @unknown default:
                    assert(false, "new value")
                }
            }
            fromContext["scene"] = "messenger"
            fromContext["location"] = "messenger_chat_shared_link_card"
        case .innerLink:
            if chatInfo.chatMode == .threadV2 {
                fromContext = [FromSceneKey.key: FromScene.topic_innerlink.rawValue]
            } else {
                switch chatInfo.type {
                case .p2P:
                    fromContext = [FromSceneKey.key: FromScene.single_innerlink.rawValue]
                case .group, .topicGroup:
                    fromContext = [FromSceneKey.key: FromScene.multi_innerlink.rawValue]
                @unknown default:
                    assert(false, "new value")
                }
            }
        case .footerLink:
            fromContext = [FromSceneKey.key: FromScene.app_flag_cardlink.rawValue]
        case .none: break
        }
        return fromContext
    }
    
    // 强制转换 URL String -> URL, 符合 RFC 协议
    private func possibleURL(_ urlStr: String) -> URL? {
        do {
            return try URL.forceCreateURL(string: urlStr)
        } catch let error {
            Self.logger.error("forceCreateURL fail with error:\(error)")
            return nil
        }
    }
    
    public func showToast(context: MessageCardActionContext, type: UDToastType, text: String, on view: UIView? = nil) {
        DispatchQueue.main.async {
            guard let targetView = view ?? Navigator.shared.mainSceneWindow?.fromViewController?.view else {
                Self.logger.error("showToast fail: targetView is nil")
                return
            }
            let toastConfig = UDToastConfig(toastType: type, text: text, operation: nil)
            UDToast.showToast(with: toastConfig, on: targetView)
        }
        // 对于转发消息,点击后需要立刻埋点
        // TODO: 目前由于 lynx 侧没开埋点口, 但转发是在 lynx 处理的,所以通过 toast 埋点 后续整体优化埋点时统一处理.
        if text == BundleI18n.LarkOpenPlatform.Lark_Legacy_forwardCardToast {
            reportAction(actionType: .interaction, elementTag: context.elementTag)
        }
        
    }
    
    private func dealWithActionResponseToast(context: MessageCardActionContext, res: Im_V2_PutActionResponse) {
        Self.logger.info("dealWithActionResponseToast, hasContent: \(res.hasToast && res.toast.hasContent)")
        guard res.hasToast, res.toast.hasContent, !res.toast.content.isEmpty else {
            return
        }
        var type = UDToastType.info
        switch Int(res.toast.code) {
        case ActionToastCode.success.rawValue:
            type = .success
        case ActionToastCode.error.rawValue:
            type = .error
        case ActionToastCode.info.rawValue:
            type = .info
        case ActionToastCode.warning.rawValue:
            type = .warning
        default:
            break
        }
        showToast(context: context, type: type, text: res.toast.content)
    }
    
    // 判断是否是当前登录用户
    private func isMe(_ chatterID: String) -> Bool {
        return AccountServiceAdapter.shared.currentChatterId == chatterID
    }

    //请求更新rust localStatus，没有使用needPush，导致内存中的message的localStatus不是最新，折叠面板状态同步有问题
    //这里手动merge内存态message的localStatus
    private func updateMessageLocalStatus(version: String, data: String) {
        let localStorageKey = Int32(Basic_V1_MessageLocalDataInfo.BusinessKey.openPlatformMessageCard.rawValue)
        //需要merge的status全集
        var updateStatus: [String: Any] = [:]
        //获取当前更新的版本的status
        guard let newStatusJsonData = data.data(using: .utf8),
              let newStatus = try? JSONSerialization.jsonObject(with: newStatusJsonData, options: []) as? [String: Any] else {
            Self.logger.error("update message localStatus failed:  data is error \(data)")
            return
        }
        do {
            //当已经有localStatus时做merge
            if let jsonData = self.message.localData?.data[localStorageKey]?.jsonDataString.data(using: .utf8),
               var status = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                updateStatus = status
            }
            //更新当前版本内容
            updateStatus[version] = newStatus
            let newJsonData = try JSONSerialization.data(withJSONObject: updateStatus, options: [])
            if let newJsonString = String(data: newJsonData, encoding: .utf8) {
                var cardLocalData = Basic_V1_MessageLocalData()
                cardLocalData.jsonDataString = newJsonString
                if self.message.localData == nil {
                   self.message.localData = Basic_V1_MessageLocalDataInfoMap()
                }
                self.message.localData?.data[localStorageKey] = cardLocalData
            }
        } catch {
            Self.logger.error("update message localStatus failed: \(self.message.id)")
        }
    }
}



