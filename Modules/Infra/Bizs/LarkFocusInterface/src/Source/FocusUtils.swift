//
//  Utils.swift
//  LarkFocusInterface
//
//  Created by 白镜吾 on 2023/1/8.
//

import Foundation
import LarkSDKInterface
import LarkContainer

public final class FocusUtils {
    // MARK: - Singleton

    private init() {}

    /// 单例
    public private(set) static var shared: FocusUtils = FocusUtils()

    // MARK: - TimeService

    @InjectedOptional
    private var timeService: ServerNTPTimeService?

    /// 当前服务器 UNIX 标准时间戳，单位 s
    public var currentServerTime: Int64 {
        return timeService?.serverTime ?? Int64(Date().timeIntervalSince1970)
    }

    /// 将本地时间戳转换为服务器时间戳，单位 s
    /// - Parameter time: 本地 UNIX 标准时间戳
    /// - Returns: 服务器 UNIX 标准时间戳
    public func getRelatedServerTime(asLocal time: Date) -> Int64 {
        let timeDifference = time.timeIntervalSince(Date())
        return currentServerTime + Int64(timeDifference)
    }

    /// 将服务器时间戳转换为本地时间戳，单位 s
    /// - Parameter time: 服务器 UNIX 标准时间戳
    /// - Returns: 本地 UNIX 标准时间戳
    public func getRelatedLocalTime(asServer time: Int64) -> Date {
        let timeDifference = ceil(TimeInterval(time - currentServerTime))
        return Date(timeIntervalSinceNow: timeDifference)
    }

}
