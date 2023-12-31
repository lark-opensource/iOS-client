//
//  FetchSpaceFeedListBatchStatus.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/3/2.
//

import Foundation

public struct FetchSpaceFeedListBatchStatus: Request {
    public typealias ResponseType = Response<MinutesFeedListStatus>

    public let endpoint: String = MinutesAPIPath.listBatchStatus
    public let requestID: String = UUID().uuidString
    public let method: RequestMethod = .get

    public let objectToken: [String]
    public var catchError: Bool

    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["token_list"] = objectToken.joined(separator: ",")
        return params
    }
}
