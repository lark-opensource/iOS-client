//
//  SelectedItemStoreTest.swift
//  UnitTests
//
//  Created by Yuri on 2022/12/30.
//

import Foundation
import XCTest
@testable import LarkIMMention

// swiftlint:disable all
final class SelectedItemStoreTest: XCTestCase {
    
    var store: SelectedItemStore!
    
    override func setUp() {
        store = SelectedItemStore()
    }
    
    /// 选择一个item
    func testSelectItem() {
        let item = Mocker.mockItem(id: "1")
        store.toggleMultiSelected(isOn: true)
        store.toggleItemSelected(item: item)
        XCTAssertEqual(store.selectedItems[0].id, "1")
        XCTAssertEqual(store.selectedCache["1"], 1)
    }
    
    /// 取消选择一个item
    func testDeselectItem() {
        let item = Mocker.mockItem(id: "1")
        store.toggleMultiSelected(isOn: true)
        store.toggleItemSelected(item: item)
        store.toggleItemSelected(item: item)
        XCTAssertEqual(store.selectedItems.count, 0)
        XCTAssertNil(store.selectedCache["1"])
    }
}
// swiftlint:enable all
