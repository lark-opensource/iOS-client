//
//  NSAttributedString+LarkFoundationTest.swift
//  LarkExtensionsDevEEUnitTest
//
//  Created by JackZhao on 2020/8/19.
//

import UIKit
import Foundation
import XCTest

class NSAttributedString_LarkFoundationTest: XCTestCase {
    func testNormal() {
        let attr = NSAttributedString(string: "一行dwd")
        let result = attr.lf.safeAttributedSubstring(from: NSRange(location: 0, length: 3))
        XCTAssert(result.string == "一行d")
    }

    func testUpperIsCutEmoji() {
        let attr = NSAttributedString(string: "一行😳")
        let result = attr.lf.safeAttributedSubstring(from: NSRange(location: 0, length: 3))
        XCTAssert(result.string == "一行")
    }

    func testLocationIsCutEmoji() {
        let attr = NSAttributedString(string: "一行😳😳😳😳")
        let result = attr.lf.safeAttributedSubstring(from: NSRange(location: 3, length: 2))
        XCTAssert(result.string == "😳")
    }

    func testUpperAndLocationAreCutEmoji() {
        let attr = NSAttributedString(string: "一行😳😳😳😳")
        let result = attr.lf.safeAttributedSubstring(from: NSRange(location: 3, length: 4))
        XCTAssert(result.string == "😳😳")
    }
}
