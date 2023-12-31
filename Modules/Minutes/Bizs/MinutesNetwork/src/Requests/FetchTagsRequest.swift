//
//  FetchTagsRequest.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation

public struct FetchTagsRequest: Request {
    public typealias ResponseType = Response<[NewDisplayTags]>

    public let endpoint: String = "/minutes/api/tags"
    public let requestID: String = UUID().uuidString
    public let method: RequestMethod = .get
    public let objectToken: String
    public let catchError: Bool

    public init(objectToken: String, catchError: Bool) {
        self.objectToken = objectToken
        self.catchError = catchError
    }

    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}

