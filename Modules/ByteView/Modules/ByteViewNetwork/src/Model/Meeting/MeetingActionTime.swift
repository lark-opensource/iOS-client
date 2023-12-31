//
//  MeetingActionTime.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_ActionTime
public struct MeetingActionTime: Equatable {

    /// 主叫邀请时间点
    public var invite: Int64

    /// ringing接受时间点
    public var accept: Int64

    /// 服务端推送起始时间
    public var push: Int64

    public init(invite: Int64, accept: Int64, push: Int64) {
        self.invite = invite
        self.accept = accept
        self.push = push
    }
}
