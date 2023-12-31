//
//  CommentTrackerInterface.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/4/3.
//  


import Foundation

public protocol CommentTrackerInterface {
    func commentReport(action: String, docsInfo: CommentDocsInfo?, cardId: String?, id: String?, isFullComment: Bool?, extra: [String: Any])
    func baseParametera(docsInfo: CommentDocsInfo) -> [String: Any]
    func update(baseParams: [String: Any])
}
