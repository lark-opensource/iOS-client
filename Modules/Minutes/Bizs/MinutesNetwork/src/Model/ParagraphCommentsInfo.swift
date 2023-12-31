//
//  ParagraphCommentsInfo.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/2.
//

import Foundation

public struct ParagraphCommentsInfo: Codable {

    public let pid: String
    public let commentNum: Int
    public var commentList: [Comment]?

    public init(pid: String, commentNum: Int, commentList: [Comment]) {
        self.pid = pid
        self.commentNum = commentNum
        self.commentList = commentList
    }

    private enum CodingKeys: String, CodingKey {
        case pid = "pid"
        case commentNum = "comment_num"
        case commentList = "comment_list"
    }
}

public struct ParagraphCommentsInfoV2: Codable {

    public let pid: String
    public let commentNum: Int

    public init(pid: String, commentNum: Int) {
        self.pid = pid
        self.commentNum = commentNum
    }

    private enum CodingKeys: String, CodingKey {
        case pid = "pid"
        case commentNum = "comment_num"
    }
}
