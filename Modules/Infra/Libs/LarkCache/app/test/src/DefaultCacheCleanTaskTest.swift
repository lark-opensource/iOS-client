//
//  DefaultCacheCleanTaskTest.swift
//  LarkCacheDevEEUnitTest
//
//  Created by Supeng on 2020/8/17.
//

import Foundation
import XCTest
@testable import LarkCache

class DefaultCacheCleanTaskTest: XCTestCase {

    func testDefaultCacheCleanTask() throws {

        let cache = CacheManager.shared.cache(relativePath: "DefaultCacheCleanTask", directory: .cache)
        let data1 = "123".data(using: .utf8)!
        let data2 = "1234567890".data(using: .utf8)!
        cache.set(object: "123".data(using: .utf8)!, forKey: "key1")
        cache.set(object: "1234567890".data(using: .utf8)!, forKey: "key2")

        DefaultCacheCleanTask().clean(config: generateCleanConfig()) { result in
            XCTAssertTrue(result.completed)
            XCTAssertTrue(result.costTime > 0)
            XCTAssertFalse(result.sizes.isEmpty)
            if case let .bytes(bytes) = result.sizes.first! {
                XCTAssertTrue(bytes >= (data1.count + data2.count))
            }
        }

        XCTAssertFalse(cache.yyCache!.diskCache.containsObject(forKey: "key1"))
        XCTAssertFalse(cache.yyCache!.diskCache.containsObject(forKey: "key2"))
    }

    func testDefaultCacheCleanTaskWithCustomCleanIdentifier() throws {

        let cache = CacheManager.shared.cache(relativePath: "DefaultCacheCleanTask1",
                                              directory: .cache,
                                              cleanIdentifier: "DefaultCacheCleanTaskIdentifier")
        cache.set(object: "123".data(using: .utf8)!, forKey: "key1")
        cache.set(object: "1234567890".data(using: .utf8)!, forKey: "key2")

        DefaultCacheCleanTask().clean(config: generateCleanConfig()) { _ in }

        XCTAssertFalse(cache.yyCache!.diskCache.containsObject(forKey: "key1"))
        XCTAssertFalse(cache.yyCache!.diskCache.containsObject(forKey: "key2"))
    }

    func testCleanTmpFolder() throws {
        let tmpFolder = NSTemporaryDirectory()

        try "123".write(toFile: tmpFolder + "/" + "temp.txt", atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpFolder + "/" + "temp.txt"))

        let appleDyld = "com.apple.dyld"
        let tmpDyldPath = tmpFolder + "/" + appleDyld
        let documentPath = CacheDirectory.document.path
        let documentDyldPath = documentPath + "/" + appleDyld
        XCTAssertFalse(FileManager.default.fileExists(atPath: documentDyldPath))

        try FileManager.default
            .createDirectory(atPath: tmpDyldPath,
                             withIntermediateDirectories: true,
                             attributes: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDyldPath))

        try "temp".write(toFile: tmpDyldPath + "/" + "temp.txt", atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDyldPath + "/" + "temp.txt"))

        DefaultCacheCleanTask().cleanTemporaryDirectory()

        XCTAssertFalse(FileManager.default.fileExists(atPath: documentDyldPath))
        //普通文件不存在
        XCTAssertFalse(FileManager.default.fileExists(atPath: tmpFolder + "/" + "temp.txt"))
        //tmp文件夹下dyld文件依旧存在
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDyldPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDyldPath + "/" + "temp.txt"))
    }
}

func generateCleanConfig() -> CleanConfig {
    let allCaches = DefaultCacheCleanTask.allCaches()
    var configs = [String: CleanConfig.CacheConfig]()
    allCaches.forEach { (cache) in
        configs[cache.cleanIdentifier] = CleanConfig.CacheConfig(timeLimit: 0, sizeLimit: 0)
    }
    return CleanConfig(cacheConfig: configs)
}
