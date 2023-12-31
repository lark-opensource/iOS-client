//
//  EditTopicRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct EditTopicRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/object/edit"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let topic: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["topic"] = topic
        return params
    }
}
