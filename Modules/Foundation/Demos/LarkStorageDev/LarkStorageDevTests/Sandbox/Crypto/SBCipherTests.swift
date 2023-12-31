//
//  SBCipherTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2023/2/10.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

/// 测试 SBCipherManager 接口
final class SBCipherTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // 屏蔽掉流式加密
        LarkStorageFG.Config.disableStreamCrypto = true
    }

    // 测试 `SBCipherManager#setCrypto(forPath:space:)` 接口
    // 确保注册目录后，在该目录的读写操作是自动加解密的
    func testCipherConfig() throws {
        let userId = String(UUID().uuidString.prefix(7))
        let rootPath = IsoPath.in(space: .user(id: userId), domain: Domain.biz.core).build(.library)
        try rootPath.createDirectoryIfNeeded()

        // prepare normal/crypto dirs
        let normalDir = rootPath + "Normal"
        try normalDir.createDirectoryIfNeeded()
        let cryptoDir = rootPath + "Crypto"
        try cryptoDir.createDirectoryIfNeeded()

        // set crypto for `cryptoDir`
        SBCipherManager.shared.register(suite: .badbeaf) { _ in BadbeafCipher() }
        SBCipherManager.shared.setCrypto(
            forPath: AbsPath(cryptoDir.absoluteString),
            space: .user(id: userId),
            with: .badbeaf
        )

        // test file in `normalDir`
        do {
            let source = "Hello".data(using: .utf8)!
            let filePath = normalDir + "hello.txt"
            try source.write(to: filePath, atomically: true)

            let test = try Data.read(from: filePath)
            XCTAssert(!BadbeafCipher.isEncryped(for: test))
            XCTAssert(source == test)
        }

        // test file in `cryptoDir`
        do {
            let source = "Hello".data(using: .utf8)!
            let filePath = cryptoDir + "hello.txt"
            try source.write(to: filePath, atomically: true)

            // 正常读 - 自动解密
            let test = try Data.read(from: filePath)
            XCTAssert(!BadbeafCipher.isEncryped(for: test))
            XCTAssert(source == test)

            // 通过最原始的方式读，读出来的数据是加密的
            let rawRead = try Data(contentsOf: filePath.url)
            XCTAssert(BadbeafCipher.isEncryped(for: rawRead))
            XCTAssert(source != rawRead)
        }
    }

}
