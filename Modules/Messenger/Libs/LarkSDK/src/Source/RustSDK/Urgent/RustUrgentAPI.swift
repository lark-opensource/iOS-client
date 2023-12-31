//
//  RustUrgentAPI.swift
//  Lark
//
//  Created by linlin on 2017/11/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import LarkModel
import LarkSDKInterface
import LarkCombine
import LarkAccountInterface
import LKCommonsLogging
import ServerPB

final class RustUrgentAPI: LarkAPI, UrgentAPI {
    static let logger = Logger.log(RustUrgentAPI.self, category: "Business.Urgent")

    private let currentChatterId: String

    init(client: SDKRustService, currentChatterId: String, onScheduler: ImmediateSchedulerType? = nil) {
        self.currentChatterId = currentChatterId
        super.init(client: client, onScheduler: onScheduler)
    }

    func fetchMessageUrgent(messageIds: [String]) -> Observable<[UrgentStatus]> {
        var request = GetUrgentsAckStatusRequest()
        request.messageIds = messageIds
        return client.sendAsyncRequest(request)
            .map({ (response: GetUrgentsAckStatusResponse) -> [UrgentStatus] in
                    let urgentStatus = response.urgentStatus
                    return messageIds.compactMap({ (messageId) -> UrgentStatus? in
                        if let rs = urgentStatus[messageId] {
                            return UrgentStatus(
                                messageId: messageId,
                                unconfirmedChatterIds: rs.initChatterIds.filter {
                                    !rs.ackChatterIds.contains($0)
                                },
                                confimedChatterIds: rs.ackChatterIds
                            )
                        } else {
                            return nil
                        }
                    })
                })
                .subscribeOn(scheduler)
    }

    func syncMessageUrgent(message: LarkModel.Message) -> Observable<LarkModel.Message> {
        return fetchMessageUrgent(messageIds: [message.id]).map({ (urgents) -> LarkModel.Message in
            if let urgent = urgents.first {
                message.isUrgent = true
                message.unackUrgentChatterIds = urgent.unconfirmedChatterIds
                message.ackUrgentChatterIds = urgent.confimedChatterIds
            }
            return message
        })
    }

    func requestUrgentList() -> Observable<[UrgentInfo]> {
        let request = GetUnackUrgentsRequest()
        let currentChatterId = self.currentChatterId
        return client.sendAsyncRequest(request, transform: { (response: GetUnackUrgentsResponse) -> [UrgentInfo] in
            let chats = RustAggregatorTransformer.transformToChatsMap(fromEntity: response.entity)
            let messages = RustAggregatorTransformer.transformToMessageModel(fromEntity: response.entity, currentChatterId: currentChatterId)
            return response.urgents.compactMap({ urgent -> UrgentInfo? in
                if let message = messages[urgent.messageID] {
                    if let chat = chats[message.channel.id] {
                        return UrgentInfo(message: message, chat: chat, urgent: urgent)
                    } else {
                        Self.logger.error("miss urgent necessary entity chat \(urgent.id) \(message.channel.id)")
                    }
                } else {
                    Self.logger.error("miss urgent necessary entity message \(urgent.id) \(urgent.messageID)")
                }
                return nil
            })
        }).subscribeOn(scheduler)
    }

    func confirmUrgentMessage(ackID: String) -> Observable<Void> {
        var request = AckUrgentRequest()
        request.urgentID = ackID
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func createUrgent(
        targetModel: UrgentTargetModel,
        extraList: UrgentExtraList,
        selectType: RustPB.Im_V1_CreateUrgentRequest.SelectType,
        basicInfos: UrgentBasicInfos?,
        cancelPushAck: Bool,
        strictMode: Bool) -> Observable<RustPB.Im_V1_CreateUrgentResponse> {
        var request = CreateUrgentRequest()
        request.messageID = targetModel.messageId
        request.strictMode = strictMode
        request.selectType = selectType
        request.cancelPushAck = cancelPushAck
            if let chatID = targetModel.chatId, let disableList = extraList.disableList, let additionalList = extraList.additionalList {
            request.chatID = chatID
            request.disableList = disableList
            request.additionalList = additionalList
        }
        request.selectType = selectType
        if let basicInfos = basicInfos {
            request.urgentChatterGroups = basicInfos.map({ (urgentGroupInfo) -> CreateUrgentRequest.UrgentChatterGroup in
                let (urgentType, chatterIds) = urgentGroupInfo
                var group = CreateUrgentRequest.UrgentChatterGroup()
                group.chatterIds = chatterIds
                group.urgentType = urgentType
                return group
            })
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func pullSelectUrgentChattersRequest(messageId: String,
                                         selectType: RustPB.Im_V1_GetSelectUrgentChattersRequest.SelectType,
                                         chatId: String,
                                         disableList: [String],
                                         additionalList: [String]) -> Observable<RustPB.Im_V1_GetSelectUrgentChattersResponse> {
        var request = GetSelectUrgentChattersRequest()
        request.messageID = messageId
        request.selectType = selectType
        request.chatID = chatId
        request.disableList = disableList
        request.additionalList = additionalList
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func pullChattersUrgentInfoRequest(chatterIds: [String],
                                       isSuperChat: Bool,
                                       messageId: String) -> Observable<ServerPB.ServerPB_Urgent_PullChattersUrgentInfoResponse> {
        var request = ServerPB.ServerPB_Urgent_PullChattersUrgentInfoRequest()
        request.chatterIds = chatterIds
        request.isSuperChat = isSuperChat
        request.messageID = messageId
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullChattersUrgentInfo)
    }

    func pullAllowedAddUrgentNumOnboarding(urgentId: String) -> Observable<Bool> {
        var request = RustPB.Im_V1_PullAllowedAddUrgentNumOnBoardingRequest()
        request.urgentID = urgentId
        return client.sendAsyncRequest(request).map({ (resp: Im_V1_PullAllowedAddUrgentNumOnBoardingResponse) -> Bool in
            return resp.isAllowed
        })
    }
}
