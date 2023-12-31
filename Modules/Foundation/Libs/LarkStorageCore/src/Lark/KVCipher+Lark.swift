//
//  KVCipher+Lark.swift
//  LarkStorage
//
//  Created by 李昊哲 on 2023/2/13.
//

import Foundation
import CommonCrypto

public extension KVCipher {

    static func md5(text: String) -> String {
        guard let str = text.cString(using: .utf8) else {
            return text
        }
        let strLen = CC_LONG(text.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        // swiftlint:disable ForceUnwrapping
        CC_MD5(str, strLen, result)
        // swiftlint:enable ForceUnwrapping
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()

        return String(format: hash as String)
    }

    /// 为 KVCipher 提供默认的 MD5 哈希实现
    func hashed(forKey key: String) -> String {
        return Self.md5(text: key)
    }

    /// 为 KVCipher 提供默认的 JSON encode 实现
    func encode<T: Codable>(value: T) throws -> Data {
        let wrapper = KVStoreCryptoProxy.JsonWrapper(value: value)
        return try JSONEncoder().encode(wrapper)
    }

    /// 为 KVCipher 提供默认的 JSON decode 实现
    func decode<T: Codable>(from data: Data) throws -> T {
        let wrapped = try JSONDecoder().decode(
            KVStoreCryptoProxy.JsonWrapper<T>.self, from: data
        )
        return wrapped.value
    }

}

public extension KVCipherSuite {
    static var passport = KVCipherSuite(name: "passport")
    public static var passportRekey = KVCipherSuite(name: "passport_rekey")
}
