//
//  PinCodeEncryption.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/30.
//

import Foundation

protocol PinCodeEncryption {
    func encryptedValue(pinCode: String) -> String
}

enum PinCodeVersion: String {
    case noVersion // 对应v1和v2版本（v1：存储原始 pinCode 和 v2：存储原始值md5后的值）
    case v3
}

// 没有 version 的加密处理
final class NoVersionPinCodeEncryption: PinCodeEncryption {
    func encryptedValue(pinCode: String) -> String {
        return pinCode.md5()
    }
}

// v3 版本的加密处理
final class V3PinCodeEncryption: PinCodeEncryption {
    func encryptedValue(pinCode: String) -> String {
        return pinCode.sha256()
    }
}

/*
可以增加新的加密方式，增加后需要更改 getNewestEncryptionType getNewestEncryptionTypeString 两个方法的返回值
 */

final class PinCodeEncryptionFactory {
    static func getEncryptionType(pinCodeVersion: PinCodeVersion) -> PinCodeEncryption {
        switch pinCodeVersion {
        case .noVersion:
            return NoVersionPinCodeEncryption()
        case .v3:
            return V3PinCodeEncryption()
        }
    }

    // 始终获取最新的加密方法
    static func getNewestEncryptionType() -> PinCodeEncryption {
        return V3PinCodeEncryption()
    }

    static func getNewestEncryptionTypeString() -> String {
        return PinCodeVersion.v3.rawValue
    }
}
