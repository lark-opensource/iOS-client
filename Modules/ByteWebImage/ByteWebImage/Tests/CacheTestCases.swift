//
//  CacheTestCases.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/7.
//

import XCTest
import RxSwift
@testable import ByteWebImage

class CacheTestCases: XCTestCase {

    let testImageKey = "TestImageKey.jpg"

    let diskCache = DefaultDiskCache(with: "com.disk_cache.default")

    lazy var testImage: UIImage? = {
        return UIImage(contentsOfFile: imagePath())
    }()

    func imagePath() -> String {
        let bundle = Bundle(for: CacheTestCases.self)
        return bundle.path(forResource: "TestImage", ofType: "jpg") ?? ""
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        ImageManager.default.defaultCache.diskCache.removeAll()
        ImageManager.default.defaultCache.memoryCache.removeAll()
        let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath()))
        diskCache.set(data, for: "TestImage") {

        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSet() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        ImageCache.shared.set(testImage, for: testImageKey)
        XCTAssertEqual(ImageCache.shared.image(for: testImageKey), testImage)
        ImageCache.shared.image(for: testImageKey, cacheOptions: .disk) { image, _ in
            XCTAssertNotNil(image)
        }
    }

    func testCleanDiskCache() {
        ImageCache.shared.set(testImage, for: testImageKey)
        ImageCache.shared.clearDisk {
            XCTAssertEqual(ImageCache.shared.image(for: self.testImageKey, cacheOptions: .memory), self.testImage)
            XCTAssertNil(ImageCache.shared.image(for: self.testImageKey, cacheOptions: .disk))
            XCTAssertEqual(ImageCache.shared.diskCache.totalSize, 0)
        }
    }

    func testRemoveExpired() {
        diskCache.removeExpiredData()
    }

    func testDefaultCacheRemove() {
        diskCache.removeAll { [weak self] in
            guard let `self` = self else {
                return
            }
            XCTAssert(self.diskCache.totalCount == 0)
            XCTAssert(self.diskCache.totalSize == 0)
        }
    }

    func tesetDefaultCacheRemoveItem() {
        diskCache.remove(for: "TestImage") {
            XCTAssert(self.diskCache.contains("TestImage"))
        }
    }

    func testDefaultCacheGet() {
        let data = diskCache.data(for: "TestImage")
        XCTAssertNotNil(data)
    }

    func testExistFile() {
        diskCache.remove(for: "TestImage")
        diskCache.setExistFile(for: "TestImage", with: imagePath())
        diskCache.contains("TestImage") { _, exist in
            XCTAssert(exist)

        }
    }

}
