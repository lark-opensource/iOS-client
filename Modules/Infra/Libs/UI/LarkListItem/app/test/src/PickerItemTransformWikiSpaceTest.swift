//
//  PickerItemTransformWikiSpaceTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/10/11.
//

import XCTest
import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class PickerItemTransformWikiSpaceTest: XCTestCase {

    var meta: PickerWikiSpaceMeta!
    var item: PickerItem!
    var transformer: PickerItemTransformer!
    let indexPath = IndexPath(row: 0, section: 0)

    override func setUp() {
        meta = WikiSpaceMocker.mockWikiSpace()
        item = PickerItemMocker.mockWikiSpace(space: meta)
        transformer = PickerItemTransformer()
    }

    func testNode() {
        let node = transformer.transform(indexPath: indexPath, item: item)
        XCTAssertEqual(node.title?.string, "TCC")
        XCTAssertEqual(node.desc?.string, "配置管理解决方案")
        XCTAssertNil(node.descIcon)
    }

    func testNormalNode() {
        meta.title = "title"
        meta.desc = "desc"
        item = PickerItemMocker.mockWikiSpace(space: meta)
        item.renderData = nil
        let node = transformer.transform(indexPath: indexPath, item: item)
        XCTAssertEqual(node.title?.string, "title")
        XCTAssertEqual(node.desc?.string, "desc")
    }
}
// swiftlint:enable all
