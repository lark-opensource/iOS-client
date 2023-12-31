//
//  HistoryType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_HistoryType
public enum HistoryType: Int, Hashable {
    case unknown // = 0

    /// 主动入会
    case historyJoin // = 1

    /// 呼叫对方
    case historyCall // = 2

    /// 被呼叫
    case historyBeCalled // = 3

    /// 离会
    case historyLeave // = 4
}
