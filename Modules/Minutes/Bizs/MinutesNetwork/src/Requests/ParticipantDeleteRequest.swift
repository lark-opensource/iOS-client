//
//  ParticipantDeleteRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/6/22
//

import Foundation
struct ParticipantDeleteRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/participants/delete"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let userId: String
    let userType: Int
    let actionId: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["action_id"] = actionId
        params["user_id"] = userId
        params["user_type"] = userType
        return params
    }
}
