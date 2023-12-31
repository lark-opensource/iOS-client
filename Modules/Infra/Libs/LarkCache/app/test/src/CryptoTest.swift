//
//  CryptoTest.swift
//  LarkCacheDevEEUnitTest
//
//  Created by Supeng on 2020/11/25.
//

import Foundation
import XCTest
@testable import LarkCache
import LarkFileKit
import LarkStorage

class CryptoTest: XCTestCase {

    override class func setUp() {
        SBCipherManager.shared.register(suite: .default) { _ in MockCipher(writeBack: false) }
        SBCipherManager.shared.register(suite: .writeBack) { _ in MockCipher(writeBack: true) }
    }

    override class func tearDown() {
        let path = Path.documentsPath + "test.txt"
        try? path.deleteFile()

        MockCryptoDependency.map = [:]
    }

    /// 测试Path类型可以对其加解密
    func testPathCanEncryptAndDecrypt() throws {
        let path = Path.documentsPath + "test.txt"
        try path.write("123".data(using: .utf8)!)

        // 测试未加密前，读取数据等于写入数据“123”
        let undecryptedData: Data? = try path.read()
        XCTAssertEqual("123".data(using: .utf8)!, undecryptedData)

        // 测试加密后，读取数据不等于写入数据“123”
        let encryptedPath = try path.encrypt()
        XCTAssertEqual(encryptedPath, path)
        let encryptedData: Data? = try encryptedPath.read()
        XCTAssertNotEqual(undecryptedData, encryptedData)

        // 测试对一个文件，再次加密，没有效果
        let secondEncryptedPath = try path.encrypt()
        XCTAssertEqual(encryptedPath, secondEncryptedPath)
        let secondEncryptedData: Data? = try secondEncryptedPath.read()
        XCTAssertEqual(secondEncryptedData, encryptedData)

        // 测试解密后，读取数据又等于“123”
        let decryptedPath = try path.decrypt()
        XCTAssertNotEqual(decryptedPath, path)
        let decryptedData: Data? = try decryptedPath.read()
        XCTAssertEqual(decryptedData, undecryptedData)

        // 测试对一个文件再次解密，没有效果
        let secondDecryptedPath = try path.decrypt()
        XCTAssertEqual(secondDecryptedPath, decryptedPath)
        let secondDecryptedData: Data? = try secondDecryptedPath.read()
        XCTAssertEqual(decryptedData, secondDecryptedData)
    }

    /// 测试String类型可以加解密
    func testStringCanEncryptAndDecrypt() throws {
        let path = Path.documentsPath + "test.txt"
        try path.write("123".data(using: .utf8)!)

        let undecryptedData: Data? = try path.read()

        let pathStr: String = path.rawValue
        let encryptedData: Data? = try pathStr.encrypt().read()
        XCTAssertNotEqual(encryptedData, undecryptedData)

        let decryptedData: Data? = try pathStr.decrypt().read()
        XCTAssertEqual(decryptedData, undecryptedData)
    }

    func testSaveFileAndEncrypt() throws {

        let cache = CacheManager.shared.cache(relativePath: "CryptoTestCache", directory: .cache)

        let path = Path(cache.rootPath) + "test.txt"
        try path.write("123".data(using: .utf8)!)

        /// 测试保存文件以后，可以直接对其加密
        let encryptedPath = try cache.saveFile(key: "key", fileName: "test.txt")?.encrypt()
        let encryptedData: Data? = try encryptedPath?.read()

        XCTAssertNotEqual(encryptedData, "123".data(using: .utf8)!)

        /// 测试读取文件以后，可以直接对其解密
        let decryptedPath = try cache.filePath(forKey: "key").decrypt()
        let decryptedData: Data? = try decryptedPath.read()

        XCTAssertEqual(decryptedData, "123".data(using: .utf8)!)
    }

    func testSaveDataAndEncrypt() throws {
        let cache = CacheManager.shared.cache(relativePath: "CryptoTestCache", directory: .cache)

        let originData = "123".data(using: .utf8)!

        let encryptedData: Data? = try cache.set(object: originData, forKey: "key")?.encrypt().read()
        XCTAssertNotEqual(encryptedData!, originData)

        let decryptedData: Data? = try cache.cachedFilePath(forKey: "key")?.decrypt().read()
        XCTAssertEqual(decryptedData!, originData)
    }

    func testWriteBackPath() throws {

        XCTAssertTrue(LarkCache.isCryptoEnable())

        let path = Path.documentsPath + "test.txt"
        try path.write("123".data(using: .utf8)!)

        XCTAssertThrowsError(try path.writeBackPath())
        let syncDecryptedPath = try path.encrypt().decrypt()

        let writeBackPath = try syncDecryptedPath.writeBackPath()
        XCTAssertEqual(writeBackPath, path)
    }
}

class MockCipher: Cipher {
    var writeBack: Bool
    init(writeBack: Bool) {
        self.writeBack = writeBack
    }

    func isEnabled() -> Bool {
        return MockCryptoDependency.isCryptoEnable()
    }

    func encrypt(_ path: String) throws -> String {
        if self.writeBack {
            return try MockCryptoDependency.writeBackPath(path)
        } else {
            return try MockCryptoDependency.encrypt(path)
        }
    }

    func decrypt(_ path: String) throws -> String {
        return try MockCryptoDependency.decrypt(path)
    }
}

struct MockCryptoDependency {
    static var map: [String: String] = [:]

    static let magicNumber: UInt8 = 9

    static func encrypt(_ path: String) throws -> String {
        let path = Path(path)
        guard var data: Data = try? path.read() else {
            throw CryptoError.EncryptError.fileNotFoundError
        }

        if data.contains(magicNumber) {
            return path.rawValue
        } else {
            data.append(contentsOf: [magicNumber])
            try path.write(data)
            return path.rawValue
        }
    }

    static func decrypt(_ path: String) throws -> String {
        let path = Path(path)
        guard let data: Data = try? path.read() else {
            throw CryptoError.EncryptError.fileNotFoundError
        }

        if data.contains(magicNumber) {
            var newData = data
            newData.removeLast()

            let tempPath = Path.userTemporary + "temp.txt"
            try? tempPath.deleteFile()
            try tempPath.write(newData)
            map[tempPath.rawValue] = path.rawValue
            return tempPath.rawValue
        } else {
            return path.rawValue
        }
    }

    static func writeBackPath(_ stagePath: String) throws -> String {
        if let path = map[stagePath] {
            return path
        } else {
            throw CryptoError.EncryptError.fileNotFoundError
        }
    }

    static func isCryptoEnable() -> Bool {
        true
    }
}
