//
//  FetchMoreDetailsRequest.swift
//  MinutesFoundation
//
//  Created by sihuahao on 2021/7/2.
//

import Foundation

struct FetchMoreDetailsRequest: Request {
    typealias ResponseType = Response<MoreDetailsInfo>

    let endpoint: String = "/minutes/api/statistics"
    let requestID: String = UUID().uuidString
    let objectToken: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
