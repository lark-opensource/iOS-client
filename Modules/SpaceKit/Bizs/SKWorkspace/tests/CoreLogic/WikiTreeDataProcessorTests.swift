//
//  WikiTreeDataProcessorTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/22.
//
// swiftlint:disable function_body_length type_body_length file_length

import XCTest
@testable import SKWorkspace
import SKFoundation

extension WikiTreeState {
    static var empty: WikiTreeState {
        WikiTreeState(viewState: WikiTreeViewState(),
                      metaStorage: [:],
                      relation: WikiTreeRelation())
    }
}

class WikiTreeDataProcessorTests: XCTestCase {

    typealias NodeChildren = WikiTreeRelation.NodeChildren
    typealias MetaStorage = WikiTreeNodeMeta.MetaStorage
    typealias Util = WikiTreeTestUtil

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testReset() {
        let processor = WikiTreeDataProcessor()
        let newViewState = WikiTreeViewState(selectedWikiToken: "TEST", expandedUIDs: [
            WikiTreeNodeUID(wikiToken: "1", section: .mainRoot, shortcutPath: ""),
            WikiTreeNodeUID(wikiToken: "2", section: .mainRoot, shortcutPath: ""),
            WikiTreeNodeUID(wikiToken: "3", section: .mainRoot, shortcutPath: "")
        ])
        let current = WikiTreeState(viewState: newViewState,
                                    metaStorage: [:],
                                    relation: WikiTreeRelation())
        let newMetas: WikiTreeNodeMeta.MetaStorage = [
            WikiTreeTestUtil.mainRootToken: WikiTreeTestUtil.TestTree.mainRoot
        ]
        let newRelation = WikiTreeRelation(nodeParentMap: ["A": "B"],
                                           nodeChildrenMap: [
                                            "A": [],
                                            "B": [
                                                WikiTreeRelation.NodeChildren(wikiToken: "random", sortID: 0)
                                            ]
                                           ])
        do {
            let result = try processor.process(operation: .reset(relation: newRelation,
                                                                 metaStorage: newMetas),
                                               treeState: current)
            // viewState 不受影响
            XCTAssertEqual(result.viewState, newViewState)
            // meta 和 relation 会被覆盖
            XCTAssertEqual(result.metaStorage, newMetas)
            XCTAssertEqual(result.relation, newRelation)
        } catch {
            XCTFail("process failed with error: \(error)")
        }
    }

