//
//  WikiTreeDBNodeTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/19.
//

import Foundation
@testable import SKWorkspace
import SQLite
import XCTest
import SKFoundation

class WikiTreeDBNodeTests: XCTestCase {

    typealias Util = WikiTreeTestUtil.DBUtil
    static let mockSpaceID = WikiTreeTestUtil.mockSpaceID
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testInsert() {
        let name = "test_wiki_tree_db_table"
        do {
            let connection = try Util.mockTable(name: name)
            let testTable = Table(name)
            let count = try connection.scalar(testTable.count)
            XCTAssertEqual(count, 7)
        } catch {
            XCTFail("db table failed, \(error)")
        }
    }

    func testDelete() {
        let name = "test_wiki_tree_db_table"
        do {
            let connection = try Util.mockTable(name: name)
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)

            table.delete(tokens: ["MOCK_1", "MOCK_2"])

            let testTable = Table(name)
            let count = try connection.scalar(testTable.count)
            XCTAssertEqual(count, 5)
        } catch {
            XCTFail("db table failed, \(error)")
        }
    }

    func testDeleteAll() {
        let name = "test_wiki_tree_db_table"
        do {
            let connection = try Util.mockTable(name: name)
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)

            table.deleteAll()

            let testTable = Table(name)
            let count = try connection.scalar(testTable.count)
            XCTAssertEqual(count, 0)
        } catch {
            XCTFail("db table failed, \(error)")
        }
    }

    func testGetNodes() {
        let name = "test_wiki_tree_db_table"
        do {
            let connection = try Util.mockTable(name: name)
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)

            let result = table.getNodes(spaceID: Self.mockSpaceID, wikiTokens: ["MOCK_MAIN_ROOT", "MOCK_1", "MOCK_2", "MOCK_1_1", "MOCK_1_2"])
                .sorted { $0.meta.wikiToken > $1.meta.wikiToken }
            XCTAssertEqual(result.count, 5)
            let expect = [Util.mockMainRoot, Util.mockNode1, Util.mockNode2, Util.mockNode1_1, Util.mockNode1_2]
                .sorted { $0.meta.wikiToken > $1.meta.wikiToken }
            XCTAssertEqual(result, expect)
        } catch {
            XCTFail("db table failed, \(error)")
        }
    }

    func testUpdateNodes() {
        let node1 = WikiTreeDBNode(meta: Util.mockNode1.meta,
                                   children: Util.mockNode1.children,
                                   parent: Util.mockNode1.parent,
                                   sortID: 1000)
        let node2 = WikiTreeDBNode(meta: Util.mockNode2.meta,
                                   children: Util.mockNode2.children,
                                   parent: Util.mockNode2.parent,
                                   sortID: 1000)
        let name = "test_wiki_tree_db_table"
        do {
            let connection = try Util.mockTable(name: name)
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)
            table.insert(nodes: [node1, node2], shouldUpdateSortID: false)
            var result = table.getNodes(spaceID: Self.mockSpaceID, wikiTokens: [node1.meta.wikiToken, node2.meta.wikiToken])
            var expect = [Util.mockNode1, Util.mockNode2]
            XCTAssertEqual(result, expect)

            table.insert(nodes: [node1, node2])
            result = table.getNodes(spaceID: Self.mockSpaceID, wikiTokens: [node1.meta.wikiToken, node2.meta.wikiToken])
            expect = [node1, node2]
            XCTAssertEqual(result, expect)
        } catch {
            XCTFail("db table failed, \(error)")
        }
    }

    func testGetRootWikiToken() {
        let name = "test_wiki_tree_db_table"
        do {
            let connection = try Util.mockTable(name: name)
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)

            let result = table.getRootWikiToken(spaceID: Self.mockSpaceID, rootType: .mainRoot)
            XCTAssertEqual(result, Util.mockMainRoot.meta.wikiToken)

            let nilResult = table.getRootWikiToken(spaceID: "random", rootType: .mainRoot)
            XCTAssertNil(nilResult)
        } catch {
            XCTFail("db table failed, \(error)")
        }
    }

    func testGetFavoriteList() {
        let name = "test_wiki_tree_db_table"
        let node1 = WikiTreeDBNode(meta: Util.mockNode2.meta,
                                   children: Util.mockNode2.children,
                                   parent: Util.mockNode2.parent,
                                   sortID: 10)
        let node2 = WikiTreeDBNode(meta: Util.mockNode3.meta,
                                   children: Util.mockNode3.children,
                                   parent: Util.mockNode3.parent,
                                   sortID: 0)
        do {
            let connection = try Util.mockTable(name: name)
            let table = WikiTreeDBNodeTable(connection: connection, tableName: name)

            let result = table.getFavoriteList(spaceID: Self.mockSpaceID)
            XCTAssertEqual(result, [node2, node1])

            let emptyResult = table.getFavoriteList(spaceID: "random")
            XCTAssertNil(emptyResult)
        } catch {
            XCTFail("db table failed, \(error)")
        }
    }
}
