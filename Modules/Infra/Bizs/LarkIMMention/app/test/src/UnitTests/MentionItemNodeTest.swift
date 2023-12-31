//
//  MentionItemNodeTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/1/5.
//

import UIKit
import Foundation
import XCTest
@testable import LarkIMMention
// swiftlint:disable all
final class MentionItemNodeTest: XCTestCase {
    
    var itemId: String!
    var avatarId: String!
    var avatarKey: String!
    
    override func setUp() {
        itemId = UUID().uuidString
        avatarId = UUID().uuidString
        avatarKey = UUID().uuidString
    }

    /// node 转换
    func testNodeBaseInfo() {
        var item = IMPickerOption(id: itemId)
        item.name = NSAttributedString(string: "name")
        item.subTitle = NSAttributedString(string: "subTitle")
        item.desc = NSAttributedString(string: "desc")
        let node = MentionItemNode(item: item)
        XCTAssertEqual(node.name?.string, "name")
        XCTAssertEqual(node.subTitle?.string, "subTitle")
        XCTAssertEqual(node.desc?.string, "desc")
    }
    
    /// 多选和骨架的属性转换
    func testSkeletonAndMultiSelect() {
        let node = MentionItemNode(item: IMPickerOption(), isMultiSelected: true, isSkeleton: true)
        XCTAssertTrue(node.isSkeleton)
        XCTAssertTrue(node.isMultiSelected)
    }
    
    /// 所有人的头像
    func testAllNodeAvatar() {
        var item = IMPickerOption(id: IMPickerOption.allId)
        item.avatarID = avatarId
        item.avatarKey = avatarKey
        let node = MentionItemNode(item: item)
        guard case .local(let image) = node.avatar else {
            XCTFail()
            return
        }
        XCTAssertNotNil(image)
    }
    
    /// Wiki头像
    func testWikiAvatar() {
        var item = IMPickerOption(id: itemId)
        item.avatarID = avatarId
        item.avatarKey = avatarKey
        item.meta = IMMentionMeta.wiki(.init(image: UIImage(), url: "", type: .wiki))
        let node = MentionItemNode(item: item)
        guard case .local(let image) = node.avatar else {
            XCTFail()
            return
        }
        XCTAssertNotNil(image)
    }
    
    /// 文档头像
    func testDocAvatar() {
        var item = IMPickerOption(id: itemId)
        item.avatarID = avatarId
        item.avatarKey = avatarKey
        item.meta = IMMentionMeta.wiki(.init(image: UIImage(), url: "", type: .doc))
        let node = MentionItemNode(item: item)
        guard case .local(let image) = node.avatar else {
            XCTFail()
            return
        }
        XCTAssertNotNil(image)
    }
    
    /// 远程item头像
    func testRemoteAvatar() {
        var item = IMPickerOption(id: itemId)
        item.avatarID = avatarId
        item.avatarKey = avatarKey
        let node = MentionItemNode(item: item)
        guard case .remote(let id, let key) = node.avatar else {
            XCTFail()
            return
        }
        XCTAssertEqual(id, avatarId)
        XCTAssertEqual(key, avatarKey)
    }
}
// swiftlint:enable all
