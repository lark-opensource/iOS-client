//
//  DeleteCommentRequest.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/2/7.
//

import Foundation

struct DeleteCommentRequest: Request {
    typealias ResponseType = Response<CommonCommentResponse>

    let endpoint: String = "/minutes/api/comment/delete"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let contentId: String
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        params["content_id"] = contentId

        return params
    }
}
