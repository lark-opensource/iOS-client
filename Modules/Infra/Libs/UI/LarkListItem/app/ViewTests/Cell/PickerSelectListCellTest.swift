//
//  PickerSelectListCellTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/10/20.
//

import XCTest
import LarkModel
@testable import LarkListItem

// swiftlint:disable all
final class PickerSelectListCellTest: ViewTestCase {
    var meta: PickerChatterMeta!
    var item: PickerItem!
    var cell: PickerSelectListCell!
    var transformer: PickerSelectedItemTransformer!

    override func setUp() {
        super.setUp()
        meta = ChatterMetaMocker.mockChatter()
        item = PickerItemMocker.mockChatter(meta: meta)
        cell = PickerSelectListCell()
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: 64)
        cell.backgroundColor = .white
        transformer = PickerSelectedItemTransformer(accessoryTransformer: .init(isOpen: true))
    }

    func testChatter() {
        cell.node = transformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
        verify(cell)
    }
}
// swiftlint:enable all
