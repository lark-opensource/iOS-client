//
//  DeleteRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct DeleteRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/object/delete"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
