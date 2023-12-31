//
//  CryptoCacheTest.swift
//  LarkCacheDevEEUnitTest
//
//  Created by Supeng on 2020/12/24.
//

import Foundation
import XCTest
import LarkFileKit
@testable import LarkCache
import LarkStorage

class CryptoCacheTest: XCTestCase {

    var cache: Cache!
    var cryptoCache: CryptoCache!

    override func setUp() {
        super.setUp()

        SBCipherManager.shared.register(suite: .default) { _ in MockCipher(writeBack: false) }
        SBCipherManager.shared.register(suite: .writeBack) { _ in MockCipher(writeBack: true) }

        self.cache = CacheManager.shared.cache(relativePath: "CryptoCacheTestCache", directory: .cache)
        self.cryptoCache = self.cache.asCryptoCache()
    }

    func testCryptoTestInit() {
        XCTAssertTrue((cache.yyCache! === cryptoCache.yyCache!))

        let newCryptoCache = cryptoCache.asCryptoCache()
        XCTAssertTrue(newCryptoCache === cryptoCache!)
    }

    func testSetObject() throws {
        let data: Data = "1234".data(using: .utf8)!
        let extendedData = "extendedData".data(using: .utf8)
        cryptoCache.set(object: data, forKey: "Key", extendedData: extendedData)

        //确保Data set接口可以正常工作
            // 确保磁盘缓存是加密的
        var diskcacheData: Data! = try Path(cache.filePath(forKey: "Key")).read()
        XCTAssertNotEqual(data, diskcacheData)
            // 确保内存缓存是未加密的
        var memorycacheData = cryptoCache.yyCache?.memoryCache.object(forKey: "Key") as? Data
        XCTAssertEqual(data, memorycacheData)

        // 确保NSCoding set接口可以正常工作
        cryptoCache.set(object: data as NSCoding, forKey: "Key", extendedData: extendedData)
        // 确保磁盘缓存是加密的
        diskcacheData = try Path(cache.filePath(forKey: "Key")).read()
        XCTAssertNotEqual(data, diskcacheData)
        // 确保内存缓存是未加密的
        memorycacheData = cryptoCache.yyCache?.memoryCache.object(forKey: "Key") as? Data
        XCTAssertEqual(data, memorycacheData)
    }

