//
//  SendReactionReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/6.
//

import Foundation

struct SendReactionReqeust: Request {
    typealias ResponseType = Response<ReactionInfoResponse>

    let endpoint: String = "/minutes/api/reaction/add"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let reaction: ReactionInfo

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        if let json = try? JSONEncoder().encode(reaction), let jsonString = String(data: json, encoding: .utf8) {
            params["reaction"] = jsonString
        }
        return params
    }
}
