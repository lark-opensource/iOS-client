//
//  CacheTest.swift
//  LarkCacheDevEEUnitTest
//
//  Created by Supeng on 2020/8/17.
//

import Foundation
import XCTest
@testable import LarkCache

class CacheTest: XCTestCase {

    var cache: Cache!
    override func setUp() {
        super.setUp()
        cache = CacheManager.shared.cache(biz: Messenger.self, directory: .cache)
    }

    override func tearDown() {
        cache = nil
        super.tearDown()
    }

    func testData() {
        let value = "value".data(using: .utf8)!
        let key = "key"
        cache.set(object: value, forKey: key)

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

        cache.set(object: value, forKey: key)

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

        let filePath = cache.rootPath + "/" + fileName
        try "value".write(toFile: filePath, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath))
        XCTAssertFalse(cache.containsFile(forKey: fileName))

        cache.saveFileName(fileName)
        XCTAssertTrue(cache.containsFile(forKey: fileName))

        cache.removeFile(forKey: fileName)
        XCTAssertFalse(cache.containsFile(forKey: fileName))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))
    }

    // MARK: Clean Test
    func testDataTrimToCost() {
        XCTAssertNotNil(cache.yyCache)
        let yycache = cache.yyCache!
        let diskCache = yycache.diskCache

        let data1 = "123".data(using: .utf8)!
        let data2 = "1234567890".data(using: .utf8)!

        // 测试cleanDiskCache传入0，可以全清
        cache.set(object: data1, forKey: "key1")
        cache.set(object: data2, forKey: "key2")

        cache.cleanDiskCache(toCost: 0)

        XCTAssertFalse(diskCache.containsObject(forKey: "key1"))
        XCTAssertFalse(diskCache.containsObject(forKey: "key2"))

        // 测试清理到data2.count的时候，只会清理data1
        cache.set(object: data1, forKey: "key1")
        cache.set(object: data2, forKey: "key2")
        cache.cleanDiskCache(toCost: data2.count)

        XCTAssertFalse(diskCache.containsObject(forKey: "key1"))
        XCTAssertTrue(diskCache.containsObject(forKey: "key2"))

        // 测试清理到data2.count - 1的时候，全部会清理
        cache.set(object: data1, forKey: "key1")
        cache.set(object: data2, forKey: "key2")
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

        cache.set(object: data1, forKey: "key1")
        sleep(2)
        cache.set(object: data2, forKey: "key2")
        cache.cleanDiskCache(toAge: TimeInterval(1))
        XCTAssertFalse(diskCache.containsObject(forKey: "key1"))
        XCTAssertTrue(diskCache.containsObject(forKey: "key2"))
    }

    func testFileTrimToCost() throws {
        XCTAssertNotNil(cache.yyCache)

        let fileName1 = "test1.txt"
        let filePath1 = cache.rootPath + "/" + fileName1
        try "123".write(toFile: filePath1, atomically: true, encoding: .utf8)

        let fileName2 = "test2.txt"
        let filePath2 = cache.rootPath + "/" + fileName2
        try "1234567890".write(toFile: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)

        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath1))
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath2))

        // 测试cleanDiskCache传入0，可以全清
        cache.cleanDiskCache(toCost: 1)

        XCTAssertFalse(cache.containsObject(forKey: fileName1))
        XCTAssertFalse(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath2))

        // 测试清理到data2.count的时候，只会清理data1
        try "123".write(toFile: filePath1, atomically: true, encoding: .utf8)
        try "1234567890".write(toFile: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)
        cache.cleanDiskCache(toCost: "1234567890".count)

        XCTAssertFalse(cache.containsObject(forKey: fileName1))
        XCTAssertTrue(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath1))
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath2))

        // 测试清理到data2.count - 1的时候，全部会清理
        try "123".write(toFile: filePath1, atomically: true, encoding: .utf8)
        try "1234567890".write(toFile: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)
        cache.cleanDiskCache(toCost: "1234567890".count - 1)

        XCTAssertFalse(cache.containsObject(forKey: fileName1))
        XCTAssertFalse(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath2))
    }

    func testFileTrimToTime() throws {
        XCTAssertNotNil(cache.yyCache)

        let fileName1 = "test1.txt"
        let filePath1 = cache.rootPath + "/" + fileName1
        try "123".write(toFile: filePath1, atomically: true, encoding: .utf8)

        let fileName2 = "test2.txt"
        let filePath2 = cache.rootPath + "/" + fileName2
        try "1234567890".write(toFile: filePath2, atomically: true, encoding: .utf8)

        cache.saveFileName(fileName1)
        cache.saveFileName(fileName2)
        sleep(2)
        // 读取fileName1,会更新fileName1的最后访问时间
        _ = cache.filePath(forKey: fileName1)
        // 清理最近1s内没有访问的数据，应该清理fileName2
        cache.cleanDiskCache(toAge: TimeInterval(1))
        XCTAssertTrue(cache.containsObject(forKey: fileName1))
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath1))
        XCTAssertFalse(cache.containsObject(forKey: fileName2))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath2))
    }

    func testRemoveAll() throws {
        XCTAssertNotNil(cache.yyCache)

        let data1 = "123".data(using: .utf8)!
        cache.set(object: data1, forKey: "key1")

        let fileName1 = "test1.txt"
        let filePath1 = cache.rootPath + "/" + fileName1
        try "123".write(toFile: filePath1, atomically: true, encoding: .utf8)
        cache.saveFileName(fileName1)

        XCTAssertTrue(cache.containsObject(forKey: fileName1))
        XCTAssertTrue(cache.containsFile(forKey: fileName1))

        let dir = "intermediateDir"
        let fileName2 = dir + "/" + "test1.txt"
        let filePath2 = cache.rootPath + "/" + fileName2
        try? FileManager.default.createDirectory(atPath: cache.rootPath + "/" + dir,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        try "123".write(toFile: filePath2, atomically: true, encoding: .utf8)
        cache.saveFileName(fileName2)

        XCTAssertTrue(cache.containsObject(forKey: fileName2))
        XCTAssertTrue(cache.containsFile(forKey: fileName2))

        cache.removeAllObjects()

        XCTAssertFalse(cache.containsObject(forKey: "key1"))
        XCTAssertFalse(cache.containsFile(forKey: fileName1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath1))
        XCTAssertFalse(cache.containsFile(forKey: fileName2))
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath2))
    }

    /// 给Data关联extendedData
    func testDataExtendedData() {
        let data: Data = "data".data(using: .utf8)!
        let extendedData: Data = "extendedData".data(using: .utf8)!
        cache.set(object: data, forKey: "testExtendedData", extendedData: extendedData)

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
        let extendedData: Data = "extendedData".data(using: .utf8)!
        cache.set(object: data, forKey: "testExtendedData", extendedData: extendedData)

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
        let extendedData: Data = "extendedData".data(using: .utf8)!
        let filePath = cache.filePath(forKey: fileName)
        try "123".write(toFile: filePath, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath))
        cache.saveFile(key: fileName, fileName: fileName, extendedData: extendedData)

        let result = cache.filePathAndExtendedData(forKey: fileName)
        XCTAssertNotNil(result)
        XCTAssertNotNil(result!.1)
        XCTAssertEqual(String(bytes: result!.1!, encoding: .utf8), "extendedData")

        cache.removeFile(forKey: fileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))
    }

    func testFileWithCustomFileKey() throws {
        let fileKey = "CustomFileKey"
        let fileName = "extendedData.txt"
        let extendedData: Data = "extendedData".data(using: .utf8)!
        let filePath = cache.filePath(forKey: fileName)
        try "123".write(toFile: filePath, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath))
        cache.saveFile(key: fileKey, fileName: fileName, extendedData: extendedData)

        let result = cache.filePathAndExtendedData(forKey: fileKey)
        XCTAssertNotNil(result)
        XCTAssertNotNil(result!.1)
        XCTAssertEqual(String(bytes: result!.1!, encoding: .utf8), "extendedData")

        cache.removeFile(forKey: fileKey)
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))
    }

    /// 测试新存入的fie，可以覆盖旧的file
    func testFileOverride() throws {
        let fileKey = "oldFileKey"

        let oldFileName = "oldfileName.txt"
        let oldFilePath = cache.filePath(forKey: oldFileName)
        try "123".write(toFile: oldFilePath, atomically: true, encoding: .utf8)
        cache.saveFile(key: fileKey, fileName: oldFileName, extendedData: nil)

        let newFileName = "newFileName.txt"
        let newFilePath = cache.filePath(forKey: newFileName)
        try "123".write(toFile: newFilePath, atomically: true, encoding: .utf8)
        cache.saveFile(key: fileKey, fileName: newFileName, extendedData: nil)

        XCTAssertNotNil(cache.filePathAndExtendedData(forKey: fileKey))

        XCTAssertFalse(FileManager.default.fileExists(atPath: oldFilePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: newFilePath))

        cache.removeFile(forKey: fileKey)
        XCTAssertFalse(FileManager.default.fileExists(atPath: newFilePath))
    }

    func testContainsFileMethodCanRemoveInvalidFile() throws {
        let fileKey = "CustomFileKey"
        let fileName = "extendedData.txt"
        let filePath = cache.filePath(forKey: fileName)
        try "123".write(toFile: filePath, atomically: true, encoding: .utf8)

        cache.saveFile(key: fileKey, fileName: fileName)
        XCTAssertTrue(cache.containsFile(forKey: fileKey))

        let newFilePath = cache.filePath(forKey: "tempPath")
        try FileManager.default.moveItem(atPath: filePath, toPath: newFilePath)

        // 移动文件以后，cache中不再包含fileKey
        XCTAssertFalse(cache.containsFile(forKey: fileKey))
        try FileManager.default.removeItem(atPath: newFilePath)
    }

    func testFilePathWhenFileNotExist() {
        // 测试当文件不存在时候，会返回一个合法的filePath
        XCTAssertFalse(cache.containsFile(forKey: "123"))
        let path = cache.filePath(forKey: "123")
        XCTAssertEqual(path, cache.rootPath + "/" + "123")
    }
}
