//
//  FetchSpeakerSuggestionRequest.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2021/6/20.
//

import Foundation

struct FetchSpeakerSuggestionRequest: Request {

    typealias ResponseType = Response<SpeakerSuggestion>

    let endpoint: String = "/minutes/api/subtitles/speaker/suggestion"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .get
    let objectToken: String
    let paragraphId: String
    let offset: Int
    let size: Int
    let language: String

    var parameters: [String: Any] {
        let para: [String: Any] = ["object_token": objectToken,
                                    "paragraph_id": paragraphId,
                                    "offset": offset,
                                    "size": size,
                                    "language": language]
        return para
    }
}
