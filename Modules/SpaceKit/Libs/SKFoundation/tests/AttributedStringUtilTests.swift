//
//  AttributedStringUtilTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/11.
//

import XCTest
@testable import SKFoundation

class AttributedStringUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testHeightOfAttrStr() {
        var attrStr = NSAttributedString(string: "hello")
        var height = AttributedStringUtil.heightOf(attrStr, byWidth: 50)
        XCTAssertTrue(height > 0)


        attrStr = NSAttributedString(string: "hello \n hello")
        height = AttributedStringUtil.heightOf(attrStr, byWidth: 50)
        XCTAssertTrue(height > 0)
    }
}
