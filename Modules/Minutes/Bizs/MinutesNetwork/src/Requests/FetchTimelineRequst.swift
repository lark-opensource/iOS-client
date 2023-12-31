//
//  FetchTimelineRequst.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/25.
//

import Foundation

struct FetchTimelineRequst: Request {
    typealias ResponseType = Response<ReactionInfoResponse>

    let endpoint: String = "/minutes/api/highlight/timeline_v2"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let language: String?

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["language"] = language
        return params
    }
}
