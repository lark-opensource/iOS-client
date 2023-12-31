//
//  Int64MemoryTests.swift
//  SKFoundation_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/5/4.
//

import XCTest
@testable import SKFoundation

class Int64MemoryTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testMemoryInB() {
        let size: Int64 = 101
        var result = size.memoryFormat
        XCTAssertTrue(result == "101.00B")
        result = size.memoryFormatWithoutFlow
        XCTAssertTrue(result == "101B")
    }
    
    func testMemoryInKB() {
        let size: Int64 = Int64(101.5 * 1024)
        var result = size.memoryFormat
        XCTAssertTrue(result == "101.50KB")
        result = size.memoryFormatWithoutFlow
        XCTAssertTrue(result == "101KB")
    }

    func testMemoryInMB() {
        let size: Int64 = Int64(101.5 * 1024 * 1024)
        var result = size.memoryFormat
        XCTAssertTrue(result == "101.50MB")
        result = size.memoryFormatWithoutFlow
        XCTAssertTrue(result == "101MB")
    }
    
    func testMemoryInGB() {
        let size: Int64 = Int64(101.5 * 1024 * 1024 * 1024)
        var result = size.memoryFormat
        XCTAssertTrue(result == "101.50GB")
        result = size.memoryFormatWithoutFlow
        XCTAssertTrue(result == "101GB")
    }
    
    func testMemoryInTB() {
        let size: Int64 = Int64(101.5 * 1024 * 1024 * 1024 * 1024)
        var result = size.memoryFormat
        XCTAssertTrue(result == "101.50TB")
        result = size.memoryFormatWithoutFlow
        XCTAssertTrue(result == "101TB")
    }
}
