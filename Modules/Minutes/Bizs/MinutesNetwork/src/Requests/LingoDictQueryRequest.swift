//
//  LingoDictQueryRequest.swift
//  MinutesNetwork
//
//  Created by ByteDance on 2023/11/3.
//

import Foundation

public struct LingoDictQueryResult: Codable {
    public let phrases: [[LingoDictPhrases]]

    private enum CodingKeys: String, CodingKey {
        case phrases = "phrases"
    }
}

public struct LingoDictPhrases: Codable {
    public let name: String
    public let ids: [String]
    public let span: Span

    public struct Span: Codable {
        public let start: Int
        public let end: Int
    }

    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case ids = "ids"
        case span = "span"
    }
}


public struct LingoDictQueryRequest: Request {

    public typealias ResponseType = Response<LingoDictQueryResult>

    public let endpoint: String = "/lingo/v2/api/batch_recall"
    public let requestID: String = UUID().uuidString
    public let method: RequestMethod = .post
    public let objectToken: String
    public let texts: [String]

    public let catchError: Bool

    public init(objectToken: String, texts: [String], catchError: Bool) {
        self.objectToken = objectToken
        self.texts = texts
        self.catchError = catchError
    }

    public var parameters: [String: Any] {
        let params: [String: Any] = ["object_token": objectToken,
                                    "enter_from": "minutes",
                                    "texts": texts]
        return params
    }
}
