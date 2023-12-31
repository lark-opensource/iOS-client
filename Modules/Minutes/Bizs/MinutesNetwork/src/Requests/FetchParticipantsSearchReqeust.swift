//
//  FetchParticipantsSearchReqeust.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/6/208.
//

import Foundation

struct FetchParticipantsSearchReqeust: Request {

    typealias ResponseType = Response<ParticipantsSearch>

    let endpoint: String = "/minutes/api/participants/search"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .get
    let objectToken: String
    let query: String
    let uuid: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["query"] = query
        params["uuid"] = uuid
        return params
    }
}
