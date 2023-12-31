//
//  FetchParticipantsSuggestionReqeust.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/6/18.
//

import Foundation

struct FetchParticipantsSuggestionReqeust: Request {

    typealias ResponseType = Response<ParticipantsSearch>

    let endpoint: String = "/minutes/api/participants/suggestion"
    let requestID: String = UUID().uuidString
    let objectToken: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
