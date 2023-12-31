//
//  OpenSecurityHelper.swift
//  OPPlugin
//
//  Created by laisanpin on 2022/1/4.
//  反作弊工具类; 后续的业务逻辑会在该类中实现而不是耦合在plugin中;

import Foundation

public final class OpenSecurityHelper: NSObject {
    /// 是否越狱
    public static func isCracked() -> Bool {
        return UIDevice.current.isIllegal
    }

    /// 是否为模拟器
    public static func isEmulator() -> Bool {
        return UIDevice.current.isSimulator
    }

    /// 是否为debug环境
    public static func isDebug() -> Bool {
        return UIDevice.current.isDebug
    }

    /// 时间戳(单位: ms)
    public static func timestamp() -> NSNumber {
        return NSNumber(value: Int(Date().timeIntervalSince1970 * 1000))
    }
}