    func testGetObject() throws {
        let data: Data = "testGetObject".data(using: .utf8)!
        let extendedData = "testGetObjectExtendedData".data(using: .utf8)
        let key = "testGetObject"
        cryptoCache.set(object: data, forKey: key, extendedData: extendedData)

        // NSCoding相关接口测试
            // 直接取NSCoding是解密的数据
        var nscodingData: NSCoding? = cryptoCache.object(forKey: key)
        XCTAssertNotNil(nscodingData)
        XCTAssertEqual((nscodingData as? Data)!, data)

            // 清理内存缓存以后，还是可以从磁盘缓存中取到解密的数据
        cryptoCache.yyCache?.memoryCache.removeAllObjects()
        XCTAssertNil(cryptoCache.yyCache?.memoryCache.object(forKey: key))
        nscodingData = cryptoCache.object(forKey: key)
        XCTAssertNotNil(nscodingData)
        XCTAssertEqual((nscodingData as? Data)!, data)

            // 从磁盘缓存中取到解密数据以后，内存缓存中又有解密数据了
        nscodingData = cryptoCache.yyCache?.memoryCache.object(forKey: key) as? NSCoding
        XCTAssertNotNil(nscodingData)
        XCTAssertEqual((nscodingData as? Data)!, data)

            // 测试可以正常获取extendedData
        let (_, newExtendedData): (NSCoding, Data?) = cryptoCache.objectAndEntendedData(forKey: key)!
        XCTAssertEqual(newExtendedData, extendedData)

            // 测试清理内存缓存以后，也可以正常获取extendedData
        cryptoCache.yyCache?.memoryCache.removeAllObjects()
        let (_, newExtendedData1): (NSCoding, Data?) = cryptoCache.objectAndEntendedData(forKey: key)!
        XCTAssertEqual(newExtendedData1, extendedData)

        // Data相关接口测试
            // 直接取Data是解密的数据
        var dataResult: Data? = cryptoCache.object(forKey: key)
        XCTAssertNotNil(dataResult)
        XCTAssertEqual(dataResult!, data)

            // 清理内存缓存以后，还是可以从磁盘缓存中取到解密的数据
        cryptoCache.yyCache?.memoryCache.removeAllObjects()
        XCTAssertNil(cryptoCache.yyCache?.memoryCache.object(forKey: key))
        dataResult = cryptoCache.object(forKey: key)
        XCTAssertNotNil(dataResult)
        XCTAssertEqual(dataResult!, data)

            // 从磁盘缓存中取到解密数据以后，内存缓存中又有解密数据了
        nscodingData = cryptoCache.yyCache?.memoryCache.object(forKey: key) as? NSCoding
        XCTAssertNotNil(dataResult)
        XCTAssertEqual(dataResult!, data)

            // 测试可以正常获取extendedData
        let (_, newExtendedData2): (NSCoding, Data?) = cryptoCache.objectAndEntendedData(forKey: key)!
        XCTAssertEqual(newExtendedData2, extendedData)

            // 测试清理内存缓存以后，也可以正常获取extendedData
        cryptoCache.yyCache?.memoryCache.removeAllObjects()
        let (_, newExtendedData3): (NSCoding, Data?) = cryptoCache.objectAndEntendedData(forKey: key)!
        XCTAssertEqual(newExtendedData3, extendedData)

        // 测试异常情况
        let emptyResult: NSCoding? = cryptoCache.object(forKey: "None exist key")
        XCTAssertNil(emptyResult)

        let emptyResult1 = cryptoCache.objectAndEntendedData(forKey: "None exist key")
        XCTAssertNil(emptyResult1)
    }

    func testFile() throws {
        let path = Path(cryptoCache.rootPath) + "test.txt"
        let data = "123".data(using: .utf8)!
        try path.write(data)
        let extendedData = "extendedData".data(using: .utf8)

        cryptoCache.saveFile(key: "Key",
                             fileName: "test.txt",
                             size: nil,
                             extendedData: extendedData)

        // 直接使用objectForKey API可以读取到解密的数据
        var newData: Data? = cryptoCache.object(forKey: "Key")
        XCTAssertNotNil(newData)
        XCTAssertEqual(newData!, data)

        // 使用filePath获取解密路径，可以读取解密的data
        let newPath = cryptoCache.filePath(forKey: "Key")
        XCTAssertNotEqual(Path(newPath), path)
        newData = try? Path(newPath).read()
        XCTAssertEqual(newData!, data)

            // 通过filePath获取一个Cache中不存在的文件，会返回Cache目录下的路径
        let nonExistFilePath = cryptoCache.filePath(forKey: "None exist key")
        XCTAssertEqual(nonExistFilePath, cryptoCache.rootPath + "/None exist key")

        // 可以正常获取extendedData
        let result = cryptoCache.filePathAndExtendedData(forKey: "Key")
        XCTAssertNotNil(result)
        XCTAssertNotEqual(result!.0, path.rawValue)
        newData = try? Path(result!.0).read()
        XCTAssertEqual(newData!, data)

        XCTAssertEqual(result!.1, extendedData)

        // 测试saveFileName接口
        cryptoCache.saveFileName("test.txt")
        newData = try? Path(cryptoCache.filePath(forKey: "test.txt")).read()
        XCTAssertEqual(newData!, data)

        // 测试异常情况
        XCTAssertNil(cryptoCache.filePathAndExtendedData(forKey: "None exist key"))

        // 测试originFilePath接口
        let originPath = cryptoCache.originFilePath(forKey: "Key")
        XCTAssertEqual(originPath, cryptoCache.rootPath + "/test.txt")
        newData = try? Path(originPath).read()
        XCTAssertNotEqual(newData!, data)
    }
}
