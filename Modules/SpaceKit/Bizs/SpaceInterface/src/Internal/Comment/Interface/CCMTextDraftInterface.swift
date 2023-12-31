//
//  CCMTextDraftInterface.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/4/3.
//  


import Foundation

/// 编辑草稿Key
public protocol CCMTextDraftKey {
    
    /// 文档或drive的唯一标识，顶级key
    var entityId: String? { get }
    
    /// 自定义Key，子级key
    var customKey: String { get }
}

public protocol CommentDraftManagerInterface {
    func removeExpiredModels(seconds: Int?) -> Bool
    func commentModel(for key: CommentDraftKey) -> Swift.Result<CommentDraftModel, Error>
    func handleDocsDelete(token: String)
}
