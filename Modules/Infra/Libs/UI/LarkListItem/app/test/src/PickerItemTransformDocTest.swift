//
//  PickerItemTransformDocTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/10/11.
//

import XCTest
import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class PickerItemTransformDocTest: XCTestCase {
    var meta: PickerDocMeta!
    var item: PickerItem!
    var transformer: PickerItemTransformer!
    let indexPath = IndexPath(row: 0, section: 0)

    override func setUp() {
        meta = DocMetaMocker.mockDoc()
        item = PickerItemMocker.mockDoc(doc: meta)
        transformer = PickerItemTransformer()
    }

    func testMetaNode() {
        let node = transformer.transform(indexPath: indexPath, item: item)
        XCTAssertEqual(node.title?.string, "TaskBoard")
        XCTAssertEqual(node.desc?.string, "所有者：谢许峰 · 最后更新于 May 24")
        XCTAssertNil(node.descIcon)
    }

    func testNormalNode() {
        meta.title = "title"
        meta.desc = "desc"
        item = PickerItemMocker.mockDoc(doc: meta)
        item.renderData = nil
        let node = transformer.transform(indexPath: indexPath, item: item)
        XCTAssertEqual(node.title?.string, "title")
        XCTAssertEqual(node.desc?.string, "desc")
    }

    func testExternal() {
        meta.meta?.isCrossTenant = true
        item = PickerItemMocker.mockDoc(doc: meta)
        item.renderData = nil
        let node = transformer.transform(indexPath: indexPath, item: item)
        XCTAssertEqual(node.tags.count, 1)
        guard case .external = node.tags.first else {
            XCTFail("\(node.tags)")
            return
        }
    }
}
// swiftlint:enable all
