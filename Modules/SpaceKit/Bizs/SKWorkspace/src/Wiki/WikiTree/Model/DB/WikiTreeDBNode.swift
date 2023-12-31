//
//  WikiTreeNodeTable.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/18.
//
// disable-lint: magic number

import Foundation
import SQLite
import SKCommon
import SKFoundation
import SpaceInterface

struct WikiTreeDBNode: Equatable, Comparable {
    let meta: WikiTreeNodeMeta

    let children: [String]?
    // 部分特殊节点（一级节点）没有 parent
    let parent: String?
    let sortID: Double

    static func < (lhs: WikiTreeDBNode, rhs: WikiTreeDBNode) -> Bool {
        return lhs.sortID < rhs.sortID
    }
}

extension WikiTreeDBNode {
    init(serverNode: WikiServerNode, children: [String]?) {
        meta = serverNode.meta
        self.children = children
        parent = serverNode.parent.isEmpty ? nil : serverNode.parent
        sortID = serverNode.sortID
    }
}

class WikiTreeDBNodeTable {
    private let wikiToken = Expression<String>("wiki_token")
    private let spaceID = Expression<String>("space_id")
    private let objToken = Expression<String>("obj_token")
    private let objType = Expression<Int>("obj_type")
    private let title = Expression<String>("title")
    private let hasChild = Expression<Bool>("has_child")
    private let secretKeyDeleted = Expression<Bool>("secret_key_deleted")
    private let isExplorerStar = Expression<Bool>("is_explorer_star")
    private let isExplorerPin = Expression<Bool>("is_explorer_pin")
    
    private let nodeType = Expression<Int>("node_type")
    private let originWikiToken = Expression<String?>("origin_wiki_token")
    private let originSpaceID = Expression<String?>("origin_space_id")
    private let originIsExternal = Expression<Bool>("origin_is_external")
    private let originDeletedFlag = Expression<Int>("entity_delete_flag")
    
    // nil 表示未请求到, "" 表示没有子节点
    private let children = Expression<String?>("children")
    private let parent = Expression<String?>("parent")
    private let sortID = Expression<Double>("sort_id")
    // true表示云文档新首页的space文档节点
    private let isSpaceLocation = Expression<Bool>("is_space_location")
    private let iconInfo = Expression<String?>("icon_info")
    private let url = Expression<String?>("url")
    
    private let db: Connection
    private let table: Table
    
    init(connection: Connection, tableName: String = "wiki_tree_db_node") {
        db = connection
        table = Table(tableName)
    }
    
    func setup() throws {
        try db.run(createTableCMD)
    }
    
    private var createTableCMD: String {
        table.create(ifNotExists: true) { t in
            t.column(wikiToken, primaryKey: true)
            t.column(spaceID)
            t.column(objToken)
            t.column(objType)
            t.column(title)
            t.column(hasChild)
            t.column(secretKeyDeleted)
            t.column(isExplorerStar)
            t.column(isExplorerPin)
            
            t.column(nodeType)
            t.column(originWikiToken)
            t.column(originSpaceID)
            t.column(originIsExternal)
            t.column(originDeletedFlag)
            
            t.column(children)
            t.column(parent)
            t.column(sortID)
            
            t.column(isSpaceLocation)
            t.column(iconInfo)
            t.column(url)
        }
    }
    
