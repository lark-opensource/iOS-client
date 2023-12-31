//
//  LocalRecordSettings.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2023/3/17.
//

import Foundation

/// 本地录制设置
public struct LocalRecordSettings: Equatable {

    /// 本地录制申请状态
    public var localRecordHandsStatus: ParticipantHandsStatus

    /// 正在本地录制
    public var isLocalRecording: Bool

    /// 参会人具有本地录制权限
    public var hasLocalRecordAuthority: Bool

    /// 申请本地录制的时间
    public var localRecordHandsUpTime: Int64
}
