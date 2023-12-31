//
//  SecureUserDefaults.swift
//  ShareExtension
//
//  Created by Supeng on 2021/4/8.
//

import Foundation
import CryptoSwift

/// 对UserDefault的封装
public final class SecureUserDefaults {

    /// extension userDefaults
    private let userDefaults: UserDefaults = { UserDefaults.extension ?? .standard }()

    /// AES key
    private let aesKey = "com.bytedance.ee"

    /// 实例
    public static let shared = SecureUserDefaults()

    private init() {}

    /// 加密一个数据，存入extension userDefaults
    ///
    /// - Parameters:
    ///   - key: userDefaults的key
    ///   - value: 被加密的数据
    public func set(key: String, value: Data) throws {
        let aes = try AES(key: Padding.zeroPadding.add(to: aesKey.bytes, blockSize: AES.blockSize), blockMode: ECB())
        let encrypted = try aes.encrypt(value.bytes)
        userDefaults.set(encrypted.toBase64(), forKey: key)
    }

    /// 从extension userDefaults提取出一个数据并解密
    ///
    /// - Parameters:
    ///   - key: userDefaults的key
    /// - Returns: 解密后的Data
    public func dataValue(with key: String) throws -> Data? {
        guard let encrypted = userDefaults.value(forKey: key) as? String,
              let encryptedData = Data(base64Encoded: encrypted) else { return nil }

        let aes = try AES(key: Padding.zeroPadding.add(to: aesKey.bytes, blockSize: AES.blockSize), blockMode: ECB())
        let decrypted = try aes.decrypt(encryptedData.bytes)
        return Data(decrypted)
    }

    /// 从extension userDefaults移除一个数据
    ///
    /// - Parameters:
    ///   - key: userDefaults的key
    public func remove(with key: String) {
        userDefaults.removeObject(forKey: key)
    }
}

public extension SecureUserDefaults {
    /// 加密一个字符串，存入extension userDefaults
    ///
    /// - Parameters:
    ///   - key: userDefaults的key
    ///   - value: 被加密的数据
    func set(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            assertionFailure("string to data failed")
            return
        }
        try set(key: key, value: data)
    }

    /// 从extension userDefaults提取出一个数据并解密
    ///
    /// - Parameters:
    ///   - key: userDefaults的key
    /// - Returns: 解密后的字符串
    func stringValue(with key: String) throws -> String? {
        let result = try dataValue(with: key)
        return result.flatMap { String(data: $0, encoding: .utf8) }
    }
}

public extension SecureUserDefaults {
    enum Key: String {
        case currentAccountID
        case currentAccountSession
        case currentUserAgent
        case currentDeviceID
        case currentTenentID
        case currentInstallID
        case currentUserUniqueID
        case currentAPPVersion

        public var userDefaultKey: String { "com.bytedance.ee." + rawValue }
    }

    /// 加密一个字符串，存入extension userDefaults
    ///
    /// - Parameters:
    ///   - key: userDefaults的key
    ///   - value: 被加密的数据
    func set(key: Key, value: String) throws {
        try set(key: key.userDefaultKey, value: value)
    }

    /// 从extension userDefaults提取出一个数据并解密
    ///
    /// - Parameters:
    ///   - key: userDefaults的key
    /// - Returns: 解密后的字符串
    func value(with key: Key) throws -> String? {
        try stringValue(with: key.userDefaultKey)
    }

    /// 从extension userDefaults移除一个数据
    ///
    /// - Parameters:
    ///   - key: SecureUserDefaults.Key
    func remove(with key: Key) {
        userDefaults.removeObject(forKey: key.userDefaultKey)
    }
}
