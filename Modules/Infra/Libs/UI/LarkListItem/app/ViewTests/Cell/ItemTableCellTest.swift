//
//  ItemTableCellTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/6/2.
//

import XCTest
import LarkModel
@testable import LarkListItem
// swiftlint:disable all
final class ItemTableCellTest: ViewTestCase {
    var image: UIImage!
    var nodeTableView: NodeTestTableView!

    override func setUp() {
        super.setUp()
        image = UIImage(contentsOfFile: Bundle(for: self.classForCoder).path(forResource: "icon", ofType: "png")!)
        nodeTableView = NodeTestTableView(frame: CGRect(x: 0, y: 0, width: 375, height: 400))
        nodeTableView.setNeedsLayout()
        nodeTableView.layoutIfNeeded()
    }

    func testCellWithoutCheckbox() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                checkBoxState: .init(isShow: false),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                desc: NSAttributedString(string: "DescDescDescDescDesc"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testCellWithCheckbox() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                checkBoxState: .init(isShow: true),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                desc: NSAttributedString(string: "DescDescDescDescDesc"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testCellWithCheckboxDisable() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                checkBoxState: .init(isShow: true, isEnable: false),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                desc: NSAttributedString(string: "DescDescDescDescDesc"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testCellWithCheckboxSelected() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                checkBoxState: .init(isShow: true, isSelected: true, isEnable: true),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                desc: NSAttributedString(string: "DescDescDescDescDesc"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testCellWithCheckboxForceSelected() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                checkBoxState: .init(isShow: true, isSelected: true, isEnable: false),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                desc: NSAttributedString(string: "DescDescDescDescDesc"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testCellWithSummary() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                content: NSAttributedString(string: "Content"),
                                desc: NSAttributedString(string: "DescDescDescDescDesc"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testSubtitle() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                subtitle: NSAttributedString(string: "Subtitle"),
                                content: NSAttributedString(string: "Content"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testLongSubtitle() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                subtitle: NSAttributedString(string: "SubtitleSubtitleSubtitleSubtitleSubtitleSubtitle"),
                                desc: NSAttributedString(string: "DescDescDescDescDescDescDescDescDescDescDescDescDescDescDesc")
                                )
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testLongTitleAndLongSubtitle() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                checkBoxState: .init(isShow: false),
                                icon: .local(image),
                                title: NSAttributedString(string: "TitleTitleTitleTitleTitleTitleTitleTitleTitle"),
                                subtitle: NSAttributedString(string: "SubtitleSubtitleSubtitleSubtitleSubtitleSubtitle"),
                                desc: NSAttributedString(string: "DescDescDescDescDescDescDescDescDescDescDescDescDescDescDesc")
                                )
        nodeTableView.node = node
        verify(nodeTableView.cell)
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

    func testTargetPreviewWithLongSubtitle() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                subtitle: NSAttributedString(string: "SubtitleSubtitleSubtitleSubtitleSubtitleSubtitle"),
                                desc: NSAttributedString(string: "DescDescDescDescDescDescDescDescDescDescDescDescDescDescDesc"),
                                accessories: [.targetPreview])
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testTags() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "Title"),
                                subtitle: NSAttributedString(string: "Subtitle"),
                                tags: [.external],
                                content: NSAttributedString(string: "Content"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testTagsWithLongTitle() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "TitleTitleTitleTitleTitleTitleTitleTitleTitleTitle"),
                                tags: [.external],
                                content: NSAttributedString(string: "Content"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }

    func testTagsWithLongTitleAndLongSubtitle() {
        let node = ListItemNode(indexPath: IndexPath(row: 0, section: 0),
                                icon: .local(image),
                                title: NSAttributedString(string: "TitleTitleTitleTitleTitleTitleTitleTitleTitleTitle"),
                                subtitle: NSAttributedString(string: "SubtitleSubtitleSubtitleSubtitleSubtitleSubtitleSubtitle"),
                                tags: [.external],
                                content: NSAttributedString(string: "Content"))
        nodeTableView.node = node
        verify(nodeTableView.cell)
    }
}
// swiftlint:enable all
