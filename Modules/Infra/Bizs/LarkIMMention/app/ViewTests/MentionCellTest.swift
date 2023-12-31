//
//  MentionCellTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/1/6.
//

import UIKit
import Foundation
import XCTest
import RustPB
@testable import LarkIMMention
// swiftlint:disable all
final class MentionCellTest: ViewTestCase {
    
    var cell: IMMentionItemCell!
    var item: IMPickerOption!

    override func setUp() {
        super.setUp()
        cell = IMMentionItemCell(frame: CGRect(x: 0, y: 0, width: 320, height: 70))
        item = IMPickerOption(id: UUID().uuidString)
        item.name = NSAttributedString(string: "name")
//        recordMode = true
    }
    
    /// cell
    func testCell() {
        item.subTitle = NSAttributedString(string: "subTitle")
        item.desc = NSAttributedString(string: "desc")
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 长名字, 长子标题
    func testLongNameLongSubtitle() {
        item.name = NSAttributedString(string: "名字名字namenamenamenamenamenamenamenamenamenamename")
        item.subTitle = NSAttributedString(string: "subTitlesubTitlesubTitlesubTitlesubTitlesubTitle")
        item.desc = NSAttributedString(string: "desc")
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 长标题, 短子标题, 短描述
    func testShortNameShortSubtitle() {
        item.name = NSAttributedString(string: "namenamenamenamenamenamenamenamenamenamenamename")
        item.subTitle = NSAttributedString(string: "subTitle")
        item.desc = NSAttributedString(string: "desc")
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 复用: 有子标题, 无子标题
    func testReuseSubtitle() {
        item.subTitle = NSAttributedString(string: "subTitle")
        item.desc = NSAttributedString(string: "desc")
        cell.node = MentionItemNode(item: item)
        item.subTitle = nil
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 复用: 有描述, 无描述
    func testReuseDesc() {
        item.subTitle = NSAttributedString(string: "subTitle")
        item.desc = NSAttributedString(string: "desc")
        cell.node = MentionItemNode(item: item)
        item.desc = nil
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 有focus状态
    func testMeeting() {
        item.subTitle = NSAttributedString(string: "subTitle")
        item.focusStatus = [Mocker.mockMeetingFocusStatus()]
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 复用: 有focus状态, 无focus状态
    func testReuseMeeting() {
        item.subTitle = NSAttributedString(string: "subTitle")
        item.focusStatus = [Mocker.mockMeetingFocusStatus()]
        cell.node = MentionItemNode(item: item)
        item.focusStatus = nil
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 有标签
    func testExternalTag() {
        var tagData = RustPB.Basic_V1_TagData()
        tagData.tagDataItems = [Mocker.mockExternalTag()]
        item.tagData = tagData
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 复用: 有标签, 无标签
    func testReuseExternalTag() {
        var tagData = RustPB.Basic_V1_TagData()
        tagData.tagDataItems = [Mocker.mockExternalTag()]
        item.tagData = tagData
        cell.node = MentionItemNode(item: item)
        item.tagData = nil
        cell.node = MentionItemNode(item: item)
        verify(cell)
    }
    
    /// 骨架样式
    func testSkeleton() {
        cell.node = MentionItemNode(item: item, isSkeleton: true)
        verify(cell)
    }
    
    /// 从骨架恢复到正常
    func testSkeletonToNormal() {
        cell.node = MentionItemNode(item: item, isSkeleton: true)
        cell.node = MentionItemNode(item: item, isSkeleton: false)
        verify(cell)
    }
    
    /// 多选样式
    func testMultiSelected() {
        cell.node = MentionItemNode(item: item, isMultiSelected: true)
        verify(cell)
    }
    
    /// 选中样式
    func testSelected() {
        item.isMultipleSelected = true
        cell.node = MentionItemNode(item: item, isMultiSelected: true)
        verify(cell)
    }
    
    /// 带删除按钮
    func testCellWithDeleteBtn() {
        cell.node = MentionItemNode(item: item)
        cell.setDeleteBtn()
        verify(cell)
    }
}
// swiftlint:enable all
