//
//  WikiTreeRelationTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/21.
//
// swiftlint:disable file_length type_body_length

import XCTest
@testable import SKWorkspace
import SKFoundation

class WikiTreeRelationTests: XCTestCase {

    typealias NodeChildren = WikiTreeRelation.NodeChildren

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testSetup() {
        let testRootToken = "TEST_ROOT"
        var relation = WikiTreeRelation()
        XCTAssertNil(relation.nodeChildrenMap[testRootToken])
        relation.setup(rootToken: testRootToken)
        XCTAssertEqual(relation.nodeChildrenMap[testRootToken], [])
    }

    func testEmpty() {
        var relation = WikiTreeRelation()
        XCTAssertTrue(relation.isEmpty)

        relation = WikiTreeRelation(nodeParentMap: ["A": "B"], nodeChildrenMap: [:])
        XCTAssertFalse(relation.isEmpty)

        relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: ["A": []])
        XCTAssertFalse(relation.isEmpty)

        relation = WikiTreeRelation(nodeParentMap: ["A": "B"], nodeChildrenMap: ["A": []])
        XCTAssertFalse(relation.isEmpty)
    }

    func testDelete() {
        var parentMap = [
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "B1": "B"
        ]

        var childrenMap = [
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 100),
                NodeChildren(wikiToken: "A2", sortID: 200),
                NodeChildren(wikiToken: "A3", sortID: 300)
            ]
        ]

        var relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childrenMap)
        // 删一个不存在的 token
        relation.delete(wikiToken: "C")
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)

        // 删一个有 parent，但 parent 没有 children 信息的脏数据
        relation.delete(wikiToken: "B1")
        parentMap["B1"] = nil
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)

        // 正常删
        relation.delete(wikiToken: "A2")
        parentMap["A2"] = nil
        childrenMap["A"] = [
            NodeChildren(wikiToken: "A1", sortID: 100),
            NodeChildren(wikiToken: "A3", sortID: 300)
        ]
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)
    }

    func testInsert() {
        var parentMap = [
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "B1": "B",
            "B2": "B",
            "B3": "B"
        ]

        var childrenMap = [
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 100),
                NodeChildren(wikiToken: "A2", sortID: 200),
                NodeChildren(wikiToken: "A3", sortID: 300)
            ],
            "B": [
                NodeChildren(wikiToken: "B1", sortID: 100),
                NodeChildren(wikiToken: "B2", sortID: 200),
                NodeChildren(wikiToken: "B3", sortID: 300)
            ]
        ]

        var relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childrenMap)
        // 插入一个父节点信息位置的数据
        relation.insert(wikiToken: "C1", sortID: 100, parentToken: "C")
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)

        // 插入到 children 末尾
        relation.insert(wikiToken: "A4", sortID: 400, parentToken: "A")
        parentMap["A4"] = "A"
        childrenMap["A"] = [
            NodeChildren(wikiToken: "A1", sortID: 100),
            NodeChildren(wikiToken: "A2", sortID: 200),
            NodeChildren(wikiToken: "A3", sortID: 300),
            NodeChildren(wikiToken: "A4", sortID: 400)
        ]
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)

        // 插入到 children 头部
        relation.insert(wikiToken: "A0", sortID: 0, parentToken: "A")
        parentMap["A0"] = "A"
        childrenMap["A"] = [
            NodeChildren(wikiToken: "A0", sortID: 0),
            NodeChildren(wikiToken: "A1", sortID: 100),
            NodeChildren(wikiToken: "A2", sortID: 200),
            NodeChildren(wikiToken: "A3", sortID: 300),
            NodeChildren(wikiToken: "A4", sortID: 400)
        ]
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)

        // 插入到 children 中间
        relation.insert(wikiToken: "AX", sortID: 150, parentToken: "A")
        parentMap["AX"] = "A"
        childrenMap["A"] = [
            NodeChildren(wikiToken: "A0", sortID: 0),
            NodeChildren(wikiToken: "A1", sortID: 100),
            NodeChildren(wikiToken: "AX", sortID: 150),
            NodeChildren(wikiToken: "A2", sortID: 200),
            NodeChildren(wikiToken: "A3", sortID: 300),
            NodeChildren(wikiToken: "A4", sortID: 400)
        ]
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)

        // 更新 AX 位置
        relation.insert(wikiToken: "AX", sortID: 250, parentToken: "A")
        parentMap["AX"] = "A"
        childrenMap["A"] = [
            NodeChildren(wikiToken: "A0", sortID: 0),
            NodeChildren(wikiToken: "A1", sortID: 100),
            NodeChildren(wikiToken: "A2", sortID: 200),
            NodeChildren(wikiToken: "AX", sortID: 250),
            NodeChildren(wikiToken: "A3", sortID: 300),
            NodeChildren(wikiToken: "A4", sortID: 400)
        ]
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)

        // 换 parent
        relation.insert(wikiToken: "AX", sortID: 250, parentToken: "B")
        parentMap["AX"] = "B"
        childrenMap["A"] = [
            NodeChildren(wikiToken: "A0", sortID: 0),
            NodeChildren(wikiToken: "A1", sortID: 100),
            NodeChildren(wikiToken: "A2", sortID: 200),
            NodeChildren(wikiToken: "A3", sortID: 300),
            NodeChildren(wikiToken: "A4", sortID: 400)
        ]
        childrenMap["B"] = [
            NodeChildren(wikiToken: "B1", sortID: 100),
            NodeChildren(wikiToken: "B2", sortID: 200),
            NodeChildren(wikiToken: "AX", sortID: 250),
            NodeChildren(wikiToken: "B3", sortID: 300)
        ]
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childrenMap)
    }

    func testGetSortID() {
        let parentMap = [
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "A4": "A",
            "B1": "B"
        ]

        let childrenMap = [
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 100),
                NodeChildren(wikiToken: "A2", sortID: 200),
                NodeChildren(wikiToken: "A3", sortID: 300)
            ]
        ]

        let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childrenMap)

        // 找不到 parent
        var result = relation.getSortID(wikiToken: "C1")
        XCTAssertNil(result)
        // parent 的 children 信息未知
        result = relation.getSortID(wikiToken: "B1")
        XCTAssertNil(result)
        // parent 的 children 中不包含查询的节点
        result = relation.getSortID(wikiToken: "A4")
        XCTAssertNil(result)
        // 正常查询
        result = relation.getSortID(wikiToken: "A2")
        XCTAssertEqual(result, 200)
    }

    func testUpdate() {
        let cacheParentMap = [
            "A": "ROOT",
            "B": "ROOT",
            "C": "ROOT",
            "D": "ROOT",
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "A21": "A2",
            "TARGET": "A2",
            "A23": "A2"
        ]
        let cacheChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 100),
                NodeChildren(wikiToken: "C", sortID: 200),
                NodeChildren(wikiToken: "D", sortID: 300)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "A2", sortID: 100),
                NodeChildren(wikiToken: "A3", sortID: 200)
            ],
            "A2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "TARGET", sortID: 100),
                NodeChildren(wikiToken: "A23", sortID: 200)
            ]
        ]

        let serverParentMap = [
            "A": "ROOT",
            "B": "ROOT",
            "C": "ROOT",
            "D": "ROOT",
            "C1": "C",
            "C2": "C",
            "C3": "C",
            "C21": "C2",
            "TARGET": "C2",
            "C23": "C2"
        ]
        let serverChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 100),
                NodeChildren(wikiToken: "C", sortID: 200),
                NodeChildren(wikiToken: "D", sortID: 300)
            ],
            "C": [
                NodeChildren(wikiToken: "C1", sortID: 0),
                NodeChildren(wikiToken: "C2", sortID: 100),
                NodeChildren(wikiToken: "C3", sortID: 200)
            ],
            "C2": [
                NodeChildren(wikiToken: "C21", sortID: 0),
                NodeChildren(wikiToken: "TARGET", sortID: 100),
                NodeChildren(wikiToken: "C23", sortID: 200)
            ]
        ]

        let expectParentMap = [
            "A": "ROOT",
            "B": "ROOT",
            "C": "ROOT",
            "D": "ROOT",
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "A21": "A2",
            "A23": "A2",
            "C1": "C",
            "C2": "C",
            "C3": "C",
            "C21": "C2",
            "TARGET": "C2",
            "C23": "C2"
        ]
        let expectChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 100),
                NodeChildren(wikiToken: "C", sortID: 200),
                NodeChildren(wikiToken: "D", sortID: 300)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "A2", sortID: 100),
                NodeChildren(wikiToken: "A3", sortID: 200)
            ],
            "A2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A23", sortID: 200)
            ],
            "C": [
                NodeChildren(wikiToken: "C1", sortID: 0),
                NodeChildren(wikiToken: "C2", sortID: 100),
                NodeChildren(wikiToken: "C3", sortID: 200)
            ],
            "C2": [
                NodeChildren(wikiToken: "C21", sortID: 0),
                NodeChildren(wikiToken: "TARGET", sortID: 100),
                NodeChildren(wikiToken: "C23", sortID: 200)
            ]
        ]
        let cacheRelation = WikiTreeRelation(nodeParentMap: cacheParentMap, nodeChildrenMap: cacheChildrenMap)
        let newRelation = WikiTreeRelation(nodeParentMap: serverParentMap, nodeChildrenMap: serverChildrenMap)

        var relation = cacheRelation
        relation.update(newRelation: newRelation, onConflict: .override)
        XCTAssertEqual(relation.nodeParentMap, expectParentMap)
        XCTAssertEqual(relation.nodeChildrenMap, expectChildrenMap)

        relation = newRelation
        relation.update(newRelation: cacheRelation, onConflict: .ignore)
        XCTAssertEqual(relation.nodeParentMap, expectParentMap)
        XCTAssertEqual(relation.nodeChildrenMap, expectChildrenMap)
    }

    func testGetPath() {
        let parentMap = [
            "A": "B",
            "B": "C",
            "C": "D",
            "D": "E",
            "E": "F",
            "F": ""
        ]
        let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: [:])
        var result = relation.getPath(wikiToken: "A")
        let expect = ["F", "E", "D", "C", "B"]
        XCTAssertEqual(result, expect)

        result = relation.getPath(wikiToken: "UNKNOWN")
        XCTAssertTrue(result.isEmpty)

        result = relation.getPath(wikiToken: "F")
        XCTAssertTrue(result.isEmpty)
    }

    func testForceInsert() {
        let parentMap = [
            "TARGET": "A"
        ]
        var favChild: [NodeChildren] = []
        var childMap = [
            "A": [
                NodeChildren(wikiToken: "TARGET", sortID: 10)
            ],
            WikiTreeNodeMeta.favoriteRootToken: favChild
        ]
        var relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childMap)
        // 插入时父节点未知，无事发生
        relation.forceInsert(wikiToken: "C", sortID: 10, parentToken: "B")
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        XCTAssertEqual(relation.nodeChildrenMap, childMap)
        // 插入收藏节点
        relation.forceInsert(wikiToken: "TARGET", sortID: 10, parentToken: WikiTreeNodeMeta.favoriteRootToken)
        // 不影响 parent
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        favChild = [
            NodeChildren(wikiToken: "TARGET", sortID: 10)
        ]
        childMap[WikiTreeNodeMeta.favoriteRootToken] = favChild
        // children 更新
        XCTAssertEqual(relation.nodeChildrenMap, childMap)

        relation.forceInsert(wikiToken: "BAR", sortID: 0, parentToken: WikiTreeNodeMeta.favoriteRootToken)
        // 不影响 parent
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        favChild = [
            NodeChildren(wikiToken: "BAR", sortID: 0),
            NodeChildren(wikiToken: "TARGET", sortID: 10)
        ]
        childMap[WikiTreeNodeMeta.favoriteRootToken] = favChild
        // children 更新
        XCTAssertEqual(relation.nodeChildrenMap, childMap)

        relation.forceInsert(wikiToken: "FOO", sortID: 20, parentToken: WikiTreeNodeMeta.favoriteRootToken)
        // 不影响 parent
        XCTAssertEqual(relation.nodeParentMap, parentMap)
        favChild = [
            NodeChildren(wikiToken: "BAR", sortID: 0),
            NodeChildren(wikiToken: "TARGET", sortID: 10),
            NodeChildren(wikiToken: "FOO", sortID: 20)
        ]
        childMap[WikiTreeNodeMeta.favoriteRootToken] = favChild
        // children 更新
        XCTAssertEqual(relation.nodeChildrenMap, childMap)
    }

    func testGetSubTreeTokens() {
        let parentMap = [
            "A11": "B1",
            "A12": "B1",
            "A21": "B2",
            "A22": "B2",
            "B1": "C",
            "B2": "C",
            "C": "D",
            "D": "E"
        ]

        let childMap = [
            "E": [NodeChildren(wikiToken: "D", sortID: 0)],
            "D": [NodeChildren(wikiToken: "C", sortID: 0)],
            "C": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "B2", sortID: 10)
            ],
            "B1": [
                NodeChildren(wikiToken: "A11", sortID: 0),
                NodeChildren(wikiToken: "A12", sortID: 10)
            ],
            "B2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A22", sortID: 10)
            ]
        ]

        let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childMap)
        // 超过 30 返回空
        var result = relation.subTreeTokens(rootToken: "E", level: 30)
        XCTAssertTrue(result.isEmpty)
        result = relation.subTreeTokens(rootToken: "E", level: 29)
        XCTAssertEqual(result, ["E"])
        // 叶子结点只有自己
        result = relation.subTreeTokens(rootToken: "A11")
        XCTAssertEqual(result, ["A11"])

        result = relation.subTreeTokens(rootToken: "B1")
        XCTAssertEqual(result, ["B1", "A11", "A12"])
        // 深度优先遍历结果
        result = relation.subTreeTokens(rootToken: "E")
        XCTAssertEqual(result, [
            "E", "D", "C",
            "B1", "A11", "A12",
            "B2", "A21", "A22"
        ])
    }

    func testCheckSubTree() {
        let parentMap = [
            "A11": "B1",
            "A12": "B1",
            "A21": "B2",
            "A22": "B2",
            "B1": "C",
            "B2": "C",
            "C": "D",
            "D": "E"
        ]

        let childMap = [
            "E": [NodeChildren(wikiToken: "D", sortID: 0)],
            "D": [NodeChildren(wikiToken: "C", sortID: 0)],
            "C": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "B2", sortID: 10)
            ],
            "B1": [
                NodeChildren(wikiToken: "A11", sortID: 0),
                NodeChildren(wikiToken: "A12", sortID: 10)
            ],
            "B2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A22", sortID: 10)
            ]
        ]
        let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childMap)
        var result = relation.checkSubTree(rootToken: "E", contains: "E")
        XCTAssertTrue(result)
        result = relation.checkSubTree(rootToken: "E", contains: "A11", level: 26)
        XCTAssertTrue(result)
        result = relation.checkSubTree(rootToken: "E", contains: "A11", level: 27)
        XCTAssertFalse(result)
        result = relation.checkSubTree(rootToken: "E", contains: "A11", level: 30)
        XCTAssertFalse(result)
        result = relation.checkSubTree(rootToken: "B1", contains: "A21")
        XCTAssertFalse(result)
        result = relation.checkSubTree(rootToken: "E", contains: "A11")
        XCTAssertTrue(result)
    }

    func testDeleteSubTree() {
        let parentMap = [
            "A11": "B1",
            "A12": "B1",
            "A21": "B2",
            "A22": "B2",
            "B1": "C",
            "B2": "C",
            "C": "D",
            "D": "E"
        ]

        let childMap = [
            "E": [NodeChildren(wikiToken: "D", sortID: 0)],
            "D": [NodeChildren(wikiToken: "C", sortID: 0)],
            "C": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "B2", sortID: 10)
            ],
            "B1": [
                NodeChildren(wikiToken: "A11", sortID: 0),
                NodeChildren(wikiToken: "A12", sortID: 10)
            ],
            "B2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A22", sortID: 10)
            ]
        ]
        let originRelation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childMap)
        var relation = originRelation
        // 删叶子结点
        var result = relation.deleteSubTree(rootToken: "A11")
        XCTAssertEqual(result, ["A11"])
        XCTAssertEqual(relation.nodeParentMap, [
            "A12": "B1",
            "A21": "B2",
            "A22": "B2",
            "B1": "C",
            "B2": "C",
            "C": "D",
            "D": "E"
        ])
        XCTAssertEqual(relation.nodeChildrenMap, [
            "E": [NodeChildren(wikiToken: "D", sortID: 0)],
            "D": [NodeChildren(wikiToken: "C", sortID: 0)],
            "C": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "B2", sortID: 10)
            ],
            "B1": [
                NodeChildren(wikiToken: "A12", sortID: 10)
            ],
            "B2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A22", sortID: 10)
            ]
        ])

        relation = originRelation
        result = relation.deleteSubTree(rootToken: "D")
        XCTAssertEqual(result, [
            "D", "C",
            "B1", "A11", "A12",
            "B2", "A21", "A22"
        ])
        XCTAssertTrue(relation.nodeParentMap.isEmpty)
        XCTAssertEqual(relation.nodeChildrenMap, [
            "E": []
        ])

        relation = originRelation
        result = relation.deleteSubTree(rootToken: "E", maxLevel: 2)
        XCTAssertEqual(result, [
            "E", "D", "C"
        ])
        XCTAssertEqual(relation.nodeParentMap, [
            "A11": "B1",
            "A12": "B1",
            "A21": "B2",
            "A22": "B2",
            "B1": "C",
            "B2": "C"
        ])
        XCTAssertEqual(relation.nodeChildrenMap, [
            "B1": [
                NodeChildren(wikiToken: "A11", sortID: 0),
                NodeChildren(wikiToken: "A12", sortID: 10)
            ],
            "B2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A22", sortID: 10)
            ]
        ])
    }
}
