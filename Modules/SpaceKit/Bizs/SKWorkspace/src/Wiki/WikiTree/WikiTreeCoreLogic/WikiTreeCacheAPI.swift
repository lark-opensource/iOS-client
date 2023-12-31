//
//  WikiTreeDataBaseHandler.swift
//  SKWikiV2
//
//  Created by 邱沛 on 2021/6/10.
//

import SKFoundation
import RxSwift
import RxCocoa
import SpaceInterface

public protocol WikiTreeCacheAPI {

    typealias NodeChildren = WikiTreeRelation.NodeChildren
    typealias MetaStorage = WikiTreeNodeMeta.MetaStorage

    func loadSpaceInfo(spaceID: String) -> Maybe<WikiSpace>
    func loadTree(spaceID: String, initialWikiToken: String?) -> Maybe<(WikiTreeRelation, MetaStorage)>
    func loadFavoriteList(spaceID: String) -> Maybe<([NodeChildren], MetaStorage)>
    /// loadChildren 需要 spaceID 是为了避免跨库移动后拉到其他知识库的数据
    /// 现有的场景一定能拿到对应节点的正确 spaceID
    func loadChildren(spaceID: String, wikiToken: String) -> Maybe<([NodeChildren], MetaStorage)>
    func updateFavoriteList(spaceID: String, metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable
    func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable
    func batchUpdate(nodes: [WikiServerNode], relation: WikiTreeRelation) -> Completable
    func update(node: WikiServerNode, children: [String]?) -> Completable
    func delete(wikiTokens: [String]) -> Completable
    func updateSpaceInfoIfNeed(spaceInfo: WikiSpace?) -> Completable
    func loadWikiSpaceTree() -> Maybe<(WikiTreeRelation, MetaStorage)>
    func loadDocumentList() -> Maybe<([NodeChildren], MetaStorage)>
    func loadHomeSharedList() -> Maybe<([NodeChildren], MetaStorage)>
    func updateClipDocumentList(metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable
    func updateHomeSharedList(metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable
    // 判断当前节点是否有子节点缓存
    func nodeHadChildren(meta: WikiTreeNodeMeta) -> Bool
}

protocol WikiTreeCacheDBProvider: AnyObject {
    var spacesTable: WikiSpaceTable? { get }
    var wikiTreeDBNodeTable: WikiTreeDBNodeTable? { get }
    var wikiSpaceQuoteListTable: WikiSpaceQuoteListTable? { get }
}

extension WikiStorage: WikiTreeCacheDBProvider {}

public class WikiTreeCacheHandle: WikiTreeCacheAPI {

    enum CacheError: Error {
        // 弱引用失效
        case cacheAPIReferenceError
        case tableNotFound
    }

    public static let shared: WikiTreeCacheHandle = {
        let api = WikiTreeCacheHandle()
        api.provider = WikiStorage.shared
        return api
    }()

    weak var provider: WikiTreeCacheDBProvider?

    var spaceTable: WikiSpaceTable? { provider?.spacesTable }
    var dbNodeTable: WikiTreeDBNodeTable? { provider?.wikiTreeDBNodeTable }
    var wikiSpaceQuoteListTable: WikiSpaceQuoteListTable? { provider?.wikiSpaceQuoteListTable }
    
    let dbQueue = DispatchQueue(label: "com.wiki.treeDBQueue")

    public func loadTree(spaceID: String, initialWikiToken: String?) -> Maybe<(WikiTreeRelation, MetaStorage)> {
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }
            self.dbQueue.async {
                guard let table = self.dbNodeTable else {
                    maybe(.error(CacheError.tableNotFound))
                    return
                }

                var metaStorage = MetaStorage()
                var relation = WikiTreeRelation()

                var nextToken: String?
                if let initialWikiToken = initialWikiToken {
                    nextToken = initialWikiToken
                } else {
                    guard let rootToken = table.getRootWikiToken(spaceID: spaceID, rootType: .mainRoot) else {
                        maybe(.completed)
                       return
                    }
                    nextToken = rootToken
                }
                // 以下为循环实现的递归调用，层层往上直到 parent 为空（到达根节点）
                while let targetToken = nextToken, !targetToken.isEmpty {
                    // 1. 先读取当前节点，可能是根节点，或树上某个节点（链接访问场景）
                    guard let targetNode = table.getNodes(spaceID: spaceID, wikiTokens: [targetToken]).first else {
                        // 读不到下一个要处理的节点，终止循环
                        break
                    }
                    // 2. 加载当前节点的 children
                    if let children = targetNode.children {
                        metaStorage[targetToken] = targetNode.meta
                        relation.setup(rootToken: targetToken)
                        let childrenNodes = table.getNodes(spaceID: spaceID, wikiTokens: children)
                        childrenNodes.forEach { node in
                            metaStorage[node.meta.wikiToken] = node.meta
                            relation.insert(wikiToken: node.meta.wikiToken,
                                            sortID: node.sortID,
                                            parentToken: targetToken)
                        }
                    }
                    // 3. 更新 nextToken 为 parent
                    nextToken = targetNode.parent
                }
                if metaStorage.isEmpty {
                    // 一个节点都没有，抛缓存不存在
                    maybe(.completed)
                    return
                }
                maybe(.success((relation, metaStorage)))
            }
            return Disposables.create()
        }
    }

    public func loadFavoriteList(spaceID: String) -> Maybe<([NodeChildren], MetaStorage)> {
        loadTreeList(type: .favoriteRoot(spaceId: spaceID))
    }
    
    public func loadDocumentList() -> Maybe<([NodeChildren], MetaStorage)> {
        loadTreeList(type: .documentRoot)
    }
    
    public func loadHomeSharedList() -> Maybe<([NodeChildren], MetaStorage)> {
        loadTreeList(type: .homeSharedRoot)
    }
    
    // 虚拟根节点类型
    private enum MockTreeRootType {
        // 原知识库内部置顶根节点
        case favoriteRoot(spaceId: String)
        // 首页置顶云文档根节点
        case documentRoot
        // 首页共享根节点
        case homeSharedRoot
    }
    
    private func loadTreeList(type: MockTreeRootType)  -> Maybe<([NodeChildren], MetaStorage)> {
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }

            self.dbQueue.async {
                guard let table = self.dbNodeTable else {
                    maybe(.error(CacheError.tableNotFound))
                    return
                }

                var metaStorage = MetaStorage()
                var relation = WikiTreeRelation()
                var rootMeta: WikiTreeNodeMeta
                var nodes: [WikiTreeDBNode]?
                
                switch type {
                case let .favoriteRoot(spaceId):
                    rootMeta = WikiTreeNodeMeta.createFavoriteRoot(spaceID: spaceId)
                    nodes = table.getFavoriteList(spaceID: spaceId)
                case .documentRoot:
                    rootMeta = WikiTreeNodeMeta.createDocumentRoot()
                    nodes = table.getDocumentList()
                case .homeSharedRoot:
                    rootMeta = WikiTreeNodeMeta.createHomeSharedRoot()
                    nodes = table.getHomeShareList()
                }

                guard let nodes else {
                    maybe(.completed)
                    return
                }
                if nodes.isEmpty {
                    // 空数据需要隐藏这一部分，因此直接返回空数据
                    maybe(.success(([], [:])))
                    return
                }
                
                metaStorage[rootMeta.wikiToken] = rootMeta
                relation.setup(rootToken: rootMeta.wikiToken)

                nodes.forEach { node in
                    metaStorage[node.meta.wikiToken] = node.meta
                    relation.insert(wikiToken: node.meta.wikiToken,
                                    sortID: node.sortID,
                                    parentToken: rootMeta.wikiToken)
                }
                let children = relation.nodeChildrenMap[rootMeta.wikiToken] ?? []
                maybe(.success((children, metaStorage)))
            }
            return Disposables.create()
        }
    }

    public func loadChildren(spaceID: String, wikiToken: String) -> Maybe<([NodeChildren], MetaStorage)> {
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }

            self.dbQueue.async {
                guard let table = self.dbNodeTable else {
                    maybe(.error(CacheError.tableNotFound))
                    return
                }

                var metaStorage = MetaStorage()
                var relation = WikiTreeRelation()

                guard let targetNode = table.getNodes(spaceID: spaceID, wikiTokens: [wikiToken]).first else {
                    maybe(.completed)
                    return
                }
                guard let childrenTokens = targetNode.children else {
                    maybe(.completed)
                    return
                }
                relation.setup(rootToken: wikiToken)
                let childrenNodes = table.getNodes(spaceID: spaceID, wikiTokens: childrenTokens)
                if childrenNodes.isEmpty {
                    maybe(.completed)
                    return
                }

                childrenNodes.forEach { node in
                    metaStorage[node.meta.wikiToken] = node.meta
                    relation.insert(wikiToken: node.meta.wikiToken,
                                    sortID: node.sortID,
                                    parentToken: wikiToken)
                }

                let children = relation.nodeChildrenMap[wikiToken] ?? []
                maybe(.success((children, metaStorage)))
            }

            return Disposables.create()
        }
    }

    public func updateFavoriteList(spaceID: String, metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
        let favoriteRoot = WikiTreeNodeMeta.createFavoriteRoot(spaceID: spaceID)
        let favoriteList = relation.nodeChildrenMap[favoriteRoot.wikiToken] ?? []
        var nodes: [WikiServerNode] = []
        favoriteList.forEach { nodeChildren in
            guard let meta = metaStorage[nodeChildren.wikiToken] else {
                spaceAssertionFailure("meta not found when update favorite list")
                return
            }
            let parent = relation.nodeParentMap[meta.wikiToken] ?? favoriteRoot.wikiToken
            let node = WikiServerNode(meta: meta,
                                      sortID: nodeChildren.sortID,
                                      parent: parent)
            nodes.append(node)
        }
        let rootNode = WikiServerNode(meta: favoriteRoot, sortID: 0, parent: "")
        nodes.append(rootNode)
        return batchUpdate(nodes: nodes, relation: relation, shouldUpdateSortID: false)
    }
    
    public func updateHomeSharedList(metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
        let root = WikiTreeNodeMeta.createHomeSharedRoot()
        return updateHomeTreeList(root: root, metaStorage: metaStorage, relation: relation)
    }
    
    public func updateClipDocumentList(metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
        let root = WikiTreeNodeMeta.createDocumentRoot()
        return updateHomeTreeList(root: root, metaStorage: metaStorage, relation: relation)
    }
    
    private func updateHomeTreeList(root: WikiTreeNodeMeta, metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
        let list = relation.nodeChildrenMap[root.wikiToken] ?? []
        var nodes: [WikiServerNode] = []
        list.forEach { nodeChildren in
            guard let meta = metaStorage[nodeChildren.wikiToken] else {
                spaceAssertionFailure("meta not found when update document list")
                return
            }
            let parent = relation.nodeParentMap[meta.wikiToken] ?? root.wikiToken
            let node = WikiServerNode(meta: meta,
                                      sortID: nodeChildren.sortID,
                                      parent: parent)
            nodes.append(node)
        }
        let rootNode = WikiServerNode(meta: root, sortID: 0, parent: "")
        nodes.append(rootNode)
        return batchUpdate(nodes: nodes, relation: relation, shouldUpdateSortID: false)
    }

    public func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
        // 将 metaStorage 中的所有节点转换为 WikiServerNode
        let nodes = Self.convert(metas: metas, relation: relation)
        return batchUpdate(nodes: nodes, relation: relation)
    }

    static func convert(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> [WikiServerNode] {
        metas.compactMap { meta in
            // 仅根节点会特化为 ""
            let parent: String
            let sortID: Double
            if let nodeParent = relation.nodeParentMap[meta.wikiToken], !nodeParent.isEmpty {
                parent = nodeParent
                guard let realSortID = relation.getSortID(wikiToken: meta.wikiToken) else {
                    spaceAssertionFailure("sortID not found")
                    return nil
                }
                sortID = realSortID
            } else {
                if !meta.nodeType.isRootType {
                    DocsLogger.warning("only root node type allow nil parent", extraInfo: ["token": DocsTracker.encrypt(id: meta.wikiToken)])
                }
                parent = ""
                sortID = 0
            }
            return WikiServerNode(meta: meta, sortID: sortID, parent: parent)
        }
    }

    public func batchUpdate(nodes: [WikiServerNode], relation: WikiTreeRelation) -> Completable {
        batchUpdate(nodes: nodes, relation: relation, shouldUpdateSortID: true)
    }
    // 会更新 nodes 中的所有节点，relation 仅提供数据辅助
    func batchUpdate(nodes: [WikiServerNode], relation: WikiTreeRelation, shouldUpdateSortID: Bool) -> Completable {
        Completable.create { [weak self] complete in
            guard let self = self else {
                complete(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }
            self.dbQueue.async {
                guard let table = self.dbNodeTable else {
                    complete(.error(CacheError.tableNotFound))
                    return
                }
                let dbNodes = nodes.map { node -> WikiTreeDBNode in
                    let children = relation.nodeChildrenMap[node.meta.wikiToken]?.map(\.wikiToken)
                    return WikiTreeDBNode(serverNode: node, children: children)
                }
                table.insert(nodes: dbNodes, shouldUpdateSortID: shouldUpdateSortID)
                complete(.completed)
            }
            return Disposables.create()
        }
    }

    public func update(node: WikiServerNode, children: [String]?) -> Completable {
        Completable.create { [weak self] complete in
            guard let self = self else {
                complete(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }
            self.dbQueue.async {
                guard let table = self.dbNodeTable else {
                    complete(.error(CacheError.tableNotFound))
                    return
                }
                let node = WikiTreeDBNode(serverNode: node,
                                          children: children)
                table.insert(nodes: [node])
                complete(.completed)
            }
            return Disposables.create()
        }
    }

    public func delete(wikiTokens: [String]) -> Completable {
        Completable.create { [weak self] complete in
            guard let self = self else {
                complete(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }
            self.dbQueue.async {
                guard let table = self.dbNodeTable else {
                    complete(.error(CacheError.tableNotFound))
                    return
                }
                table.delete(tokens: wikiTokens)
                complete(.completed)
            }
            return Disposables.create()
        }
    }

    public func loadSpaceInfo(spaceID: String) -> Maybe<WikiSpace> {
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }
            self.dbQueue.async {
                guard let table = self.spaceTable else {
                    maybe(.error(CacheError.tableNotFound))
                    return
                }
                guard let spaceInfo = table.getSpace(spaceID) else {
                    maybe(.completed)
                    return
                }
                maybe(.success(spaceInfo))
            }
            return Disposables.create()
        }
    }
    
    // 只在打开某个知识库，且表中没有当前库的spaceInfo数据时添加
    public func updateSpaceInfoIfNeed(spaceInfo: WikiSpace?) -> Completable {
        Completable.create { [weak self] complete in
            guard let self, let spaceTable = self.spaceTable else {
                complete(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }
            guard let spaceInfo, spaceTable.getSpace(spaceInfo.spaceID) == nil else {
                complete(.completed)
                return Disposables.create()
            }
            self.dbQueue.async {
                spaceTable.insert(space: spaceInfo)
                complete(.completed)
            }
            return Disposables.create()
        }
    }
    
    public func loadWikiSpaceTree() -> Maybe<(WikiTreeRelation, MetaStorage)> {
        Maybe.create { [weak self] maybe in
            guard let self else {
                maybe(.error(CacheError.cacheAPIReferenceError))
                return Disposables.create()
            }
            
            self.dbQueue.async {
                guard let spaceTable = self.spaceTable, let quoteListTable = self.wikiSpaceQuoteListTable else {
                    maybe(.error(CacheError.tableNotFound))
                    return
                }
                
                let spaceIds = quoteListTable.getAllStarSpaceIds()
                let spaces = spaceTable.getAllSpacesOfCurrentClass(with: spaceIds)
                var metaStorage = MetaStorage()
                var relation = WikiTreeRelation()
                // 插入虚拟“云空间”根节点
                let mutilTreeRoot = WikiTreeNodeMeta.createMutilTreeRoot()
                metaStorage[mutilTreeRoot.wikiToken] = mutilTreeRoot
                relation.setup(rootToken: mutilTreeRoot.wikiToken)
                
                for (inedx, space) in spaces.enumerated() {
                    // 将space列表空间转化为wikiMeta，与虚拟节点构建父子关系
                    var meta = WikiTreeNodeMeta(wikiToken: space.rootToken,
                                                spaceID: space.spaceID,
                                                objToken: "",
                                                objType: .unknownDefaultType,
                                                title: space.spaceName,
                                                hasChild: true,
                                                secretKeyDeleted: false,
                                                isExplorerStar: false,
                                                nodeType: .mainRoot,
                                                originDeletedFlag: 0,
                                                isExplorerPin: false,
                                                iconInfo: space.iconInfo?.infoString ?? "", 
                                                url: nil)
                    meta.wikiSpaceIconType = space.iconInfo?.iconType
                    metaStorage[space.rootToken] = meta
                    relation.insert(wikiToken: meta.wikiToken, sortID: Double(inedx), parentToken: WikiTreeNodeMeta.mutilTreeRootToken)
                }
                if metaStorage.isEmpty {
                    // 没有知识库，抛缓存不存在
                    maybe(.completed)
                    return
                }
                maybe(.success((relation, metaStorage)))
            }
            return Disposables.create()
        }
    }
    
    public func nodeHadChildren(meta: WikiTreeNodeMeta) -> Bool {
        guard let table = self.dbNodeTable else {
            return false
        }
        guard let targetNode = table.getNodes(spaceID: meta.spaceID, wikiTokens: [meta.wikiToken]).first else {
            return false
        }
        guard targetNode.children != nil else {
            return false
        }
        return true
    }
}
