//
//  WikiTreeTestUtil.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/15.
//

import Foundation
@testable import SKWorkspace
import SQLite

extension WikiTreeTestUtil {
    // 树结构参考
    // https://cf5dgiouqc.feishu.cn/wiki/wikcnyjnPA4G9fLBDOvkww1KqTc
    enum TestTree {
        // level 0
        static let mainRoot = WikiTreeNodeMeta.createMainRoot(rootToken: mainRootToken, spaceID: mockSpaceID)
        static let starRoot = WikiTreeNodeMeta.createFavoriteRoot(spaceID: mockSpaceID)
        static let sharedRoot = WikiTreeNodeMeta.createSharedRoot(spaceID: mockSpaceID)
        // level 1
        static let leaf1 = mockNode(token: "1.leaf", hasChild: false)
        static let shortcut2 = mockShortcutNode(token: "2.leaf-shortcut", originNode: leaf1)
        static let normal3 = mockNode(token: "3.normal", hasChild: true)
        static let shortcut4 = mockShortcutNode(token: "4.normal-shortcut", originNode: normal3)
        static let normal5 = mockNode(token: "5.normal", hasChild: true)
        static let star1 = mockNode(token: "1.star", hasChild: false)
        static let shared1 = mockNode(token: "1.shared", hasChild: false)
        // level 2
        // 3.X
        static let leaf3_1 = mockNode(token: "3.1.leaf", hasChild: false)
        static let shortcut3_2 = mockShortcutNode(token: "3.2.leaf-shortcut", originNode: leaf3_1)
        static let normal3_3 = mockNode(token: "3.3.normal", hasChild: true)
        static let shortcut3_4 = mockShortcutNode(token: "3.4.normal-shortcut", originNode: normal3_3)
        static let shortcut3_5 = mockShortcutNode(token: "3.5.normal-shortcut", originNode: normal5)
        // 5.X
        static let shortcut5_1 = mockShortcutNode(token: "5.1.normal-shortcut", originNode: normal3)
        // level 3
        // 3.3.X
        static let leaf3_3_1 = mockNode(token: "3.3.1.leaf", hasChild: false)

        static var allNodes: [WikiTreeNodeMeta] {
            [mainRoot, leaf1, shortcut2, normal3, shortcut4, normal5, leaf3_1, shortcut3_2, normal3_3, shortcut3_4, shortcut3_5, shortcut5_1, leaf3_3_1, starRoot,
             sharedRoot, star1, shared1]
        }
        static var mainRootChildren: [WikiTreeNodeMeta] {
            [leaf1, shortcut2, normal3, shortcut4, normal5]
        }
        static var node3Children: [WikiTreeNodeMeta] {
            [leaf3_1, shortcut3_2, normal3_3, shortcut3_4, shortcut3_5]
        }
        static var starRootChildren: [WikiTreeNodeMeta] {
            [star1]
        }
        static var sharedRootChildren: [WikiTreeNodeMeta] {
            [shared1]
        }

        static var metaStorage: [String: WikiTreeNodeMeta] {
            var storage: [String: WikiTreeNodeMeta] = [:]
            allNodes.forEach { node in
                storage[node.wikiToken] = node
            }
            return storage
        }

        static var relation: WikiTreeRelation {
            var parentMap: [String: String] = [:]
            mainRootChildren.forEach { node in
                parentMap[node.wikiToken] = mainRoot.wikiToken
            }
            node3Children.forEach { node in
                parentMap[node.wikiToken] = normal3.wikiToken
            }
            parentMap[leaf3_3_1.wikiToken] = normal3_3.wikiToken
            parentMap[shortcut5_1.wikiToken] = normal5.wikiToken
            parentMap[star1.wikiToken] = starRoot.wikiToken
            parentMap[shared1.wikiToken] = sharedRoot.wikiToken

            var childrenMap: [String: [NodeChildren]] = [:]
            childrenMap[mainRoot.wikiToken] = mainRootChildren.enumerated().map { (index, node) in
                NodeChildren(wikiToken: node.wikiToken, sortID: Double(index * 10))
            }
            childrenMap[normal3.wikiToken] = node3Children.enumerated().map { (index, node) in
                NodeChildren(wikiToken: node.wikiToken, sortID: Double(index * 10))
            }
            childrenMap[starRoot.wikiToken] = starRootChildren.enumerated().map({ (index, node) in
                NodeChildren(wikiToken: node.wikiToken, sortID: Double(index * 10))
            })
            childrenMap[sharedRoot.wikiToken] = sharedRootChildren.enumerated().map({ (index, node) in
                NodeChildren(wikiToken: node.wikiToken, sortID: Double(index * 10))
            })
            childrenMap[normal3_3.wikiToken] = [NodeChildren(wikiToken: leaf3_3_1.wikiToken, sortID: 10)]
            childrenMap[normal5.wikiToken] = [NodeChildren(wikiToken: shortcut5_1.wikiToken, sortID: 10)]
            return WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childrenMap)
        }
    }
}

