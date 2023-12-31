//
//  PinAPI.swift
//  LarkSDKInterface
//
//  Created by chengzhipeng-bytedance on 2018/9/19.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public struct PinModel {
    public let message: Message
    public let chat: Chat
    public let hitTerms: [String]
    public init(message: Message, chat: Chat, hitTerms: [String] = []) {
        self.message = message
        self.chat = chat
        self.hitTerms = hitTerms
    }
}

//新pin列表接口返回结果
public struct GetPinListResultV2 {
    public let hasMore: Bool
    public let lastReadTime: Int64
    public let pins: [PinModel]
    public let sdkCost: Double
    public init(pins: [PinModel],
                hasMore: Bool,
                lastReadTime: Int64,
                sdkCost: Double) {
        self.hasMore = hasMore
        self.lastReadTime = lastReadTime
        self.pins = pins
        self.sdkCost = sdkCost
    }
}

public struct PinSetting {
    public let subscribeSetting: RustPB.Settings_V1_PinSubscribeSetting
    public init(subscribeSetting: RustPB.Settings_V1_PinSubscribeSetting) {
        self.subscribeSetting = subscribeSetting
    }
}

public protocol PinAPI {
    func createPin(messageId: String) -> Observable<Void>

    func deletePin(messageId: String, chatId: String) -> Observable<Void>

    func getPinListV2(chatId: String, isFromServer: Bool, timestampCursor: Int64, count: Int32) -> Observable<GetPinListResultV2>

    func getPinReadStatus(chatId: String) -> Observable<Bool>

    func getChatPinCount(chatId: Int64, useLocal: Bool) -> Observable<Int64>

    func updatePinReadStatus(chatId: String) -> Observable<Void>
}
