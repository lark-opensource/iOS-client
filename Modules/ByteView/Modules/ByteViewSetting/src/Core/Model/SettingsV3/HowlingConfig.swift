//
//  HowlingConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation
import ByteViewCommon

// disable-lint: magic number
public struct HowlingConfig: Decodable, CustomStringConvertible {
    private let meetingCheck: [String: UInt]
    private let deviceCheck: [String: UInt]

    public var description: String {
        "HowlingConfig(meetingCheck: \(meetingCheck), deviceCheck: \(deviceCheck))"
    }

    /// e.g 本次会议3分钟内忽略2次
    public var meetingMinute: UInt { meetingCheck[Keys.minutePeriod, default: 3] }
    public var meetingIgnoreCount: UInt { meetingCheck[Keys.maxIgnoreCount, default: 2] }
    /// e.g 下次弹窗距离上次忽略时间不小于15秒
    public var meetingSecond: UInt { meetingCheck[Keys.secondInterval, default: 15] }

    /// e.g 该设备7天内忽略10次 则30天内不弹窗
    public var deviceIgnoreCount: UInt { deviceCheck[Keys.maxIgnoreCount, default: 10] }
    public var deviceDay: UInt { deviceCheck[Keys.dayPeriod, default: 7] }
    public var deviceNoWarnDay: UInt { deviceCheck[Keys.noWarnDay, default: 30] }

    private enum Keys {
        static let maxIgnoreCount = "max_ignore_count"
        static let minutePeriod = "minute_period"
        static let dayPeriod = "day_period"
        static let noWarnDay = "no_warn_day"
        static let secondInterval = "second_interval"
    }

    static let `default` = HowlingConfig(meetingCheck: [Keys.maxIgnoreCount: 2, Keys.minutePeriod: 3, Keys.secondInterval: 15],
                                         deviceCheck: [Keys.maxIgnoreCount: 10, Keys.dayPeriod: 10, Keys.noWarnDay: 30])
}
