//
//  CommentInputModelType.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/4/3.
//  


import Foundation

public protocol CommentInputModelType {
    var commentID: String? { get }
    var replyID: String? { get }
    var isWhole: Bool { get }
    var needLoading: Bool?  { get }
    var statsExtra: CommentStatsExtra? { get set }
    mutating func update(docsInfo: CommentDocsInfo)
}
