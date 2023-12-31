//
//  ExitMonitorStrategyConsts.swift
//  Timor
//
//  Created by changrong on 2020/10/16.
//

import Foundation

@objcMembers
open class ExitMonitorStrategyConsts: NSObject {
    /// 白点的比例（如 1/1000 为1000个点有1个为白点）
    public static let blankRate = "blank_rate"
    /// 透明点的比例 （如 1/1000 为1000个点有1个为透明点）
    public static let lucency = "lucency"
    /// 非正常关闭的次数 （如 3 为3次非正常退出的次数）
    public static let closeCount = "close_count"
    
    public static let maxPureColor = "maxPureColor"

    public static let maxPureColorRate = "maxPureColorRate"

}
