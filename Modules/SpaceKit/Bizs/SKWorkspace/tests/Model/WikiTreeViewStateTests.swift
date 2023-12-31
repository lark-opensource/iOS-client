//
//  WikiTreeViewStateTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/21.
//

import XCTest
@testable import SKWorkspace
import SKFoundation

class WikiTreeViewStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testEmpty() {
        var state = WikiTreeViewState()
        XCTAssertTrue(state.isEmpty)

        state.select(wikiToken: "TEST")
        XCTAssertFalse(state.isEmpty)

        state.select(wikiToken: nil)
        XCTAssertTrue(state.isEmpty)
        let testUID = WikiTreeNodeUID(wikiToken: "TEST", section: .mainRoot, shortcutPath: "")
        state.expand(nodeUID: testUID)
        XCTAssertFalse(state.isEmpty)

        state.collapse(nodeUID: testUID)
        XCTAssertTrue(state.isEmpty)

        state.select(wikiToken: "TEST")
        state.expand(nodeUID: testUID)
        XCTAssertFalse(state.isEmpty)
    }

    func testSelect() {
        var state = WikiTreeViewState()
        XCTAssertNil(state.selectedWikiToken)

        var target = "TEST"
        state.select(wikiToken: target)
        XCTAssertEqual(target, state.selectedWikiToken)

        target = "TEST_MOCK"
        state.select(wikiToken: target)
        XCTAssertEqual(target, state.selectedWikiToken)

        state.select(wikiToken: nil)
        XCTAssertNil(state.selectedWikiToken)
    }

    func testExpand() {
        var state = WikiTreeViewState()
        XCTAssertTrue(state.expandedUIDs.isEmpty)

        let target = WikiTreeNodeUID(wikiToken: "MOCK_UID", section: .mainRoot, shortcutPath: "")
        state.expand(nodeUID: target)
        XCTAssertTrue(state.expandedUIDs.contains(target))
        // 重复 expand
        state.expand(nodeUID: target)
        XCTAssertTrue(state.expandedUIDs.contains(target))
    }

    func testCollapse() {
        var state = WikiTreeViewState()
        XCTAssertTrue(state.expandedUIDs.isEmpty)

        let target = WikiTreeNodeUID(wikiToken: "MOCK_UID", section: .mainRoot, shortcutPath: "")
        XCTAssertFalse(state.expandedUIDs.contains(target))

        state.collapse(nodeUID: target)
        XCTAssertFalse(state.expandedUIDs.contains(target))

        state.expand(nodeUID: target)
        state.collapse(nodeUID: target)
        XCTAssertFalse(state.expandedUIDs.contains(target))
    }

    func testToggle() {
        var state = WikiTreeViewState()
        let target = WikiTreeNodeUID(wikiToken: "MOCK_UID", section: .mainRoot, shortcutPath: "")
        XCTAssertFalse(state.expandedUIDs.contains(target))
        state.toggle(nodeUID: target)
        XCTAssertTrue(state.expandedUIDs.contains(target))
        state.toggle(nodeUID: target)
        XCTAssertFalse(state.expandedUIDs.contains(target))

        state.expand(nodeUID: target)
        state.toggle(nodeUID: target)
        XCTAssertFalse(state.expandedUIDs.contains(target))
    }

    func testTreeState() {
        var state = WikiTreeState.empty
        XCTAssertTrue(state.isEmpty)

        let viewState = WikiTreeViewState(selectedWikiToken: "TEST", expandedUIDs: [])
        state = WikiTreeState(viewState: viewState, metaStorage: [:], relation: WikiTreeRelation())
        XCTAssertFalse(state.isEmpty)

        state = WikiTreeState(viewState: WikiTreeViewState(),
                              metaStorage: ["TEST": WikiTreeNodeMeta.createFavoriteRoot(spaceID: "TEST")],
                              relation: WikiTreeRelation())
        XCTAssertFalse(state.isEmpty)

        state = WikiTreeState(viewState: WikiTreeViewState(),
                              metaStorage: [:],
                              relation: WikiTreeRelation(nodeParentMap: ["A": "B"], nodeChildrenMap: [:]))
        XCTAssertFalse(state.isEmpty)
    }

    func testNodeUID() {
        let nodeUID = WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: "")
        var expect = WikiTreeNodeUID(wikiToken: "B", section: .mainRoot, shortcutPath: "")
        var result = nodeUID.extend(childToken: "B", currentIsShortcut: false)
        XCTAssertEqual(result, expect)

        expect = WikiTreeNodeUID(wikiToken: "B", section: .mainRoot, shortcutPath: "-A")
        result = nodeUID.extend(childToken: "B", currentIsShortcut: true)
        XCTAssertEqual(result, expect)
    }
}
