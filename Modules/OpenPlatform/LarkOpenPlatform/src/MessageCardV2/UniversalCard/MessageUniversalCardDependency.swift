//
//  MessageUniversalCardDependency.swift
//  LarkOpenPlatform
//
//  Created by zhujingcheng on 10/19/23.
//

import Foundation
import UniversalCard
import RustPB
import LKCommonsLogging
import UniverseDesignToast
import LarkModel
import LarkAccountInterface
import LarkRustClient
import RxSwift
import LarkMessageBase
import ECOProbe
import LarkContainer
import UniversalCardInterface
import LarkSetting

final class MessageUniversalCardDependencyImpl: UniversalCardDependencyProtocol {
    let userResolver: LarkContainer.UserResolver?
    // im 框架内要求的常量值
    var copyableKeyPrefix: String = "msgCardCopyableBaseKey"
    var actionService: UniversalCardActionServiceProtocol?
    
    init(userResolver: LarkContainer.UserResolver?, actionDependency: MessageUniversalCardDependency?) {
        self.userResolver = userResolver
        self.actionService = MessageUniversalCardActionService(dependency: actionDependency)
    }
}

final class MessageUniversalCardActionService: UniversalCardActionServiceProtocol {
    private static let logger = Logger.oplog(MessageUniversalCardActionService.self, category: "MessageUniversalCardActionService")
    private weak var dependency: MessageUniversalCardDependency?
    private lazy var serviceImpl: UniversalCardActionServiceImpl = {
       return UniversalCardActionServiceImpl(userResolver: dependency?.userResolver, dependency: dependency, monitor: self, logger: Self.logger)
    }()
    private var rustService: RustService?
    private var accountService: PassportUserService?
    private var cardModuleDependency: UniversalCardModuleDependencyProtocol?
    
    private var actionFinished: Bool = true
    private let disposeBag = DisposeBag()
    private var disposable: Disposable?
    private var actioningTrace: OPTrace?
    private var contextExtra: CardContent.ExtraType? { (message?.content as? CardContent)?.extra }

    @FeatureGatingValue(key: "universalcard.updatemessagelocaldata.enable")
    var enableUpdateLocalData: Bool

    var message: LarkModel.Message? { dependency?.message }
    var messageID: String { message?.id ?? "" }
    var scene: ContextScene? { dependency?.scene }
    var templateVersion: String? { cardModuleDependency?.templateVersion }
    var summary: String?
    var translateSummary: String?

    init(dependency: MessageUniversalCardDependency?) {
        self.dependency = dependency
        rustService = try? dependency?.userResolver?.resolve(assert: RustService.self)
        accountService = try? dependency?.userResolver?.resolve(assert: PassportUserService.self)
        cardModuleDependency = try? dependency?.userResolver?.resolve(assert: UniversalCardModuleDependencyProtocol.self)
        self.registerPushCmd()
    }

