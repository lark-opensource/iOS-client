//
//  ParticipantSearchUsersAddRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct ParticipantSearchUsersAddRequest: Request {
    typealias ResponseType = Response<Participant>

    let endpoint: String = "/minutes/api/participants/search-users/add"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let userName: String
    let uuid: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["user_name"] = userName
        params["uuid"] = uuid
        return params
    }
}
