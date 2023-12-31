//
//  PickerItemTransformWikiTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/10/11.
//

import XCTest
import LarkModel
@testable import LarkListItem

final class PickerItemTransformWikiTest: XCTestCase {

    var meta: PickerWikiMeta!
    var item: PickerItem!
    var transformer: PickerItemTransformer!
    let indexPath = IndexPath(row: 0, section: 0)

    override func setUp() {
        meta = WikiMetaMocker.mockWiki()
        item = PickerItemMocker.mockWiki(wiki: meta)
        transformer = PickerItemTransformer()
    }

    func testNode() {
        let node = transformer.transform(indexPath: indexPath, item: item)
        XCTAssertEqual(node.title?.string, "Lark iOS Core模块技术目录")
        XCTAssertEqual(node.desc?.string, "￼ Lark Office · 最后更新于 Mar 3")
        XCTAssertNil(node.descIcon)
    }

    func testNormalNode() {
        meta.title = "title"
        meta.desc = "desc"
        item = PickerItemMocker.mockWiki(wiki: meta)
        item.renderData = nil
        let node = transformer.transform(indexPath: indexPath, item: item)
        XCTAssertEqual(node.title?.string, "title")
        XCTAssertEqual(node.desc?.string, "desc")
    }
}
