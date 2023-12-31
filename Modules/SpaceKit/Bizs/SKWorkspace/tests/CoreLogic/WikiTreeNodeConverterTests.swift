//
//  WikiTreeNodeConverterTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/15.
//
// swiftlint:disable type_body_length file_length function_body_length

import XCTest
@testable import SKWorkspace
import SKFoundation
import SKResource

class WikiTreeNodeConverterTests: XCTestCase {
    typealias NodeChildren = WikiTreeRelation.NodeChildren
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    typealias Util = WikiTreeTestUtil

    func testConvertRootNode() {
        let mainRoot = WikiTreeNodeMeta.createMainRoot(rootToken: Util.mainRootToken, spaceID: Util.mockSpaceID)
        var viewState = WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [])
        let relation = WikiTreeRelation()
        let metaStorage = [Util.mainRootToken: mainRoot]
        var converter = WikiTreeNodeConverter(relation: relation,
                                              viewState: viewState,
                                              metaStorage: metaStorage,
                                              config: .init())
        var rootNode = converter.convertRootNode(section: .mainRoot, meta: mainRoot)
        XCTAssertEqual(rootNode.id, Util.mainRootToken)
        XCTAssertEqual(rootNode.section, TreeNodeRootSection.mainRoot)
        XCTAssertEqual(rootNode.title, BundleI18n.SKResource.LarkCCM_CM_MyLib_TableOfContent_Title)
        XCTAssertFalse(rootNode.isSelected)
        XCTAssertFalse(rootNode.isOpened)
        XCTAssertTrue(rootNode.isEnabled)
        XCTAssertEqual(rootNode.level, 0)
        XCTAssertFalse(rootNode.isLeaf)
        XCTAssertFalse(rootNode.isShortcut)

        viewState = WikiTreeViewState(selectedWikiToken: Util.mainRootToken, expandedUIDs: [])
        converter = WikiTreeNodeConverter(relation: relation,
                                          viewState: viewState,
                                          metaStorage: metaStorage,
                                          config: .init())
        rootNode = converter.convertRootNode(section: .mainRoot, meta: mainRoot)
        XCTAssertEqual(rootNode.id, Util.mainRootToken)
        XCTAssertEqual(rootNode.section, TreeNodeRootSection.mainRoot)
        XCTAssertEqual(rootNode.title, BundleI18n.SKResource.LarkCCM_CM_MyLib_TableOfContent_Title)
        XCTAssertTrue(rootNode.isSelected)
        XCTAssertFalse(rootNode.isOpened)
        XCTAssertTrue(rootNode.isEnabled)
        XCTAssertEqual(rootNode.level, 0)
        XCTAssertFalse(rootNode.isLeaf)
        XCTAssertFalse(rootNode.isShortcut)

