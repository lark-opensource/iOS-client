//
//  ReviewAppealRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/2/28.
//

import Foundation

struct ReviewAppealRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/review/appeal"

    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
