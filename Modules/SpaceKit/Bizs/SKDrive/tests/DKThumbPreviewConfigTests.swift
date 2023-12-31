//
//  DKThumbPreviewConfigTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/8/15.
//

import XCTest
import SKCommon
@testable import SKDrive

class DKThumbPreviewConfigTests: XCTestCase {
    let json = """
    {
        "typesConfig": {
            "PNG": 52428800,
            "JPEG": 52428800
        },
        "supportAppID": ["2", "19", "26", "44", "45", "56"],
        "minSize": 1048576
    }
    """.data(using: .utf8)!
    let invalidJson =  """
    {
    }
    """.data(using: .utf8)!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDecodeInvalidJson() {
        do {
            let sut = try JSONDecoder().decode(ThumbnailPreviewConfig.self, from: invalidJson)
            XCTAssertNil(sut.typesConfig["PNG"])
            XCTAssertFalse(sut.suppotedApps.contains("2"))
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func testMaxSizeForType() {
        do {
            let sut = try JSONDecoder().decode(ThumbnailPreviewConfig.self, from: json)
            XCTAssertTrue(sut.typesConfig["PNG"] == 50 * 1024 * 1024)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testCheckIfSupported() {
        do {
            let sut = try JSONDecoder().decode(ThumbnailPreviewConfig.self, from: json)
            XCTAssertTrue(sut.suppotedApps.contains("2"))
            XCTAssertFalse(sut.suppotedApps.contains("1001"))
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testGetMinSize() {
        do {
            let sut = try JSONDecoder().decode(ThumbnailPreviewConfig.self, from: json)
            XCTAssertTrue(sut.minSize == 1024 * 1024)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
