//
//  AESConstants.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/6/30.
//

import Foundation

/// AESError
///
enum AESError: Error {
    case isNotCrypto
    case operationIsError(String)
    case userIDNotMatched(String)
    case nonceIsNil
}

extension AESError: CustomStringConvertible {
    var description: String {
        switch self {
        case .isNotCrypto:
            return "is not crypted"
        case .operationIsError(let desc):
            return desc
        case .userIDNotMatched(let desc):
            return desc
        case .nonceIsNil:
            return "aes nonce is nil"
        }
    }
}

/// AESMetaInfo
public class AESMetaInfo {
    public let filePath: String
    public let deviceKey: Data
    public let uid: String
    public let did: String
    /// 暂存下加密版本，避免多次读取导致 io 操作过多
    public var encryptVersion: AESFileKind?
    
    public init(filePath: String, deviceKey: Data, uid: String, did: String) {
        self.filePath = filePath
        self.deviceKey = deviceKey
        self.uid = uid
        self.did = did
    }
}

/// AESSeekWhere
/// 
public enum AESSeekWhere: Int {
    case start = 0
    case current
    case end
}

/// AESFileOption

public enum AESFileOption {
    case read
    case write
    /// seek to end, then write data start from end.
    case append
}

/// 加解密分组大小
let AESCryptorDivider = 100 * 1000 * 1000
