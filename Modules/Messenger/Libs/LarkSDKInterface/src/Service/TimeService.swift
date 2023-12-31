//
//  TimeService.swift
//  LarkSDKInterface
//
//  Created by 李晨 on 2019/12/29.
//

import Foundation
import RxSwift
import RxCocoa

public protocol ServerNTPTimeService {
    /// 定时器
    var burnTimer: Observable<Int64> { get }

    /// 当前服务器时间 单位s
    var serverTime: Int64 { get }

    /// 是否在服务器时间之后 单位ms
    func afterThatServerTime(time: Int64) -> Bool
}

public protocol TimeFormatSettingService {
    var is24HourTime: Bool { get set }
}
