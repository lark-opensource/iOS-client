//
//  PickerItemTransformChatterTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/9/27.
//

import XCTest
import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class PickerItemTransformChatterTest: XCTestCase {

    var meta: PickerChatterMeta!
    var item: PickerItem!

    override func setUp() {
        meta = ChatterMetaMocker.mockChatter()
        item = PickerItemMocker.mockChatter(meta: meta)
    }

    func testTransformChatter() {
        let node = PickerItemTransformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        XCTAssertEqual(node.title?.string, "MuMu")
        XCTAssertEqual(node.desc?.string, "Lark Office Engineering-Performance")
        if case .avatar(let id, let key) = node.icon {
            XCTAssertEqual(id, "")
            XCTAssertEqual(key, "15094e27-7366-46df-bee8-c535b8bf745g")
        } else {
            XCTFail()
        }
    }

    func testSubtitle() {
        let node = PickerItemTransformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        XCTAssertEqual(node.subtitle?.string, "Unit test")
    }

    func testNilSubtitle() {
        meta.description = nil
        item = PickerItemMocker.mockChatter(meta: meta)
        let node = PickerItemTransformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        XCTAssertNil(node.subtitle)
    }
    func testEmptySubtitle() {
        meta.description = ""
        item = PickerItemMocker.mockChatter(meta: meta)
        let node = PickerItemTransformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        XCTAssertNil(node.subtitle)
    }
    func testAvatarKey() {
        meta.avatarKey = "1"
        meta.avatarUrl = "2"
        item = PickerItemMocker.mockChatter(meta: meta)
        let node = PickerItemTransformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
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
        let node = PickerItemTransformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        if case .avatarImageURL(let url) = node.icon {
            XCTAssertEqual(url?.absoluteString, "2")
        } else {
            XCTFail()
        }
    }
}
// swiftlint:enable all
