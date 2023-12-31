//
//  RtcProxy.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 飞书视频会议支持通过socks5代理
/// - Videoconference_V1_RTCProxy
/// - 需求文档：https://bytedance.feishu.cn/docs/doccnmsLLGG4rUWQDl96vYKmYUd
/// - 技术方案：https://bytedance.feishu.cn/docs/doccn1i7rdnzTWuWcIJ9eN91Qcb#
public struct RTCProxy: Equatable {

    public init(status: Bool, proxyType: ProxyType, proxyIp: String, proxyPort: Int64, userName: String, passport: String) {
        self.status = status
        self.proxyType = proxyType
        self.proxyIp = proxyIp
        self.proxyPort = proxyPort
        self.userName = userName
        self.passport = passport
    }

    /// proxy 开关状态
    public var status: Bool

    public var proxyType: ProxyType

    public var proxyIp: String

    public var proxyPort: Int64

    public var userName: String

    public var passport: String

    public enum ProxyType: Int, Hashable {
        case none // = 0
        case https // = 1
        case socks5 // = 2
        case http // = 3
        case unknown // = 4
    }
}

extension RTCProxy: CustomStringConvertible {
    public var description: String {
        String(
            indent: "RTCProxy",
            "status: \(status)",
            "type: \(proxyType)"
        )
    }
}
