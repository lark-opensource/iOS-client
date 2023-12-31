//
//  E2EEKey.swift
//  ByteViewNetwork
//
//  Created by ZhangJi on 2023/4/13.
//

import Foundation
import RustPB
import ServerPB

typealias PBE2EEKey = Videoconference_V1_E2EEKey
typealias ServerPBE2EEKey = ServerPB_Videochat_E2EEKey
typealias PBE2EEJoinInfo = Videoconference_V1_E2EEJoinInfo
typealias ServerPBE2EEJoinInfo = ServerPB_Videochat_E2EEJoinInfo

// Videoconference_V1_E2EEKey
public struct E2EEKey: Equatable {
    /// key 版本
    public var version: UInt64
    /// 签发者
    public var issuer: ByteviewUser?
    /// 未加密的秘钥
    public var meetingKey: Data?

    public init(version: UInt64, issuer: ByteviewUser?, meetingKey: Data?) {
        self.version = version
        self.issuer = issuer
        self.meetingKey = meetingKey
    }
}

extension E2EEKey {
    var pbType: PBE2EEKey {
        var key = PBE2EEKey()
        key.version = version
        key.issuer = issuer?.pbType ?? Videoconference_V1_ByteviewUser()
        key.meetingKeyDecrypted = meetingKey ?? Data()
        return key
    }
}

extension E2EEKey: CustomStringConvertible {
    public var description: String {
        var range = 0
        if let key = meetingKey {
            range = min(3, key.count - 1)
        }
        return String(
            indent: "E2EEKey",
            "version: \(version)",
            "issuer: \(issuer)",
            "hasKey: \(meetingKey != nil)",
            "keySize: \(meetingKey?.count)",
            "key: \(meetingKey?.subdata(in: Range(0...range)).bytes) ***"
        )
    }
}

extension PBE2EEKey {
    var vcType: E2EEKey {
        return E2EEKey(version: version, issuer: hasIssuer ? issuer.vcType : nil, meetingKey: hasMeetingKeyDecrypted ? meetingKeyDecrypted : nil)
    }
}

extension ServerPBE2EEKey {
    var vcType: E2EEKey {
        // serverPB 透传的是加密的会议秘钥, 未加密的会议秘钥为nil
        return E2EEKey(version: version, issuer: hasIssuer ? issuer.vcType : nil, meetingKey: nil)
    }
}

// Videoconference_V1_E2EEJoinInfo
public struct E2EEJoinInfo: Equatable {
    public var keys: [UInt64: E2EEKey] = [:]
}

extension PBE2EEJoinInfo {
    var vcType: E2EEJoinInfo {
        var info = E2EEJoinInfo()
        info.keys = keys.mapValues{ $0.vcType }
        return info
    }
}

extension ServerPBE2EEJoinInfo {
    var vcType: E2EEJoinInfo {
        var info = E2EEJoinInfo()
        info.keys = keys.mapValues{ $0.vcType }
        return info
    }
}
