//
//  DriveImageDownsampleUtilsTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/4/22.
//

import XCTest
@testable import SKDrive
@testable import SKFoundation

class DriveImageDownsampleUtilsTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNeedTileImage() {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "support", withExtension: "heic") else {
            XCTFail()
            return
        }

        let filePath = SKFilePath(absUrl: url)
        let result = DriveImageDownsampleUtils.needTileImage(imagePath: filePath)
        XCTAssertFalse(result)
    }
    
    func testNeedTileDownshample() {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "support", withExtension: "heic") else {
            XCTFail()
            return
        }

        let filePath = SKFilePath(absUrl: url)
        let result = DriveImageDownsampleUtils.needDownsample(imagePath: filePath)
        XCTAssertFalse(result)
    }
    
    func testDefaultImageMaxSize() {
        let result = DriveImageDownsampleUtils.defaultImageMaxSize(for: CGSize(width: 10, height: 5), scale: 3.0)
        XCTAssertEqual(30, result, accuracy: 0.1)
    }

    func testImageSizeOverLimited() {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "support", withExtension: "heic") else {
            XCTFail()
            return
        }
        
        let filePath = SKFilePath(absUrl: url)
        let result = DriveImageDownsampleUtils.imageSizeOverLimited(imagePath: filePath)
        XCTAssertFalse(result)
    }
}
