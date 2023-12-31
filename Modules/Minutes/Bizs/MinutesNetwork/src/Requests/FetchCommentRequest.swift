//
//  FetchCommentRequest.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/2.
//

import Foundation

struct FetchCommentRequest: Request {

    typealias ResponseType = Response<CommentResponse>

    let endpoint: String = "/minutes/api/comment_v2"
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
