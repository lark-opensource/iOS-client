//
//  ItemTableCellAccessoryTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/10/19.
//

import XCTest
import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class ItemTableCellAccessoryTest: ViewTestCase {
    var image: UIImage!
    var nodeTableView: NodeTestTableView!

    override func setUp() {
        super.setUp()
        image = UIImage(contentsOfFile: Bundle(for: self.classForCoder).path(forResource: "icon", ofType: "png")!)
        nodeTableView = NodeTestTableView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        nodeTableView.setNeedsLayout()
        nodeTableView.layoutIfNeeded()
    }

    func testTargetPreview() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                desc: NSAttributedString(string: "DescDescDescDescDescDescDescDescDescDescDescDescDescDescDesc"),
                                accessories: [.targetPreview])
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testTargetPreviewAndDelete() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                desc: NSAttributedString(string: "DescDescDescDescDescDescDescDescDescDescDescDescDescDescDesc"),
                                accessories: [.targetPreview, .delete])
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

}
// swiftlint:enable all
