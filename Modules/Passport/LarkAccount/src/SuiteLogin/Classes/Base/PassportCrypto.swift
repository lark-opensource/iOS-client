//
//  PassportCrypto.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2021/4/20.
//
import Foundation
import CommonCrypto

enum PassportCrypto {
    case md5, sha1, sha224, sha256, sha384, sha512

    func method() -> Int {
        switch self {
        case .md5:
            return kCCHmacAlgMD5
        case .sha1:
            return kCCHmacAlgSHA1
        case .sha224:
            return kCCHmacAlgSHA224
        case .sha256:
            return kCCHmacAlgSHA256
        case .sha384:
            return kCCHmacAlgSHA384
        case .sha512:
            return kCCHmacAlgSHA512
        }
    }

    func length() -> Int32 {
        switch self {
        case .md5:
            return CC_MD5_DIGEST_LENGTH
        case .sha1:
            return CC_SHA1_DIGEST_LENGTH
        case .sha224:
            return CC_SHA224_DIGEST_LENGTH
        case .sha256:
            return CC_SHA256_DIGEST_LENGTH
        case .sha384:
            return CC_SHA384_DIGEST_LENGTH
        case .sha512:
            return CC_SHA512_DIGEST_LENGTH
        }
    }

    func hash(message: String, salt: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(self.length()))
        CCHmac(CCHmacAlgorithm(self.method()), salt, salt.count, message, message.count, &digest)
        let data = Data(digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
}
