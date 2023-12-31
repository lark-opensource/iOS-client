//
//  FetchClipListRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2022/5/10.
//

import Foundation

struct FetchClipListRequest: Request {
    typealias ResponseType = Response<MinutesClipList>

    let endpoint: String = "/minutes/api/clip"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .get
    let objectToken: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        return params
    }
}