        viewState = WikiTreeViewState(selectedWikiToken: nil,
                                      expandedUIDs: [
                                        WikiTreeNodeUID(wikiToken: Util.mainRootToken, section: .mainRoot, shortcutPath: "")
                                      ])
        converter = WikiTreeNodeConverter(relation: relation,
                                          viewState: viewState,
                                          metaStorage: metaStorage,
                                          config: .init())
        rootNode = converter.convertRootNode(section: .mainRoot, meta: mainRoot)
        XCTAssertEqual(rootNode.id, Util.mainRootToken)
        XCTAssertEqual(rootNode.section, TreeNodeRootSection.mainRoot)
        XCTAssertEqual(rootNode.title, BundleI18n.SKResource.LarkCCM_CM_MyLib_TableOfContent_Title)
        XCTAssertFalse(rootNode.isSelected)
        XCTAssertTrue(rootNode.isOpened)
        XCTAssertTrue(rootNode.isEnabled)
        XCTAssertEqual(rootNode.level, 0)
        XCTAssertFalse(rootNode.isLeaf)
        XCTAssertFalse(rootNode.isShortcut)
    }

    func testCanExpand() {
        let mockNormalNode = WikiTreeNodeMeta(wikiToken: "MOCK_WIKI_TOKEN",
                                              spaceID: Util.mockSpaceID,
                                              objToken: "MOCK_OBJ_TOKEN",
                                              objType: .doc,
                                              title: "MOCK_TITLE",
                                              hasChild: true,
                                              secretKeyDeleted: false,
                                              isExplorerStar: false,
                                              nodeType: .normal, originDeletedFlag: 0,
                                              isExplorerPin: false)

        let mockShortcutNode = WikiTreeNodeMeta(wikiToken: "MOCK_SHORTCUT_TOKEN",
                                                spaceID: Util.mockSpaceID,
                                                objToken: "MOCK_OBJ_TOKEN",
                                                objType: .doc,
                                                title: "MOCK_TITLE",
                                                hasChild: true,
                                                secretKeyDeleted: false,
                                                isExplorerStar: false,
                                                nodeType: .shortcut(location: .inWiki(wikiToken: "MOCK_WIKI_TOKEN",
                                                                                      spaceID: Util.mockSpaceID)),
                                                originDeletedFlag: 0,
                                                isExplorerPin: false)
        let mockLeafNode = WikiTreeNodeMeta(wikiToken: "MOCK_LEAF_TOKEN",
                                            spaceID: Util.mockSpaceID,
                                            objToken: "MOCK_OBJ_TOKEN",
                                            objType: .doc,
                                            title: "MOCK_TITLE",
                                            hasChild: false,
                                            secretKeyDeleted: false,
                                            isExplorerStar: false,
                                            nodeType: .normal,
                                            originDeletedFlag: 0,
                                            isExplorerPin: false)

        let metaStorage: [String: WikiTreeNodeMeta] = [
            "MOCK_WIKI_TOKEN": mockNormalNode,
            "MOCK_SHORTCUT_TOKEN": mockShortcutNode,
            "MOCK_LEAF_TOKEN": mockLeafNode
        ]
        var relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: ["MOCK_WIKI_TOKEN": []])
        let viewState = WikiTreeViewState()

        var converter = WikiTreeNodeConverter(relation: relation,
                                              viewState: viewState,
                                              metaStorage: metaStorage,
                                              config: .init())
        // 没有 meta
        XCTAssertFalse(converter.canExpand(section: .mainRoot, token: "UNKNOWN", path: []))
        // hasChild 为 false
        XCTAssertFalse(converter.canExpand(section: .mainRoot, token: "MOCK_LEAF_TOKEN", path: []))
        // 没有子节点
        XCTAssertTrue(converter.canExpand(section: .mainRoot, token: "MOCK_SHORTCUT_TOKEN", path: []))
        XCTAssertTrue(converter.canExpand(section: .mainRoot, token: "MOCK_WIKI_TOKEN", path: []))

        relation = WikiTreeRelation()
        converter = WikiTreeNodeConverter(relation: relation,
                                          viewState: viewState,
                                          metaStorage: metaStorage,
                                          config: .init())
        // 套娃
        XCTAssertFalse(converter.canExpand(section: .mainRoot, token: "MOCK_SHORTCUT_TOKEN", path: ["MOCK_WIKI_TOKEN"]))
        XCTAssertFalse(converter.canExpand(section: .mainRoot, token: "MOCK_WIKI_TOKEN", path: ["MOCK_WIKI_TOKEN"]))
        // 正常展开
        XCTAssertTrue(converter.canExpand(section: .mainRoot, token: "MOCK_SHORTCUT_TOKEN", path: ["MOCK_OTHER_TOKEN"]))
    }

    func testConvertChildNode() {
        let token = "MOCK_LEAF_NODE"
        let meta = WikiTreeNodeMeta(wikiToken: token,
                                    spaceID: Util.mockSpaceID,
                                    objToken: "MOCK_OBJ_TOKEN",
                                    objType: .doc,
                                    title: "MOCK_LEAF_TITLE",
                                    hasChild: false,
                                    secretKeyDeleted: false,
                                    isExplorerStar: false,
                                    nodeType: .normal,
                                    originDeletedFlag: 0,
                                    isExplorerPin: false)
        var converter = WikiTreeNodeConverter(relation: WikiTreeRelation(),
                                              viewState: WikiTreeViewState(),
                                              metaStorage: [token: meta],
                                              config: .init())
        var node = converter.convertChildNode(section: .mainRoot,
                                              meta: meta,
                                              level: 1,
                                              path: [Util.mainRootToken],
                                              shortcutPath: "-A-B-C")
        XCTAssertEqual(node.id, token)
        XCTAssertEqual(node.section, .mainRoot)
        XCTAssertEqual(node.title, "MOCK_LEAF_TITLE")
        XCTAssertFalse(node.isSelected)
        XCTAssertFalse(node.isOpened)
        XCTAssertTrue(node.isEnabled)
        XCTAssertEqual(node.level, 1)
        XCTAssertTrue(node.isLeaf)
        XCTAssertFalse(node.isShortcut)
        XCTAssertEqual(node.diffId, WikiTreeNodeUID(wikiToken: token, section: .mainRoot, shortcutPath: "-A-B-C"))

        let config = WikiTreeNodeConverter.Config(filter: nil, enableChecker: { _ in
            false
        })
        converter = WikiTreeNodeConverter(relation: WikiTreeRelation(),
                                          viewState: WikiTreeViewState(),
                                          metaStorage: [token: meta],
                                          config: config)
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertFalse(node.isEnabled)
    }

    // 普通叶子结点
    func testConvertLeafChildNode() {
        let token = "MOCK_LEAF_NODE"
        let meta = WikiTreeNodeMeta(wikiToken: token,
                                    spaceID: Util.mockSpaceID,
                                    objToken: "MOCK_OBJ_TOKEN",
                                    objType: .doc,
                                    title: "MOCK_LEAF_TITLE",
                                    hasChild: false,
                                    secretKeyDeleted: false,
                                    isExplorerStar: false,
                                    nodeType: .normal,
                                    originDeletedFlag: 0,
                                    isExplorerPin: false)
        let metaStorage = [token: meta]
        var viewState = WikiTreeViewState()
        let relation = WikiTreeRelation(nodeParentMap: [:],
                                        nodeChildrenMap: [token: []])
        var converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        var node = converter.convertChildNode(section: .mainRoot,
                                              meta: meta,
                                              level: 1,
                                              path: [Util.mainRootToken],
                                              shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertFalse(node.isOpened)
        XCTAssertTrue(node.isLeaf)

        // 选中态
        viewState.select(wikiToken: token)
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertTrue(node.isSelected)
        XCTAssertFalse(node.isOpened)
        XCTAssertTrue(node.isLeaf)

        // 展开态
        viewState.select(wikiToken: nil)
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: token, section: .mainRoot, shortcutPath: ""))
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertTrue(node.isOpened)
        XCTAssertTrue(node.isLeaf)
    }

    // 普通叶子结点
    func testConvertLeafShortcutNode() {
        let token = "MOCK_LEAF_SHORTCUT_NODE"
        let originToken = "MOCK_LEAF_NODE"
        let meta = WikiTreeNodeMeta(wikiToken: token,
                                    spaceID: Util.mockSpaceID,
                                    objToken: "MOCK_OBJ_TOKEN",
                                    objType: .doc,
                                    title: "MOCK_LEAF_SHORTCUT_TITLE",
                                    hasChild: false,
                                    secretKeyDeleted: false,
                                    isExplorerStar: false,
                                    nodeType: .shortcut(location: .inWiki(wikiToken: originToken,
                                                                          spaceID: Util.mockSpaceID)),
                                    originDeletedFlag: 0,
                                    isExplorerPin: false)
        let metaStorage = [token: meta]
        var viewState = WikiTreeViewState()
        let relation = WikiTreeRelation(nodeParentMap: [:],
                                        nodeChildrenMap: [originToken: []])
        var converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        var node = converter.convertChildNode(section: .mainRoot,
                                              meta: meta,
                                              level: 1,
                                              path: [Util.mainRootToken],
                                              shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertFalse(node.isOpened)
        XCTAssertTrue(node.isLeaf)
        XCTAssertTrue(node.isShortcut)

        // 选中态
        viewState.select(wikiToken: token)
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertTrue(node.isSelected)
        XCTAssertFalse(node.isOpened)
        XCTAssertTrue(node.isLeaf)
        XCTAssertTrue(node.isShortcut)

        // 展开态
        let UID = WikiTreeNodeUID(wikiToken: token, section: .mainRoot, shortcutPath: "")
        viewState.select(wikiToken: nil)
        viewState.expand(nodeUID: UID)
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertTrue(node.isOpened)
        XCTAssertTrue(node.isLeaf)
        XCTAssertTrue(node.isShortcut)
        XCTAssertEqual(node.diffId, UID)
    }

    // 普通非叶子结点
    func testConvertNormalChildNode() {
        let token = "MOCK_NORMAL_NODE"
        let meta = WikiTreeNodeMeta(wikiToken: token,
                                    spaceID: Util.mockSpaceID,
                                    objToken: "MOCK_OBJ_TOKEN",
                                    objType: .doc,
                                    title: "MOCK_NORMAL_TITLE",
                                    hasChild: true,
                                    secretKeyDeleted: false,
                                    isExplorerStar: false,
                                    nodeType: .normal,
                                    originDeletedFlag: 0,
                                    isExplorerPin: false)
        let metaStorage = [token: meta]
        
        var viewState = WikiTreeViewState()
        let relation = WikiTreeRelation(nodeParentMap: [:],
                                        nodeChildrenMap: [
                                            token: [NodeChildren(wikiToken: "MOCK_CHILD_NODE", sortID: 1)]
                                        ])
        var converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        var node = converter.convertChildNode(section: .mainRoot,
                                              meta: meta,
                                              level: 1,
                                              path: [Util.mainRootToken],
                                              shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertFalse(node.isOpened)
        XCTAssertFalse(node.isLeaf)
        XCTAssertFalse(node.isShortcut)

        // 选中态
        viewState.select(wikiToken: token)
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertTrue(node.isSelected)
        XCTAssertFalse(node.isOpened)

        // 展开态
        viewState.select(wikiToken: nil)
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: token, section: .mainRoot, shortcutPath: ""))
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertTrue(node.isOpened)

        // 套娃
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [token],
                                          shortcutPath: "-A-B")
        XCTAssertFalse(node.isOpened)
        XCTAssertTrue(node.isLeaf)
    }

    // shortcut 非叶子结点
    func testConvertShortcutNormalNode() {
        let token = "MOCK_SHORTCUT_NODE"
        let originToken = "MOCK_NORMAL_NODE"
        let meta = WikiTreeNodeMeta(wikiToken: token,
                                    spaceID: Util.mockSpaceID,
                                    objToken: "MOCK_OBJ_TOKEN",
                                    objType: .doc,
                                    title: "MOCK_SHORTCUT_TITLE",
                                    hasChild: true,
                                    secretKeyDeleted: false,
                                    isExplorerStar: false,
                                    nodeType: .shortcut(location: .inWiki(wikiToken: originToken,
                                                                          spaceID: Util.mockSpaceID)),
                                    originDeletedFlag: 0,
                                    isExplorerPin: false)
        let metaStorage = [token: meta]
        var viewState = WikiTreeViewState()
        let relation = WikiTreeRelation(nodeParentMap: [:],
                                        nodeChildrenMap: [originToken: [NodeChildren(wikiToken: "MOCK_CHILD_NODE", sortID: 1)]])
        var converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        var node = converter.convertChildNode(section: .mainRoot,
                                              meta: meta,
                                              level: 1,
                                              path: [Util.mainRootToken],
                                              shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertFalse(node.isOpened)
        XCTAssertFalse(node.isLeaf)
        XCTAssertTrue(node.isShortcut)

        // 选中态
        viewState.select(wikiToken: token)
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertTrue(node.isSelected)
        XCTAssertFalse(node.isOpened)

        // 展开态
        let UID = WikiTreeNodeUID(wikiToken: token, section: .mainRoot, shortcutPath: "")
        viewState.select(wikiToken: nil)
        viewState.expand(nodeUID: UID)
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [Util.mainRootToken],
                                          shortcutPath: "")
        XCTAssertFalse(node.isSelected)
        XCTAssertTrue(node.isOpened)
        XCTAssertFalse(node.isLeaf)
        XCTAssertTrue(node.isShortcut)

        // 套娃
        node = converter.convertChildNode(section: .mainRoot,
                                          meta: meta,
                                          level: 1,
                                          path: [originToken],
                                          shortcutPath: "-A-B")
        XCTAssertFalse(node.isOpened)
        XCTAssertTrue(node.isLeaf)
    }

    func testConvertTree() {
        let (relation, metaStorage) = Util.mockTree()
        var viewState = WikiTreeViewState()
        var converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        var result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        XCTAssertTrue(mainSection.items.isEmpty)
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: Util.mainRootToken, section: .mainRoot, shortcutPath: ""))
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        var levelExpect = [1, 1, 1, 1, 1]
        var leafExpect = [true, true, false, false, false]
        var openExpect = [false, false, false, false, false]
        XCTAssertEqual(mainSection.items.count, 5)
        XCTAssertEqual(mainSection.items.map(\.level), levelExpect)
        XCTAssertEqual(mainSection.items.map(\.isLeaf), leafExpect)
        XCTAssertEqual(mainSection.items.map(\.isOpened), openExpect)

        // 测试一下过滤 shortcut
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: Util.mainRootToken, section: .mainRoot, shortcutPath: ""))
        let shortcutFilterConfig = WikiTreeNodeConverter.Config(filter: { !$0.isShortcut }, enableChecker: nil)
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: shortcutFilterConfig)
        result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        XCTAssertEqual(mainSection.items.count, 3)
        XCTAssertEqual(mainSection.items.map(\.level), [1, 1, 1])
        XCTAssertEqual(mainSection.items.map(\.isLeaf), [true, false, false])
        XCTAssertEqual(mainSection.items.map(\.isOpened), [false, false, false])
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: "3.normal", section: .mainRoot, shortcutPath: ""))
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        openExpect[2] = true
        levelExpect.insert(contentsOf: [2, 2, 2, 2, 2], at: 3)
        leafExpect.insert(contentsOf: [true, true, false, false, false], at: 3)
        openExpect.insert(contentsOf: [false, false, false, false, false], at: 3)

        XCTAssertEqual(mainSection.items.count, 10)
        XCTAssertEqual(mainSection.items.map(\.level), levelExpect)
        XCTAssertEqual(mainSection.items.map(\.isLeaf), leafExpect)
        XCTAssertEqual(mainSection.items.map(\.isOpened), openExpect)
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: "3.5.normal-shortcut", section: .mainRoot, shortcutPath: ""))
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        openExpect[7] = true
        levelExpect.insert(3, at: 8)
        leafExpect.insert(true, at: 8)
        openExpect.insert(false, at: 8)

        XCTAssertEqual(mainSection.items.count, 11)
        XCTAssertEqual(mainSection.items.map(\.level), levelExpect)
        XCTAssertEqual(mainSection.items.map(\.isLeaf), leafExpect)
        XCTAssertEqual(mainSection.items.map(\.isOpened), openExpect)
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: "5.normal", section: .mainRoot, shortcutPath: ""))
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        openExpect[10] = true
        levelExpect.insert(2, at: 11)
        leafExpect.insert(false, at: 11)
        openExpect.insert(false, at: 11)

        XCTAssertEqual(mainSection.items.count, 12)
        XCTAssertEqual(mainSection.items.map(\.level), levelExpect)
        XCTAssertEqual(mainSection.items.map(\.isLeaf), leafExpect)
        XCTAssertEqual(mainSection.items.map(\.isOpened), openExpect)
        viewState.expand(nodeUID: WikiTreeNodeUID(wikiToken: "5.1.normal-shortcut", section: .mainRoot, shortcutPath: ""))
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        openExpect[11] = true
        levelExpect.insert(contentsOf: [3, 3, 3, 3, 3], at: 12)
        leafExpect.insert(contentsOf: [true, true, false, false, true], at: 12)
        openExpect.insert(contentsOf: [false, false, false, false, false], at: 12)

        XCTAssertEqual(mainSection.items.count, 17)
        XCTAssertEqual(mainSection.items.map(\.level), levelExpect)
        XCTAssertEqual(mainSection.items.map(\.isLeaf), leafExpect)
        XCTAssertEqual(mainSection.items.map(\.isOpened), openExpect)

        viewState.select(wikiToken: "5.1.normal-shortcut")
        converter = WikiTreeNodeConverter(relation: relation, viewState: viewState, metaStorage: metaStorage, config: .init())
        result = converter.convert(rootList: [(.mainRoot, Util.mainRootToken)])
        XCTAssertEqual(result.count, 1)
        guard let mainSection = result.first else {
            return
        }
        let selectedExpect = [
            false, false, false, // 1 ~ 3
            false, false, false, false, false, // 3.1 ~ 3.5
            true, // 3.5-5.1
            false, false, // 4 ~ 5
            true, // 5.1
            false, false, false, false, false // 5.1 - 3.1 ~ 3.5
        ]
        XCTAssertEqual(mainSection.items.map(\.isSelected), selectedExpect)
    }

    func testEmptyNode() {
        let normalEmptyNode = WikiTreeNodeConverter.makeEmptyNode(section: .mainRoot,
                                                                  level: 2,
                                                                  parentToken: WikiTreeNodeMeta.favoriteRootToken,
                                                                  shortcutPath: "")
        XCTAssertEqual(normalEmptyNode.type, .empty)
        XCTAssertEqual(normalEmptyNode.title, BundleI18n.SKResource.CreationMobile_Wiki_NoSubpages_Placeholder)

        let starEmptyNode = WikiTreeNodeConverter.makeEmptyNode(section: .favoriteRoot,
                                                                level: 1,
                                                                parentToken: WikiTreeNodeMeta.favoriteRootToken,
                                                                shortcutPath: "")
        XCTAssertEqual(starEmptyNode.type, .empty)
        XCTAssertEqual(starEmptyNode.title, BundleI18n.SKResource.CreationMobile_Wiki_NoPage_Placeholder)
    }

    func testEmptyFavoriteTree() {
        let favRoot = WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
        let UID = WikiTreeNodeUID(wikiToken: favRoot.wikiToken, section: .favoriteRoot, shortcutPath: "")
        let viewState = WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [UID])
        let metaStorage = [favRoot.wikiToken: favRoot]
        let converter = WikiTreeNodeConverter(relation: WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: [favRoot.wikiToken: []]),
                                              viewState: viewState,
                                              metaStorage: metaStorage,
                                              config: .init())
        let result = converter.convertChildNodes(section: .favoriteRoot,
                                                 parentToken: favRoot.wikiToken,
                                                 level: 0,
                                                 path: [], shortcutPath: "")
        XCTAssertEqual(result.count, 1)
        guard let emptyNode = result.first else { return }
        XCTAssertEqual(emptyNode.type, .empty)
        XCTAssertEqual(emptyNode.title, BundleI18n.SKResource.CreationMobile_Wiki_NoPage_Placeholder)
    }

    func testEmptyChildTree() {
        let parentNode = Util.mockNode(token: "PARENT", hasChild: true)
        let UID = WikiTreeNodeUID(wikiToken: parentNode.wikiToken, section: .mainRoot, shortcutPath: "")
        let viewState = WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [UID])
        let metaStorage = [parentNode.wikiToken: parentNode]
        let converter = WikiTreeNodeConverter(relation: WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: [parentNode.wikiToken: []]),
                                              viewState: viewState,
                                              metaStorage: metaStorage,
                                              config: .init())
        let result = converter.convertChildNodes(section: .mainRoot,
                                                 parentToken: parentNode.wikiToken,
                                                 level: 0,
                                                 path: [],
                                                 shortcutPath: "")
        XCTAssertEqual(result.count, 1)
        guard let emptyNode = result.first else { return }
        XCTAssertEqual(emptyNode.type, .empty)
        XCTAssertEqual(emptyNode.title, BundleI18n.SKResource.CreationMobile_Wiki_NoSubpages_Placeholder)
    }

    func testFavoriteTreeUID() {
        let favRoot = WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
        let viewState = WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [
            WikiTreeNodeUID(wikiToken: favRoot.wikiToken, section: .favoriteRoot, shortcutPath: ""),
            WikiTreeNodeUID(wikiToken: "A", section: .favoriteRoot, shortcutPath: "-A")
        ])
        let metaStorage = [
            favRoot.wikiToken: favRoot,
            "A": Util.mockNode(token: "A", hasChild: true),
            "B": Util.mockNode(token: "B", hasChild: false)
        ]
        let relation = WikiTreeRelation(nodeParentMap: [
            "A": "ROOT",
            "B": "A"
        ], nodeChildrenMap: [
            favRoot.wikiToken: [
                NodeChildren(wikiToken: "A", sortID: 0),
                NodeChildren(wikiToken: "B", sortID: 10)
            ],
            "A": [
                NodeChildren(wikiToken: "B", sortID: 0)
            ]
        ])
        let converter = WikiTreeNodeConverter(relation: relation,
                                              viewState: viewState,
                                              metaStorage: metaStorage,
                                              config: .init())
        do {
            let section = try converter.convert(section: .favoriteRoot, rootToken: favRoot.wikiToken)
            XCTAssertEqual(section.items.count, 3)
            XCTAssertEqual(section.items.map(\.level), [1, 2, 1])
            XCTAssertEqual(section.items.map(\.isLeaf), [false, true, true])
            XCTAssertEqual(section.items.map(\.isOpened), [true, false, false])
            XCTAssertEqual(section.items.map(\.diffId), [
                WikiTreeNodeUID(wikiToken: "A", section: .favoriteRoot, shortcutPath: "-A"),
                WikiTreeNodeUID(wikiToken: "B", section: .favoriteRoot, shortcutPath: "-A"),
                WikiTreeNodeUID(wikiToken: "B", section: .favoriteRoot, shortcutPath: "-B")
            ])
        } catch {
            XCTFail("convert fav failed: \(error)")
        }
    }
}
