//
//  CommentTranslationTools.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/7/15.
//  

import SKFoundation
import SpaceInterface
import SKCommon 

public final class CommentTranslationTools: CommentTranslationToolsInterface {

    public static let shared = CommentTranslationTools()

    // 被点击过的翻译位置
    typealias UniqueID = (commentID: String, replyID: String)
    /// 存储点击过"仅译文场景"的"展示原文" commentID + replyID
    var clickedShowOriInOnlyTrans: [UniqueID] = []

    /// 存储过点击"Bothshow场景"的"收起译文" commentID + replyID
    var clickedCloseTransInBothShow: [UniqueID] = []

    public var docsInfo: DocsInfo?

    public func update(commentDocsInfo: CommentDocsInfo?) {
        self.docsInfo = commentDocsInfo as? DocsInfo
    }

    private init() { }

    public func clear() {
        clickedShowOriInOnlyTrans.removeAll()
        clickedCloseTransInBothShow.removeAll()
        translatedStore.removeAll()
        docsInfo = nil
    }

    public var isShowingFeed = false
    
    /// 记录不需要显示翻译的评论，即手动点击了收起译文/显示原文的评论
    var translatedStore: [String: Bool] = [:]
}


// MARK: - 使用Dictionary优化

extension CommentTranslationTools: CommentTranslationToolProtocol {
    
    public func add(store: CommentTranslationStore) {
        translatedStore[store.key] = true
    }
    
    public func remove(store: CommentTranslationStore) {
        translatedStore.removeValue(forKey: store.key)
    }
    
    public func contain(store: CommentTranslationStore) -> Bool {
        return translatedStore[store.key] ?? false
    }
}
