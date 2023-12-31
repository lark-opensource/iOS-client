//
//  MeetingRTMInfo.swift
//  ByteViewNetwork
//
//  Created by wangpeiran on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_ActionTime
public struct MeetingRTMInfo: Equatable {

    public var signature: String
    public var url: String
    public var reqKey: Data
    public var pushPublicKey: Data
    public var token: String
    public var uid: String

    public init(signature: String, url: String, reqKey: Data, pushPublicKey: Data, token: String, uid: String) {
        self.signature = signature
        self.url = url
        self.reqKey = reqKey
        self.pushPublicKey = pushPublicKey
        self.token = token
        self.uid = uid
    }
}