enum WikiTreeTestUtil {
    static let mainRootToken = "MAIN_ROOT"
    static let mockSpaceID = TreeJSON.mockSpaceID
    typealias NodeChildren = WikiTreeRelation.NodeChildren
    static func mockNode(token: String, hasChild: Bool, spaceID: String = mockSpaceID) -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: token,
                         spaceID: spaceID,
                         objToken: token,
                         objType: .doc,
                         title: token,
                         hasChild: hasChild,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .normal,
                         originDeletedFlag: 0,
                         isExplorerPin: false)
    }

    static func mockShortcutNode(token: String, spaceID: String = mockSpaceID, originNode: WikiTreeNodeMeta) -> WikiTreeNodeMeta {
        mockShortcutNode(token: token,
                         spaceID: spaceID,
                         hasChild: originNode.hasChild,
                         originWikiToken: originNode.originWikiToken ?? originNode.wikiToken,
                         originSpaceID: originNode.originSpaceID ?? originNode.spaceID)
    }

    static func mockShortcutNode(token: String, spaceID: String = mockSpaceID, hasChild: Bool, originWikiToken: String, originSpaceID: String) -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: token,
                         spaceID: spaceID,
                         objToken: token,
                         objType: .doc,
                         title: token,
                         hasChild: hasChild,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .shortcut(location: .inWiki(wikiToken: originWikiToken, spaceID: originSpaceID)),
                         originDeletedFlag: 0,
                         isExplorerPin: false)
    }

    static func mockExternalShortcutNode(token: String, spaceID: String = mockSpaceID, hasChild: Bool) -> WikiTreeNodeMeta {
        WikiTreeNodeMeta(wikiToken: token,
                         spaceID: spaceID,
                         objToken: token,
                         objType: .doc,
                         title: token,
                         hasChild: hasChild,
                         secretKeyDeleted: false,
                         isExplorerStar: false,
                         nodeType: .shortcut(location: .external),
                         originDeletedFlag: 0,
                         isExplorerPin: false)
    }

    static func mockTree() -> (WikiTreeRelation, [String: WikiTreeNodeMeta]) {
        (TestTree.relation, TestTree.metaStorage)
    }

    static func mockSpace(spaceID: String, name: String) -> WikiSpace {
        WikiSpace(spaceId: spaceID,
                  spaceName: name,
                  rootToken: "MOCK_ROOT_TOKEN",
                  tenantID: nil,
                  wikiDescription: "",
                  isStar: nil,
                  cover: .init(originPath: "", thumbnailPath: "", name: "", isDarkStyle: false, rawColor: ""),
                  lastBrowseTime: nil,
                  wikiScope: nil,
                  ownerPermType: nil,
                  migrateStatus: nil,
                  openSharing: nil,
                  spaceType: nil,
                  createUID: nil,
                  displayTag: nil)
    }

    static var mockSpacePermission: WikiUserSpacePermission {
        WikiUserSpacePermission(canViewGeneralInfo: true, canStarWiki: true)
    }
}

