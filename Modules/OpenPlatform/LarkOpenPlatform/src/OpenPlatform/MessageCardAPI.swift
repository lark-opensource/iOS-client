//
//  MessageCardAPI.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/9.
//

import UIKit
import RustPB
import Swinject
import LarkRustClient
import RxSwift
import EEMicroAppSDK
import LarkAccount
import LarkSendMessage
import LarkOPInterface

enum MessageCardErr {
    case userCancelSend
    case sendCardError(Int, [String]?)
    case jsonToPBError(Int)
    case cardContentToJsonError
    case noPermissionByNoOpenRecord
    case featureGatingNotOpen
    case chatIDsEmpty
    case getChatItemsFailed
    case ok
    case sendTextError([String]?)

    func getCallBackDic() -> [String: Any] {
        switch self {
        case .featureGatingNotOpen:
            return ["code": -6, "msg": "feature gating key not open"]
        case .userCancelSend:
            return ["code": -5, "msg": "user cancel send"]
        case .sendCardError(let sendStatus, let _):
            return ["code": -4, "msg": "send card error \(sendStatus)"]
        case .jsonToPBError(let convertStatus):
            return ["code": -3, "msg": "card json convert to pb error \(convertStatus)"]
        case .cardContentToJsonError:
            return ["code": -2, "msg": "card content dic convert to json error"]
        case .noPermissionByNoOpenRecord:
            return ["code": -1, "msg": "send messageCard need open miniprograme from chat keyboard"]
        case .chatIDsEmpty:
            return ["code": -7, "msg": "chatIDs empty"]
        case .getChatItemsFailed:
            return ["code": -8, "msg": "get chatItems failed"]
        case .ok:
            return ["code": 0, "msg": "ok"]
        case .sendTextError( _):
            return ["code": 42406, "msg": "send additional message failed"]
        }
    }

    func getCallBackResult(sendInfos: [EMASendCardInfo]? = nil,
                           sendTextInfo: [EMASendCardAditionalTextInfo]? = nil) -> (SendMessageCardErrorCode, String?, [String]?, [EMASendCardInfo]?, [EMASendCardAditionalTextInfo]?) {
        switch self {
        case .featureGatingNotOpen:
            return (.otherError, "feature gating key not open", nil, sendInfos, nil)
        case .userCancelSend:
            return (.userCancel, "user cancel send", nil, sendInfos, nil)
        case .sendCardError(let sendStatus, let failedChatIDs):
            return (.sendFailed, "send card error \(sendStatus)", failedChatIDs, sendInfos, nil)
        case .jsonToPBError(let convertStatus):
            return (.cardContentFormatError, "card json convert to pb error \(convertStatus)", nil, sendInfos, nil)
        case .cardContentToJsonError:
            return (.cardContentFormatError, "card content dic convert to json error", nil, sendInfos, nil)
        case .noPermissionByNoOpenRecord:
            return (.otherError, "sendMessageCard need open miniprograme from chat keyboard", nil, sendInfos, nil)
        case .chatIDsEmpty:
            return (.otherError, "chatIDs empty", nil, sendInfos, nil)
        case .getChatItemsFailed:
            return (.otherError, "get chatItems failed", nil, sendInfos, nil)
        case .ok:
            return (.noError, nil, nil, sendInfos, nil)
        case .sendTextError(_):
            return (.sendTextError, "send additional message failed", nil, sendInfos, sendTextInfo)
        }
    }
}

/// 内部错误码
public enum SendTextErrorCode: Int {
    case ok
    case otherError = -1
    case errorQuasiMessage = -2
    case errorSendMessage = -3
    case cannotsend = -4
    case initState = -5
    case timeout = -6
}

class MessageCardAPI: NSObject {
    private let resolver: Resolver
    private let disposeBag = DisposeBag()

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func resuqstCardPB(jsonStr: String,
                       appId: String,
                       chatId: String,
                       complete: @escaping ((Openplatform_V1_CardJsonToPBResponse?) -> Void)) {
        if let client = resolver.resolve(RustService.self) {
            var req = Openplatform_V1_CardJsonToPBRequest()
            req.appID = appId
            req.chatID = chatId
            req.jsonStr = jsonStr
            let start = Date()
            client.sendAsyncRequest(req, transform: {(response: Openplatform_V1_CardJsonToPBResponse) -> Void in
                complete(response)
            }).subscribe(
                onNext: {
                    let duration = Date().timeIntervalSince(start)
                    let monitor = OPMonitor(name: MonitorField.EventName, code: EPMClientOpenPlatformCardCode.messagecard_card_json2pb_success)
                        .setDuration(duration)
                        .setResultTypeSuccess()
                },
                onError: { error in
                    var errorInfo: BusinessErrorInfo?
                    if case let .businessFailure( info) = error as? RCError {
                        errorInfo = info
                    }
                    let monitor = OPMonitor(name: MonitorField.EventName, code: EPMClientOpenPlatformCardCode.messagecard_card_json2pb_error)
                        .setErrorCode(String(errorInfo?.errorCode ?? 0))
                        .setErrorMessage(errorInfo?.debugMessage)
                        .addCategoryValue(MonitorField.TTLogId, errorInfo?.ttLogId)
                        .addCategoryValue(MonitorField.ErrorStatus, errorInfo?.errorStatus)
                }
            
            ).disposed(by: disposeBag)
        } else {
            complete(nil)
        }
    }

