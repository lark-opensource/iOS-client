//
//  LKApplicationBadge.swift
//  LarkUIKit
//
//  Created by kongkaikai on 2023/4/18.
//
// 这个文件是使用 swift 重写了OC实现以便做纯swift的构建，如有问题请联系原作者 Supeng

import Foundation
import UIKit

private var isDebuggedBySysctlCache: Bool? = nil

public enum LKApplicationBadge {
    private static func isDebuggedBySysctl() -> Bool {
        if let result = isDebuggedBySysctlCache { return result }

        var info = kinfo_proc()
        var infoSize = MemoryLayout.size(ofValue: info)
        info.kp_proc.p_flag = 0

        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        if sysctl(&mib, 4, &info, &infoSize, nil, 0) == -1 {
            isDebuggedBySysctlCache = false
            return false
        }

        let result = info.kp_proc.p_flag & P_TRACED != 0
        isDebuggedBySysctlCache = result

        return result
    }

    private static func unavailableiOS12() -> Bool {
        if #unavailable(iOS 12.0) {
            return true
        }
        return false
    }

    public static func requestNumber(_ callback: @escaping (Int) -> Void) {
        if isDebuggedBySysctl() || unavailableiOS12() {
            // Sync
            // In DEBUG environment, we should not let Main Thread Checker report this method
            callback(UIApplication.shared.applicationIconBadgeNumber)
            return
        }

        DispatchQueue.global().async {
            let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
            DispatchQueue.main.async {
                callback(badgeNumber)
            }
        }
    }

    public static func setApplicationBadgeNumber(
        _ badgeNumber: Int,
        callback: @escaping () -> Void
    ) {

        if TARGET_OS_SIMULATOR != 0 || isDebuggedBySysctl() || unavailableiOS12() {
            // 1. CI上的单测case使用xctest命令执行的，并不是启动Xcode -> 启动模拟器，此时严格要求主线程执行UI操作
            // 2. Sync. In DEBUG environment, we should not let Main Thread Checker report this method
            // 3. Sync.
            UIApplication.shared.applicationIconBadgeNumber = badgeNumber
            callback()
            return
        }

        DispatchQueue.global().async {
            UIApplication.shared.applicationIconBadgeNumber = badgeNumber
            DispatchQueue.main.async {
                callback()
            }
        }
    }
}
