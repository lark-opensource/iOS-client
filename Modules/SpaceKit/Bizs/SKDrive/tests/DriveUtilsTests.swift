//
//  DriveUtilsTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/22.
//

import XCTest
@testable import SKDrive

class DriveUtilsTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // 通过mime返回后缀名
    func testFileExtensionFromMIMEType() {
        // TODO: zhuangyizhong fix it
        var result = DriveUtils.fileExtensionFromMIMEType("application/msword")
        print("testFileExtensionFromMIMEType application/msword result: \(result)")
//        XCTAssertTrue(result == "doc" || result == "dot")
        result = DriveUtils.fileExtensionFromMIMEType("image/png")
//        XCTAssertTrue(result == "png")
        
    }
    
    // ogg场景
    func testFileExtensionFromMIMEWithMap() {
        var result = DriveUtils.fileExtensionFromMIMEType("video/ogg")
        XCTAssertTrue(result == "ogg")
        result = DriveUtils.fileExtensionFromMIMEType("audio/ogg")
        XCTAssertTrue(result == "ogg")
    }

}
