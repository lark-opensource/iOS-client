//
//  GetMessageDetailHandler.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/10/14.
//

import Foundation
import Swinject
import LKCommonsLogging
import LarkAccountInterface
import RxSwift
import SwiftyJSON
import LarkOpenAPIModel
import EEMicroAppSDK
import LarkContainer

private let logger = Logger.log(GetMessageDetailHandler.self, category: "GetMessageDetailHandler")
/// 请求的上下文
struct GetMessageDetailRequest {
    let appID: String
    let triggerCode: String
    let extraInfo: [String: Any]?
    let complete: ((Error?, OpenAPIErrnoProtocol?, [String: Any]) -> Void)?
    var api: OpenPlatformAPI?
}
private let messageKeyMessageContents = "message_contents"
private let messageKeyBizType = "bizType"
private let messageKeyMessage = "message"
/// 后端返回的message type字符串，不再由客户端针对之前后端返回的数字类型message_type和本地的字符串进行hard code匹配
private let messageKeyMessageTypeString = "message_type_string"
private let messageKeyMessageTypeResultKey = "messageType"
private let messageKeyTimeType = "create_time"
private let messageKeyTimeTypeResultKey = "createTime"
private let messageKeySender = "sender"
private let messageKeySenderNameKey = "name"
private let messageKeySenderOpenIDKey = "open_id"
private let messageKeySupport = "support"
private let messageKeyISRecalled = "is_recalled"
private let messageKeyContent = "content"
private let messageKeyMessages = "messages"
private let messageKeyActionTime = "actionTime"
private let messageKeyMessageUnsupport = "unsupport"
private let messageKeyMessageStatus = "status"
/// 3.40版本增加需求
private let messageKeyOpenChatId = "chat_id"
private let messageKeyOpenChatResultId = "openChatId"
private let messageKeyOpenMessageId = "message_id"
private let messageKeyOpenMessageResultId = "openMessageId"

