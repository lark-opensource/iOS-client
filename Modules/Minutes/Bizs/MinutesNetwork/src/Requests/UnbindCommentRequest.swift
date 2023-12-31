//
//  UnbindCommentRequest.swift
//  MinutesFoundation
//
//  Created by yangyao on 2022/12/15.
//

import Foundation

struct UnbindCommentRequest: Request {
    typealias ResponseType = Response<String>

    let endpoint: String = "/minutes/api/comment/unbind"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let commentId: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["comment_id"] = commentId

        return params
    }
}
