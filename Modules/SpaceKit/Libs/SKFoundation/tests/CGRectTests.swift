//
//  CGRectTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/11.
//

import XCTest

class CGRectTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testShift() {
        let rect = CGRect(x: 0, y: 0, width: 0, height: 0)
        let res = rect.shift(top: -3, left: -4, bottom: 5, right: -2)
        XCTAssertEqual(res.left, -4)
        XCTAssertEqual(res.top, -3)
        XCTAssertEqual(res.width, 2)
        XCTAssertEqual(res.height, 8)
    }

    func testExpandEvenly() {
        let rect = CGRect(x: 0, y: 0, width: 0, height: 0)
        let res = rect.expandEvenly(by: 4)
        XCTAssertEqual(res.left, -4)
        XCTAssertEqual(res.top, -4)
        XCTAssertEqual(res.width, 8)
        XCTAssertEqual(res.height, 8)
    }
}
