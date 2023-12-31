//
//  UrgentAPI.swift
//  LarkSDKInterface
//
//  Created by liuwanlin on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB

public struct UrgentStatus {
    public let messageId: String
    public let unconfirmedChatterIds: [String]
    public let confimedChatterIds: [String]

    public init(messageId: String, unconfirmedChatterIds: [String], confimedChatterIds: [String]) {
        self.messageId = messageId
        self.unconfirmedChatterIds = unconfirmedChatterIds
        self.confimedChatterIds = confimedChatterIds
    }
}

public struct UrgentInfo {
    public let message: Message
    public let chat: Chat
    public let urgent: RustPB.Basic_V1_Urgent
    public init(message: Message, chat: Chat, urgent: RustPB.Basic_V1_Urgent) {
        self.message = message
        self.chat = chat
        self.urgent = urgent
    }
}

public struct UrgentFailInfo {
    public let message: Message
    public let chat: Chat
    public let failedTip: String
    public let urgentId: String
    public let urgentType: RustPB.Basic_V1_Urgent.TypeEnum

    public init(message: Message,
                urgentId: String,
                chat: Chat,
                urgentType: RustPB.Basic_V1_Urgent.TypeEnum,
                failedTip: String) {
        self.message = message
        self.urgentId = urgentId
        self.chat = chat
        self.urgentType = urgentType
        self.failedTip = failedTip
    }
}

public typealias UrgentBasicInfos = [(urgentType: RustPB.Basic_V1_Urgent.TypeEnum, chatterIds: [String])]

public struct UrgentTargetModel {
    public var messageId: String
    public var chatId: String?
    public init(messageId: String,
                chatId: String?) {
        self.messageId = messageId
        self.chatId = chatId
    }
}

public struct UrgentExtraList {
    public var disableList: [String]?
    public var additionalList: [String]?
    public init(disableList: [String]?,
                additionalList: [String]?) {
        self.disableList = disableList
        self.additionalList = additionalList
    }
}

public protocol UrgentAPI {
    func requestUrgentList() -> Observable<[UrgentInfo]>

    func confirmUrgentMessage(ackID: String) -> Observable<Void>

    func createUrgent(targetModel: UrgentTargetModel,
                      extraList: UrgentExtraList,
                      selectType: RustPB.Im_V1_CreateUrgentRequest.SelectType,
                      basicInfos: UrgentBasicInfos?,
                      cancelPushAck: Bool,
                      strictMode: Bool) -> Observable<RustPB.Im_V1_CreateUrgentResponse>

    func fetchMessageUrgent(messageIds: [String]) -> Observable<[UrgentStatus]>

    func syncMessageUrgent(message: Message) -> Observable<Message>

    func pullSelectUrgentChattersRequest(messageId: String,
                                         selectType: RustPB.Im_V1_GetSelectUrgentChattersRequest.SelectType,
                                         chatId: String,
                                         disableList: [String],
                                         additionalList: [String]) -> Observable<RustPB.Im_V1_GetSelectUrgentChattersResponse>

    func pullChattersUrgentInfoRequest(chatterIds: [String],
                                       isSuperChat: Bool,
                                       messageId: String) -> Observable<ServerPB.ServerPB_Urgent_PullChattersUrgentInfoResponse>
    // 拉取是否展示添加紧急联系人到通讯录引导
    func pullAllowedAddUrgentNumOnboarding(urgentId: String) -> Observable<Bool>
}

public typealias UrgentAPIProvider = () -> UrgentAPI
public typealias UrgentChatterRestrictGroup = RustPB.Im_V1_UrgentChatterRestrictGroup
