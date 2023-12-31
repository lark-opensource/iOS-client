//
//  MailConstants.swift
//  MailSDK
//
//  Created by raozhongtao on 2023/2/24.
//

import Foundation
/// 时间常用的常量
enum timeIntvl {
    
    ///极短间隔 0.1s 单位： 秒
    static let ultraShort: Double = 0.1
    
    ///极短间隔 100ms 单位： 毫秒秒
    static let ultraShortMili: Int = 100
    
    /// animate with Duration 常用间隔 0.2s
    static let uiAnimateNormal: Double = 0.2

    static let transitioAnimateNormal: Double = 0.25

    /// 短间隔 0.3 s 单位：秒
    /// 常用于延迟显示VC、等待其他代码执行等；
    static let short: Double = 0.3
    
    /// 短间隔 300 ms 单位：毫秒；
    /// 常用于延迟显示VC、等待其他代码执行等；
    static let shortMili: Int = 300
    
    /// 常规间隔 0.5s 单位：秒
    /// 常用于延迟显示Toast、Alert窗口等；
    static let normal: Double = 0.5
    
    /// 常规间隔 500ms 单位：毫秒
    /// 常用于延迟显示Toast、Alert窗口等；
    static let normalMili: Int = 500
    
    /// 长间隔 0.8s 单位：秒
    static let large: Double = 0.8
        
    /// 长间隔 800ms 单位：毫秒
    static let largeMili: Int = 800

    /// 常规延时 3s 单位： 秒
    static let normalSecond: Int = 3

    /// 长延时 30s 单位：秒
    static let largeSecond: Int = 30

    /// toast 默认消失时间 1.5s 单位：秒
    static let toastDismiss: Double = 1.5

    /// folder press 默认消失时间 2s 单位：秒
    static let pressDismiss: Int = 2
}

enum Const {
    
    /// 附件有效期15天
    static let attachExpireDay: Int64 = 15

    /// 位于 view 高度 2/3 以下时，popover 显示到上方
    static let popoverShowFactor: CGFloat = 2 / 3
}

