//
//  Cache2Tests.swift
//  LarkCacheDevEEUnitTest
//
//  Created by zhangwei on 2022/11/24.
//

import Foundation
import XCTest
@testable import LarkCache
import LarkStorage

/// 和 CacheTests.swift 一致，只是基于 .iso 接口
final class Cache2Tests: XCTestCase {

    var rootPath: IsoPath!
    var cache: Cache!
    override func setUp() {
        super.setUp()
        let domain = Domain.biz.core.child("Cache2Tests_\(UUID().uuidString.prefix(5))")
        rootPath = IsoPath.global.in(domain: domain).build(.cache)
        cache = CacheManager.shared.cache(rootPath: rootPath, cleanIdentifier: "Cache2Tests")
    }

    override func tearDown() {
        rootPath = nil
        cache = nil
        super.tearDown()
    }

    func testData() {
        let value = "value".data(using: .utf8)!
        let key = "key"
        cache.iso.setObject(value as NSData, forKey: key)

        XCTAssertTrue(cache.containsObject(forKey: key))
        var result: Data? = cache.object(forKey: key)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, value)

        cache.removeObject(forKey: key)
        result = cache.object(forKey: key)
        XCTAssertNil(result)
    }

    func testNSCoding() {
        let value = NSNumber(value: 123)
        let key = "key"

        cache.iso.setObject(value, forKey: key)

        XCTAssertTrue(cache.containsObject(forKey: key))
        var result: NSCoding? = cache.object(forKey: key)
        XCTAssertNotNil(result)
        XCTAssertTrue(result! is NSNumber)
        XCTAssertEqual((result as? NSNumber)!, value)

        cache.removeObject(forKey: key)
        result = cache.object(forKey: key)
        XCTAssertNil(result)
    }

    func testFile() throws {
        let fileName = "test.txt"

        let filePath = rootPath + fileName
        try "value".write(to: filePath, atomically: true, encoding: .utf8)

        XCTAssertTrue(filePath.exists)
        XCTAssertFalse(cache.containsFile(forKey: fileName))

        cache.saveFileName(fileName)
        XCTAssertTrue(cache.containsFile(forKey: fileName))

        cache.removeFile(forKey: fileName)
        XCTAssertFalse(cache.containsFile(forKey: fileName))
        XCTAssertFalse(filePath.exists)
    }

    // MARK: Clean Test
    func testDataTrimToCost() {
        XCTAssertNotNil(cache.yyCache)
        let yycache = cache.yyCache!
        let diskCache = yycache.diskCache

        let data1 = "123".data(using: .utf8)!
        let data2 = "1234567890".data(using: .utf8)!

        // 测试cleanDiskCache传入0，可以全清
        cache.iso.setObject(data1 as NSData, forKey: "key1")
        cache.iso.setObject(data2 as NSData, forKey: "key2")

        cache.cleanDiskCache(toCost: 0)

        XCTAssertFalse(diskCache.containsObject(forKey: "key1"))
        XCTAssertFalse(diskCache.containsObject(forKey: "key2"))

        // 测试清理到data2.count的时候，只会清理data1
        cache.iso.setObject(data1 as NSData, forKey: "key1")
        cache.iso.setObject(data2 as NSData, forKey: "key2")
        cache.cleanDiskCache(toCost: data2.count)

        XCTAssertFalse(diskCache.containsObject(forKey: "key1"))
        XCTAssertTrue(diskCache.containsObject(forKey: "key2"))

        // 测试清理到data2.count - 1的时候，全部会清理
        cache.iso.setObject(data1 as NSData, forKey: "key1")
        cache.iso.setObject(data2 as NSData, forKey: "key2")
        cache.cleanDiskCache(toCost: data2.count - 1)
        XCTAssertFalse(diskCache.containsObject(forKey: "key1"))
        XCTAssertFalse(diskCache.containsObject(forKey: "key2"))
    }

    func testDataTrimToTime() {
        XCTAssertNotNil(cache.yyCache)
        let yycache = cache.yyCache!
        let diskCache = yycache.diskCache

        let data1 = "123".data(using: .utf8)!
        let data2 = "1234567890".data(using: .utf8)!

        cache.iso.setObject(data1 as NSData, forKey: "key1")
        sleep(2)
        cache.iso.setObject(data2 as NSData, forKey: "key2")
        cache.cleanDiskCache(toAge: TimeInterval(1))
        XCTAssertFalse(diskCache.containsObject(forKey: "key1"))
        XCTAssertTrue(diskCache.containsObject(forKey: "key2"))
    }

    func testFileTrimToCost() throws {
        XCTAssertNotNil(cache.yyCache)

        let fileName1 = "test1.txt"
        let filePath1 = rootPath + "/" + fileName1
        try "123".write(to: filePath1, atomically: true, encoding: .utf8)

        let fileName2 = "test2.txt"
        let filePath2 = rootPath + "/" + fileName2
        try "1234567890".write(to: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)

        XCTAssertTrue(filePath1.exists)
        XCTAssertTrue(filePath2.exists)

        // 测试cleanDiskCache传入0，可以全清
        cache.cleanDiskCache(toCost: 1)

        XCTAssertFalse(cache.containsObject(forKey: fileName1))
        XCTAssertFalse(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(filePath1.exists)
        XCTAssertFalse(filePath2.exists)

        // 测试清理到data2.count的时候，只会清理data1
        try "123".write(to: filePath1, atomically: true, encoding: .utf8)
        try "1234567890".write(to: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)
        cache.cleanDiskCache(toCost: "1234567890".count)

        XCTAssertFalse(cache.containsObject(forKey: fileName1))
        XCTAssertTrue(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(filePath1.exists)
        XCTAssertTrue(filePath2.exists)

        // 测试清理到data2.count - 1的时候，全部会清理
        try "123".write(to: filePath1, atomically: true, encoding: .utf8)
        try "1234567890".write(to: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)
        cache.cleanDiskCache(toCost: "1234567890".count - 1)

        XCTAssertFalse(cache.containsObject(forKey: fileName1))
        XCTAssertFalse(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(filePath1.exists)
        XCTAssertFalse(filePath2.exists)
    }

    func testFileTrimToTime() throws {
        XCTAssertNotNil(cache.yyCache)

        let fileName1 = "test1.txt"
        let filePath1 = rootPath + fileName1
        try "123".write(to: filePath1, atomically: true, encoding: .utf8)

        let fileName2 = "test2.txt"
        let filePath2 = rootPath + fileName2
        try "1234567890".write(to: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)
        sleep(2)
        // 读取fileName1,会更新fileName1的最后访问时间
        _ = cache.filePath(forKey: fileName1)
        // 清理最近1s内没有访问的数据，应该清理fileName2
        cache.cleanDiskCache(toAge: TimeInterval(1))
        XCTAssertTrue(cache.containsObject(forKey: fileName1))
        XCTAssertTrue(filePath1.exists)
        XCTAssertFalse(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(filePath2.exists)
    }

    func testRemoveAll() throws {
        XCTAssertNotNil(cache.yyCache)

        let data1 = "123".data(using: .utf8)!
        cache.iso.setObject(data1 as NSData, forKey: "key1")

        let fileName1 = "test1.txt"
        let filePath1 = rootPath + fileName1
        try "123".write(to: filePath1, atomically: true, encoding: .utf8)
        cache.saveFileName(fileName1)

        XCTAssertTrue(cache.containsObject(forKey: fileName1))
        XCTAssertTrue(cache.containsFile(forKey: fileName1))

        let dir = "intermediateDir"
        let fileName2 = dir + "/" + "test1.txt"
        let filePath2 = rootPath + fileName2
        try? (rootPath + dir).createDirectoryIfNeeded()
        try "123".write(to: filePath2, atomically: true, encoding: .utf8)
        cache.saveFileName(fileName2)

        XCTAssertTrue(cache.containsObject(forKey: fileName2))
        XCTAssertTrue(cache.containsFile(forKey: fileName2))

        cache.removeAllObjects()

        XCTAssertFalse(cache.containsObject(forKey: "key1"))
        XCTAssertFalse(cache.containsFile(forKey: fileName1))
        XCTAssertFalse(filePath1.exists)
        XCTAssertFalse(cache.containsFile(forKey: fileName2))
        XCTAssertFalse(filePath2.exists)
    }

    /// 给Data关联extendedData
    func testDataExtendedData() {
        let data = "data".data(using: .utf8)!
        let extendedData = "extendedData".data(using: .utf8)!
        cache.iso.setObject(data as NSData, forKey: "testExtendedData", extendedData: extendedData)

        // 测试内存缓存extendData工作正常
        let result = cache.objectAndEntendedData(forKey: "testExtendedData")
        XCTAssertNotNil(result)
        XCTAssertNotNil(result!.1)

        XCTAssertEqual(String(bytes: result!.1!, encoding: .utf8), "extendedData")

        // 测试磁盘缓存extendData工作正常
        cache.yyCache?.memoryCache.removeAllObjects()
        let result1 = cache.objectAndEntendedData(forKey: "testExtendedData")
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result1!.1)

        XCTAssertEqual(String(bytes: result1!.1!, encoding: .utf8), "extendedData")
    }

    /// 给NSCoding关联extendedData
    func testNSCodingExtendedData() {
        let data: NSCoding = ("data".data(using: .utf8)! as NSData)
        let extendedData = "extendedData".data(using: .utf8)!
        cache.iso.setObject(data, forKey: "testExtendedData", extendedData: extendedData)

        // 测试以Data方式读取数据，可以获取到extendedData
        let result = cache.objectAndEntendedData(forKey: "testExtendedData")
        XCTAssertNotNil(result)
        XCTAssertNotNil(result!.1)

        XCTAssertEqual(String(bytes: result!.1!, encoding: .utf8), "extendedData")

        // 测试以NSCoding方式读取数据，可以获取到extendedData
        let result1 = cache.objectAndEntendedData(forKey: "testExtendedData")
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result1!.1)

        XCTAssertEqual(String(bytes: result1!.1!, encoding: .utf8), "extendedData")
    }

    func testFileExtendedData() throws {
        let fileName = "extendedData.txt"
        let extendedData = "extendedData".data(using: .utf8)!
        let filePath = cache.iso.filePath(forKey: fileName)
        try "123".write(to: filePath, atomically: true, encoding: .utf8)

        XCTAssertTrue(filePath.exists)
        cache.iso.saveFile(forKey: fileName, fileName: fileName, extendedData: extendedData)

        let result = cache.iso.filePathAndExtendedData(forKey: fileName)
        XCTAssertNotNil(result)
        XCTAssertNotNil(result!.1)
        XCTAssertEqual(String(bytes: result!.1!, encoding: .utf8), "extendedData")

        cache.removeFile(forKey: fileName)
        XCTAssertFalse(filePath.exists)
    }

    func testFileWithCustomFileKey() throws {
        let fileKey = "CustomFileKey"
        let fileName = "extendedData.txt"
        let extendedData = "extendedData".data(using: .utf8)!
        let filePath = cache.iso.filePath(forKey: fileName)
        try "123".write(to: filePath, atomically: true, encoding: .utf8)

        XCTAssertTrue(filePath.exists)
        cache.iso.saveFile(forKey: fileKey, fileName: fileName, extendedData: extendedData)

        let result = cache.iso.filePathAndExtendedData(forKey: fileKey)
        XCTAssertNotNil(result)
        XCTAssertNotNil(result!.1)
        XCTAssertEqual(String(bytes: result!.1!, encoding: .utf8), "extendedData")

        cache.removeFile(forKey: fileKey)
        XCTAssertFalse(filePath.exists)
    }

    /// 测试新存入的fie，可以覆盖旧的file
    func testFileOverride() throws {
        let fileKey = "oldFileKey"

        let oldFileName = "oldfileName.txt"
        let oldFilePath = cache.iso.filePath(forKey: oldFileName)
        try "123".write(to: oldFilePath, atomically: true, encoding: .utf8)
        cache.iso.saveFile(forKey: fileKey, fileName: oldFileName, extendedData: nil)

        let newFileName = "newFileName.txt"
        let newFilePath = cache.iso.filePath(forKey: newFileName)
        try "123".write(to: newFilePath, atomically: true, encoding: .utf8)
        cache.iso.saveFile(forKey: fileKey, fileName: newFileName, extendedData: nil)

        XCTAssertNotNil(cache.iso.filePathAndExtendedData(forKey: fileKey))

        XCTAssertFalse(oldFilePath.exists)
        XCTAssertTrue(newFilePath.exists)

        cache.removeFile(forKey: fileKey)
        XCTAssertFalse(newFilePath.exists)
    }

    func testContainsFileMethodCanRemoveInvalidFile() throws {
        let fileKey = "CustomFileKey"
        let fileName = "extendedData.txt"
        let filePath = cache.iso.filePath(forKey: fileName)
        try "123".write(to: filePath, atomically: true, encoding: .utf8)

        cache.saveFile(key: fileKey, fileName: fileName)
        XCTAssertTrue(cache.containsFile(forKey: fileKey))

        let newFilePath = cache.iso.filePath(forKey: "tempPath")
        try filePath.moveItem(to: newFilePath)

        // 移动文件以后，cache中不再包含fileKey
        XCTAssertFalse(cache.containsFile(forKey: fileKey))
        try newFilePath.removeItem()
    }

    func testFilePathWhenFileNotExist() {
        // 测试当文件不存在时候，会返回一个合法的filePath
        XCTAssertFalse(cache.containsFile(forKey: "123"))
        let path = cache.iso.filePath(forKey: "123")
        XCTAssertEqual(path.absoluteString, (rootPath + "123").absoluteString)
    }
}
