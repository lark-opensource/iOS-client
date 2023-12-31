//
//  String+MD5.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/13.
//

import Foundation
import CommonCrypto
import CryptoKit

extension ImageWrapper where Base == String {

    public var md5: String {
        guard let data = base.data(using: .utf8) else {
            return base
        }
        return data.bt.md5
    }
}

extension ImageWrapper where Base == Data {

    public var md5: String {
        if #available(iOS 13.0, *) {
            let digest = Insecure.MD5.hash(data: base)
            return digest.map { String(format: "%02x", $0) }.joined()
        } else {
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            _ = base.withUnsafeBytes {
                CC_MD5($0.baseAddress, CC_LONG(base.count), &digest)
            }
            return digest.map { String(format: "%02x", $0) }.joined()
        }
    }
}