    /// insert + update 二合一方法
    /// - Parameters:
    ///   - shouldUpdateSortID: update 场景，是否需要覆盖 sortID，仅在更新收藏列表的数据时才应该设为 false
    func insert(nodes: [WikiTreeDBNode], shouldUpdateSortID: Bool = true) {
        do {
            try db.transaction {
                for node in nodes {
                    let insert = table.insert(or: .ignore,
                                              wikiToken <- node.meta.wikiToken,
                                              spaceID <- node.meta.spaceID,
                                              objToken <- node.meta.objToken,
                                              objType <- node.meta.objType.rawValue,
                                              title <- node.meta.title,
                                              hasChild <- node.meta.hasChild,
                                              secretKeyDeleted <- node.meta.secretKeyDeleted,
                                              isExplorerStar <- node.meta.isExplorerStar,
                                              isExplorerPin <- node.meta.isExplorerPin,
                                              nodeType <- node.meta.nodeType.rawValue,
                                              originWikiToken <- node.meta.originWikiToken,
                                              originSpaceID <- node.meta.originSpaceID,
                                              originIsExternal <- node.meta.originIsExternal,
                                              originDeletedFlag <- node.meta.originDeletedFlag,
                                              children <- node.children?.joined(separator: ","),
                                              parent <- node.parent,
                                              sortID <- node.sortID,
                                              isSpaceLocation <- node.meta.nodeLocation != .wiki,
                                              iconInfo <- node.meta.iconInfo,
                                              url <- node.meta.url)
                    var updateSetters = [
                        spaceID <- node.meta.spaceID,
                        objToken <- node.meta.objToken,
                        objType <- node.meta.objType.rawValue,
                        title <- node.meta.title,
                        hasChild <- node.meta.hasChild,
                        secretKeyDeleted <- node.meta.secretKeyDeleted,
                        isExplorerStar <- node.meta.isExplorerStar,
                        isExplorerPin <- node.meta.isExplorerPin,
                        nodeType <- node.meta.nodeType.rawValue,
                        originWikiToken <- node.meta.originWikiToken,
                        originSpaceID <- node.meta.originSpaceID,
                        originIsExternal <- node.meta.originIsExternal,
                        originDeletedFlag <- node.meta.originDeletedFlag,
                        parent <- node.parent,
                        isSpaceLocation <- node.meta.nodeLocation != .wiki,
                        iconInfo <- node.meta.iconInfo,
                        url <- node.meta.url
                    ]
                    // 仅在有 children 时，才 update 缓存的 children 字段
                    // 避免 server 数据覆盖了 children 字段后，无法再索引到 cache 中的 children 缓存
                    if let nodeChildren = node.children {
                        updateSetters.append(children <- nodeChildren.joined(separator: ","))
                    }
                    if shouldUpdateSortID {
                        updateSetters.append(sortID <- node.sortID)
                    }
                    let update = table.filter(wikiToken == node.meta.wikiToken).update(updateSetters)
                    try db.run(insert)
                    try db.run(update)
                }
            }
        } catch {
            spaceAssertionFailure("insert failed \(error)")
        }
    }
    
    func delete(tokens: [String]) {
        if tokens.isEmpty {
            return
        }
        do {
            let delete = table
                .filter(tokens.contains(wikiToken))
                .delete()
            try db.run(delete)
        } catch {
            spaceAssertionFailure("delete failed \(error)")
        }
    }
    
    func deleteAll() {
        do {
            let delete = table.delete()
            try db.run(delete)
        } catch {
            spaceAssertionFailure("delete all failed \(error)")
        }
    }
    
    func getNodes(spaceID: String, wikiTokens: [String]) -> [WikiTreeDBNode] {
        if wikiTokens.isEmpty { return [] }
        do {
            let nodes = try db.prepare(table.filter(self.spaceID == spaceID && wikiTokens.contains(wikiToken)))
                .compactMap { parse(row: $0) }
            return nodes
        } catch {
            spaceAssertionFailure("cannot get nodes from db \(error)")
            return []
        }
    }
    
    func getRootWikiToken(spaceID: String, rootType: WikiTreeNodeMeta.NodeType) -> String? {
        guard let row = getRootRow(spaceID: spaceID, rootType: rootType) else {
            return nil
        }
        return row[wikiToken]
    }
    
    private func getRootRow(spaceID: String, rootType: WikiTreeNodeMeta.NodeType) -> Row? {
        guard rootType.isRootType else {
            spaceAssertionFailure("only root node type can be used in this API")
            return nil
        }
        do {
            let filter = table
                .filter(nodeType == rootType.rawValue)
                .filter(self.spaceID == spaceID)
            let rows = try db.prepare(filter)
            return rows.map { $0 }.first
        } catch {
            spaceAssertionFailure("cannot get root wikiToken from db \(error)")
            return nil
        }
    }
    
    func getFavoriteList(spaceID: String) -> [WikiTreeDBNode]? {
        guard let starRootRow = getRootRow(spaceID: spaceID, rootType: .starRoot) else {
            return nil
        }
        guard let childrenValue = starRootRow[children] else {
            return nil
        }
        let childrenTokens = childrenValue.components(separatedBy: ",")
        if childrenTokens.isEmpty { return [] }
        do {
            let rows = try db.prepare(table.filter(childrenTokens.contains(wikiToken)))
            return rows.compactMap {
                let token = $0[wikiToken]
                guard let index = childrenTokens.firstIndex(of: token) else {
                    spaceAssertionFailure("index not found when get favorite list")
                    return nil
                }
                // 收藏列表需要特化一下 sortID 字段，不使用本体信息的 sortID
                // DB 读出来的顺序与 childrenTokens 不一定匹配，需要按照 childrenTokens 的顺序更新 sortID 并排序
                return parse(row: $0, overrideSortID: Double(index * 10))
            }.sorted(by: <)
        } catch {
            spaceAssertionFailure("cannot get favorite nodes from db \(error)")
            return nil
        }
    }
    
