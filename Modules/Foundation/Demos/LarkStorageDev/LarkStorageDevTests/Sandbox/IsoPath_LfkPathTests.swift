//
//  IsoPath_LfkPathTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage
import LarkCache

/// 测试 IsoPath 和 LfkPath 的兼容性
class IsoPath_LfkPathTests: XCTestCase {

    lazy var rootDir: IsoPath = {
        IsolateSandbox(space: .global, domain: Domain.biz.feed.child(typeName))
            .rootPath(forType: .library)
    }()

    override func setUpWithError() throws {
        try super.setUpWithError()
        // 屏蔽掉流式加密
        LarkStorageFG.Config.disableStreamCrypto = true
        if rootDir.exists {
            try rootDir.removeItem()
        }
        try rootDir.createDirectory()
    }

    func testFileSize() throws {
        let data = String(repeating: "hello", count: 1024).data(using: .utf8)
        let filePath = rootDir + "testFileSize.data"
        try filePath.createFile(with: data)

        let size1 = filePath.fileSize!
        let size2 = LfkPath(filePath.absoluteString).fileSize!
        XCTAssert(size1 > 0 && size2 > 0 && size1 == size2, "testFileSize. size1: \(size1), size2: \(size2)")
    }

    func testRecursiveFileSize() throws {
        let data = String(repeating: "hello", count: 1024).data(using: .utf8)

        let testDir = rootDir + "testRecursiveFileSize"
        try testDir.createDirectory()

        let dataDirs: [IsoPath] = [
            testDir + "a",
            testDir + "a/a1/",
            testDir + "a/a1/a2",
            testDir + "b",
            testDir + "b/b1/",
            testDir + "b/b1/b2"
        ]
        try dataDirs.forEach {
            try $0.createDirectory()
        }
        XCTAssert(testDir.recursiveFileSize(ignoreDirectorySize: true) == 0)
        XCTAssert(testDir.recursiveFileSize(ignoreDirectorySize: false) != 0)
        try dataDirs.forEach { dir in
            try (dir + "file.data").createFile(with: data)
        }
        let size1 = testDir.recursiveFileSize()
        let size2 = LfkPath(testDir.absoluteString).recursizeFileSize
        XCTAssert(size1 > 0 && size2 > 0 && size1 == size2, "size1: \(size1), size2: \(size2)")
    }

    func testChildren() throws {
        let testDir = rootDir + "testChildren"
        try [
            testDir + "a",
            testDir + "b",
            testDir + "c"
        ].forEach { try $0.createDirectory() }
        try [
            testDir + "a/a1/a2",
            testDir + "b/b1/b2",
            testDir + "c/c1/c2"
        ].forEach { try $0.createDirectory() }

        let arr1 = try rootDir
            .childrenOfDirectory(recursive: true)
            .map(\.absoluteString)
            .sorted()
        let arr2 = LfkPath(rootDir.absoluteString)
            .children(recursive: true)
            .map(\.rawValue)
            .sorted()
        XCTAssertEqual(arr1, arr2)

        let arr3 = try rootDir
            .childrenOfDirectory(recursive: false)
            .map(\.absoluteString)
            .sorted()
        let arr4 = LfkPath(rootDir.absoluteString)
            .children(recursive: false)
            .map(\.rawValue)
            .sorted()
        XCTAssertEqual(arr3, arr4)
    }

    func testEachChildren() throws {
        let testDir = rootDir + "testChildren"
        try [
            testDir + "a",
            testDir + "b",
            testDir + "c"
        ].forEach { try $0.createDirectory() }
        try [
            testDir + "a/a1/a2",
            testDir + "b/b1/b2",
            testDir + "c/c1/c2"
        ].forEach { try $0.createDirectory() }

        var arr1 = [String]()
        rootDir.eachChildren(recursive: true) { arr1.append($0.absoluteString) }
        arr1.sort()

        var arr2 = [String]()
        LfkPath(rootDir.absoluteString).eachChildren(recursive: true) { arr2.append($0.rawValue) }
        arr2.sort()

        XCTAssertEqual(arr1, arr2)

        var arr3 = [String]()
        rootDir.eachChildren(recursive: false) { arr3.append($0.absoluteString) }
        arr3.sort()

        var arr4 = [String]()
        LfkPath(rootDir.absoluteString).eachChildren(recursive: false) { arr4.append($0.rawValue) }
        arr4.sort()

        XCTAssertEqual(arr3, arr4)
    }

    func testReadWrite() throws {
        do {
            let isoPath = rootDir + "testReadWrite_data.file"
            let lfkPath = LfkPath(isoPath.absoluteString)

            // IsoPath 写 -> LfkPath 读
            let w1 = "data1".data(using: .utf8)!
            try w1.write(to: isoPath)
            let r1 = try Data.read(from: lfkPath)
            XCTAssert(r1 == w1)
            // LfkPath 写 -> IsoPath 读
            let w2 = "data2".data(using: .utf8)!
            try w2.write(to: lfkPath)
            let r2 = try Data.read(from: isoPath)
            XCTAssert(r2 == w2)
        }
    }

