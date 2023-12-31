//
//  ItemMainViewDocTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/5/31.
//

import XCTest
@testable import LarkModel
@testable import LarkListItem
// swiftlint:disable all

final class ItemMainViewDocTest: ViewTestCase {
    var item: PickerItem!
    var tableView: TestTableView!

    override func setUp() {
        super.setUp()
        item = PickerItemMocker.mockDoc()
        tableView = TestTableView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }

    func testDocMainView() {
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }

    func testDocMainViewWithoutExtraInfos() {
        item.renderData?.extraInfos = nil
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }

    func testDocMainViewWithLongExtraInfos() {
        var infos = item.renderData?.extraInfos
        infos?.append(contentsOf: item.renderData?.extraInfos ?? [])
        item.renderData?.extraInfos = infos
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }

    func testMainViewWithLongTitle() {
        item.renderData?.titleHighlighted = NSAttributedString(string: "🧑‍💻 别的工程师都用 chatgpt 写代码了，你还在 github 上面拷")
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }

    func testMp3Icon() {
        if case .doc(var meta) = item.meta {
            meta.meta?.type = .file
            item.meta = .doc(meta)
        }
        item.renderData?.titleHighlighted = NSAttributedString(string: "song.mp3")
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }

    func testShortcutIcon() {
        if case .doc(var meta) = item.meta {
            meta.meta?.type = .shortcut
            meta.meta?.oriType = .bitable
            item.meta = .doc(meta)
        }
        item.renderData?.titleHighlighted = NSAttributedString(string: "song.mp3")
        tableView.item = item
        FBSnapshotVerifyView(tableView.cell)
    }
}
// swiftlint:enable all
