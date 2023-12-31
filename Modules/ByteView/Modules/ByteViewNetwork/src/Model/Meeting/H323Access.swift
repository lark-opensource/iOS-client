//
//  H323Access.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// https://bytedance.feishu.cn/docs/doccnb8uI64b7gG6y0xoHUZ5Xze
/// - Videoconference_V1_VideoChatH323Setting
public struct H323Setting: Equatable {
    public init(h323AccessList: [H323Access], ercDomainList: [String], isShowCrc: Bool) {
        self.h323AccessList = h323AccessList
        self.ercDomainList = ercDomainList
        self.isShowCrc = isShowCrc
    }

    public var h323AccessList: [H323Access]
    public var ercDomainList: [String]
    public var isShowCrc: Bool

    public struct H323Access: Equatable {
        public init(ip: String, country: String) {
            self.ip = ip
            self.country = country
        }

        public var ip: String
        public var country: String
    }

}
