//
//  BindCommentRequest.swift
//  MinutesFoundation
//
//  Created by yangyao on 2022/12/1.
//

import Foundation

public struct BindCommentRequestPayload: Codable {

    public let quote: String
    public let commentID: String
    public let content: String?
    public let highlights: [String: [SentenceHighlightsInfo]]?

    private enum CodingKeys: String, CodingKey {
        case quote = "quote"
        case commentID = "comment_id"
        case content = "content"
        case highlights = "highlights"
    }
}

struct BindCommentRequest: Request {
    typealias ResponseType = Response<CommentResponseV2>

    let endpoint: String = "/minutes/api/comment/bind"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let comment: BindCommentRequestPayload
    var catchError: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["object_token"] = objectToken
        if let payload = try? JSONEncoder().encode(comment) {
            params["comment"] = String(data: payload, encoding: .utf8)
        }

        return params
    }
}
