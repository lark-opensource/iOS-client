//
//  LarkImageServiceTestCases.swift
//  ByteWebImage-Unit-Tests
//
//  Created by xiongmin on 2021/10/28.
//

import XCTest
import ByteWebImage

class LarkImageServiceTestCases: XCTestCase {

    override class func setUp() {
        super.setUp()
        ImageManager.default.forceDecode = true
        LarkImageService.shared.originCache.diskCache.removeAll()
    }

    func imagePath(key: String) -> String {
        let bundle = Bundle(for: CacheTestCases.self)
        let component = key.split(separator: ".")
        let name = component.first
        let type = component.last
        return bundle.path(forResource: String(name ?? ""), ofType: String(type ?? "")) ?? ""
    }

    func testCacheImage() {
        let key = "TestImage.jpg"
        let path = imagePath(key: key)
        let image = UIImage(contentsOfFile: path)
        let resource = LarkImageResource.default(key: key)
        LarkImageService.shared.cacheImage(image: image!, resource: resource, cacheOptions: .all) { _, _ in
            XCTAssert(LarkImageService.shared.isCached(resource: resource, options: .all))
        }
    }

    func testRemoveCacheImage() {
        let key = "TestImage.jpg"
        let path = imagePath(key: key)
        let image = UIImage(contentsOfFile: path)
        let resource = LarkImageResource.default(key: key)
        LarkImageService.shared.cacheImage(image: image!, resource: resource, cacheOptions: .all)
        LarkImageService.shared.removeCache(resource: resource, options: .all)
        XCTAssert(!LarkImageService.shared.isCached(resource: resource, options: .all))
    }

    func testGetCachedImage() {
        let key = "TestImage.jpg"
        let path = imagePath(key: key)
        let image = UIImage(contentsOfFile: path)
        let resource = LarkImageResource.default(key: key)
        LarkImageService.shared.cacheImage(image: image!, resource: resource, cacheOptions: .all)
        let cacheImage = LarkImageService.shared.image(with: resource, cacheOptions: .all)
        XCTAssertEqual(image, cacheImage)
        LarkImageService.shared.image(with: resource,
                                      cacheOptions: .all) { image, _ in
            XCTAssertNotNil(image)
        }
    }

    func testRemoVeExpire() {
        LarkImageService.shared.originCache.diskCache.removeExpiredData()
    }

}
