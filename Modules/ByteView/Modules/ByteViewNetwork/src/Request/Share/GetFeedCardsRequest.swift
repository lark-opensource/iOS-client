//
//  GetFeedCardsResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Feed_V1_GetFeedCardsV3Request
public struct GetFeedCardsRequest {
    public static let command: NetworkCommand = .rust(.getFeedCardsV3)
    public typealias Response = GetFeedCardsResponse

    public init(count: Int) {
        self.count = count
    }

    /// LoadMore或Refresh时获取的最大数量
    public var count: Int
}

/// Feed_V1_GetFeedCardsV3Response
public struct GetFeedCardsResponse {

    /// feed预览中的信息
    public var previews: [FeedPreview]

    /// Feed_V1_FeedEntityPreview + Feed_V1_ChatData
    public struct FeedPreview: Equatable {
        public let feedID: String
        public let isGroup: Bool
        public let chatterID: String
        public let rankTime: Int64
    }
}

extension GetFeedCardsRequest: RustRequestWithResponse {
    typealias ProtobufType = Feed_V1_GetFeedCardsV3Request
    func toProtobuf() throws -> Feed_V1_GetFeedCardsV3Request {
        var request = ProtobufType()
        request.getType = .refresh
        request.cursor = 0
        request.count = Int32(count)
        return request
    }
}

extension GetFeedCardsResponse: RustResponse {
    typealias ProtobufType = Feed_V1_GetFeedCardsV3Response
    init(pb: Feed_V1_GetFeedCardsV3Response) throws {
        self.previews = pb.entityPreviews.compactMap { preview -> FeedPreview? in
            guard preview.feedType == .inbox, case let .chatData(chat) = preview.extraData,
                  chat.hasLocalizedDigestMessage, !chat.isCrypto, chat.chatterType != .bot else {
                      return nil
                  }
            let id = preview.feedID
            switch chat.chatType {
            case .group:
                return .init(feedID: id, isGroup: true, chatterID: "", rankTime: chat.rankTime)
            case .p2P:
                return .init(feedID: id, isGroup: false, chatterID: chat.chatterID, rankTime: chat.rankTime)
            @unknown default:
                return nil
            }
        }.sorted(by: { $0.rankTime > $1.rankTime })
    }
}
