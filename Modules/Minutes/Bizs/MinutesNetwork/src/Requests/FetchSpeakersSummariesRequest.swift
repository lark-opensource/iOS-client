//
//  FetchSpeakersSummariesRequest.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/10/8.
//

import Foundation

public struct FetchSpeakersSummariesRequest: Request {
    public typealias ResponseType = Response<SpeakersSummaries>

    public let endpoint: String = MinutesAPIPath.speakersSummaries
    public let requestID: String = UUID().uuidString
    public let objectToken: String
    public let language: String?
    public var catchError: Bool
    public let aiType: Int

    public init(objectToken: String, language: String?, catchError: Bool, aiType: Int) {
        self.objectToken = objectToken
        self.language = language
        self.catchError = catchError
        self.aiType = aiType
    }

    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["translate_lang"] = language
        params["ai_type"] = aiType
        return params
    }
}
