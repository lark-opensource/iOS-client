//
//  WikiStorageAPI.swift
//  SKCommon
//
//  Created by majie.7 on 2023/5/11.
//

import Foundation
import SpaceInterface

// TODO: 暂时放到SKCommon, 后续下沉到SKWokrSpace  @majie.7
public protocol WikiStorageBase: SimpleModeObserver {
    func cleanUpDB()
    func deleteDB()
    func resetDB()
    /// 保存WikiNodeMeta信息（需请求），注意可能出现 wiki 移动到 space 的场景，此时 spaceID 没有意义，是空字符串
    func setWikiMeta(wikiToken: String, completion: @escaping (WikiInfo?, Error?) -> Void)
    /// 保存WikiNodeMeta信息（不需请求）
    func setWikiMeta(wikiToken: String, objToken: String, objType: Int, spaceId: String)
    /// 获取WikiNodeMeta信息
    func getWikiInfo(by wikiToken: String) -> WikiInfo?
    /// 插入fakeNode到文档库目录树
    func insertFakeNodeForLibrary(wikiNode: WikiNode)
}


// 供其他业务方使用的简洁的wiki数据结构
public struct WikiNode {
    public let wikiToken: String
    public let spaceId: String
    public let objToken: String
    public let objType: DocsType
    public let title: String
    
    public init(wikiToken: String, spaceId: String, objToken: String, objType: DocsType, title: String) {
        self.wikiToken = wikiToken
        self.spaceId = spaceId
        self.objToken = objToken
        self.objType = objType
        self.title = title
    }
}