    func testCryptoRead() throws {
        SBCipherManager.shared.register(suite: .badbeaf) { _ in BadbeafCipher() }

        let fileName = "testReadWrite_string.file"
        let isoPath = (rootDir + fileName).usingCipher(suite: .badbeaf)
        let lfkPath = LfkPath(isoPath.absoluteString)
        let str = "str"
        let data = str.data(using: .utf8)!
        try str.write(to: isoPath)

        do {
            let wdata1 = try Data.read(from: isoPath)
            let wstr1 = try String.read(from: isoPath)
            XCTAssertEqual(data, wdata1)
            XCTAssertEqual(str, wstr1)

            let withoutCipherPath = rootDir + fileName
            let wdata2 = try Data.read(from: withoutCipherPath)
            XCTAssertNotEqual(data, wdata2)

            let wdata3 = try Data.read(from: lfkPath)
            XCTAssertNotEqual(data, wdata3)
        }
    }

    func testCryptoCreate() throws {
        SBCipherManager.shared.register(suite: .badbeaf) { _ in BadbeafCipher()}

        let str = "testCryptoCreate"
        let data = str.data(using: .utf8)!

        XCTAssertFalse(BadbeafCipher.isEncryped(for: data))

        let filePath = rootDir + "testCryptoCreate_string.file"

        try filePath.usingCipher(suite: .badbeaf).createFile(with: data)

        // 不解密读数据
        do {
            let rdata = try Data.read(from: filePath)
            XCTAssertTrue(BadbeafCipher.isEncryped(for: rdata))
        }

        // 解密读数据
        do {
            let data = try Data.read(from: filePath.usingCipher(suite: .badbeaf))
            XCTAssertFalse(BadbeafCipher.isEncryped(for: data))
            XCTAssertEqual(str, String(data: data, encoding: .utf8)!)
        }
    }

}

extension SBCipherSuite {
    static let badbeaf = SBCipherSuite(key: "badbeaf")
}

class BadbeafCipher: SBCipher {
    static let codes: [UInt8] = [0xb, 0xa, 0xd, 0xb, 0xe, 0xa, 0xf]
    let sandbox = SandboxBase<AbsPath>()

    func isEnabled() -> Bool {
        return true
    }

    var headerBytes: Int { Self.codes.count }

    static func isEncryped(for data: Data) -> Bool {
        return data.count > codes.count && data.suffix(codes.count) == codes
    }

    func encryptPath(_ path: RawPath) throws -> RawPath {
        let absPath = AbsPath(path)
        guard var data = try? Data.read(from: absPath) else {
            throw CryptoError.EncryptError.fileNotFoundError
        }
        guard !Self.isEncryped(for: data) else {
            return path
        }
        data.append(contentsOf: Self.codes)
        try sandbox.performWriting(data, atPath: absPath, with: .atomically(true))
        return path
    }

    func decryptPath(_ path: RawPath) throws -> RawPath {
        let absPath = AbsPath(path)
        guard let data = try? Data.read(from: absPath) else {
            throw CryptoError.DecryptError.fileNotFoundError
        }
        guard Self.isEncryped(for: data) else {
            return path
        }
        var newData = data
        newData.removeLast(Self.codes.count)

        let tempPath = AbsPath.temporary + UUID().uuidString
        try sandbox.performWriting(newData, atPath: tempPath, with: .atomically(true))
        return tempPath.absoluteString
    }

    func checkEncrypted(for data: Data) -> Bool {
        Self.isEncryped(for: data)
    }

    func checkEncrypted(forPath path: RawPath) -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return false
        }
        return checkEncrypted(for: data)
    }

    func decryptPathInPlace(_ path: RawPath) throws {
        // do nothing
    }

    func writeData(_ data: Data, to path: RawPath) throws {
        // do nothing
    }

    func readData(from path: RawPath) throws -> Data {
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    func inputStream(atPath path: RawPath) -> SBInputStream? {
        return InputStream(url: .init(fileURLWithPath: path))
    }

    func outputStream(atPath path: RawPath, append shouldAppend: Bool) -> SBOutputStream? {
        return OutputStream(toFileAtPath: path, append: shouldAppend)
    }

    func fileHandle(atPath path: RawPath, forUsage usage: FileHandleUsage) throws -> SBFileHandle {
        let url = URL(fileURLWithPath: path)
        switch usage {
        case .reading:
            return try FileHandle(forReadingFrom: url).sb
        case .updating:
            return try FileHandle(forUpdating: url).sb
        case .writing:
            return try FileHandle(forWritingTo: url).sb
        }
    }

    func fileSize(atPath path: RawPath) throws -> Int {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        guard let num = attrs[FileAttributeKey.size] as? NSNumber else {
            return 0
        }
        return num.intValue
    }
}
