//
//  UpdateTitleRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/23.
//

import Foundation

struct UpdateTitleRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/object/edit"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let topic: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["topic"] = topic
        return params
    }
}
