//
//  Magic.swift
//  FileCryptoDemo
//
//  Created by qingchun on 2023/2/22.
//

import Foundation

/// value from rustsdk: https://code.byted.org/lark/rust-sdk/blob/master/lark-security/src/file_secure/file_kind.rs
public enum AESFileKind: UInt8 {
    case v1
    case v2
    case regular = 255
}

extension AESFileKind {

    /// value from rustsdk: https://code.byted.org/lark/rust-sdk/blob/master/lark-security/src/file_secure/v2/header.rs#L16
    var magic: [UInt8] {
        switch self {
        case .v1:
            return "5EES0000".compactMap(AESFileKind.covertToAsciiValue)
        case .v2:
            return "11116ees".compactMap(AESFileKind.covertToAsciiValue)
        case .regular:
            return []
        }
    }

    private static func covertToAsciiValue(_ char: Character) -> UInt8 {
        if let value = UInt8(String(char)) {
            return value
        }
        return char.asciiValue ?? 0
    }
    
    var isEncrypted: Bool {
        return self != .regular
    }
}