extension WikiTreeTestUtil {
    enum DBTestTree {
        // level 0
        static var mainRoot: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.mainRoot,
                           children: TestTree.mainRootChildren.map(\.wikiToken),
                           parent: nil,
                           sortID: 0)
        }
        // level 1
        static var leaf1: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.leaf1,
                           children: [],
                           parent: TestTree.mainRoot.wikiToken,
                           sortID: 0)
        }
        static var shortcut2: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.shortcut2,
                           children: nil,
                           parent: TestTree.mainRoot.wikiToken,
                           sortID: 10)
        }
        static var normal3: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.normal3,
                           children: TestTree.node3Children.map(\.wikiToken),
                           parent: TestTree.mainRoot.wikiToken,
                           sortID: 20)
        }
        static var shortcut4: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.shortcut4,
                           children: nil,
                           parent: TestTree.mainRoot.wikiToken,
                           sortID: 30)
        }
        static var normal5: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.normal5,
                           children: [TestTree.shortcut5_1.wikiToken],
                           parent: TestTree.mainRoot.wikiToken,
                           sortID: 40)
        }
        // level 2
        // 3.X
        static var leaf3_1: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.leaf3_1,
                           children: [],
                           parent: TestTree.normal3.wikiToken,
                           sortID: 0)
        }
        static var shortcut3_2: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.shortcut3_2,
                           children: nil,
                           parent: TestTree.normal3.wikiToken,
                           sortID: 10)
        }
        static var normal3_3: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.normal3_3,
                           children: [TestTree.leaf3_3_1.wikiToken],
                           parent: TestTree.normal3.wikiToken,
                           sortID: 20)
        }
        static var shortcut3_4: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.shortcut3_4,
                           children: nil,
                           parent: TestTree.normal3.wikiToken,
                           sortID: 30)
        }
        static var shortcut3_5: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.shortcut3_5,
                           children: nil,
                           parent: TestTree.normal3.wikiToken,
                           sortID: 40)
        }
        // 5.X
        static var shortcut5_1: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.shortcut5_1,
                           children: nil,
                           parent: TestTree.normal5.wikiToken,
                           sortID: 10)
        }
        // level 3
        // 3.3.X
        static var leaf3_3_1: WikiTreeDBNode {
            WikiTreeDBNode(meta: TestTree.leaf3_3_1,
                           children: [],
                           parent: TestTree.normal3_3.wikiToken,
                           sortID: 10)
        }

        static var allNodes: [WikiTreeDBNode] {
            [mainRoot, leaf1, shortcut2, normal3, shortcut4, normal5, leaf3_1, shortcut3_2, normal3_3, shortcut3_4, shortcut3_5, shortcut5_1, leaf3_3_1]
        }

        static var mainRootChildren: [WikiTreeDBNode] {
            [leaf1, shortcut2, normal3, shortcut4, normal5]
        }

        static var node3Children: [WikiTreeDBNode] {
            [leaf3_1, shortcut3_2, normal3_3, shortcut3_4, shortcut3_5]
        }
    }
    enum DBUtil {
        static var mockMainRoot: WikiTreeDBNode {
            let mainRoot = WikiTreeNodeMeta.createMainRoot(rootToken: "MOCK_MAIN_ROOT", spaceID: mockSpaceID)
            return WikiTreeDBNode(meta: mainRoot, children: ["MOCK_1", "MOCK_2", "MOCK_3"], parent: nil, sortID: 0)
        }

        static var mockFavoriteRoot: WikiTreeDBNode {
            let mainRoot = WikiTreeNodeMeta.createFavoriteRoot(spaceID: mockSpaceID)
            return WikiTreeDBNode(meta: mainRoot, children: ["MOCK_3", "MOCK_2"], parent: nil, sortID: 0)
        }

        static var mockNode1: WikiTreeDBNode {
            WikiTreeDBNode(meta: mockNode(token: "MOCK_1", hasChild: true),
                           children: ["MOCK_1_1", "MOCK_1_2"],
                           parent: "MOCK_MAIN_ROOT",
                           sortID: 0)
        }

        static var mockNode1_1: WikiTreeDBNode {
            WikiTreeDBNode(meta: mockExternalShortcutNode(token: "MOCK_1_1", hasChild: false),
                           children: [],
                           parent: "MOCK_1",
                           sortID: 100)
        }

        static var mockNode1_2: WikiTreeDBNode {
            let meta = mockShortcutNode(token: "MOCK_1_2",
                                        hasChild: false,
                                        originWikiToken: "MOCK_3",
                                        originSpaceID: mockSpaceID)
            return WikiTreeDBNode(meta: meta,
                                  children: [],
                                  parent: "MOCK_1",
                                  sortID: 200)
        }

        static var mockNode2: WikiTreeDBNode {
            WikiTreeDBNode(meta: mockNode(token: "MOCK_2", hasChild: false),
                           children: [],
                           parent: "MOCK_MAIN_ROOT",
                           sortID: 0)
        }

        static var mockNode3: WikiTreeDBNode {
            WikiTreeDBNode(meta: mockNode(token: "MOCK_3", hasChild: false),
                           children: [],
                           parent: "MOCK_MAIN_ROOT",
                           sortID: 0)
        }

        static func mockTable(name: String) throws -> Connection {
            let connection = try Connection()
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)
            try table.setup()
            table.insert(nodes: [mockNode1, mockNode2, mockNode3, mockMainRoot, mockFavoriteRoot, mockNode1_1, mockNode1_2])
            return connection
        }

        static func mockTableWithTree(name: String) throws -> Connection {
            let connection = try Connection()
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)
            try table.setup()
            table.insert(nodes: DBTestTree.allNodes)
            return connection
        }
    }
}

