//
//  MinutesClipDeleteRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2022/5/10.
//

import Foundation

struct MinutesClipDeleteRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/clip/delete"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
