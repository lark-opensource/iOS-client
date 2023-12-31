//
//  KVCryptoTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/9/29.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage
@testable import LarkStorageAssembly

class KVCryptoTests: KVTestCase {

    func testCipher() throws {
        try doTestCipher(suite: .aes)
        try doTestCipher(suite: .mock)
        try doTestCipher(suite: .fake)
    }

    func doTestCipher(suite: KVCipherSuite) throws {
        func innerTest(space: Space, type: KVStoreType) throws {
            let domain = classDomain.uuidChild()
            let config = KVStoreConfig(space: space, domain: domain, type: type)
            for filePath in paths(forConfig: config, suite: suite) {
                // remove udkv/mmkv file if needed
                if filePath.exists {
                    try filePath.notStrictly.removeItem()
                }
                XCTAssertFalse(filePath.exists)
            }

            let store = makeStore(forConfig: config, suite: suite).disposed(self)
            KVItems.saveAllCases(in: store)
            KVItems.checkAllCases(in: store)
            KVObjects.saveAllCases(in: store)
            KVObjects.checkAllCases(in: store)
        }

        // global space; udkv
        try innerTest(space: .global, type: .udkv)
        // global space; mmkv
        try innerTest(space: .global, type: .mmkv)
        // user space; udkv
        try innerTest(space: .uuidUser(type: typeName), type: .udkv)
        // user space; mmkv
        try innerTest(space: .uuidUser(type: typeName), type: .mmkv)
    }

    func testCryptTime() throws {
        let cipher = KVAesCipher()

        let randomLength = Int.random(in: 1...1024)
        var randomBytes = [UInt8](repeating: 0, count: randomLength)
        arc4random_buf(&randomBytes, randomLength)
        let data = Data(randomBytes)
        let encrypted = try cipher.encrypt(data)

        let time1 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<1000 {
            _ = try cipher.encrypt(data)
        }
        let time2 = CFAbsoluteTimeGetCurrent()
        print("cipher encrypt time:", time2 - time1)

        let time3 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<1000 {
            _ = try cipher.decrypt(encrypted)
        }
        let time4 = CFAbsoluteTimeGetCurrent()
        print("cipher decrypt time:", time4 - time3)
    }
}

// mock cipher
final class KVMockCipher: KVCipher {
    private static let prefix = "mockmock".data(using: .utf8)!

    func encrypt(_ data: Data) throws -> Data {
        var ret = Self.prefix
        ret.append(data)
        return ret
    }

    func decrypt(_ data: Data) throws -> Data {
        var ret = data
        ret.removeFirst(Self.prefix.count)
        return ret
    }

    static func checkCrypted(_ data: Data) -> Bool {
        return data.count >= Self.prefix.count &&
            Data(data.prefix(Self.prefix.count)) == Self.prefix
    }
}

// fake cipher
final class KVFakeCipher: KVCipher {
    func encrypt(_ data: Data) throws -> Data {
        return data
    }

    func decrypt(_ data: Data) throws -> Data {
        return data
    }
}

extension KVCipherSuite {
    static var mock = KVCipherSuite(name: "mock")
    static var fake = KVCipherSuite(name: "fake")
}

extension KVCipherManager {
    @_silgen_name("Lark.LarkStorage_KeyValueCryptoRegistry.KVCryptoTests")
    public static func registTestsCipher() {
        print("LarkStorageDevTests registTestsCipher")
        KVCipherManager.shared.register(suite: .aes) { KVAesCipher() }
        KVCipherManager.shared.register(suite: .mock) { KVMockCipher() }
        KVCipherManager.shared.register(suite: .fake) { KVFakeCipher() }
    }
}
