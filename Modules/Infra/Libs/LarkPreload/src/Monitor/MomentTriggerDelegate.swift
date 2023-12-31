//
//  MomentTriggerDelegate.swift
//  LarkPreload
//
//  Created by huanglx on 2023/3/19.
//

import Foundation

/// 触发时机代理
public protocol MomentTriggerDelegate: AnyObject {
    //触发时机
    func momentTriggerType() -> PreloadMoment

    //开始触发时机监控
    func startMomentTriggerMonitor()

    //移除触发时机监控
    func removeMomentTriggerMonitor()

    //设置监听者
    var reciever: MomentTriggerCallBackDelegate? { get set }

    //是否正在监听注册任务触发时机
    var isMonitorRegister: Bool { get set }
}

///注册任务触发时机回调代理
public protocol MomentTriggerCallBackDelegate: AnyObject {
    ///返回添加调度队列时机
    func callbackMonent(moment: PreloadMoment)
}

extension MomentTriggerDelegate {
    //移除触发时机监控
    func removeMomentTriggerMonitor() {}
}