    func getHomeShareList() -> [WikiTreeDBNode]? {
        let shareRootRow = getRootRow(spaceID: WikiTreeNodeMeta.homeSharedSpaceID, rootType: .homeSharedRoot)
        let list = getHomeTreeList(rootRow: shareRootRow)
        return list
    }
    
    func getDocumentList() -> [WikiTreeDBNode]? {
        let documentRootRow = getRootRow(spaceID: WikiTreeNodeMeta.clipDocumentSpaceID, rootType: .clipDocumentListRoot)
        let list = getHomeTreeList(rootRow: documentRootRow)
        return list
    }
    
    private func getHomeTreeList(rootRow: Row?) -> [WikiTreeDBNode]? {
        guard let rootRow else {
            return nil
        }
        guard let childrenValue = rootRow[children] else {
            return nil
        }
        let childrenTokens = childrenValue.components(separatedBy: ",")
        if childrenTokens.isEmpty { return [] }
        do {
            let rows = try db.prepare(table.filter(childrenTokens.contains(wikiToken)))
            return rows.compactMap {
                let token = $0[wikiToken]
                guard let index = childrenTokens.firstIndex(of: token) else {
                    spaceAssertionFailure("index not found when get favorite list")
                    return nil
                }
                // 收藏列表需要特化一下 sortID 字段，不使用本体信息的 sortID
                // DB 读出来的顺序与 childrenTokens 不一定匹配，需要按照 childrenTokens 的顺序更新 sortID 并排序
                return parse(row: $0, overrideSortID: Double(index * 10))
            }.sorted(by: <)
        } catch {
            spaceAssertionFailure("cannot get document nodes from db \(error)")
            return nil
        }
    }

    private func parseNodeType(row: Row) -> WikiTreeNodeMeta.NodeType? {
        let nodeTypeRawValue = row[nodeType]
        switch nodeTypeRawValue {
        case 0:
            return .normal
        case 1:
            let originIsExternal = row[self.originIsExternal]
            if originIsExternal {
                return .shortcut(location: .external)
            } else {
                guard let originWikiToken = row[self.originWikiToken],
                      let originSpaceID = row[self.originSpaceID] else {
                    DocsLogger.error("origin wiki info not found when parsing shortcut row")
                    return nil
                }
                return .shortcut(location: .inWiki(wikiToken: originWikiToken, spaceID: originSpaceID))
            }
        case 2:
            return .mainRoot
        case 998:
            return .starRoot
        case 1000:
            return .sharedRoot
        case 1011:
            return .multiTreeRoot
        case 1012:
            return .clipDocumentListRoot
        default:
            DocsLogger.error("unknown nodeType \(nodeTypeRawValue) found")
            return nil
        }
    }

    /// 从 DB 记录转换为 DB 数据结构
    /// - Parameters:
    ///   - row: DB 行
    ///   - overrideSortID: 强制指定的 sortID，仅在置顶列表场景使用
    /// - Returns: 返回构建得到的 DB 数据结构，若 NodeType 解析失败，则为空
    private func parse(row: Row, overrideSortID: Double? = nil) -> WikiTreeDBNode? {
        guard let nodeType = parseNodeType(row: row) else {
            DocsLogger.error("parse node type from row failed")
            return nil
        }
        let childrenTokens: [String]?
        let childrenValue = row[children]
        if let childrenValue = childrenValue {
            if childrenValue.isEmpty {
                childrenTokens = []
            } else {
                childrenTokens = childrenValue.components(separatedBy: ",")
            }
        } else {
            childrenTokens = nil
        }
        var meta = WikiTreeNodeMeta(wikiToken: row[wikiToken],
                                    spaceID: row[spaceID],
                                    objToken: row[objToken],
                                    objType: DocsType(rawValue: row[objType]),
                                    title: row[title],
                                    hasChild: row[hasChild],
                                    secretKeyDeleted: row[secretKeyDeleted],
                                    isExplorerStar: row[isExplorerStar],
                                    nodeType: nodeType,
                                    originDeletedFlag: row[originDeletedFlag],
                                    isExplorerPin: row[isExplorerPin],
                                    iconInfo: row[iconInfo] ?? "", 
                                    url: row[url])
        let isSpaceLocation = row[isSpaceLocation]
        if isSpaceLocation {
            let entry = SpaceEntry(type: meta.objType, nodeToken: meta.objToken, objToken: meta.objToken)
            meta.setNodeLocation(location: .space(file: entry))
        }
        return WikiTreeDBNode(meta: meta,
                              children: childrenTokens,
                              parent: row[parent],
                              sortID: overrideSortID ?? row[sortID])
    }
}
