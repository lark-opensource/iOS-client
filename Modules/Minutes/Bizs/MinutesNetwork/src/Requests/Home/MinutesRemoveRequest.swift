//
//  MinutesRemoveRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/7/9.
//

import Foundation

struct MinutesRemoveRequest: Request {
    typealias ResponseType = BasicResponse

    let endpoint: String = "/minutes/api/space/remove"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectTokens: [String]
    let spaceName: MinutesSpaceType

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_tokens"] = objectTokens.joined(separator: ",")
        params["space_name"] = spaceName.rawValue
        return params
    }
}
