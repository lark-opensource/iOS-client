//
//  ChatChatterDataFetcher.swift
//  LarkSDK
//
//  Created by zc09v on 2018/11/16.
//
import Foundation
import Homeric
import RxSwift
import LarkModel
import LarkSDKInterface

import LKCommonsTracker

final class ChatChatterDataFetcher: DataFetcher {
    let chatterAPI: ChatterAPI

    init(chatterAPI: ChatterAPI) {
        self.chatterAPI = chatterAPI
    }

    func asyncFetch(with item: CollectItem) -> Observable<PackData> {
        var chatterObservable: Observable<PackData> = .just(.default)

        let chatterIds = item.data[.chatChatter] ?? []
        let chatId = item.extraInfo[.chatId] ?? ""
        if !chatterIds.isEmpty, !chatId.isEmpty {
            chatterObservable = chatterAPI
                .fetchChatChatters(ids: chatterIds, chatId: chatId)
                .map { PackData(data: [.chatChatter: $0]) }
        }
        for chatterId in chatterIds {
            Tracker.post(TeaEvent(Homeric.MESSAGE_PARSE_ENTITY_MISS_CHATTER,
                                  params: ["info": "chatId: \(chatId), chatterId: \(chatterId)"]))
        }
        return chatterObservable
    }
}
