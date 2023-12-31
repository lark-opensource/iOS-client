//
//  WikiTreeCacheAPITests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/20.
//
// swiftlint:disable type_body_length file_length

import Foundation
@testable import SKWorkspace
import SQLite
import XCTest
import SKFoundation
import RxSwift

class MockCacheProvider: WikiTreeCacheDBProvider {
    var spacesTable: WikiSpaceTable?
    var wikiTreeDBNodeTable: WikiTreeDBNodeTable?
    var wikiSpaceQuoteListTable: WikiSpaceQuoteListTable?
    init() {}
}

class WikiTreeCacheAPITests: XCTestCase {

    typealias Util = WikiTreeTestUtil
    typealias API = WikiTreeCacheHandle
    typealias NodeChildren = WikiTreeRelation.NodeChildren

    var bag = DisposeBag()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        bag = DisposeBag()
    }

    func testLoadNoExistTree() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            provider.wikiTreeDBNodeTable = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            let cache = WikiTreeCacheHandle()
            cache.provider = provider
            // 加载一个不存在的知识库缓存
            var expect = expectation(description: "expect load tree")
            cache.loadTree(spaceID: "unknown", initialWikiToken: nil)
                .subscribe { _ in
                    XCTFail("unexpected success")
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

            // 加载一个有缓存知识库中不存在的节点
            expect = expectation(description: "expect load tree")
            cache.loadTree(spaceID: Util.mockSpaceID, initialWikiToken: "unknown")
                .subscribe { _ in
                    XCTFail("unexpected success")
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    // load 一级节点
    func testLoadRoot() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            provider.wikiTreeDBNodeTable = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            let expect = expectation(description: "expect load tree")
            cache.loadTree(spaceID: Util.mockSpaceID, initialWikiToken: nil)
                .subscribe { (relation, storage) in
                    var expectStorage: [String: WikiTreeNodeMeta] = [:]
                    var expectNodes = Util.TestTree.mainRootChildren
                    expectNodes.append(Util.TestTree.mainRoot)
                    expectNodes.forEach { meta in
                        expectStorage[meta.wikiToken] = meta
                    }
                    XCTAssertEqual(storage, expectStorage)
                    Util.TestTree.mainRootChildren.forEach { meta in
                        XCTAssertEqual(relation.nodeParentMap[meta.wikiToken], Util.TestTree.mainRoot.wikiToken)
                    }
                    XCTAssertEqual(Util.TestTree.relation.nodeChildrenMap[Util.TestTree.mainRoot.wikiToken],
                                   relation.nodeChildrenMap[Util.TestTree.mainRoot.wikiToken])
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    XCTFail("unexpected complete without element")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testLoadWithToken() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            provider.wikiTreeDBNodeTable = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            let expect = expectation(description: "expect load tree")
            // 加载 3.3.1, 预期加载 root - 1~5 3.1~3.5 3.3.1
            cache.loadTree(spaceID: Util.mockSpaceID, initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken)
                .subscribe { (relation, storage) in
                    // level 1
                    Util.TestTree.mainRootChildren.forEach { meta in
                        XCTAssertEqual(relation.nodeParentMap[meta.wikiToken], Util.TestTree.mainRoot.wikiToken)
                    }
                    XCTAssertEqual(Util.TestTree.relation.nodeChildrenMap[Util.mainRootToken],
                                   relation.nodeChildrenMap[Util.mainRootToken])
                    // level 2
                    Util.TestTree.node3Children.forEach { meta in
                        XCTAssertEqual(relation.nodeParentMap[meta.wikiToken], Util.TestTree.normal3.wikiToken)
                    }
                    XCTAssertEqual(Util.TestTree.relation.nodeChildrenMap[Util.TestTree.normal3.wikiToken],
                                   relation.nodeChildrenMap[Util.TestTree.normal3.wikiToken])
                    // level 3
                    XCTAssertEqual(relation.nodeParentMap[Util.TestTree.leaf3_3_1.wikiToken],
                                   Util.TestTree.normal3_3.wikiToken)
                    XCTAssertEqual(Util.TestTree.relation.nodeChildrenMap[Util.TestTree.normal3_3.wikiToken],
                                   relation.nodeChildrenMap[Util.TestTree.normal3_3.wikiToken])

                    var expectStorage: [String: WikiTreeNodeMeta] = [:]
                    var expectNodes = Util.TestTree.mainRootChildren
                    expectNodes.append(Util.TestTree.mainRoot)
                    expectNodes.append(contentsOf: Util.TestTree.node3Children)
                    expectNodes.append(Util.TestTree.leaf3_3_1)
                    expectNodes.forEach { meta in
                        expectStorage[meta.wikiToken] = meta
                    }
                    XCTAssertEqual(storage, expectStorage)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    XCTFail("unexpected complete without element")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testLoadChildren() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            provider.wikiTreeDBNodeTable = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            let expect = expectation(description: "expect load tree")
            // 加载 3 的 children, 预期加载 3.1~3.5
            cache.loadChildren(spaceID: Util.mockSpaceID, wikiToken: Util.TestTree.normal3.wikiToken)
                .subscribe { (children, storage) in
                    XCTAssertEqual(Util.TestTree.relation.nodeChildrenMap[Util.TestTree.normal3.wikiToken],
                                   children)
                    var expectStorage: [String: WikiTreeNodeMeta] = [:]
                    Util.TestTree.node3Children.forEach { meta in
                        expectStorage[meta.wikiToken] = meta
                    }
                    XCTAssertEqual(storage, expectStorage)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    XCTFail("unexpected complete without element")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testLoadNoExistChildren() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            provider.wikiTreeDBNodeTable = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            let cache = WikiTreeCacheHandle()
            cache.provider = provider
            // 加载一个children 未知的节点 children
            var expect = expectation(description: "expect load tree")
            cache.loadChildren(spaceID: Util.mockSpaceID, wikiToken: Util.TestTree.shortcut2.wikiToken)
                .subscribe { _ in
                    XCTFail("unexpected success")
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

            // 加载一个spaceID 不匹配的节点children
            expect = expectation(description: "expect load tree")
            cache.loadChildren(spaceID: "UNKNOWN", wikiToken: Util.TestTree.normal3.wikiToken)
                .subscribe { _ in
                    XCTFail("unexpected success")
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

            // 加载一个不存在的节点children
            expect = expectation(description: "expect load tree")
            cache.loadChildren(spaceID: Util.mockSpaceID, wikiToken: "unknown")
                .subscribe { _ in
                    XCTFail("unexpected success")
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

            // 加载一个叶子节点children
            expect = expectation(description: "expect load tree")
            cache.loadChildren(spaceID: Util.mockSpaceID, wikiToken: Util.TestTree.leaf1.wikiToken)
                .subscribe { _ in
                    XCTFail("unexpected success")
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testUpdate() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            let table = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            provider.wikiTreeDBNodeTable = table
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            // 更新已有节点的 title
            var expect = expectation(description: "expect load tree")
            var newMeta = Util.TestTree.normal3_3
            newMeta.title = "Test"
            var node = WikiServerNode(meta: newMeta, sortID: 20, parent: Util.TestTree.mainRoot.wikiToken)
            cache.update(node: node, children: nil)
                .subscribe {
                    guard let dbNode = table.getNodes(spaceID: Util.mockSpaceID, wikiTokens: [newMeta.wikiToken]).first else {
                        XCTFail("test node not found in DB")
                        expect.fulfill()
                        return
                    }
                    XCTAssertEqual(dbNode.meta, newMeta)
                    XCTAssertEqual(dbNode.children?.count, 1)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

            // 更新缓存节点的 children
            expect = expectation(description: "expect load tree")
            newMeta = Util.TestTree.normal3_3
            newMeta.title = "Test Title"
            node = WikiServerNode(meta: newMeta, sortID: 20, parent: Util.TestTree.mainRoot.wikiToken)
            cache.update(node: node, children: [])
                .subscribe {
                    guard let dbNode = table.getNodes(spaceID: Util.mockSpaceID, wikiTokens: [newMeta.wikiToken]).first else {
                        XCTFail("test node not found in DB")
                        expect.fulfill()
                        return
                    }
                    XCTAssertEqual(dbNode.meta, newMeta)
                    XCTAssertEqual(dbNode.children, [])
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

            // 插入新节点
            expect = expectation(description: "expect load tree")
            newMeta = Util.mockNode(token: "MOCK_TEST_NODE", hasChild: true, spaceID: Util.mockSpaceID)
            node = WikiServerNode(meta: newMeta, sortID: 100, parent: Util.TestTree.mainRoot.wikiToken)
            cache.update(node: node, children: nil)
                .subscribe {
                    guard let dbNode = table.getNodes(spaceID: Util.mockSpaceID, wikiTokens: [newMeta.wikiToken]).first else {
                        XCTFail("test node not found in DB")
                        expect.fulfill()
                        return
                    }
                    XCTAssertEqual(dbNode.meta, newMeta)
                    XCTAssertEqual(dbNode.sortID, 100)
                    XCTAssertEqual(dbNode.parent, Util.TestTree.mainRoot.wikiToken)
                    XCTAssertNil(dbNode.children)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testBatchUpdate() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            let table = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            provider.wikiTreeDBNodeTable = table
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            // 更新已有节点的 title
            let expect = expectation(description: "expect load tree")
            var newMeta1 = Util.TestTree.normal3_3
            newMeta1.title = "Test"
            let node1 = WikiServerNode(meta: newMeta1, sortID: 100, parent: Util.TestTree.mainRoot.wikiToken)
            var newMeta2 = Util.TestTree.normal5
            newMeta2.title = "Test"
            let node2 = WikiServerNode(meta: newMeta2, sortID: 200, parent: Util.TestTree.mainRoot.wikiToken)
            var newMeta3 = Util.mockNode(token: "MOCK_TOKEN", hasChild: true, spaceID: Util.mockSpaceID)
            newMeta3.title = "Test"
            let node3 = WikiServerNode(meta: newMeta3, sortID: 300, parent: Util.TestTree.mainRoot.wikiToken)
            let childrenMap: [String: [WikiTreeRelation.NodeChildren]] = [
                newMeta2.wikiToken: []
            ]
            let relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: childrenMap)
            cache.batchUpdate(nodes: [node1, node2, node3],
                              relation: relation)
                .subscribe {
                    let nodes = table.getNodes(spaceID: Util.mockSpaceID, wikiTokens: [newMeta1.wikiToken, newMeta2.wikiToken, newMeta3.wikiToken])
                        .sorted { $0.sortID < $1.sortID }

                    guard nodes.count == 3 else {
                        XCTFail("test node not found in DB, nodes: \(nodes)")
                        expect.fulfill()
                        return
                    }
                    XCTAssertEqual(nodes[0].meta, newMeta1)
                    XCTAssertEqual(nodes[0].children?.count, 1)
                    XCTAssertEqual(nodes[0].sortID, 100)
                    XCTAssertEqual(nodes[0].parent, Util.TestTree.mainRoot.wikiToken)

                    XCTAssertEqual(nodes[1].meta, newMeta2)
                    XCTAssertEqual(nodes[1].children, [])
                    XCTAssertEqual(nodes[1].sortID, 200)
                    XCTAssertEqual(nodes[1].parent, Util.TestTree.mainRoot.wikiToken)

                    XCTAssertEqual(nodes[2].meta, newMeta3)
                    XCTAssertNil(nodes[2].children)
                    XCTAssertEqual(nodes[2].sortID, 300)
                    XCTAssertEqual(nodes[2].parent, Util.TestTree.mainRoot.wikiToken)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testConvertMetas() {
        var metas = Util.TestTree.mainRootChildren
        metas.append(Util.TestTree.mainRoot)
        let relation = Util.TestTree.relation
        let result = WikiTreeCacheHandle.convert(metas: metas, relation: relation)
        var expect = Util.ServerTestTree.mainRootChildren
        expect.append(Util.ServerTestTree.mainRoot)
        XCTAssertEqual(result.count, 6)
        XCTAssertEqual(result, expect)
    }

    func testLoadFavoriteList() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTable(name: tableName)
            let provider = MockCacheProvider()
            provider.wikiTreeDBNodeTable = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            var expect = expectation(description: "expect load fav tree")
            cache.loadFavoriteList(spaceID: Util.mockSpaceID)
                .subscribe { (children, storage) in
                    let node1 = WikiTreeDBNode(meta: Util.DBUtil.mockNode2.meta,
                                               children: Util.DBUtil.mockNode2.children,
                                               parent: Util.DBUtil.mockNode2.parent,
                                               sortID: 0)
                    let node2 = WikiTreeDBNode(meta: Util.DBUtil.mockNode3.meta,
                                               children: Util.DBUtil.mockNode3.children,
                                               parent: Util.DBUtil.mockNode3.parent,
                                               sortID: 10)
                    let expectStorage: [String: WikiTreeNodeMeta] = [
                        node1.meta.wikiToken: node1.meta,
                        node2.meta.wikiToken: node2.meta,
                        WikiTreeNodeMeta.favoriteRootToken: WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
                    ]
                    XCTAssertEqual(storage, expectStorage)

                    let expectChildren = [
                        WikiTreeRelation.NodeChildren(wikiToken: node2.meta.wikiToken, sortID: 0),
                        WikiTreeRelation.NodeChildren(wikiToken: node1.meta.wikiToken, sortID: 10)
                    ]
                    XCTAssertEqual(children, expectChildren)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    XCTFail("unexpected complete without element")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }

            expect = expectation(description: "expect load unknown fav tree")
            cache.loadFavoriteList(spaceID: "unknown")
                .subscribe { (_, _) in
                    XCTFail("unexpected success")
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                } onCompleted: {
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testUpdateFavoriteList() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            let table = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            provider.wikiTreeDBNodeTable = table
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            let expect = expectation(description: "expect update fav tree")
            let newNode = Util.mockNode(token: "X.new_node", hasChild: false)
            let newNodeParent = "X.new_node_parent"
            let metas = [
                WikiTreeNodeMeta.favoriteRootToken: WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID),
                Util.TestTree.normal3.wikiToken: Util.TestTree.normal3,
                newNode.wikiToken: newNode
            ]
            let relation = WikiTreeRelation(nodeParentMap: [
                Util.TestTree.normal3.wikiToken: Util.TestTree.mainRoot.wikiToken,
                newNode.wikiToken: newNodeParent
            ],
                                            nodeChildrenMap: [
                                                WikiTreeNodeMeta.favoriteRootToken: [
                                                    NodeChildren(wikiToken: Util.TestTree.normal3.wikiToken,
                                                                 sortID: 10000),
                                                    NodeChildren(wikiToken: newNode.wikiToken, sortID: 20000)
                                                ]
                                            ])
            cache.updateFavoriteList(spaceID: Util.mockSpaceID,
                                     metaStorage: metas, relation: relation)
                .subscribe {
                    let expectTokens = [Util.TestTree.normal3.wikiToken, newNode.wikiToken]
                    let tokens = table.getFavoriteList(spaceID: Util.mockSpaceID)?.map(\.meta.wikiToken)
                    XCTAssertEqual(tokens, expectTokens)
                    let favList = table.getNodes(spaceID: Util.mockSpaceID, wikiTokens: expectTokens)
                    guard favList.count == 2 else {
                        XCTFail("saved fav node not founc")
                        expect.fulfill()
                        return
                    }
                    // 校验 2 个节点
                    // 更新已知节点时，检查 sortID 不受影响
                    let expectNode1 = Util.DBTestTree.normal3
                    XCTAssertEqual(favList[0], expectNode1)
                    let expectNode2 = WikiTreeDBNode(meta: newNode, children: nil, parent: newNodeParent, sortID: 20000)
                    XCTAssertEqual(favList[1], expectNode2)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test cache API failed, \(error)")
        }
    }

    func testDelete() {
        do {
            let tableName = "unit_test"
            let connection = try Util.DBUtil.mockTableWithTree(name: tableName)
            let provider = MockCacheProvider()
            let table = WikiTreeDBNodeTable(connection: connection, tableName: tableName)
            provider.wikiTreeDBNodeTable = table
            let cache = WikiTreeCacheHandle()
            cache.provider = provider

            // 更新已有节点的 title
            let expect = expectation(description: "delete tokens")
            let tokens = Util.DBTestTree.allNodes.map(\.meta.wikiToken)
            cache.delete(wikiTokens: tokens)
                .subscribe {
                    let dbNodes = table.getNodes(spaceID: Util.mockSpaceID, wikiTokens: tokens)
                    XCTAssertTrue(dbNodes.isEmpty)
                    expect.fulfill()
                } onError: { error in
                    XCTFail("unexpected error \(error)")
                    expect.fulfill()
                }
                .disposed(by: bag)
            waitForExpectations(timeout: 10) { error in
                XCTAssertNil(error)
            }
        } catch {
            XCTFail("test delete cache failed")
        }
    }
}
