//
//  FetchSpaceMyFeedListRequest.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/2/25.
//

import Foundation

public struct FetchSpaceMyFeedListRequest: Request {
    public typealias ResponseType = Response<MinutesFeedList>

    public let endpoint: String = "/minutes/api/space/my/feed-list"
    public let requestID: String = UUID().uuidString
    public let method: RequestMethod = .get

    public let timestamp: String
    public let size: Int

    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["timestamp"] = timestamp
        params["size"] = size
        return params
    }
}
