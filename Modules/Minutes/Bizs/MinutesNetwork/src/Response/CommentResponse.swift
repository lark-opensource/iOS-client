//
//  CommentResponse.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/2.
//

import Foundation

public struct CommentResponse: Codable {

    public let comments: [String: ParagraphCommentsInfo]

}

public struct CommonCommentResponse: Codable {
    public let comments: [String: ParagraphCommentsInfo]
    public let subtitles: [String: Paragraph]

    public init(comments: [String: ParagraphCommentsInfo], subtitles: [String: Paragraph] ) {
        self.comments = comments
        self.subtitles = subtitles
    }

}

public struct CommonCommentResponseV2: Codable {
    public let comments: [String: ParagraphCommentsInfoV2]
    public let subtitles: [String: Paragraph]

    public init(comments: [String: ParagraphCommentsInfoV2], subtitles: [String: Paragraph] ) {
        self.comments = comments
        self.subtitles = subtitles
    }

}

public struct CommentResponseV2: Codable {
    public let commentID: String
    public let subtitles: [String: Paragraph]

    public init(commentID: String, subtitles: [String: Paragraph] ) {
        self.commentID = commentID
        self.subtitles = subtitles
    }

}
