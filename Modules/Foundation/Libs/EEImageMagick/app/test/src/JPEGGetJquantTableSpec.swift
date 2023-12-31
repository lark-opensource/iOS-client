//
//  JPEGGetJquantTableSpec.swift
//  EEImageMagickDevEEUnitTest
//
//  Created by qihongye on 2019/12/10.
//
// swiftlint:disable overridden_super_call
import Foundation
import XCTest

@testable import EEImageMagick

class JPEGGetJquantTableSpec: XCTestCase {
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

    func testQuality() {
        if true {
            let imageInfos = [("quality_1.0", 100), ("quality_0.9", 96), ("quality_0.8", 94), ("quality_0.7", 91), ("quality_0.6", 86), ("quality_0.5", 78), ("quality_0.4", 64), ("quality_0.3", -1), ("quality_0.2", -1), ("quality_0.1", -1), ("quality_0.0", -1)]
            for image in imageInfos {
                let url = bundle_0.url(forResource: image.0, withExtension: "jpg")!
                let data = try? Data(contentsOf: url)
                XCTAssertNotNil(data)
                XCTAssert(getJPEGQuality(data!) == image.1)
            }
        }
        if true {
            let imageInfos = [("quality_1.0", 100), ("quality_0.9", 96), ("quality_0.8", 94), ("quality_0.7", 91), ("quality_0.6", 86), ("quality_0.5", 78), ("quality_0.4", 64), ("quality_0.3", -1), ("quality_0.2", -1), ("quality_0.1", -1), ("quality_0.0", -1)]
            for image in imageInfos {
                let url = bundle_lena.url(forResource: image.0, withExtension: "jpg")!
                let data = try? Data(contentsOf: url)
                XCTAssertNotNil(data)
                XCTAssert(getJPEGQuality(data!) == image.1)
            }
        }
        if true {
            let imageInfos = [("quality_1.0", 100), ("quality_0.9", 90), ("quality_0.8", 80), ("quality_0.7", 70), ("quality_0.6", 60), ("quality_0.5", 50), ("quality_0.4", 40), ("quality_0.3", 30), ("quality_0.2", 20), ("quality_0.0", 1)]
            for image in imageInfos {
                let url = bundle_lena_android.url(forResource: image.0, withExtension: "jpg")!
                let data = try? Data(contentsOf: url)
                XCTAssertNotNil(data)
                XCTAssert(getJPEGQuality(data!) == image.1)
            }
        }
    }

    func testGetQualityByPath() {
        if true {
            let path = "AndroidOOM"
            let url = bundle.url(forResource: path, withExtension: "png")!
            XCTAssert(getJPEGQuality(path: url.absoluteString.replacingOccurrences(of: "file://", with: "")) == -1)
        }
        if true {
            let imageInfos = [("quality_1.0", 100), ("quality_0.9", 96), ("quality_0.8", 94), ("quality_0.7", 91), ("quality_0.6", 86), ("quality_0.5", 78), ("quality_0.4", 64), ("quality_0.3", -1), ("quality_0.2", -1), ("quality_0.1", -1), ("quality_0.0", -1)]
            for image in imageInfos {
                let url = bundle_0.url(forResource: image.0, withExtension: "jpg")!
                XCTAssert(getJPEGQuality(path: url.absoluteString.replacingOccurrences(of: "file://", with: "")) == image.1)
            }
        }
        if true {
            let imageInfos = [("quality_1.0", 100), ("quality_0.9", 96), ("quality_0.8", 94), ("quality_0.7", 91), ("quality_0.6", 86), ("quality_0.5", 78), ("quality_0.4", 64), ("quality_0.3", -1), ("quality_0.2", -1), ("quality_0.1", -1), ("quality_0.0", -1)]
            for image in imageInfos {
                let url = bundle_lena.url(forResource: image.0, withExtension: "jpg")!
                XCTAssert(getJPEGQuality(path: url.absoluteString.replacingOccurrences(of: "file://", with: "")) == image.1)
            }
        }
        if true {
            let imageInfos = [("quality_1.0", 100), ("quality_0.9", 90), ("quality_0.8", 80), ("quality_0.7", 70), ("quality_0.6", 60), ("quality_0.5", 50), ("quality_0.4", 40), ("quality_0.3", 30), ("quality_0.2", 20), ("quality_0.0", 1)]
            for image in imageInfos {
                let url = bundle_lena_android.url(forResource: image.0, withExtension: "jpg")!
                XCTAssert(getJPEGQuality(path: url.absoluteString.replacingOccurrences(of: "file://", with: "")) == image.1)
            }
        }
    }

    func testQuality_badcase() {
        if true {
            let url = bundle_lena_android.url(forResource: "quality_0.1", withExtension: "jpg")!
            let data = try? Data(contentsOf: url)
            XCTAssertNotNil(data)
            XCTAssert(getJPEGQuality(data!) == -1)
        }
        if true {
            let data = Data([0xff, 0xdb, 0xff])
            XCTAssertNil(getJPEGQuality(data), "data length < 5 is cannot get quality.")
        }
    }

    func testPerformanceQuality_0() {
        let imageInfos = [("quality_1.0", 100), ("quality_0.9", 96), ("quality_0.8", 94), ("quality_0.7", 91), ("quality_0.6", 86), ("quality_0.5", 78), ("quality_0.4", 64), ("quality_0.3", -1), ("quality_0.2", -1), ("quality_0.1", -1), ("quality_0.0", -1)]
        let datas = imageInfos.map { (info) -> Data in
            let url = bundle_0.url(forResource: info.0, withExtension: "jpg")!
            let data = try? Data(contentsOf: url)
            return data!
        }

        self.measure {
            for data in datas {
                _ = getJPEGQuality(data)
            }
        }
    }

    func testPerformanceQuality_lena() {
        let imageInfos = [("quality_1.0", 100), ("quality_0.9", 96), ("quality_0.8", 94), ("quality_0.7", 91), ("quality_0.6", 86), ("quality_0.5", 78), ("quality_0.4", 64), ("quality_0.3", -1), ("quality_0.2", -1), ("quality_0.1", -1), ("quality_0.0", -1)]
        let datas = imageInfos.map { (info) -> Data in
            let url = bundle_lena.url(forResource: info.0, withExtension: "jpg")!
            let data = try? Data(contentsOf: url)
            return data!
        }

        self.measure {
            for data in datas {
                _ = getJPEGQuality(data)
            }
        }
    }
}
