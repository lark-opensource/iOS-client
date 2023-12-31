//
//  HistoryInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_HistoryInfo
public struct HistoryInfo: Equatable {
    public init(historyType: HistoryType, historyInfoType: HistoryInfoType, callStatus: CallStatus,
                interacterUserID: String, interacterUserType: ParticipantType,
                callStartTime: Int64, joinTime: Int64, leaveTime: Int64, cancelReason: CancelReason, offlineReason: Participant.OfflineReason) {
        self.historyType = historyType
        self.historyInfoType = historyInfoType
        self.callStatus = callStatus
        self.interacterUserID = interacterUserID
        self.interacterUserType = interacterUserType
        self.callStartTime = callStartTime
        self.joinTime = joinTime
        self.leaveTime = leaveTime
        self.cancelReason = cancelReason
        self.offlineReason = offlineReason
    }

    /// 记录类型
    public var historyType: HistoryType

    /// 历史记录类型
    public var historyInfoType: HistoryInfoType

    /// 呼叫状态
    public var callStatus: CallStatus

    /// 交互用户ID, 被呼叫时为主叫ID, 呼叫时为被叫ID
    public var interacterUserID: String

    /// 交互用户类型
    public var interacterUserType: ParticipantType

    /// 开始呼叫时间，主动入会时不填
    public var callStartTime: Int64

    /// 入会时间
    public var joinTime: Int64

    /// 离会时间
    public var leaveTime: Int64

    /// 呼入的办公电话用以区分拒接/未接
    public var cancelReason: CancelReason

    /// 用于区分网络研讨会嘉宾观众身份切换造成的离会
    public var offlineReason: Participant.OfflineReason

    /// Videoconference_V1_CallStatus
    public enum CallStatus: Int, Hashable {
        case unknown // = 0

        /// 呼叫已接听
        case callAccepted // = 1

        /// 呼叫已取消(不区分对方拒接、响铃超时、主动取消)
        case callCanceled // = 2

    }

    /// Videoconference_V1_HistoryInfoType
    public enum HistoryInfoType: Int, Hashable {
        case unknown // = 0
        case videoConference // = 1
        case enterprisePhone // = 2
        case ipPhone // = 3
        case recruitment // = 4
    }

    public enum CancelReason: Int, Hashable {
        case cancel // = 0
        case refuse // = 1
        case timeout // = 2
    }
}

extension HistoryInfo {
    public init() {
        self.init(historyType: .unknown, historyInfoType: .unknown, callStatus: .unknown, interacterUserID: "",
                  interacterUserType: .unknown, callStartTime: 0, joinTime: 0, leaveTime: 0, cancelReason: .cancel, offlineReason: .unknown)
    }
}
