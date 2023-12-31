//
//  FetchKeywordsRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

struct FetchKeywordsRequest: Request {
    typealias ResponseType = Response<Keywords>

    let endpoint: String = MinutesAPIPath.keywords
    let requestID: String = UUID().uuidString
    let objectToken: String
    let language: String?
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["translate_lang"] = language
        return params
    }
}
