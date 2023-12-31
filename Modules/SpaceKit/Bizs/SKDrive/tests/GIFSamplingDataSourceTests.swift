//
//  GIFSamplingDataSourceTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/7/1.
//

import XCTest
import ImageIO
import CoreServices
import SKUIKit
@testable import SKDrive

class GIFSamplingDataSourceTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testParseDamageGif() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "damageGIF", withExtension: "gif")
        guard let data = try? Data(contentsOf: url!) else {
            XCTFail("data not found")
            return
        }
        
        // 测试 shouldCache 作用
        let options: [String: Any] = [kCGImageSourceShouldCache as String: true,
                                      kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            XCTFail("imagesource not found")
            return
        }
        let sut = GIFSamplingDataSource(imageSource: imageSource, maxSize: 1000000)
        sut.start()
        sut.renderFrame = { (result: Result<UIImage, Error>) -> Void in
            if case let Result.failure(error) = result {
                guard let error = error as? GIFParseError else {
                    XCTFail("expect gif parse error")
                    return
                }
                XCTAssertTrue(error == GIFParseError.noImages)
            } else {
                XCTFail("expect to render failed")
            }
        }
    }
}
