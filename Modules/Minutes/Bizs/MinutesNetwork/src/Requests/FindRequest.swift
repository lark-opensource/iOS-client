//
//  FindRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct FindRequest: Request {
    typealias ResponseType = Response<FindResult>

    let endpoint: String = "/minutes/api/find"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let language: String?
    let type: FindType?
    let query: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["translate_lang"] = language
        params["type"] = type?.rawValue
        params["query"] = query
        return params
    }
}
