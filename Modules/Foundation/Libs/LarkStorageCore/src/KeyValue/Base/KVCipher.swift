//
//  KVCipher.swift
//  LarkStorage
//
//  Created by 7Up on 2022/9/23.
//

import Foundation
import EEAtomic

/// 定义 KV 的加密套件
public protocol KVCipher: AnyObject {
    /// 计算 key 哈希
    func hashed(forKey key: String) -> String
    /// 加密数据
    func encrypt(_ data: Data) throws -> Data
    /// 解密数据
    func decrypt(_ data: Data) throws -> Data
    /// 将任意 Codable 对象编码为 Data
    func encode<T: Codable>(value: T) throws -> Data
    /// 将 Data 解码为任意 Codable 对象
    func decode<T: Codable>(from data: Data) throws -> T
}

/// 加密套件
public struct KVCipherSuite: Hashable {
    let name: String

    internal init(name: String) {
        self.name = name
    }
}

public extension KVCipherSuite {
    static var aes = KVCipherSuite(name: "aes")
}

public final class KVCipherManager {

    static let loadableKey = "LarkStorage_KeyValueCryptoRegistry"

    public typealias CipherProvider = () throws -> KVCipher

    private var _allSuites: [KVCipherSuite: CipherProvider] = [
        .aes: { KVAesCipher() }
    ]
    private var cacheLock = UnfairLock()
    private var cachedCiphers = [String: KVCipher]()

    private var allSuites: [KVCipherSuite: CipherProvider] {
        Dependencies.loadOnce(Self.loadableKey)
        return _allSuites
    }

    public static let shared = KVCipherManager()

    /// 注册加密套件
    public func register(suite: KVCipherSuite, provider: @escaping CipherProvider) {
        _allSuites[suite] = provider
        cachedCiphers.removeValue(forKey: suite.name)
    }

    /// 根据 suite 获取加密套件
    public func cipher(forSuite suite: KVCipherSuite) -> KVCipher? {
        let cachedKey = suite.name
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = cachedCiphers[cachedKey] {
            return cached
        }
        guard let cipher = try? allSuites[suite]?() else {
            return nil
        }
        cachedCiphers[cachedKey] = cipher
        return cipher
    }

}
