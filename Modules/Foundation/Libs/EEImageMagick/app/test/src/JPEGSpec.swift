//
//  JPEGSpec.swift
//  EEImageMagickDevEEUnitTest
//
//  Created by qihongye on 2019/12/3.
//
// swiftlint:disable overridden_super_call
import Foundation
import XCTest

@testable import EEImageMagick

class JPEGSpec: XCTestCase {
    lazy var bundle: Bundle = {
        return Bundle(for: type(of: self))
    }()

    lazy var bundle_0: Bundle = {
        return Bundle(url: bundle.url(forResource: "0", withExtension: "bundle")!)!
    }()

    lazy var bundle_lena: Bundle = {
        return Bundle(url: bundle.url(forResource: "lena", withExtension: "bundle")!)!
    }()

    lazy var bundle_lena_android: Bundle = {
        return Bundle(url: bundle.url(forResource: "lena_android", withExtension: "bundle")!)!
    }()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsJPEG() {
        // png
        if true {
            let path = "0"
            let url = bundle.url(forResource: path, withExtension: "png")!
            let data = try? Data(contentsOf: url)
            XCTAssertFalse(isJPEG(data!), "png is not jpeg")
        }
        // bmp
        if true {
            let path = "lena"
            let url = bundle.url(forResource: path, withExtension: "bmp")!
            let data = try? Data(contentsOf: url)
            XCTAssertFalse(isJPEG(data!), "png is not jpeg")
        }

        // jpeg
        if true {
            var imageNames = ["quality_1.0"]
            for i in 0...9 {
                imageNames.append("quality_0.\(i)")
            }
            for imageName in imageNames {
                let url = bundle_0.url(forResource: imageName, withExtension: "jpg")!
                let data = try? Data(contentsOf: url)
                XCTAssert(isJPEG(data!), "jpg is jpeg")
            }
        }
        // jpeg
        if true {
            var imageNames = ["quality_1.0"]
            for i in 0...9 {
                imageNames.append("quality_0.\(i)")
            }
            for imageName in imageNames {
                let url = bundle_lena.url(forResource: imageName, withExtension: "jpg")!
                let data = try? Data(contentsOf: url)
                XCTAssert(isJPEG(data!), "jpg is jpeg")
            }
        }
        if true {
            var imageNames = ["quality_1.0"]
            for i in 0...9 {
                imageNames.append("quality_0.\(i)")
            }
            for imageName in imageNames {
                let url = bundle_lena_android.url(forResource: imageName, withExtension: "jpg")!
                let data = try? Data(contentsOf: url)
                XCTAssert(isJPEG(data!), "jpg is jpeg")
            }
        }
        if true {
            let data = Data([0, 0])
            XCTAssertFalse(isJPEG(data), "data length < 3 is not jpeg")
        }
    }

    func testPerformanceTestIsJPEG_PNG() {
        let path = "0"
        let url = bundle.url(forResource: path, withExtension: "png")!
        let data = try? Data(contentsOf: url)
        self.measure {
            XCTAssertFalse(isJPEG(data!), "png is not jpeg")
        }
    }

    func testPerformanceTestIsJPEG_JPEG9() {
        let url = bundle_lena.url(forResource: "quality_0.9", withExtension: "jpg")!
        let data = try? Data(contentsOf: url)
        self.measure {
            XCTAssert(isJPEG(data!), "jpg is jpeg")
        }
    }

    func testPerformanceTestIsJPEG_JPEG1() {
        let url = bundle_0.url(forResource: "quality_0.1", withExtension: "jpg")!
        let data = try? Data(contentsOf: url)
        self.measure {
            XCTAssert(isJPEG(data!), "jpg is jpeg")
        }
    }
}
