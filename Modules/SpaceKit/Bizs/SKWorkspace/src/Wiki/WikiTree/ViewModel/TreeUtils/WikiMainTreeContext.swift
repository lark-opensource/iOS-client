//
//  WikiMainTreeScene.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/19.
//

import Foundation


// 目录树场景，便于一些需要区分场景做不同逻辑的判断
public enum WikiMainTreeScene: Equatable {
    // 知识空间首页目录树
    case spacePage
    // 文档详情页内目录树
    case documentDraggablePage
    // 我的文档库
    case myLibrary
}

// 从知识空间打开详情页，需要携带一份目录树上下文
public struct WikiTreeContext {
    
    public let nodeUID: WikiTreeNodeUID
    // 替代一次 TreeInfo 请求所需的信息
    public let spaceID: String
    public let treeState: WikiTreeState
    public let spaceInfo: WikiSpace?
    public let userSpacePermission: WikiUserSpacePermission?
    // 携带的一些传递给wiki容器的参数
    public let params: [String: Any]?
    
    public init(nodeUID: WikiTreeNodeUID,
                spaceID: String,
                treeState: WikiTreeState,
                spaceInfo: WikiSpace? = nil,
                userSpacePermission: WikiUserSpacePermission? = nil,
                params: [String: Any]? = nil) {
        self.nodeUID = nodeUID
        self.spaceID = spaceID
        self.treeState = treeState
        self.spaceInfo = spaceInfo
        self.userSpacePermission = userSpacePermission
        self.params = params
    }
}
