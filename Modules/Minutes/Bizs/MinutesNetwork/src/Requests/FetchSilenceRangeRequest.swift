//
//  FetchSlienceRangeRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/7.
//

import Foundation

struct FetchSilenceRangeRequest: Request {
    typealias ResponseType = Response<SilenceInfo>

    let endpoint: String = "/minutes/api/silence"
    let requestID: String = UUID().uuidString
    let objectToken: String
    let language: String?
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["language"] = language
        return params
    }
}
