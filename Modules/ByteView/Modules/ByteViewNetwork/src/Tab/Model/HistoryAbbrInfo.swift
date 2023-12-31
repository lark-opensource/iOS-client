//
//  HistoryAbbrInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// Videoconference_V1_HistoryAbbrInfo
public struct HistoryAbbrInfo: Equatable {
    public init(historyType: HistoryType, callStatus: HistoryInfo.CallStatus, callCount: Int64,
                interacterUserID: String, interacterUserType: ParticipantType) {
        self.historyType = historyType
        self.callStatus = callStatus
        self.callCount = callCount
        self.interacterUserID = interacterUserID
        self.interacterUserType = interacterUserType
    }

    /// 记录类型
    public var historyType: HistoryType

    /// 呼叫状态
    public var callStatus: HistoryInfo.CallStatus

    /// 显示的呼叫总次数
    public var callCount: Int64

    /// 交互用户ID, 被呼叫时为主叫ID, 呼叫时为被叫ID， 为空时列表上不展示
    public var interacterUserID: String

    /// 交互用户类型
    public var interacterUserType: ParticipantType
}