    func testUpdate() {
        let expectViewState = WikiTreeViewState(selectedWikiToken: "TEST", expandedUIDs: [
            WikiTreeNodeUID(wikiToken: "1", section: .mainRoot, shortcutPath: ""),
            WikiTreeNodeUID(wikiToken: "2", section: .mainRoot, shortcutPath: ""),
            WikiTreeNodeUID(wikiToken: "3", section: .mainRoot, shortcutPath: "")
        ])

        let currentMetas: WikiTreeNodeMeta.MetaStorage = [
            "ROOT": WikiTreeNodeMeta.createMainRoot(rootToken: "ROOT", spaceID: Util.mockSpaceID),

            "A": Util.mockNode(token: "A", hasChild: true),
            "A1": Util.mockNode(token: "A1", hasChild: false),
            "A2": Util.mockNode(token: "A2", hasChild: true),
            "A21": Util.mockNode(token: "A21", hasChild: false),
            "A22": Util.mockNode(token: "A22", hasChild: false),

            "B": Util.mockNode(token: "B", hasChild: true),
            "B1": Util.mockNode(token: "B1", hasChild: true),
            "B2": Util.mockNode(token: "B2", hasChild: false)
        ]
        let currentParentMap = [
            "A": "ROOT",
            "A1": "A",
            "A2": "A",
            "A21": "A2",
            "A22": "A2",

            "B": "ROOT",
            "B1": "B",
            "B2": "B1"
        ]
        let currentChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "A2", sortID: 10)
            ],
            "A2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A22", sortID: 10)
            ],
            "B": [
                NodeChildren(wikiToken: "B1", sortID: 0)
            ],
            "B1": [
                NodeChildren(wikiToken: "B2", sortID: 0)
            ]
        ]

        let currentRelation = WikiTreeRelation(nodeParentMap: currentParentMap,
                                               nodeChildrenMap: currentChildrenMap)

        // ROOT 下新增 C
        // A 下新增 A3 A4
        // B 下移除 B1
        // C 下新增 B1
        let newMetas: WikiTreeNodeMeta.MetaStorage = [
            "ROOT": WikiTreeNodeMeta.createMainRoot(rootToken: "ROOT", spaceID: Util.mockSpaceID),

            "A": Util.mockNode(token: "A", hasChild: true),
            "A1": Util.mockNode(token: "A1", hasChild: false),
            "A2": Util.mockNode(token: "A2", hasChild: true),
            // 新增 A3 A4
            "A3": Util.mockNode(token: "A3", hasChild: false),
            "A4": Util.mockNode(token: "A4", hasChild: false),

            "B": Util.mockNode(token: "B", hasChild: false),
            "C": Util.mockNode(token: "C", hasChild: true),
            "B1": Util.mockNode(token: "B1", hasChild: true),
            "B2": Util.mockNode(token: "B2", hasChild: false)
        ]
        let newParentMap = [
            "A": "ROOT",
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "A4": "A",

            "B": "ROOT",
            "C": "ROOT",
            "B1": "C",
            "B2": "B1"
        ]
        let newChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10),
                NodeChildren(wikiToken: "C", sortID: 20)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "A2", sortID: 10),
                NodeChildren(wikiToken: "A3", sortID: 20),
                NodeChildren(wikiToken: "A4", sortID: 30)
            ],
            "C": [
                NodeChildren(wikiToken: "B1", sortID: 0)
            ],
            "B1": [
                NodeChildren(wikiToken: "B2", sortID: 0)
            ]
        ]
        let newRelation = WikiTreeRelation(nodeParentMap: newParentMap,
                                           nodeChildrenMap: newChildrenMap)


        let expectMetas: WikiTreeNodeMeta.MetaStorage = [
            "ROOT": WikiTreeNodeMeta.createMainRoot(rootToken: "ROOT", spaceID: Util.mockSpaceID),
            "A": Util.mockNode(token: "A", hasChild: true),
            "A1": Util.mockNode(token: "A1", hasChild: false),
            "A2": Util.mockNode(token: "A2", hasChild: true),
            "A21": Util.mockNode(token: "A21", hasChild: false),
            "A22": Util.mockNode(token: "A22", hasChild: false),
            "A3": Util.mockNode(token: "A3", hasChild: false),
            "A4": Util.mockNode(token: "A4", hasChild: false),
            "B": Util.mockNode(token: "B", hasChild: false),
            "C": Util.mockNode(token: "C", hasChild: true),
            "B1": Util.mockNode(token: "B1", hasChild: true),
            "B2": Util.mockNode(token: "B2", hasChild: false)
        ]
        let expectParentMap = [
            "A": "ROOT",
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "A4": "A",
            "A21": "A2",
            "A22": "A2",

            "B": "ROOT",
            "C": "ROOT",
            "B1": "C",
            "B2": "B1"
        ]
        let expectChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10),
                NodeChildren(wikiToken: "C", sortID: 20)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "A2", sortID: 10),
                NodeChildren(wikiToken: "A3", sortID: 20),
                NodeChildren(wikiToken: "A4", sortID: 30)
            ],
            "A2": [
                NodeChildren(wikiToken: "A21", sortID: 0),
                NodeChildren(wikiToken: "A22", sortID: 10)
            ],
            "B": [
            ],
            "C": [
                NodeChildren(wikiToken: "B1", sortID: 0)
            ],
            "B1": [
                NodeChildren(wikiToken: "B2", sortID: 0)
            ]
        ]
        let expectRelation = WikiTreeRelation(nodeParentMap: expectParentMap,
                                              nodeChildrenMap: expectChildrenMap)

        var state = WikiTreeState(viewState: expectViewState,
                                  metaStorage: currentMetas,
                                  relation: currentRelation)
        let processor = WikiTreeDataProcessor()
        do {
            var result = try processor.process(operation: .update(relation: newRelation,
                                                                  metaStorage: newMetas,
                                                                  onConflict: .override),
                                               treeState: state)

            XCTAssertEqual(result.viewState, expectViewState)
            XCTAssertEqual(result.metaStorage, expectMetas)
            XCTAssertEqual(result.relation, expectRelation)

            state = WikiTreeState(viewState: expectViewState,
                                  metaStorage: newMetas,
                                  relation: newRelation)
            result = try processor.process(operation: .update(relation: currentRelation,
                                                              metaStorage: currentMetas,
                                                              onConflict: .ignore),
                                           treeState: state)
            XCTAssertEqual(result.viewState, expectViewState)
            XCTAssertEqual(result.metaStorage, expectMetas)
            XCTAssertEqual(result.relation, expectRelation)
        } catch {
            XCTFail("process failed with error: \(error)")
        }
    }

    func testExpandTo() {
        let (relation, metas) = Util.mockTree()
        let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: relation)
        let processor = WikiTreeDataProcessor()
        do {
            let newState = try processor.process(operation: .expandTo(wikiToken: Util.TestTree.leaf3_3_1.wikiToken), treeState: state)
            XCTAssertEqual(newState.relation, relation)
            XCTAssertEqual(newState.metaStorage, metas)
            let expandTokens = [
                Util.TestTree.mainRoot.wikiToken,
                Util.TestTree.normal3.wikiToken,
                Util.TestTree.normal3_3.wikiToken
            ].map {
                WikiTreeNodeUID(wikiToken: $0, section: .mainRoot, shortcutPath: "")
            }
            let expectViewState = WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: Set(expandTokens))
            XCTAssertEqual(newState.viewState, expectViewState)
        } catch {
            XCTFail("process failed with error: \(error)")
        }
    }

    func testUpdateFavoriteList() {
        let cacheMetas: WikiTreeNodeMeta.MetaStorage = [
            "ROOT": WikiTreeNodeMeta.createMainRoot(rootToken: "ROOT", spaceID: Util.mockSpaceID),

            "A": Util.mockNode(token: "A", hasChild: true),
            "A1": Util.mockNode(token: "A1", hasChild: false),
            "A2": Util.mockNode(token: "A2", hasChild: true),
            "A3": Util.mockNode(token: "A3", hasChild: false),
            "A4": Util.mockNode(token: "A4", hasChild: false),

            "B": Util.mockNode(token: "B", hasChild: true),
            "C": Util.mockNode(token: "C", hasChild: true),
            "B1": Util.mockNode(token: "B1", hasChild: true),
            "B2": Util.mockNode(token: "B2", hasChild: false)
        ]
        let parentMap = [
            "A": "ROOT",
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "A4": "A",

            "B": "ROOT",
            "C": "ROOT",
            "B1": "B",
            "B2": "B1"
        ]
        let childrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10),
                NodeChildren(wikiToken: "C", sortID: 20)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "A2", sortID: 10),
                NodeChildren(wikiToken: "A3", sortID: 20),
                NodeChildren(wikiToken: "A4", sortID: 30)
            ],
            "C": [
            ],
            "B1": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "B2", sortID: 10)
            ]
        ]
        let cacheRelation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: childrenMap)

        let favMetas = [
            "A": Util.mockNode(token: "A", hasChild: true),
            "A3": Util.mockNode(token: "A3", hasChild: false),
            "B1": Util.mockNode(token: "B1", hasChild: true),
            "F": Util.mockNode(token: "F", hasChild: true)
        ]
        let favList = [
            NodeChildren(wikiToken: "A", sortID: 0),
            NodeChildren(wikiToken: "A3", sortID: 10),
            NodeChildren(wikiToken: "B1", sortID: 20),
            NodeChildren(wikiToken: "F", sortID: 30)
        ]
        let favRelation = WikiTreeRelation(nodeParentMap: [
            "A": "ROOT",
            "A3": "A",
            "B1": "B",
            "F": "E"
        ], nodeChildrenMap: [
            WikiTreeNodeMeta.favoriteRootToken: favList
        ])

        let expectMetas: WikiTreeNodeMeta.MetaStorage = [
            "ROOT": WikiTreeNodeMeta.createMainRoot(rootToken: "ROOT", spaceID: Util.mockSpaceID),
            WikiTreeNodeMeta.favoriteRootToken: WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID),

            "A": Util.mockNode(token: "A", hasChild: true),
            "A1": Util.mockNode(token: "A1", hasChild: false),
            "A2": Util.mockNode(token: "A2", hasChild: true),
            "A3": Util.mockNode(token: "A3", hasChild: false),
            "A4": Util.mockNode(token: "A4", hasChild: false),

            "B": Util.mockNode(token: "B", hasChild: true),
            "C": Util.mockNode(token: "C", hasChild: true),
            "B1": Util.mockNode(token: "B1", hasChild: true),
            "B2": Util.mockNode(token: "B2", hasChild: false),
            "F": Util.mockNode(token: "F", hasChild: true)
        ]
        let expectParentMap = [
            "A": "ROOT",
            "A1": "A",
            "A2": "A",
            "A3": "A",
            "A4": "A",

            "B": "ROOT",
            "C": "ROOT",
            "B1": "B",
            "B2": "B1",
            "F": "E"
        ]
        let expectChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10),
                NodeChildren(wikiToken: "C", sortID: 20)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "A2", sortID: 10),
                NodeChildren(wikiToken: "A3", sortID: 20),
                NodeChildren(wikiToken: "A4", sortID: 30)
            ],
            "C": [
            ],
            "B1": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "B2", sortID: 10)
            ],
            WikiTreeNodeMeta.favoriteRootToken: favList
        ]

        var state = WikiTreeState(viewState: WikiTreeViewState(),
                                  metaStorage: cacheMetas,
                                  relation: cacheRelation)
        let processor = WikiTreeDataProcessor()
        do {
            var result = try processor.process(operation: .updateFavoriteList(spaceID: Util.mockSpaceID,
                                                                              relation: favRelation,
                                                                              metaStorage: favMetas,
                                                                              onConflict: .override),
                                               treeState: state)

            XCTAssertEqual(result.metaStorage, expectMetas)
            XCTAssertEqual(result.relation.nodeParentMap, expectParentMap)
            XCTAssertEqual(result.relation.nodeChildrenMap, expectChildrenMap)

            state = WikiTreeState(viewState: WikiTreeViewState(),
                                  metaStorage: favMetas,
                                  relation: favRelation)
            result = try processor.process(operation: .updateFavoriteList(spaceID: Util.mockSpaceID,
                                                                          relation: cacheRelation,
                                                                          metaStorage: cacheMetas,
                                                                          onConflict: .ignore),
                                           treeState: state)

            XCTAssertEqual(result.metaStorage, expectMetas)
            XCTAssertEqual(result.relation.nodeParentMap, expectParentMap)
            XCTAssertEqual(result.relation.nodeChildrenMap, expectChildrenMap)
        } catch {
            XCTFail("process failed with error: \(error)")
        }
    }

    func testCleanDivergePath() {
        let cacheParentMap = [
            "TARGET": "D",
            "D": "C",
            "C": "B",
            "B": "A",
            "A": "ROOT",
            "A1": "A",
            "B1": "B",
            "CHILD": "ROOT",
            "A11": "A1",
            "A12": "A1"
        ]

        let cacheChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "CHILD", sortID: 10)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10)
            ],
            "B": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "C", sortID: 10)
            ],
            "C": [
                NodeChildren(wikiToken: "D", sortID: 0)
            ],
            "D": [
                NodeChildren(wikiToken: "TARGET", sortID: 0)
            ],
            "A1": [
                NodeChildren(wikiToken: "A11", sortID: 0),
                NodeChildren(wikiToken: "A12", sortID: 10)
            ]
        ]

        let cacheRelation = WikiTreeRelation(nodeParentMap: cacheParentMap, nodeChildrenMap: cacheChildrenMap)
        let currentViewState = WikiTreeViewState(selectedWikiToken: "TARGET",
                                                 expandedUIDs: [
                                                    WikiTreeNodeUID(wikiToken: "D", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "C", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "B", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "A11", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "ROOT", section: .mainRoot, shortcutPath: "")
                                                 ])

        let serverParentMap = [
            "TARGET": "E",
            "E": "B",
            "B": "A",
            "A": "ROOT",
            "A1": "A",
            "B1": "B",
            "CHILD": "ROOT"
        ]

        let serverChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "CHILD", sortID: 10)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10)
            ],
            "B": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "C", sortID: 10),
                NodeChildren(wikiToken: "E", sortID: 20)
            ],
            "E": [
                NodeChildren(wikiToken: "TARGET", sortID: 0)
            ]
        ]

        let serverRelation = WikiTreeRelation(nodeParentMap: serverParentMap, nodeChildrenMap: serverChildrenMap)
        let expectParentMap = [
            "C": "B",
            "B": "A",
            "A": "ROOT",
            "A1": "A",
            "B1": "B",
            "CHILD": "ROOT",
            "A11": "A1",
            "A12": "A1"
        ]
        let expectChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "CHILD", sortID: 10)
            ],
            "A": [
                NodeChildren(wikiToken: "A1", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10)
            ],
            "B": [
                NodeChildren(wikiToken: "B1", sortID: 0),
                NodeChildren(wikiToken: "C", sortID: 10)
            ],
            "A1": [
                NodeChildren(wikiToken: "A11", sortID: 0),
                NodeChildren(wikiToken: "A12", sortID: 10)
            ]
        ]
        let expectViewState = WikiTreeViewState(selectedWikiToken: "TARGET",
                                                expandedUIDs: [
                                                    WikiTreeNodeUID(wikiToken: "B", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "A11", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "ROOT", section: .mainRoot, shortcutPath: "")
                                                ])
        let processor = WikiTreeDataProcessor()
        let state = WikiTreeState(viewState: currentViewState,
                                  metaStorage: [:],
                                  relation: cacheRelation)
        do {
            let result = try processor.process(operation: .cleanDivergePath(wikiToken: "TARGET", newRelation: serverRelation),
                                               treeState: state)
            // 检查 diverge path 是否被 collapse
            XCTAssertEqual(result.viewState, expectViewState)
            // parentMap 预期不会被改动
            XCTAssertEqual(result.relation.nodeParentMap, expectParentMap)
            // childrenMap 预期会清空 diverge path 的 children
            XCTAssertEqual(result.relation.nodeChildrenMap, expectChildrenMap)
        } catch {
            XCTFail("process failed with error: \(error)")
        }
    }

    func testCleanDivergePathUnchanged() {
        // 不产生实际影响的清理测试
        let cacheParentMap = [
            "TARGET": "C",
            "C": "B",
            "B": "A",
            "A": "ROOT"
        ]

        let cacheChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0)
            ],
            "A": [
                NodeChildren(wikiToken: "B", sortID: 0)
            ],
            "B": [
                NodeChildren(wikiToken: "C", sortID: 0)
            ],
            "C": [
                NodeChildren(wikiToken: "TARGET", sortID: 0)
            ]
        ]

        let cacheRelation = WikiTreeRelation(nodeParentMap: cacheParentMap, nodeChildrenMap: cacheChildrenMap)
        let currentViewState = WikiTreeViewState(selectedWikiToken: "TARGET",
                                                 expandedUIDs: [
                                                    WikiTreeNodeUID(wikiToken: "C", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "B", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: ""),
                                                    WikiTreeNodeUID(wikiToken: "ROOT", section: .mainRoot, shortcutPath: "")
                                                 ])

        let serverParentMap = [
            "TARGET": "E",
            "E": "D",
            "D": "C",
            "C": "B",
            "B": "A",
            "A": "ROOT"
        ]

        let serverChildrenMap = [
            "ROOT": [
                NodeChildren(wikiToken: "A", sortID: 0)
            ],
            "A": [
                NodeChildren(wikiToken: "B", sortID: 0)
            ],
            "B": [
                NodeChildren(wikiToken: "C", sortID: 0)
            ],
            "C": [
                NodeChildren(wikiToken: "D", sortID: 0)
            ],
            "D": [
                NodeChildren(wikiToken: "E", sortID: 0)
            ],
            "E": [
                NodeChildren(wikiToken: "TARGET", sortID: 0)
            ]
        ]

        let serverRelation = WikiTreeRelation(nodeParentMap: serverParentMap, nodeChildrenMap: serverChildrenMap)

        let processor = WikiTreeDataProcessor()
        let state = WikiTreeState(viewState: currentViewState,
                                  metaStorage: [:],
                                  relation: cacheRelation)
        do {
            let result = try processor.process(operation: .cleanDivergePath(wikiToken: "TARGET", newRelation: serverRelation),
                                               treeState: state)
            // 都没变
            XCTAssertEqual(result.viewState, currentViewState)
            XCTAssertEqual(result.relation.nodeParentMap, cacheParentMap)
            XCTAssertEqual(result.relation.nodeChildrenMap, cacheChildrenMap)
        } catch {
            XCTFail("process failed with error: \(error)")
        }
    }

    func testInsert() {
        let processor = WikiTreeDataProcessor()
        do {
            _ = try processor.process(operation: .insert(parentWikiToken: "UNKNOWN", nodes: []), treeState: .empty)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.InsertError {
            if error != .parentNotFound {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            let parentMeta = Util.mockNode(token: "PARENT", hasChild: true)
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: ["PARENT": parentMeta], relation: WikiTreeRelation())
            _ = try processor.process(operation: .insert(parentWikiToken: "PARENT", nodes: []), treeState: state)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.InsertError {
            if error != .parentChildrenUnknown {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            var parentMeta = Util.mockNode(token: "PARENT", hasChild: false)
            let child1Meta = Util.mockNode(token: "CHILD1", hasChild: false)
            let child2Meta = Util.mockNode(token: "CHILD2", hasChild: false)
            let node1 = WikiServerNode(meta: child1Meta, sortID: 100, parent: "PARENT")
            let node2 = WikiServerNode(meta: child2Meta, sortID: 200, parent: "PARENT")
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: ["PARENT": parentMeta], relation: WikiTreeRelation())
            let result = try processor.process(operation: .insert(parentWikiToken: "PARENT", nodes: [node1, node2]), treeState: state)
            XCTAssertTrue(result.viewState.isEmpty)
            parentMeta.hasChild = true
            XCTAssertEqual(result.metaStorage, [
                "PARENT": parentMeta,
                "CHILD1": child1Meta,
                "CHILD2": child2Meta
            ])
            XCTAssertEqual(result.relation.nodeParentMap, ["CHILD1": "PARENT", "CHILD2": "PARENT"])
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                "PARENT": [
                    NodeChildren(wikiToken: "CHILD1", sortID: 100),
                    NodeChildren(wikiToken: "CHILD2", sortID: 200)
                ]
            ])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }

    func testDelete() {
        // 删除的详细测试再 testBatchDelete 里
        let processor = WikiTreeDataProcessor()
        do {
            _ = try processor.delete(wikiToken: "CHILD", response: { _ in }, treeState: .empty)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.DeleteError {
            if error != .parentNotFound {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        let parentMeta = Util.mockNode(token: "PARENT", hasChild: true)
        let child1 = Util.mockNode(token: "1", hasChild: true)
        let child11 = Util.mockNode(token: "1-1", hasChild: false)
        let child2 = Util.mockNode(token: "2", hasChild: false)
        let child3 = Util.mockNode(token: "3", hasChild: false)
        let relation = WikiTreeRelation(nodeParentMap: [
            "1": "PARENT",
            "1-1": "1",
            "2": "PARENT",
            "3": "PARENT"
        ], nodeChildrenMap: [
            "PARENT": [
                NodeChildren(wikiToken: "1", sortID: 10),
                NodeChildren(wikiToken: "2", sortID: 20),
                NodeChildren(wikiToken: "3", sortID: 30)
            ],
            "1": [
                NodeChildren(wikiToken: "1-1", sortID: 10)
            ],
            WikiTreeNodeMeta.favoriteRootToken: [
                NodeChildren(wikiToken: "1", sortID: 10),
                NodeChildren(wikiToken: "1-1", sortID: 20),
                NodeChildren(wikiToken: "2", sortID: 30),
                NodeChildren(wikiToken: "3", sortID: 40)
            ]
        ])
        do {
            let expect = expectation(description: "delete response")
            let response: WikiTreeOperation.DeleteResponse = { deletedTokens in
                XCTAssertEqual(deletedTokens, ["1", "1-1"])
                expect.fulfill()
            }
            let state = WikiTreeState(viewState: WikiTreeViewState(),
                                      metaStorage: [
                                        "PARENT": parentMeta,
                                        "1": child1,
                                        "1-1": child11,
                                        "2": child2,
                                        "3": child3
                                      ], relation: relation)
            let result = try processor.process(operation: .delete(wikiToken: "1", response: response),
                                               treeState: state)
            waitForExpectations(timeout: 1) { error in
                XCTAssertNil(error)
            }
            XCTAssertTrue(result.viewState.isEmpty)
            XCTAssertEqual(result.metaStorage, [
                "PARENT": parentMeta,
                "2": child2,
                "3": child3
            ])
            XCTAssertEqual(result.relation.nodeParentMap, [
                "3": "PARENT",
                "2": "PARENT"
            ])
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                "PARENT": [
                    NodeChildren(wikiToken: "2", sortID: 20),
                    NodeChildren(wikiToken: "3", sortID: 30)
                ],
                WikiTreeNodeMeta.favoriteRootToken: [
                    NodeChildren(wikiToken: "2", sortID: 30),
                    NodeChildren(wikiToken: "3", sortID: 40)
                ]
            ])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }

    func testBatchDelete() {
        var parentMeta = Util.mockNode(token: "PARENT", hasChild: true)
        let child1 = Util.mockNode(token: "1", hasChild: true)
        let child11 = Util.mockNode(token: "1-1", hasChild: false)
        let child2 = Util.mockNode(token: "2", hasChild: false)
        let child3 = Util.mockNode(token: "3", hasChild: false)
        let relation = WikiTreeRelation(nodeParentMap: [
            "1": "PARENT",
            "1-1": "1",
            "2": "PARENT",
            "3": "PARENT"
        ], nodeChildrenMap: [
            "PARENT": [
                NodeChildren(wikiToken: "1", sortID: 10),
                NodeChildren(wikiToken: "2", sortID: 20),
                NodeChildren(wikiToken: "3", sortID: 30)
            ],
            "1": [
                NodeChildren(wikiToken: "1-1", sortID: 10)
            ],
            WikiTreeNodeMeta.favoriteRootToken: [
                NodeChildren(wikiToken: "1", sortID: 10),
                NodeChildren(wikiToken: "1-1", sortID: 20),
                NodeChildren(wikiToken: "2", sortID: 30),
                NodeChildren(wikiToken: "3", sortID: 40)
            ]
        ])
        let processor = WikiTreeDataProcessor()
        do {
            let expect = expectation(description: "delete response")
            let response: WikiTreeOperation.DeleteResponse = { deletedTokens in
                XCTAssertEqual(deletedTokens, ["1", "1-1", "2"])
                expect.fulfill()
            }
            let state = WikiTreeState(viewState: WikiTreeViewState(),
                                      metaStorage: [
                                        "PARENT": parentMeta,
                                        "1": child1,
                                        "1-1": child11,
                                        "2": child2,
                                        "3": child3
                                      ], relation: relation)
            let result = try processor.process(operation: .batchDelete(parentToken: "PARENT", wikiTokens: ["1", "2"], response: response),
                                               treeState: state)
            waitForExpectations(timeout: 1) { error in
                XCTAssertNil(error)
            }
            XCTAssertTrue(result.viewState.isEmpty)
            XCTAssertEqual(result.metaStorage, [
                "PARENT": parentMeta,
                "3": child3
            ])
            XCTAssertEqual(result.relation.nodeParentMap, ["3": "PARENT"])
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                "PARENT": [
                    NodeChildren(wikiToken: "3", sortID: 30)
                ],
                WikiTreeNodeMeta.favoriteRootToken: [
                    NodeChildren(wikiToken: "3", sortID: 40)
                ]
            ])
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            let expect = expectation(description: "delete response")
            let response: WikiTreeOperation.DeleteResponse = { deletedTokens in
                XCTAssertEqual(deletedTokens, ["1", "1-1", "2", "3"])
                expect.fulfill()
            }
            let state = WikiTreeState(viewState: WikiTreeViewState(),
                                      metaStorage: [
                                        "PARENT": parentMeta,
                                        "1": child1,
                                        "1-1": child11,
                                        "2": child2,
                                        "3": child3
                                      ], relation: relation)
            let result = try processor.process(operation: .batchDelete(parentToken: "PARENT", wikiTokens: ["1", "2", "3"], response: response),
                                               treeState: state)
            waitForExpectations(timeout: 1) { error in
                XCTAssertNil(error)
            }
            XCTAssertTrue(result.viewState.isEmpty)
            parentMeta.hasChild = false
            XCTAssertEqual(result.metaStorage, [
                "PARENT": parentMeta
            ])
            XCTAssertTrue(result.relation.nodeParentMap.isEmpty)
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                "PARENT": [],
                WikiTreeNodeMeta.favoriteRootToken: []
            ])
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            _ = try processor.process(operation: .batchDelete(parentToken: "PARENT", wikiTokens: ["1"], response: { _ in }),
                                      treeState: .empty)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.DeleteError {
            if error != .targetNotFound {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }

    func testMove() {
        let processor = WikiTreeDataProcessor()
        do {
            var parent1 = Util.mockNode(token: "PARENT-1", hasChild: true)
            var parent2 = Util.mockNode(token: "PARENT-2", hasChild: false)
            let child = Util.mockNode(token: "CHILD", hasChild: false)
            let relation = WikiTreeRelation(nodeParentMap: ["CHILD": "PARENT-1"],
                                            nodeChildrenMap: [
                                                "PARENT-1": [NodeChildren(wikiToken: "CHILD", sortID: 10)]
                                            ])
            let state = WikiTreeState(viewState: WikiTreeViewState(),
                                      metaStorage: [
                                        "PARENT-1": parent1,
                                        "PARENT-2": parent2,
                                        "CHILD": child
                                      ], relation: relation)
            let node = WikiServerNode(meta: child, sortID: 20, parent: "PARENT-2")
            let result = try processor.process(operation: .move(oldParentToken: "PARENT-1",
                                                                newParentToken: "PARENT-2",
                                                                nodes: [node]),
                                               treeState: state)
            parent1.hasChild = false
            parent2.hasChild = true
            XCTAssertEqual(result.metaStorage, [
                "PARENT-1": parent1,
                "PARENT-2": parent2,
                "CHILD": child
            ])
            XCTAssertEqual(result.relation.nodeParentMap, ["CHILD": "PARENT-2"])
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                "PARENT-1": [],
                "PARENT-2": [NodeChildren(wikiToken: "CHILD", sortID: 20)]
            ])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }

    func testMoveUpdateSortID() {
        let processor = WikiTreeDataProcessor()
        do {
            let parent = Util.mockNode(token: "PARENT-1", hasChild: true)
            let child1 = Util.mockNode(token: "CHILD-1", hasChild: false)
            let child2 = Util.mockNode(token: "CHILD-2", hasChild: false)
            let parentMap = [
                "CHILD-1": "PARENT-1",
                "CHILD-2": "PARENT-1"
            ]
            let childMap = [
                "PARENT-1": [
                    NodeChildren(wikiToken: "CHILD-1", sortID: 10),
                    NodeChildren(wikiToken: "CHILD-2", sortID: 20)
                ]
            ]
            let relation = WikiTreeRelation(nodeParentMap: parentMap,
                                            nodeChildrenMap: childMap)
            let metas = [
                "PARENT-1": parent,
                "CHILD-1": child1,
                "CHILD-2": child2
              ]
            let state = WikiTreeState(viewState: WikiTreeViewState(),
                                      metaStorage: metas, relation: relation)
            let node = WikiServerNode(meta: child1, sortID: 30, parent: "PARENT-1")
            let result = try processor.process(operation: .move(oldParentToken: "PARENT-1",
                                                                newParentToken: "PARENT-1",
                                                                nodes: [node]),
                                               treeState: state)
            XCTAssertEqual(result.metaStorage, metas)
            XCTAssertEqual(result.relation.nodeParentMap, parentMap)
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                "PARENT-1": [
                    NodeChildren(wikiToken: "CHILD-2", sortID: 20),
                    NodeChildren(wikiToken: "CHILD-1", sortID: 30)
                ]
            ])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }

    func testToggleStar() {
        let processor = WikiTreeDataProcessor()
        do {
            _ = try processor.process(operation: .toggleWikiStar(wikiToken: "UNKNOWN", isStar: true), treeState: .empty)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.UpdateError {
            if error != .wikiStarRootNotFound {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            let metas = [
                WikiTreeNodeMeta.favoriteRootToken: WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
            ]
            let relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: [
                WikiTreeNodeMeta.favoriteRootToken: [
                    NodeChildren(wikiToken: "A", sortID: 10)
                ]
            ])
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: relation)
            _ = try processor.process(operation: .toggleWikiStar(wikiToken: "A", isStar: true), treeState: state)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.UpdateError {
            if error != .starStateUnchanged {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            let metas = [
                WikiTreeNodeMeta.favoriteRootToken: WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
            ]
            let relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: [
                WikiTreeNodeMeta.favoriteRootToken: [
                    NodeChildren(wikiToken: "A", sortID: 10)
                ]
            ])
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: relation)
            var result = try processor.process(operation: .toggleWikiStar(wikiToken: "B", isStar: true), treeState: state)
            XCTAssertTrue(result.viewState.isEmpty)
            XCTAssertEqual(metas, result.metaStorage)
            XCTAssertTrue(result.relation.nodeParentMap.isEmpty)
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                WikiTreeNodeMeta.favoriteRootToken: [
                    NodeChildren(wikiToken: "B", sortID: 0),
                    NodeChildren(wikiToken: "A", sortID: 10)
                ]
            ])

            result = try processor.process(operation: .toggleWikiStar(wikiToken: "C", isStar: true), treeState: result)
            XCTAssertTrue(result.viewState.isEmpty)
            XCTAssertEqual(metas, result.metaStorage)
            XCTAssertTrue(result.relation.nodeParentMap.isEmpty)
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                WikiTreeNodeMeta.favoriteRootToken: [
                    NodeChildren(wikiToken: "C", sortID: -10),
                    NodeChildren(wikiToken: "B", sortID: 0),
                    NodeChildren(wikiToken: "A", sortID: 10)
                ]
            ])

            result = try processor.process(operation: .toggleWikiStar(wikiToken: "B", isStar: false), treeState: result)
            XCTAssertTrue(result.viewState.isEmpty)
            XCTAssertEqual(metas, result.metaStorage)
            XCTAssertTrue(result.relation.nodeParentMap.isEmpty)
            XCTAssertEqual(result.relation.nodeChildrenMap, [
                WikiTreeNodeMeta.favoriteRootToken: [
                    NodeChildren(wikiToken: "C", sortID: -10),
                    NodeChildren(wikiToken: "A", sortID: 10)
                ]
            ])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }

    func testToggleExplorerStar() {
        let processor = WikiTreeDataProcessor()
        do {
            _ = try processor.process(operation: .toggleExplorerStar(wikiToken: "UNKNOWN", isStar: true), treeState: .empty)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.UpdateError {
            if error != .targetNotFound {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            let meta = Util.mockNode(token: "A", hasChild: false)
            let metas = [
                "A": meta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            _ = try processor.process(operation: .toggleExplorerStar(wikiToken: "A", isStar: false), treeState: state)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.UpdateError {
            if error != .starStateUnchanged {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            var meta = Util.mockNode(token: "A", hasChild: false)
            let metas = [
                "A": meta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            let result = try processor.process(operation: .toggleExplorerStar(wikiToken: "A", isStar: true), treeState: state)
            meta.isExplorerStar = true
            XCTAssertEqual(result.metaStorage, ["A": meta])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
        
        do {
            var meta = Util.mockNode(token: "A", hasChild: false)
            var shortcutMeta = Util.mockShortcutNode(token: "A-Shortcut",
                                                     originNode: meta)
            let metas = [
                "A": meta,
                "A-Shortcut": shortcutMeta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            let result = try processor.process(operation: .toggleExplorerStar(wikiToken: "A", isStar: true), treeState: state)
            meta.isExplorerStar = true
            shortcutMeta.isExplorerStar = true
            XCTAssertEqual(result.metaStorage,
                           ["A": meta, "A-Shortcut": shortcutMeta])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }
    
    func testToggleExplorerStarForExternal() {
        let processor = WikiTreeDataProcessor()
        do {
            var shortcutMeta = Util.mockExternalShortcutNode(token: "A",
                                                             hasChild: false)
            let otherMeta = Util.mockExternalShortcutNode(token: "B",
                                                          hasChild: false)
            let metas = [
                "A": shortcutMeta,
                "B": otherMeta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            let operation = WikiTreeOperation.toggleExplorerStarForExternalShortcut(objToken: "A", isStar: true)
            let result = try processor.process(operation: operation,
                                               treeState: state)
            shortcutMeta.isExplorerStar = true
            XCTAssertEqual(result.metaStorage,
                           ["A": shortcutMeta, "B": otherMeta])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }

    func testGetNodeSection() {
        let relation = WikiTreeRelation(nodeParentMap: ["child": "parent"], nodeChildrenMap: [:])
        var state = WikiTreeState(viewState: WikiTreeViewState(),
                                  metaStorage: [:],
                                  relation: relation)
        var result = WikiTreeDataProcessor.getNodeSection(wikiToken: "child", treeState: state)
        XCTAssertNil(result)

        var metas = ["parent": WikiTreeNodeMeta.createMainRoot(rootToken: "parent", spaceID: "mock")]
        state = WikiTreeState(viewState: WikiTreeViewState(),
                              metaStorage: metas,
                              relation: relation)
        result = WikiTreeDataProcessor.getNodeSection(wikiToken: "child", treeState: state)
        XCTAssertEqual(result, .mainRoot)

        metas = ["parent": WikiTreeNodeMeta.createSharedRoot(spaceID: "mock")]
        state = WikiTreeState(viewState: WikiTreeViewState(),
                              metaStorage: metas,
                              relation: relation)
        result = WikiTreeDataProcessor.getNodeSection(wikiToken: "child", treeState: state)
        XCTAssertEqual(result, .sharedRoot)

        metas = ["parent": WikiTreeNodeMeta.createFavoriteRoot(spaceID: "mock")]
        state = WikiTreeState(viewState: WikiTreeViewState(),
                              metaStorage: metas,
                              relation: relation)
        result = WikiTreeDataProcessor.getNodeSection(wikiToken: "child", treeState: state)
        XCTAssertEqual(result, .favoriteRoot)
    }
    
    func testToggleExplorerPin() {
        let processor = WikiTreeDataProcessor()
        do {
            _ = try processor.process(operation: .toggleExplorerPin(wikiToken: "UNKNOWN", isPin: true), treeState: .empty)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.UpdateError {
            if error != .targetNotFound {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            let meta = Util.mockNode(token: "A", hasChild: false)
            let metas = [
                "A": meta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            _ = try processor.process(operation: .toggleExplorerPin(wikiToken: "A", isPin: false), treeState: state)
            XCTFail("process should failed")
        } catch let error as WikiTreeOperation.UpdateError {
            if error != .pinStateUnchanged {
                XCTFail("process found unknown error \(error)")
            }
        } catch {
            XCTFail("process found unknown error \(error)")
        }

        do {
            var meta = Util.mockNode(token: "A", hasChild: false)
            let metas = [
                "A": meta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            let result = try processor.process(operation: .toggleExplorerPin(wikiToken: "A", isPin: true), treeState: state)
            meta.isExplorerPin = true
            XCTAssertEqual(result.metaStorage, ["A": meta])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
        
        do {
            var meta = Util.mockNode(token: "A", hasChild: false)
            var shortcutMeta = Util.mockShortcutNode(token: "A-Shortcut",
                                                     originNode: meta)
            let metas = [
                "A": meta,
                "A-Shortcut": shortcutMeta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            let result = try processor.process(operation: .toggleExplorerPin(wikiToken: "A", isPin: true), treeState: state)
            meta.isExplorerPin = true
            shortcutMeta.isExplorerPin = true
            XCTAssertEqual(result.metaStorage,
                           ["A": meta, "A-Shortcut": shortcutMeta])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }
    
    func testToggleExplorerPinForExternal() {
        let processor = WikiTreeDataProcessor()
        do {
            var shortcutMeta = Util.mockExternalShortcutNode(token: "A",
                                                             hasChild: false)
            let otherMeta = Util.mockExternalShortcutNode(token: "B",
                                                          hasChild: false)
            let metas = [
                "A": shortcutMeta,
                "B": otherMeta
            ]
            let state = WikiTreeState(viewState: WikiTreeViewState(), metaStorage: metas, relation: WikiTreeRelation())
            let operation = WikiTreeOperation.toggleExplorerPinForExternalShortcut(objToken: "A", isPin: true)
            let result = try processor.process(operation: operation,
                                               treeState: state)
            shortcutMeta.isExplorerPin = true
            XCTAssertEqual(result.metaStorage,
                           ["A": shortcutMeta, "B": otherMeta])
        } catch {
            XCTFail("process found unknown error \(error)")
        }
    }
}