extension WikiTreeTestUtil {
    enum ServerTestTree {
        // level 0
        static var mainRoot: WikiServerNode {
            WikiServerNode(meta: TestTree.mainRoot, sortID: 0, parent: "")
        }
        // level 1
        static var leaf1: WikiServerNode {
            WikiServerNode(meta: TestTree.leaf1,
                           sortID: 0,
                           parent: TestTree.mainRoot.wikiToken)
        }
        static var shortcut2: WikiServerNode {
            WikiServerNode(meta: TestTree.shortcut2,
                           sortID: 10,
                           parent: TestTree.mainRoot.wikiToken)
        }
        static var normal3: WikiServerNode {
            WikiServerNode(meta: TestTree.normal3,
                           sortID: 20,
                           parent: TestTree.mainRoot.wikiToken)
        }
        static var shortcut4: WikiServerNode {
            WikiServerNode(meta: TestTree.shortcut4,
                           sortID: 30,
                           parent: TestTree.mainRoot.wikiToken)
        }
        static var normal5: WikiServerNode {
            WikiServerNode(meta: TestTree.normal5,
                           sortID: 40,
                           parent: TestTree.mainRoot.wikiToken)
        }
        // level 2
        // 3.X
        static var leaf3_1: WikiServerNode {
            WikiServerNode(meta: TestTree.leaf3_1,
                           sortID: 0,
                           parent: TestTree.normal3.wikiToken)
        }
        static var shortcut3_2: WikiServerNode {
            WikiServerNode(meta: TestTree.shortcut3_2,
                           sortID: 0,
                           parent: TestTree.normal3.wikiToken)
        }
        static var normal3_3: WikiServerNode {
            WikiServerNode(meta: TestTree.normal3_3,
                           sortID: 20,
                           parent: TestTree.normal3.wikiToken)
        }
        static var shortcut3_4: WikiServerNode {
            WikiServerNode(meta: TestTree.shortcut3_4,
                           sortID: 30,
                           parent: TestTree.normal3.wikiToken)
        }
        static var shortcut3_5: WikiServerNode {
            WikiServerNode(meta: TestTree.shortcut3_5,
                           sortID: 40,
                           parent: TestTree.normal3.wikiToken)
        }
        // 5.X
        static var shortcut5_1: WikiServerNode {
            WikiServerNode(meta: TestTree.shortcut5_1,
                           sortID: 10,
                           parent: TestTree.normal5.wikiToken)
        }
        // level 3
        // 3.3.X
        static var leaf3_3_1: WikiServerNode {
            WikiServerNode(meta: TestTree.leaf3_3_1,
                           sortID: 10,
                           parent: TestTree.normal3_3.wikiToken)
        }

        static var allNodes: [WikiServerNode] {
            [mainRoot, leaf1, shortcut2, normal3, shortcut4, normal5, leaf3_1, shortcut3_2, normal3_3, shortcut3_4, shortcut3_5, shortcut5_1, leaf3_3_1]
        }

        static var mainRootChildren: [WikiServerNode] {
            [leaf1, shortcut2, normal3, shortcut4, normal5]
        }

        static var node3Children: [WikiServerNode] {
            [leaf3_1, shortcut3_2, normal3_3, shortcut3_4, shortcut3_5]
        }
    }
}
