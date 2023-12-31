//
//  MessageLinkDataSourceHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/25.
//

import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface

final class MessageLinkDataSourceHandler: MergeForwardMessageDetailDataSourceService {
    private let messageAPI: MessageAPI?
    private let messageLink: MessageLink
    private let previewID: String
    // 分页Index，为即将拉取的消息
    private var startIndex: Int = 0
    private var isFetching: Bool = false

    init(messageAPI: MessageAPI?, messageLink: MessageLink, previewID: String) {
        self.messageAPI = messageAPI
        self.messageLink = messageLink
        self.previewID = previewID
    }

    func loadFirstScreenMessages() -> Observable<(messages: [Message], hasMoreNew: Bool, hasMoreOld: Bool, sdkCost: Int64)> {
        guard let messageAPI = messageAPI,
              startIndex < messageLink.entityIDs.count,
              !messageLink.entityIDs.isEmpty,
              !isFetching else {
            return .just(([], false, false, 0))
        }
        isFetching = true
        let endIndex = min(messageLink.entityIDs.count, startIndex + 30)
        let needMessageIDs = Array(messageLink.entityIDs[startIndex..<endIndex])
        if needMessageIDs.isEmpty {
            return .just(([], false, false, 0))
        }
        return messageAPI.pullMessageLink(
            token: messageLink.token,
            previewID: previewID,
            needMessageIDs: needMessageIDs,
            syncDataStrategy: .tryLocal
        ).map({ [weak self] (response, sdkCost) in
            guard let self = self else {
                return ([], false, false, 0)
            }
            let newMessageLink = MessageLink.transform(previewID: self.previewID, messageLink: response.link)
            let messages = newMessageLink.entityIDs.compactMap({ newMessageLink.entities[$0]?.message })
            self.startIndex = endIndex
            self.isFetching = false
            return (messages, endIndex < self.messageLink.entityIDs.count, false, sdkCost)
        })
    }

    func loadMoreNewMessages() -> Observable<(messages: [Message], hasMoreNew: Bool, sdkCost: Int64)> {
        guard let messageAPI = messageAPI,
              startIndex < messageLink.entityIDs.count,
              !messageLink.entityIDs.isEmpty,
              !isFetching else {
            return .just(([], false, 0))
        }
        isFetching = true
        // 分页30
        let endIndex = min(messageLink.entityIDs.count, startIndex + 30)
        let needMessageIDs = Array(messageLink.entityIDs[startIndex..<endIndex])
        if needMessageIDs.isEmpty {
            return .just(([], false, 0))
        }
        return messageAPI.pullMessageLink(
            token: messageLink.token,
            previewID: previewID,
            needMessageIDs: needMessageIDs,
            syncDataStrategy: .tryLocal
        ).map({ [weak self] (response, sdkCost) in
            guard let self = self else { return ([], false, 0) }
            let newMessageLink = MessageLink.transform(previewID: self.previewID, messageLink: response.link)
            let messages = newMessageLink.entityIDs.compactMap({ newMessageLink.entities[$0]?.message })
            self.startIndex = endIndex
            self.isFetching = false
            return (messages, endIndex < self.messageLink.entityIDs.count, sdkCost)
        })
    }
}
