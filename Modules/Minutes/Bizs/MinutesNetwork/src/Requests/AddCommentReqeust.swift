//
//  AddCommentReqeust.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/2.
//

import Foundation

public struct AddCommentReqeustPayload: Codable {

    public let quote: String?
    public let content: String
    public let commentID: String?
    public let highlights: [String: [SentenceHighlightsInfo]]?

    private enum CodingKeys: String, CodingKey {
        case quote = "quote"
        case content = "content"
        case commentID = "commentId"
        case highlights = "highlights"
    }
}

struct AddCommentReqeust: Request {
    typealias ResponseType = Response<CommonCommentResponse>

    let endpoint: String = "/minutes/api/comment/add_v2"
    let requestID: String = UUID().uuidString
    let method: RequestMethod = .post
    let objectToken: String
    let comment: AddCommentReqeustPayload
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