    func sendCard(chatIDs: [String],
                  cardKey: String,
                  complete: @escaping ((Openplatform_V1_SendPreviewCardResponse?) -> Void)) {
        if let client = resolver.resolve(RustService.self) {
            var req = Openplatform_V1_SendPreviewCardRequest()
            req.chatIds = chatIDs
            req.cardKey = cardKey
            req.version = .v2
            let start = Date()
            client.sendAsyncRequest(req, transform: {(response: Openplatform_V1_SendPreviewCardResponse) -> Void in
                complete(response)
            }).subscribe(
                onNext: {
                    let duration = Date().timeIntervalSince(start)
                    let monitor = OPMonitor(name: MonitorField.EventName, code: EPMClientOpenPlatformCardCode.messagecard_send_preview_card_success)
                        .setDuration(duration)
                        .setResultTypeSuccess()
                },
                onError: { error in
                    var errorInfo: BusinessErrorInfo?
                    if case let .businessFailure( info) = error as? RCError {
                        errorInfo = info
                    }
                    let monitor = OPMonitor(name: MonitorField.EventName, code: EPMClientOpenPlatformCardCode.messagecard_send_preview_card_error)
                        .setErrorCode(String(errorInfo?.errorCode ?? 0))
                        .setErrorMessage(errorInfo?.debugMessage)
                        .addCategoryValue(MonitorField.TTLogId, errorInfo?.ttLogId)
                        .addCategoryValue(MonitorField.ErrorStatus, errorInfo?.errorStatus)
                }
            
            ).disposed(by: disposeBag)
        } else {
            complete(nil)
        }
    }
    
    func sendText(chatIDMaps: [String: String],
                  message: String,
                  complete: @escaping ((Error?, [EMASendCardAditionalTextInfo]?) -> Void)) {
        DispatchQueue.global().async {
            if let sendMessageAPI = self.resolver.resolve(SendMessageAPI.self) {
                let richText = RustPB.Basic_V1_RichText.text(message)
                let group = DispatchGroup()
                let queue = DispatchQueue(label: "sendText",
                                          qos: .default,
                                          attributes: .concurrent)
                let lock = NSLock()
                /// 初始化认为所有的记录
                var result: [String: EMASendCardAditionalTextInfo] = chatIDMaps.mapValues { openChatId in
                    let info = EMASendCardAditionalTextInfo()
                    info.openChatId = openChatId
                    info.message = message
                    info.status = SendTextErrorCode.initState.rawValue
                    return info
                }
                func updateResult(chatId: String, status: Int, sema: DispatchSemaphore) {
                    lock.lock()
                    let firstUpdate = result[chatId] != nil
                    let info = EMASendCardAditionalTextInfo()
                    info.chatId = chatId
                    info.openChatId = chatIDMaps[chatId] ?? ""
                    info.message = message
                    info.status = status
                    result[chatId] = info
                    lock.unlock()
                    if firstUpdate {
                        sema.signal()
                    }
                }
                for chatId in chatIDMaps.keys {
                    queue.async(group: group, execute: DispatchWorkItem(block: {
                        let sema = DispatchSemaphore(value: 0)
                        sendMessageAPI.sendText(context: nil,
                                                content: richText,
                                                parentMessage: nil,
                                                chatId: chatId,
                                                threadId: nil) { state in
                            switch state {
                            case .errorQuasiMessage:
                                OPLogger.error("send message error \(self)")
                                updateResult(chatId: chatId,
                                             status: SendTextErrorCode.errorQuasiMessage.rawValue,
                                             sema: sema)
                                break
                            case .otherError:
                                OPLogger.error("send message error \(self)")
                                updateResult(chatId: chatId,
                                             status: SendTextErrorCode.otherError.rawValue,
                                             sema: sema)
                                break
                            case .errorSendMessage(cid: let cid, error: let error):
                                OPLogger.error("send message \(cid) error", tag: "", additionalData: nil, error: error)
                                updateResult(chatId: chatId,
                                             status: SendTextErrorCode.errorSendMessage.rawValue,
                                             sema: sema)
                                break
                            case .finishSendMessage(_, contextId: let contextId,
                                                    messageId: let messageId,
                                                    netCost: let netCost, _):
                                OPLogger.info("send message \(contextId) cost \(netCost) success \(String(describing: messageId))")
                                updateResult(chatId: chatId,
                                             status: SendTextErrorCode.ok.rawValue,
                                             sema: sema)
                                break
                            default:
                                break
                            }
                            OPLogger.info("send message return \(state)")
                        }
                        _ = sema.wait(timeout: (DispatchTime.now() + .seconds(10)))
                    }))
                }
                let waitResult = group.wait(timeout: (DispatchTime.now() + .seconds(20)))
                switch waitResult {
                case .success:
                    OPLogger.info("send batch card message success")
                    complete(nil, result.values.map{ $0 })
                    break
                case .timedOut:
                    OPLogger.info("send batch card message success, but part time out")
                    let mapResult: [String: EMASendCardAditionalTextInfo] = result.mapValues { info in
                        let resultInfo = info
                        if resultInfo.status == SendTextErrorCode.initState.rawValue {
                            resultInfo.status = SendTextErrorCode.timeout.rawValue
                        }
                        return resultInfo
                    }
                    let error = NSError(domain: "send text with card part failed",
                                        code: SendTextErrorCode.timeout.rawValue,
                                        userInfo: nil)
                    let timeoutResult: [EMASendCardAditionalTextInfo] = mapResult.values.map{ $0 }
                    complete(error, timeoutResult)
                    break
                }
            } else {
                let error = NSError(domain: "send text with card failed",
                                    code: SendTextErrorCode.cannotsend.rawValue,
                                    userInfo: nil)
                complete(error, nil)
            }
        }
    }
}

/// 扩展发卡片返回接口
extension Openplatform_V1_SendPreviewCardResponse {
    /// 提取chatId到openChatId的map
    public func chatIdToOpenChatIdMap() -> [String: String] {
        return sendCardInfos.mapValues { info in
            return info.openChatID
        }
    }
}