    private func registerPushCmd() {
        disposable = rustService?.register(pushCmd: Basic_V1_Command.pushCardActionUpdateTimeout) {
            [weak self] data, _ in
            guard let self = self else {
                Self.logger.error("Action timeout but self is release ")
                return
            }
            guard let notify = try? Im_V2_CardActionUpdateTimeoutNotify(serializedData: data), let message = message,
                  notify.messageID == message.id && notify.contentVersion == message.contentVersion else { return }
            self.dependency?.actionTimeout()
            Self.logger.error("SendAction timeout", additionalData: ["messageID": message.id, "traceID": self.actioningTrace?.traceId ?? ""])
            self.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_time_out, trace: self.actioningTrace ?? OPTraceService().generateTrace())
                .setError(ActionError.requestTimeout)
                .flush()
        }
    }

    func openUrl(context: UniversalCardActionContext, cardID: String?, urlStr: String?, from: UIViewController, callback: ((Error?) -> Void)?) {
        serviceImpl.openUrl(context: context, id: cardID, urlStr: urlStr, from: from, callback: callback)
    }
    
    func sendRequest(context: UniversalCardActionContext, cardSource: UniversalCardDataActionSourceInfo, actionID: String, params: [String : String]?, callback: ((Error?, UniversalCardRequestResultType?) -> Void)?) {
        actioningTrace = context.trace
        Self.logger.info("SendAction with actionID: \(actionID)", additionalData: ["messageID": messageID, "traceID": context.trace.traceId])
        guard !(isMe() && contextExtra == .senderCannotClick) else {
            showToast(context: context, type: .info, text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardUnsupportedActionMobile)
            Self.logger.error("SendAction fail: action not allow", additionalData: ["messageID": messageID, "actionID": actionID])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_not_allow, trace: context.trace, cardID: messageID)
                .setError(ActionError.actionNotAllow)
                .flush()
            return
        }
        
        guard actionFinished else {
            Self.logger.info(
                "SendAction fail: last action not finished, skip send action",
                additionalData: ["messageID": messageID, "actionID": actionID]
            )
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_not_allow, trace: context.trace, cardID: messageID)
                .setError(ActionError.lastActionNotFinished)
                .flush()
            return
        }
        
        guard !actionID.isEmpty else {
            Self.logger.info("SendAction fail: actionID is nil", additionalData: ["messageID": messageID, "actionID": actionID])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_data_error, trace: context.trace, cardID: messageID)
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
        request.isEphemeral = message?.isEphemeral ?? false
        if let params = params { request.params = params }
        request.contentVersion = message?.contentVersion ?? 0
        
        let actionService = self
        rustService?.async(RequestPacket(message: request)) { [weak self] (responsePacket: ResponsePacket<Im_V2_PutActionResponse>) in
            switch responsePacket.result {
            case .success(let res):
                actionService.actionFinished = true
                actionService.dealWithActionResponseToast(context: context, res: res)
                callback?(nil, res.method == .none ? .FinishedWaitUpdate : .RequestFinished)
                Self.logger.info("SendAction success", additionalData: ["messageID": actionService.messageID, "actionID": actionID])
                actionService.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_success,
                                            trace: context.trace,
                                            cardID: actionService.messageID,
                                            startTime: startTime,
                                            componentTag: context.elementTag)
                .addCategoryValue(MonitorField.ActionID, [actionID])
                .addCategoryValue(MonitorField.ActionTimestampDetail, res.timestampDetail)
                .flush()
                actionService.trackUniversalCardClick(actionType: .interaction, elementTag: context.elementTag, cardID: actionService.messageID)
            case .failure(let error):
                self?.actioningTrace = nil
                actionService.actionFinished = true
                actionService.showToast(context: context, type: .error, text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardFail)
                Self.logger.error(
                    "recived send action callback",
                    additionalData: ["messageID": actionService.messageID, "actionID": actionID],
                    error: error
                )
                var errorInfo: BusinessErrorInfo?
                if case let .businessFailure(info) = error as? RCError {
                    errorInfo = info
                }
                callback?(error, .RequestFinished)
                actionService.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_network_error,
                                            trace: context.trace,
                                            cardID: actionService.messageID,
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
    
    func openProfile(context: UniversalCardActionContext, id: String, from: UIViewController) {
        serviceImpl.openProfile(context: context, id: id, from: from)
    }
    
    func getChatID() -> String? {
        return dependency?.chat.id
    }
    
    func updateLocalData(context: UniversalCardActionContext, bizID: String, cardID: String, version: String, data: String, callback: @escaping (Error?, CardVersion?, CardStatus?) -> Void) {
        Self.logger.info("UpdateLocalData with cardID: \(cardID) version: \(version)", additionalData: ["traceID": context.trace.traceId])
        var request = Openplatform_V1_UpdateMessageCardLocalDataRequest()
        request.messageID = cardID
        request.version = version
        request.jsonDeltaData = data
        if enableUpdateLocalData {
            updateMessageLocalStatus(version: version, data: data)
            dependency?.dataSynchronization()
        }
        rustService?.sendAsyncRequest(request).subscribe(
            onNext: { (res: Openplatform_V1_UpdateMessageCardLocalDataResponse) in
                Self.logger.info("UpdateLocalData success cardVersion:\(res.version), jsonData: \(res.jsonData)", additionalData: ["traceID": context.trace.traceId])
                callback(nil, res.version, res.jsonData)
            },
            onError: { error in
                var errorInfo: BusinessErrorInfo?
                if case let .businessFailure( info) = error as? RCError {
                    errorInfo = info
                }
                Self.logger.info("UpdateLocalData fail error code:\(errorInfo?.errorCode) debugMessage: \(errorInfo?.debugMessage)", additionalData: ["traceID": context.trace.traceId])
                callback(error, nil, nil)
            }).disposed(by: self.disposeBag)
    }
    
    func showToast(context: UniversalCardActionContext, type: UDToastType, text: String, on view: UIView? = nil) {
        serviceImpl.showToast(context: context, type: type, text: text, on: view)
    }
    
    func fetchUsers(context: UniversalCardActionContext, ids: [String], callback: @escaping (Error?, [String : UniversalCardPersonInfo]?) -> Void) {
        serviceImpl.fetchUsers(context: context, ids: ids, callback: callback)
    }
    
    func showImagePreview(context: UniversalCardActionContext, properties: [RustPB.Basic_V1_RichTextElement.ImageProperty], index: Int, from: UIViewController) {
        serviceImpl.showImagePreview(context: context, properties: properties, index: index, from: from)
    }
    
    func updateSummary(context: UniversalCardActionContext, original: String, translation: String) {
        guard var message = dependency?.message else {
            return
        }
        if var content = message.content as? CardContent {
            content.summary = original
            message.content = content
        }
        if var translateContent = message.translateContent as? CardContent {
            translateContent.summary = translation
            message.translateContent = translateContent
        }
        summary = original
        translateSummary = translation
    }
    
    func openCodeBlockDetail(context: UniversalCardActionContext, property: Basic_V1_RichTextElement.CodeBlockV2Property, from: UIViewController) {
        serviceImpl.openCodeBlockDetail(context: context, property: property, from: from)
    }
    
    func getTranslateConfig() -> UniversalCardConfig.TranslateConfig? {
        guard let message = dependency?.message else {
            return nil
        }
        guard let renderType = UniversalCardConfig.TranslateConfig.RenderType(rawValue: getRenderType(message, scene: dependency?.scene).rawValue) else {
            return nil
        }
        return UniversalCardConfig.TranslateConfig(
            renderType: renderType,
            translateLanguage: message.translateLanguage
        )
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
            if let jsonData = self.message?.localData?.data[localStorageKey]?.jsonDataString.data(using: .utf8),
               var status = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                updateStatus = status
            }
            //更新当前版本内容
            updateStatus[version] = newStatus
            let newJsonData = try JSONSerialization.data(withJSONObject: updateStatus, options: [])
            if let newJsonString = String(data: newJsonData, encoding: .utf8) {
                var cardLocalData = Basic_V1_MessageLocalData()
                cardLocalData.jsonDataString = newJsonString
                if self.message?.localData == nil {
                   self.message?.localData = Basic_V1_MessageLocalDataInfoMap()
                }
                self.message?.localData?.data[localStorageKey] = cardLocalData
            }
        } catch {
            Self.logger.error("update message localStatus failed: \(self.message?.id)")
        }
    }
}

extension MessageUniversalCardActionService {
    fileprivate func dealWithActionResponseToast(context: UniversalCardActionContext, res: Im_V2_PutActionResponse) {
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
    
    fileprivate func isMe() -> Bool {
        guard let fromID = message?.fromId else {
            return false
        }
        return accountService?.user.userID == fromID
    }
}
