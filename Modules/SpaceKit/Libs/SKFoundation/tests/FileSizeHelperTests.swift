//
//  FileSizeHelperTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/10.
//

import XCTest
@testable import SKFoundation

class FileSizeHelperTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testMemoryFormat() {
        var expect = "365.00B"
        var byte: UInt64 = 365
        var res = FileSizeHelper.memoryFormat(byte)
        XCTAssertEqual(res, expect)

        expect = "1.00KB"
        byte = 1024
        res = FileSizeHelper.memoryFormat(byte)
        XCTAssertEqual(res, expect)

        expect = "2.00MB"
        byte = 1024 * 1024 * 2
        res = FileSizeHelper.memoryFormat(byte)
        XCTAssertEqual(res, expect)

        expect = "2.00GB"
        byte = 1024 * 1024 * 1024 * 2
        res = FileSizeHelper.memoryFormat(byte)
        XCTAssertEqual(res, expect)

        expect = "2.00TB"
        byte = 1024 * 1024 * 1024 * 1024 * 2
        res = FileSizeHelper.memoryFormat(byte)
        XCTAssertEqual(res, expect)

        expect = "2.00PB"
        byte = 1024 * 1024 * 1024 * 1024 * 1024 * 2
        res = FileSizeHelper.memoryFormat(byte)
        XCTAssertEqual(res, expect)

        expect = "2.00EB"
        byte = 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 2
        res = FileSizeHelper.memoryFormat(byte)
        XCTAssertEqual(res, expect)
    }
}