class GetMessageDetailHandler {
    public static let shared = GetMessageDetailHandler()
    /// 成功请求结果的cache
    private var messageDetailCache = NSCache<NSString, NSObject>()
    /// 请求查询队列
    private var messageRequestQueueMap: [String: [GetMessageDetailRequest]] = [:]
    /// result cache lock
    private let cacheLock = NSRecursiveLock()
    /// callback queue lock
    private let callbackLock = NSRecursiveLock()
    /// 获取消息详情
    func getBlockActionDetail(resolver: UserResolver,
                              appID: String,
                              triggerCode: String?,
                              extraInfo: [String: Any]?,
                              complete: ((Error?, OpenAPIErrnoProtocol?, [String: Any]) -> Void)?) {
        let result = [String: Any]()
        ///  检查 triggerCode 是否合法，是否存在相应的操作记录
        guard let validTriggerCode = triggerCode,
              let messageContext = MessageCardSession.shared().getMessageActionContext(triggerCode: validTriggerCode) else {
            let triggerCodeNotValidError = (triggerCode?.isEmpty ?? true) ? GetMessageError.triggercodeIsEmpty.toError() : GetMessageError.triggercodeNotValid.toError()
            logger.error("getBlockActionDetail triggerCode not valid", error: triggerCodeNotValidError)
            complete?(triggerCodeNotValidError, OpenAPICommonErrno.invalidParam(.invalidParam(param: "triggerCode")), result)
            return
        }
        /// 生成本次的请求上下文
        let requestContext = GetMessageDetailRequest(appID: appID,
                                                     triggerCode: validTriggerCode,
                                                     extraInfo: extraInfo,
                                                     complete: complete)
        /// 如果上一次已经存在结果了，那么直接回调
        if let lastMessage = lastMessageDetail(triggerCode: validTriggerCode as NSString) {
            complete?(nil, nil, lastMessage)
            return
        }
        ///  检查 httpClient 是否存在
        guard let httpClient = try? resolver.resolve(assert: OpenPlatformHttpClient.self) else {
            let httpClientNotValidError = GetMessageError.serviceNotValid.toError()
            logger.error("getBlockActionDetail httpClient not exist", error: httpClientNotValidError)
            complete?(httpClientNotValidError, OpenAPICommonErrno.internalError, result)
            return
        }
        ///  请求 triggerCode 对应消息的详情内容
        let api = OpenPlatformAPI.getMessageContentAPI(triggerCode: validTriggerCode,
                                                       messageIds: messageContext.messageIds,
                                                       appid: appID, resolver: resolver)
        recordRequest(request: requestContext)
        let monitorSuccess = OPMonitor(EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.get_action_info_success).setResultTypeSuccess().timing()
        let monitorFail = OPMonitor(EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.get_action_info_fail).setResultTypeFail()
        _ = httpClient.request(api: api)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result: GetMessageDetailAPIResponse) in
                let logID = result.lobLogID
                guard let self = self else {
                    logger.warn("getBlockActionDetail's self missed, response json exit")
                    return
                }
                if let resultCode = result.code, resultCode == 0 {
                    self.handleMessageDetailSuccess(cipher: result.cipher ?? EMANetworkCipher(),
                                                    triggerCode: validTriggerCode,
                                                    result: result.json["data"],
                                                    complete: complete)
                    monitorSuccess
                        .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                        .timing()
                        .flush()
                } else {
                    let errCode = result.json["code"].intValue
                    let errMsg = result.json["msg"].stringValue
                    let error = NSError(domain: GetMessageError.errorDomain,
                                        code: errCode,
                                        userInfo: [NSLocalizedDescriptionKey: errMsg])
                    monitorFail
                        .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                        .setError(error)
                        .flush()
                    self.handleMessageDetailFailed(triggerCode: validTriggerCode,
                                                    sourceError: error,
                                                    complete: complete)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else {
                    logger.error("getBlockActionDetail's self missed, response error exit", error: error)
                    return
                }
                let logID = (error as NSError).userInfo[OpenPlatformHttpClient.lobLogIDKey] as? String
                monitorFail
                    .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyRequestID, logID)
                    .setError(error)
                    .flush()
                logger.error("getBlockActionDetail response error", error: error)
                self.handleMessageDetailFailed(triggerCode: validTriggerCode,
                                                sourceError: error,
                                                complete: complete)
            })
    }
    /// 成功请求到消息内容
    func handleMessageDetailSuccess(cipher: EMANetworkCipher,
                                    triggerCode: String,
                                    result: JSON?,
                                    complete: ((Error?, OpenAPIErrnoProtocol?, [String: Any]) -> Void)?) {
        if let contextItem = MessageCardSession.shared().getMessageActionContext(triggerCode: triggerCode),
           let message_contents = result?[messageKeyMessageContents].dictionary {
            let requestArray = popRequestInQueue(triggerCode: triggerCode)
            let messageIds = contextItem.messageIds
            var result: [String: Any] = [messageKeyBizType: messageKeyMessage]
            var messages: [[String: Any]] = []
            for messageId in messageIds {
                /// 如果结果存在这个消息的返回数据
                if var messageItem = message_contents[messageId] {
                    /// 检查消息是否被撤回
                    let isRecalled = (messageItem[messageKeyISRecalled].bool ?? false)
                    let status = !isRecalled
                    let messageType: String
                    let isMessageTypeExsits: Bool
                    if let messageTypeString = messageItem[messageKeyMessageTypeString].string {
                        messageType = messageTypeString
                        isMessageTypeExsits = true
                    } else {
                        messageType = messageKeyMessageUnsupport
                        isMessageTypeExsits = false
                        logger.error("message_type_string for messageId(\(messageId) is not exsit")
                    }
                    /// 消息对应消息类型
                    if isMessageTypeExsits,
                       /// 检查服务端是否支持这个类型
                       (messageItem[messageKeySupport].bool ?? false) == true,
                       /// 得到服务端返回的查询到的消息
                       var messageItemDic = messageItem.dictionaryObject,
                       /// 原始消息内容
                       let messageEncrypt: String = messageItem[messageKeyContent].string,
                       /// 解密消息中的消息内容
                       let decryptMessage = EMANetworkCipher.decryptDict(forEncryptedContent: messageEncrypt, cipher: cipher) as? [String: Any] {
                        /// 得到返回的结果
                        resetMessageDictionary(messageItem: &messageItemDic,
                                               decryptMessage: decryptMessage,
                                               support: true,
                                               messageType: messageType,
                                               status: status)
                        messages.append(messageItemDic)
                    } else {
                        /// make unsupport item
                        messageItem[messageKeySupport] = false
                        var notSupport = messageItem.dictionaryObject ?? notSupportDictionary()
                        resetMessageDictionary(messageItem: &notSupport,
                                               decryptMessage: notSupportTitle(),
                                               support: false,
                                               messageType: messageType,
                                               status: status)
                        messages.append(notSupport)
                    }
                } else {
                    /// 不存在这个消息的返回数据，后端解析不正常
                    messages.append(notSupportDictionary())
                }
            }
            let actionTime = Int(contextItem.createDate.timeIntervalSince1970)
            result[messageKeyContent] = [messageKeyMessages: messages, messageKeyActionTime: actionTime]
            for request in requestArray {
                request.complete?(nil, nil, result)
            }
            cacheMessageDetail(triggerCode: triggerCode as NSString, result: result)
        }
        OPMonitor(EPMJsOpenPlatformGadgetAppMsgActionCode.message_action_get_detail_event)
            .setResultTypeSuccess()
            .flush()
    }
    ///
    /// 不支持的消息类型的国际化文案
    private func notSupportTitle() -> String {
        return BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_MsgScTypeUnsupport
    }
    /// 不支持的消息类型的国际化文案
    private func notSupportDictionary() -> [String: Any] {
        return [messageKeySupport: false, messageKeyContent: notSupportTitle(), messageKeyMessageTypeResultKey: messageKeyMessageUnsupport]
    }
    /// 修改支持的类型返回的字段
    private func resetMessageDictionary(messageItem: inout [String: Any],
                                        decryptMessage: Any?,
                                        support: Bool,
                                        messageType: String,
                                        status: Bool) {
        /// create time 驼峰
        messageItem[messageKeyTimeTypeResultKey] = messageItem[messageKeyTimeType]
        messageItem.removeValue(forKey: messageKeyContent)
        messageItem[messageKeyContent] = decryptMessage
        /// 移除sender中的status
        if var senderItem = messageItem[messageKeySender] as? [String: Any] {
            let validMessageKeys = [messageKeySenderNameKey,
                                    messageKeySenderOpenIDKey]
            senderItem = senderItem.filter{ validMessageKeys.contains($0.key) }
            messageItem[messageKeySender] = senderItem
        }
        /// 如果可以转成string
        if let msg = decryptMessage,
           JSONSerialization.isValidJSONObject(msg),
           let data = try? JSONSerialization.data(withJSONObject: msg, options: .sortedKeys),
           let dataString = String(data: data, encoding: .utf8) {
            messageItem[messageKeyContent] = dataString
        }
        messageItem[messageKeyMessageStatus] = status
        messageItem[messageKeySupport] = support
        /// message type 驼峰
        messageItem[messageKeyMessageTypeResultKey] = messageType
        /// 3.40
        if let openChatId = messageItem[messageKeyOpenChatId] {
            messageItem[messageKeyOpenChatResultId] = openChatId
        }
        if let openMessageId = messageItem[messageKeyOpenMessageId] {
            messageItem[messageKeyOpenMessageResultId] = openMessageId
        }
        let validMessageKeys = [messageKeyMessageTypeResultKey,
                                messageKeySender,
                                messageKeyTimeTypeResultKey,
                                messageKeySupport,
                                messageKeyContent,
                                messageKeyMessageStatus,
                                messageKeyOpenChatResultId,
                                messageKeyOpenMessageResultId]
        messageItem = messageItem.filter { validMessageKeys.contains($0.key)}
    }
    /// 成功请求到消息内容
    func handleMessageDetailFailed(triggerCode: String,
                                   sourceError: Error,
                                   complete: ((Error?, OpenAPIErrnoProtocol?, [String: Any]) -> Void)?) {
        let sourceErrorInfo = [GetMessageError.sourceErrorKey: "\(sourceError.localizedDescription)"]
        let resultError = GetMessageError.getMessageFailed.toError(userInfo: sourceErrorInfo)
        let requestArray = popRequestInQueue(triggerCode: triggerCode)
        for request in requestArray {
            request.complete?(resultError, OpenAPICommonErrno.networkFail, [:])
        }
        OPMonitor(EPMJsOpenPlatformGadgetAppMsgActionCode.message_action_get_detail_error)
            .setError(sourceError)
            .setResultTypeFail()
            .flush()
    }
    /// 查询上一次缓存的请求结果
    func lastMessageDetail(triggerCode: NSString) -> [String: Any]? {
        defer {
            cacheLock.unlock()
        }
        cacheLock.lock()
        return messageDetailCache.object(forKey: triggerCode as NSString) as? [String: Any]
    }
    /// cache result of message
    func cacheMessageDetail(triggerCode: NSString, result: [String: Any]) {
        defer {
            cacheLock.unlock()
        }
        cacheLock.lock()
        messageDetailCache.setObject(result as NSDictionary,
                                     forKey: triggerCode)
    }
    /// 记录请求的上下文
    func recordRequest(request: GetMessageDetailRequest) {
        defer {
            callbackLock.unlock()
        }
        callbackLock.lock()
        var requestQueue: [GetMessageDetailRequest] = messageRequestQueueMap[request.triggerCode] ?? []
        requestQueue.append(request)
        messageRequestQueueMap[request.triggerCode] = requestQueue
    }
    /// 查询请求队列中的上下文
    func popRequestInQueue(triggerCode: String) -> [GetMessageDetailRequest] {
        defer {
            callbackLock.unlock()
        }
        callbackLock.lock()
        let requestQueue: [GetMessageDetailRequest] = messageRequestQueueMap[triggerCode] ?? []
        messageRequestQueueMap.removeValue(forKey: triggerCode)
        return requestQueue
    }
}
