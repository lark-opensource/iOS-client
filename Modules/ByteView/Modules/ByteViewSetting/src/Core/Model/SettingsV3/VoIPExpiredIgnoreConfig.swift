//
//  VoIPExpiredIgnoreConfig.swift
//  ByteViewSetting
//
//  Created by shin on 2023/11/13.
//

import Foundation

public struct VoIPExpiredIgnoreConfig: Decodable {
    /// 是否启用忽略策略
    public let enabled: Bool
    /// 过期时间，单位为分钟
    public let expiredMinutes: Int
    /// 忽略次数
    public let ignoreCount: Int
    /// 忽略周期，单位为天
    public let ignorePeriod: Int

    static let `default` = VoIPExpiredIgnoreConfig(enabled: false, expiredMinutes: 0, ignoreCount: 0, ignorePeriod: 0)

    /// 是否有效配置
    public var isValid: Bool {
        return enabled && expiredMinutes > 0 && ignoreCount > 0 && ignorePeriod > 0
    }

    /// 过期时间间隔，单位秒
    public var expiredInterval: TimeInterval {
        return TimeInterval(expiredMinutes * 60)
    }
}

public struct VoIPExpiredIgnoreRecord: Codable {
    /// 记录最后忽略的本地时间
    public let records: [TimeInterval]

    public init(records: [TimeInterval]) {
        self.records = records
    }
}

public struct DeviceNtpTimeRecord: Codable {
    /// 通过 ntp 接口获取到的 ntp 时间与本地时间的偏移量，单位 ms
    public var ntpOffset: Int64
    /// 系统自启动计时时间戳和当前本地时间的偏移量，单位 s
    public var systemOffset: UInt64

    public init(ntpOffset: Int64) {
        self.ntpOffset = ntpOffset
        let boottime = Self.systemBoottime()
        let now = UInt64(Date().timeIntervalSince1970)
        self.systemOffset = now - boottime
    }

    /// 系统启动到当前时间（包含系统休眠），单位秒。
    ///
    /// 获取系统自启动开始的单调递增的时钟时间，并将原始纳秒转换成秒，可以参考：
    /// https://developer.apple.com/documentation/kernel/1646199-mach_continuous_time
    /// - Returns: 系统启动后单调递增的时间
    public static func systemBoottime() -> UInt64 {
        // 纳秒转换成秒
        // nolint-next-line: magic number
        return clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) / 1_000_000_000
    }

    /// 当前设备未修改本地时间
    ///
    /// 如果设备重启了，第一次也会被认为修改了时间，因为系统启动时间被重置了；
    /// - Returns: true: 当前设备未修改本地时间；false: 反之。
    public func deviceTimeNotChange() -> Bool {
        // 系统启动时间
        let boottime = Self.systemBoottime()
        let now = UInt64(Date().timeIntervalSince1970)
        let nowOffset = now - boottime
        // 本地时间与系统启动时间差在 10s 内
        let offset = max(nowOffset, systemOffset) - min(nowOffset, systemOffset)
        return offset < 10
    }

    /// 根据 ntp 时间偏移量及当前设备时间是否更改计算出来的 ntp 时间
    ///
    ///  存在误差，可以作参考，精准时间请使用 GetNtpTimeRequest 获取
    /// - Returns: date: 不为空时为本地计算的 ntp 时间，nil 则表示无法计算；
    public func deviceNtpDate() -> Date? {
        guard deviceTimeNotChange() else { return nil }
        let timeInterval = Date().timeIntervalSince1970
        return Date(timeIntervalSince1970: timeInterval + TimeInterval(ntpOffset / 1_000))
    }
}
