//
//  FetchSummariesRequest.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/5/12.
//

import Foundation

public struct FetchSummariesRequest: Request {
    public typealias ResponseType = Response<Summaries>

    public let endpoint: String = MinutesAPIPath.summaries
    public let requestID: String = UUID().uuidString
    public let objectToken: String
    public let language: String?
    public var catchError: Bool
    public var chapter: Bool? = nil

    public init(objectToken: String, language: String?, catchError: Bool, chapter: Bool? = nil) {
        self.objectToken = objectToken
        self.language = language
        self.catchError = catchError
        self.chapter = chapter
    }

    public var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["translate_lang"] = language
        if let chapter = chapter {
            params["only_agenda"] = true
        }
        return params
    }
}
