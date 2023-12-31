//
//  FollowPatch.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 表示一个strategy的增量数据包
/// - Videoconference_V1_FollowPatch
public struct FollowPatch: Equatable {
    public init(sender: String, opType: FollowPatchType, dataType: FollowDataType, stateKey: String?, webData: FollowWebData?) {
        self.sender = sender
        self.opType = opType
        self.dataType = dataType
        self.stateKey = stateKey
        self.webData = webData
    }

    /// 发送者UID
    public var sender: String

    public var opType: FollowPatchType

    public var dataType: FollowDataType

    public var stateKey: String?

    public var webData: FollowWebData?
}

public enum FollowPatchType: Int, Hashable {
    case unknown // = 0
    case appendType // = 1
}
