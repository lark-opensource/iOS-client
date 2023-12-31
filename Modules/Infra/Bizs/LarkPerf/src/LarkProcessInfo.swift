//
//  LarkProcessInfo.swift
//  LarkPerf
//
//  Created by KT on 2020/6/23.
//

import UIKit
import Foundation

/// Lark进程相关
public final class LarkProcessInfo {
    /// main函数执行时间
    public static var mainStartTime: CFTimeInterval?
    /// 是否是preWarm
    public static var isPreWarm: Bool = false
    /**
     进程创建的时间：CACurrentMediaTime
     可以直接获得距离进程创建的绝对时间：CACurrentMediaTime()*1000 - processStartTime
     精确到ms
      之所以切换为func的原因是因为iOS15之后processStartTime不准确
     */
    public static func processStartTime() -> CFTimeInterval {
        if #available(iOS 15.0, *),
           let mainStartTime = Self.mainStartTime,
           LarkProcessInfoPrivate.getWillFinishLaunchTime() - mainStartTime > 1 {
            return LarkProcessInfoPrivate.getWillFinishLaunchTime() * 1_000
        } else {
            // 系统获取的进程创建时间戳
            let since1970 = LarkProcessInfoPrivate.processStartTime()
            // 当前时间戳
            let currentDate = NSDate().timeIntervalSince1970 * 1_000
            let interval = currentDate - since1970
            // QuartzCore时间
            let currentQuartzCoreTime = CACurrentMediaTime() * 1_000
            return currentQuartzCoreTime - interval
        }
    }
    /**
     由于iOS 15.4 又更改了prewarm时机，
     之前在processStartTime的判断失效了，需要做二次check，暂定main到进程创建超过5s(参考main线上P99小于2s)
     */
    public static func doubleCheckPreWarm() {
        if #available(iOS 15.4, *) {
            if (CACurrentMediaTime() * 1_000 - Self.processStartTime()) > 5_000 {
                Self.isPreWarm = true
            } else {
                Self.isPreWarm = false
            }
        } else {
            Self.isPreWarm = false
        }
    }
    /**
     距离进程创建的时间
     精确到ms
     */
    public static func sinceStart() -> CFTimeInterval {
        if Self.isPreWarm {
            return (CACurrentMediaTime() - (Self.mainStartTime ?? 0)) * 1_000
        } else {
            return CACurrentMediaTime() * 1_000 - Self.processStartTime()
        }
    }
}
