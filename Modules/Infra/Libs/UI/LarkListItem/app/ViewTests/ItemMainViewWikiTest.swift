//
//  ItemMainViewWikiTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/6/1.
//

import XCTest
@testable import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class ItemMainViewWikiTest: ViewTestCase {

    var item: PickerItem!
    var tableView: TestTableView!

    override func setUp() {
        super.setUp()
        item = PickerItemMocker.mockWiki()
        tableView = TestTableView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }
    
    func testWikiMainView() {
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }
}
// swiftlint:enable all
