//
//  LKTextParserTests.swift
//  LarkUIKitDemoTests
//
//  Created by qihongye on 2018/12/10.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import RichLabel

extension LKTextCharacterGroup: Equatable {
    public static func == (lhs: LKTextCharacterGroup, rhs: LKTextCharacterGroup) -> Bool {
        if lhs.originRange != rhs.originRange {
            return false
        }
        return NSDictionary(dictionary: lhs.attributes).isEqual(to: rhs.attributes)
    }
}

func == (_ l: [LKTextCharacterGroup], _ r: [LKTextCharacterGroup]) -> Bool {
    if l.count != r.count {
        return false
    }
    for i in 0..<l.count where l[i] != r[i] {
        return false
    }
    return true
}

class LKTextParserTests: XCTestCase {
//    var parser: LKTextParser

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
//        self.parser = LKTextParserImpl()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPointParser() {
        let parser = LKTextParserImpl()
        parser.characterParsers = [PointCharacterParser()]
        let attrStr = NSMutableAttributedString(string: "01⃣️23⃣️4🌕", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.red, range: NSRange(location: 1, length: 1))
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.red, range: NSRange(location: 8, length: 1))
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.red, range: NSRange(location: attrStr.length - 1, length: 1))
//        for _ in 0..<100 {
//            attrStr.append(attrStr.copy() as! NSAttributedString)
//        }

        let expectCharacters: [LKTextCharacterGroup] = [
            LKTextCharacterGroup(range: NSRange(location: 0, length: 1), attributes: [
                    .font: UIFont.systemFont(ofSize: 16)
            ]),
            LKTextCharacterGroup(range: NSRange(location: 1, length: 3), attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                LKPointAttributeName: UIColor.red
            ]),
            LKTextCharacterGroup(range: NSRange(location: 4, length: 4), attributes: [
                    .font: UIFont.systemFont(ofSize: 16)
            ]),
            LKTextCharacterGroup(range: NSRange(location: 8, length: 1), attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                LKPointAttributeName: UIColor.red
            ]),
            LKTextCharacterGroup(range: NSRange(location: 9, length: 2), attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                LKPointAttributeName: UIColor.red
            ])
        ]

        parser.originAttrString = attrStr
        parser.parse()

        XCTAssertEqual(parser.characterGroups, expectCharacters)
//        XCTAssertEqual(parser.findCharacterIndex(from: 1), 1)
//        XCTAssertEqual(parser.findCharacterIndex(from: 2), 1)
//        XCTAssertEqual(parser.findCharacterIndex(from: 3), 1)
//        XCTAssertEqual(parser.findCharacterIndex(from: 9), 5)
//        XCTAssertEqual(parser.findCharacterIndex(from: 10), 5)
    }

    func testParser() {

    }

    func testPerformPointParser() {
        let parser = LKTextParserImpl()
        parser.characterParsers = [PointCharacterParser()]
        let attrStr = NSMutableAttributedString(string: "01⃣️23⃣️4🌕", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.red, range: NSRange(location: 1, length: 1))
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.red, range: NSRange(location: 8, length: 1))
        attrStr.addAttribute(LKPointAttributeName, value: UIColor.red, range: NSRange(location: attrStr.length - 1, length: 1))
        let appendStr = attrStr.copy() as! NSAttributedString
        for _ in 0..<1000 {
            attrStr.append(appendStr.copy() as! NSAttributedString)
        }

        self.measure {
            parser.originAttrString = attrStr
            parser.parse()
        }
    }
}
