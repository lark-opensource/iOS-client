//
//  DataParse.swift
//  DocsNetwork
//
//  Created by weidong fu on 5/12/2017.
//

import Foundation
import SwiftyJSON

public struct DataParser {
    fileprivate var data: [String: Any]?
    fileprivate var entities: [String: Any]?
    fileprivate var nodeList: [TokenStruct]?

    //space列表页
    public init(json: JSON) {
        #if DEBUG
        assert(!Thread.isMainThread, "Warning: Don't Parse data on Main Thread")
        #endif
        let json = json
        self.data = json["data"].dictionaryObject
        self.entities = data?["entities"] as? [String: Any]
        self.nodeList = []

        var data = json["data"].dictionaryObject
        guard let entities = data?["entities"] as? [String: Any],
              let nodes = entities["nodes"] as? [String: Any],
              let nodeList = data?["node_list"] as? [String]  else {
            return
        }

        var newNodeList: [TokenStruct] = []
        var newEntities: [String: Any] = entities
        var newNodes: [TokenStruct: Any] = [:]

        //nodes中节点数和list中的token数量可能不一致。如 nodes中可能有根节点的node,而list中没有根节点的token
        for token in nodeList {
            if let node = nodes[token] as? [String: Any] {
                let tokenNode = TokenStruct(token: token, nodeType: (node["node_type"] as? Int) ?? 0)
                newNodeList.append(tokenNode)
            }
        }

        for (key, value) in nodes {
            if let node = value as? [String: Any] {
                let tokenNode: TokenStruct = TokenStruct(token: key, nodeType: (node["node_type"] as? Int) ?? 0)
                newNodes[tokenNode] = node
            }
        }

        newEntities["nodes"] = newNodes
        data?["entities"] = newEntities

        self.data = data
        self.entities = newEntities
        self.nodeList = newNodeList
    }

    // 添加至 - 最近文件夹
    public init(foderPathJson: JSON) {
        #if DEBUG
        assert(!Thread.isMainThread, "Warning: Don't Parse data on Main Thread")
        #endif
        let json = foderPathJson
        self.data = json["data"].dictionaryObject
        self.entities = data?["entities"] as? [String: Any]
        self.nodeList = []

        guard let tokenPairs = data?["path"] as? [[String]] else {
            return
        }
        let tokens = tokenPairs.compactMap { $0.last }

        var data = json["data"].dictionaryObject
        guard let entities = data?["entities"] as? [String: Any],
              let nodes = entities["nodes"] as? [String: Any] else {
            return
        }

        var newNodeList: [TokenStruct] = []
        var newEntities: [String: Any] = entities
        var newNodes: [TokenStruct: Any] = [:]

        for token in tokens {
            if let node = nodes[token] as? [String: Any] {
                let tokenNode = TokenStruct(token: token, nodeType: (node["node_type"] as? Int) ?? 0)
                newNodeList.append(tokenNode)
                newNodes[tokenNode] = node
            }
        }
        newEntities["nodes"] = newNodes
        data?["entities"] = newEntities

        self.data = data
        self.entities = newEntities
        self.nodeList = newNodeList
    }

    // 旧的解析方式，现在只用于search
    public init(oldJson: JSON) {
        #if DEBUG
        assert(!Thread.isMainThread, "Warning: Don't Parse data on Main Thread")
        #endif
        self.data = oldJson["data"].dictionaryObject
        self.entities = data?["entities"] as? [String: Any]
        self.nodeList = []
    }

    /// 返回nodeToken列表
    public func getFileNodeTokenList() -> [TokenStruct]? {
        return nodeList
    }

    public func getObjTokenList() -> [TokenStruct]? {
        return nodeList
    }
    
    /// 返回User id 与信息的对应关系列表
    public func getUsers() -> ([FileListDefine.UserID: [FileListDefine.Key: Any]]?) {
        return entities?["users"] as? [String: [String: Any]]
    }
    
    /// 返回nodeToken 与信息的对应关系列表
    public func getNodes() -> [TokenStruct: [FileListDefine.Key: Any]]? {
        return entities?["nodes"] as? [TokenStruct: [String: Any]]
    }

    /// 返回objToken 与信息的对应关系列表
    public func getObjInfos() -> [TokenStruct: [FileListDefine.Key: Any]]? {
        return entities?["nodes"] as? [TokenStruct: [String: Any]]
    }
    
    public func getOffline() -> [TokenStruct: [String: Any]]? {
        guard let entities = self.entities,
              let children = entities["offline"] as? [String: [String: Any]] else {
            return nil
        }
        var temp: [TokenStruct: [String: Any]] = [:]
        for (token, node) in children {
            temp[TokenStruct(token: token)] = node
        }
        return temp
    }
    
    public  func getPathes() -> [String]? {
        return data?["path"] as? [String]
    }

    public func getTotalFrom() -> Int? {
        return data?["total"] as? Int
    }
    
    public func getPageTitle() -> String? {
        guard let pathArray = data?["path"] as? [String], let pathNode = pathArray.last else {
            return nil
        }
        let token = TokenStruct(token: pathNode)
        guard let nodes = entities?["nodes"] as? [TokenStruct: [String: Any]], let node = nodes[token] else {
            return nil
        }
        return node["name"] as? String
    }
    
    public func getHasMoreFlag() -> Bool {
        return data?["has_more"] as? Bool ?? false
    }
    
    public func getLastLabel() -> String? {
        return data?["last_label"] as? String
    }
        
    public func getPageInfo() -> PagingInfo {
        let hasMore = getHasMoreFlag()
        let total = getTotalFrom()
        let lastLabel = getLastLabel()
        return PagingInfo(hasMore: hasMore, total: total, pageTitle: nil, lastLabel: lastLabel)
    }

    
    public func getRecentFolderToken() -> [String]? {
        guard let tokenPairs = data?["path"] as? [[String]] else {
            return nil
        }
        
        let tokens = tokenPairs.compactMap { $0.last }
        return tokens
    }
}

// MARK: - Search 相关
extension DataParser {
    // 搜到的联系人的信息
    public func getUserObjs() -> [[String: Any]]? {
        return data?["candidates"] as? [[String: Any]]
    }

    public func getFileObjs() -> [String: [String: Any]]? {
        return entities?["objs"] as? [String: [String: Any]]
    }

    // 搜到的文档的 owner 信息
    public func getOwnerObjs() -> [String: [String: Any]]? {
        return entities?["users"] as? [String: [String: Any]]
    }

    public func getQueryCorrection() -> [String]? {
        if let objs = data?["query_correction"] as? [String], objs.count > 0 {
            return objs
        }
        return nil
    }

    public func getQueryCompletion() -> [String]? {
        if let objs = data?["query_suggestion"] as? [String], objs.count > 0 {
            return objs
        }
        return nil
    }

    public func getStrategy() -> String? {
        return data?["strategy"] as? String
    }

    public func getFileTokens() -> [String]? {
        if let objs = data?["tokens"] as? [String], objs.count > 0 {
            return objs
        }
        return nil
    }
}

// MARK: - Pins 相关
extension DataParser {
    public func getChildrenNodes() -> [TokenStruct: [String: Any]]? {
        guard let entities = self.entities,
              let children = entities["children"] as? [String: [String: Any]] else {
            return nil
        }
        var temp: [TokenStruct: [String: Any]] = [:]
        for (token, node) in children {
            temp[TokenStruct(token: token)] = node
        }
        return temp
    }
}

// MARK: - Feed 相关
extension DataParser {
    public func getMsgs() -> [Any]? {
        return data?["messages"] as? [Any]
    }
}
