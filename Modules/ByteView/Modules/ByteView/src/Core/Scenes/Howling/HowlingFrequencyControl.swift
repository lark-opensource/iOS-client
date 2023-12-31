//
//  HowlingFrequencyControl.swift
//  ByteView
//
//  Created by wulv on 2021/8/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewSetting

/// 啸叫提醒频率控制
/// https://bytedance.feishu.cn/docs/doccnwLfLqXsZ02zajPRt7i70vb#
struct HowlingFrequencyControl {

    private struct MeetingCondition {
        let count: UInt
        let minute: UInt
        let second: UInt
    }

    private struct DeviceCondition {
        let count: UInt
        let day: UInt
        let noDay: UInt
    }

    let db: HowlingDatabase
    init(howlingConfig: HowlingConfig, db: HowlingDatabase) {
        self.db = db
        self.meetingCondition = MeetingCondition(count: howlingConfig.meetingIgnoreCount,
                                                 minute: howlingConfig.meetingMinute,
                                                 second: howlingConfig.meetingSecond)
        self.deviceCondition = DeviceCondition(count: howlingConfig.deviceIgnoreCount,
                                               day: howlingConfig.deviceDay,
                                               noDay: howlingConfig.deviceNoWarnDay)
    }

    /// appSettings配置
    private let meetingCondition: MeetingCondition
    private let deviceCondition: DeviceCondition

    /// 本次会议A分钟内首次忽略时刻（A分钟来自AppSettings配置）
    private var ignoreTime: TimeInterval?
    /// 本次会议连续忽略次数
    private var ignoreCount: UInt = 0
    /// 当前时间戳
    private var currentTime: TimeInterval {
        Date().timeIntervalSince1970
    }
    /// 当前日期零点的时间戳
    private var currentDay: TimeInterval {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let date = Calendar.current.date(from: components) ?? Date()
        return date.timeIntervalSince1970
    }
    /// 上次忽略时刻
    private var lastIgnoreTime: TimeInterval?

    private var ignoreTimeAllowed: Bool {
        if let time = lastIgnoreTime, !moreThanMinIgnoreSecond(time, now: currentTime) {
            return false
        }
        return true
    }

    private lazy var ignoreCountAllowed: Bool = {
        guard lessThanMeetingMaxIgnoreCount(0) else {
            return false
        }
        let day = currentDay
        if let localFirstNoWarnDate = db.firstNoWarnDate() {
            if satisfyDeviceNoWarn(localFirstNoWarnDate, current: day) {
                return false
            } else {
                clearDeviceLocalIgnore()
                return true
            }
        } else {
            if let localFirstIgnoreDate = db.firstIgnoreDate() {
                if isInDeviceIgnorePeriod(localFirstIgnoreDate, current: day) {
                    if let localTotalIgnoreCount = db.totalIgnoreCount() {
                        if lessThanDeviceMaxIgnoreCount(localTotalIgnoreCount) {
                            return true
                        } else {
                            db.updateFirstNoWarnDate(day)
                            return false
                        }
                    } else {
                        // 不合预期
                        Logger.howling.error("no local ignore count, but has local first ignore date")
                        // 兜底
                        let countForError: UInt = 1
                        db.updateTotalIgnoreCount(countForError)
                        if lessThanDeviceMaxIgnoreCount(countForError) {
                            return true
                        } else {
                            db.updateFirstNoWarnDate(day)
                            return false
                        }
                    }
                } else {
                    clearDeviceLocalIgnore()
                    return true
                }
            } else {
                return true
            }
        }
    }()

    mutating func handleIgnore() {
        // 判断会议维度的条件是否满足
        var meetingAllowed: Bool = true
        let time = currentTime
        if let firstIgnoreTime = ignoreTime,
           isInMeetingIgnorePeriod(firstIgnoreTime, now: time) {
            ignoreCount += 1
        } else {
            ignoreCount = 1
            ignoreTime = time
        }
        if !lessThanMeetingMaxIgnoreCount(ignoreCount) {
            meetingAllowed = false
        }
        lastIgnoreTime = time // 记录忽略时刻

        // 判断设备维度的条件是否满足
        var deviceAllowed: Bool = true
        let day = currentDay
        var localTotalCount = db.totalIgnoreCount() ?? 0
        if let localFirstIgnoreDate = db.firstIgnoreDate(),
           isInDeviceIgnorePeriod(localFirstIgnoreDate, current: day) {
            localTotalCount += 1
        } else {
            db.updateFirstIgnoreDate(day)
            localTotalCount = 1
        }
        db.updateTotalIgnoreCount(localTotalCount)
        if !lessThanDeviceMaxIgnoreCount(localTotalCount) {
            db.updateFirstNoWarnDate(day)
            deviceAllowed = false
        }

        ignoreCountAllowed = meetingAllowed && deviceAllowed
        Logger.howling.info("ignoreTime = \(time), ignoreCount = \(ignoreCount), localTotalCount = \(localTotalCount)")
    }

    mutating func handleMute() {
        clearMeetingIgnore()
        if !lessThanMeetingMaxIgnoreCount(ignoreCount) {
            ignoreCountAllowed = false
        }
    }

    /// 是否满足提醒条件
    mutating func allowWarn() -> Bool {
        return ignoreTimeAllowed && ignoreCountAllowed
    }
}

// MARK: - 设备维度的条件
extension HowlingFrequencyControl {

    fileprivate func clearDeviceLocalIgnore() {
        db.clearAll()
    }

    fileprivate func satisfyDeviceNoWarn(_ firstNoWarnDay: TimeInterval, current: TimeInterval) -> Bool {
        return (current - firstNoWarnDay) <= Double(deviceCondition.noDay * 24 * 60 * 60)
    }

    fileprivate func isInDeviceIgnorePeriod(_ firstIgnoreDay: TimeInterval, current: TimeInterval) -> Bool {
        return (current - firstIgnoreDay) <= Double(deviceCondition.day * 24 * 60 * 60)
    }

    fileprivate func lessThanDeviceMaxIgnoreCount(_ count: UInt) -> Bool {
        return count < deviceCondition.count
    }
}

// MARK: - 会议维度的条件
extension HowlingFrequencyControl {

    fileprivate mutating func clearMeetingIgnore() {
        ignoreTime = nil
        ignoreCount = 0
    }

    fileprivate func lessThanMeetingMaxIgnoreCount(_ current: UInt) -> Bool {
        return current < meetingCondition.count
    }

    fileprivate func isInMeetingIgnorePeriod(_ last: TimeInterval, now: TimeInterval) -> Bool {
        return (now - last) <= Double(meetingCondition.minute * 60)
    }

    fileprivate func moreThanMinIgnoreSecond(_ last: TimeInterval, now: TimeInterval) -> Bool {
        return (now - last) > Double(meetingCondition.second)
    }
}
