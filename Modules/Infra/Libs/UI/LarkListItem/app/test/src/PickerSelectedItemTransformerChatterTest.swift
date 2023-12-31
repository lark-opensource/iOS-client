//
//  PickerSelectedItemTransformerChatterTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/10/20.
//

import XCTest
import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class PickerSelectedItemTransformerChatterTest: XCTestCase {

    var meta: PickerChatterMeta!
    var item: PickerItem!
    var transformer: PickerSelectedItemTransformer!

    override func setUp() {
        meta = ChatterMetaMocker.mockChatter()
        item = PickerItemMocker.mockChatter(meta: meta)
        transformer = PickerSelectedItemTransformer(accessoryTransformer: .init(isOpen: true))
    }

    func testChatter() {
        let node = transformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        XCTAssertEqual(node.title?.string, "MuMu")
        XCTAssertNil(node.desc)
        XCTAssertNil(node.status)
        XCTAssertEqual(node.accessories?.count, 2)
    }

    func testAvatarKey() {
        meta.avatarKey = "1"
        meta.avatarUrl = "2"
        item = PickerItemMocker.mockChatter(meta: meta)
        let node = transformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        if case .avatar(_, let key) = node.icon {
            XCTAssertEqual(key, "1")
        } else {
            XCTFail()
        }
    }

    func testAvatarUrl() {
        meta.avatarKey = nil
        meta.avatarUrl = "2"
        item = PickerItemMocker.mockChatter(meta: meta)
        let node = transformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        if case .avatarImageURL(let url) = node.icon {
            XCTAssertEqual(url?.absoluteString, "2")
        } else {
            XCTFail()
        }
    }

}
// swiftlint:enable all
