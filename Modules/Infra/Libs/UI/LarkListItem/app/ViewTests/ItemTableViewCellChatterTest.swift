//
//  ItemTableViewCellChatterTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/10/9.
//

import XCTest
import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class ItemTableViewCellChatterTest: ViewTestCase {

    var meta: PickerChatterMeta!
    var item: PickerItem!
    var tableView: TestTableView!

    override func setUp() {
        super.setUp()
        meta = ChatterMetaMocker.mockChatter()
        item = PickerItemMocker.mockChatter(meta: meta)
        tableView = TestTableView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }

    func testChatterCell() {
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }

    func testLongDepartment() {
        item.renderData?.summary = "LongDepartmentLongDepartmentLongDepartmentLongDepartment"
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }
}
// swiftlint:enable all
