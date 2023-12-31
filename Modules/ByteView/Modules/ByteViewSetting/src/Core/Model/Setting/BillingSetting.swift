//
//  BillingSetting.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/23.
//

import Foundation
import ByteViewNetwork

public struct BillingSetting: Equatable {
    var meetingType: MeetingType

    /// 需要进行倒计时展示时填入，单位是分钟，倒计时在start_time+countdown_duration时归零
    public var countdownDuration: Int32?

    /// 会议最大时长，单位是分钟
    public var maxVideochatDuration: Int32

    /// 套餐类型
    public var planType: VideoChatSettings.PlanType

    public var planTimeLimit: Int32

    // 套餐时长不够
    // 1v1不限制时长，多人会议限制套餐时长
    public var isInsufficientOfRemainingTime: Bool {
        if meetingType == .meet, let countdown = self.countdownDuration {
            return countdown > 0
        } else {
            return false
        }
    }
}
