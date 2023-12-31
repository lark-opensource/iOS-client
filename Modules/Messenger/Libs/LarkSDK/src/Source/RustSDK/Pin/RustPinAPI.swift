//
//  RustPinAPI.swift
//  LarkSDK
//
//  Created by chengzhipeng-bytedance on 2018/9/19.
//

import Foundation
import UIKit
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface

final class RustPinAPI: LarkAPI, PinAPI {
    private static let logger = Logger.log(RustPinAPI.self, category: "RustPinAPI")
    private let userPushCenter: PushNotificationCenter
    private let currentChatterId: String
    private let urlPreviewService: MessageURLPreviewService

    init(userPushCenter: PushNotificationCenter, currentChatterId: String, client: SDKRustService, urlPreviewService: MessageURLPreviewService, onScheduler: ImmediateSchedulerType? = nil) {
        self.userPushCenter = userPushCenter
        self.currentChatterId = currentChatterId
        self.urlPreviewService = urlPreviewService
        super.init(client: client, onScheduler: onScheduler)
    }

    func createPin(messageId: String) -> Observable<Void> {
        var request = CreatePinRequest()
        request.messageID = messageId
        return self.client.sendAsyncRequest(request).subscribeOn(self.scheduler)
    }

    func deletePin(messageId: String, chatId: String) -> Observable<Void> {
        var request = DeletePinRequest()
        request.messageID = messageId
        request.chatID = chatId
        return self.client.sendAsyncRequest(request)
            .do(onNext: { [weak self] (_) in
                self?.userPushCenter.post(PushDeletePinList(pinId: messageId))
            }).subscribeOn(self.scheduler)
    }

    func getPinListV2(chatId: String, isFromServer: Bool, timestampCursor: Int64, count: Int32) -> Observable<GetPinListResultV2> {
        var request = GetChatPinMessagesRequest()
        request.chatID = chatId
        request.timestampCursor = timestampCursor
        request.count = count
        request.isFromServer = isFromServer
        let start = CACurrentMediaTime()
        return self.client.sendAsyncRequest(request).map { (response: GetChatPinMessagesResponse) -> GetPinListResultV2 in
            let sdkCost = CACurrentMediaTime() - start
            let chats = RustAggregatorTransformer.transformToChatsMap(fromEntity: response.entity)
            let messages = RustAggregatorTransformer.transformToMessageModel(fromEntity: response.entity, currentChatterId: self.currentChatterId)
            let pins = response.orderedMessageIds.compactMap({ (msgId) -> PinModel? in
                if let message = messages[msgId], let chat = chats[message.channel.id] {
                    return PinModel(message: message, chat: chat, hitTerms: [])
                }
                RustPinAPI.logger.error("获取Pin列表结果缺少依赖的msg或chat", additionalData: ["msgId": "\(msgId)"])
                return nil
            })
            return GetPinListResultV2(pins: pins, hasMore: response.hasMore_p, lastReadTime: response.lastReadTime, sdkCost: sdkCost)
        }.do(onNext: { [weak self] result in
            let messages = result.pins.map({ $0.message })
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(self.scheduler)
    }

    func getPinReadStatus(chatId: String) -> Observable<Bool> {
        var request = GetPinReadStatusRequest()
        request.chatID = chatId
        return self.client.sendAsyncRequest(request) { (response: GetPinReadStatusResponse) -> Bool in
            return !response.hasUnreadPin_p
        }.subscribeOn(self.scheduler)
    }

    func getChatPinCount(chatId: Int64, useLocal: Bool) -> Observable<Int64> {
        var request = Im_V1_GetChatPinCountRequest()
        request.chatID = chatId
        if useLocal {
            request.syncDataStrategy = .local
        } else {
            request.syncDataStrategy = .forceServer
        }
        return self.client.sendAsyncRequest(request) { (response: Im_V1_GetChatPinCountResponse) -> Int64 in
            return response.count
        }.subscribeOn(self.scheduler)
    }

    func updatePinReadStatus(chatId: String) -> Observable<Void> {
        var request = UpdatePinReadRequest()
        request.chatID = chatId
        return self.client.sendAsyncRequest(request).subscribeOn(self.scheduler)
    }
}
