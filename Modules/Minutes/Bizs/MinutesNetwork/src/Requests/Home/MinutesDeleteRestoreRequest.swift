//
//  MinutesDeleteRestoreRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/7/9.
//

import Foundation

struct MinutesDeleteRestoreRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/space/delete/restore"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectTokens: [String]

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_tokens"] = objectTokens.joined(separator: ",")
        return params
    }
}
