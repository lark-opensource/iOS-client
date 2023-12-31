//
//  PreloadTask.swift
//  Lark
//
//  Created by huanglx on 2023/1/17.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import QuartzCore

/// Task 唯一标识¨
public typealias TaskIdentify = String
// 具体任务
public typealias TaskAction = () -> Void
// 回调task状态
public typealias TaskStateCallBack = (TaskState) -> Void
// 回调taskId
public typealias TaskIdCallBack = (TaskIdentify) -> Void

/// 任务执行的队列，默认主队列
public enum Scheduler {
    case async       // 子队列，串行, 默认
    case concurrent  // 多线程
    case main        // 主队列
}

enum TaskType {
    case normalType  //常规类型
    case registType  //注册类型
}

/// 任务作用域，用于切租户场景
public enum TaskScope {
    case user      // 用户级别，登出不执行
    case container // 容器级别，确保执行
}

/// 执行状态
public enum TaskState: String {
    case unStart            //未开始
    case await              // 待执行
    case start              // 开始调度（放到具体线程中执行）
    case run                // 执行任务
    case end                // 执行完毕，开始下一任务
    case cancel             // 取消任务
    case disableByLowDevice //低端机被禁用
    case disableByHitRate   //命中率低被禁用，可以主动触发执行。
}

/// 优先级
public enum PreloadPriority: Int {
    case low = 1        //低优先级
    case middle = 2     //中优先级
    case hight = 3      //高优先级
}

///等级变更类型
enum PriporityChangeType: String {
    case noChange               //没有改变
    case cancelBySampling       //被采样取消预加载
    case cancelByFeedbackCount  //因使用频次低取消预加载
    case cancelByLowHitRate     //因命中率低被取消
    case upToHight              //升到最高
    case downToLow              //降到最低
}

/// 所属业务
public enum PreloadBiz: String {
    case unKnown    //未知
    case Common     //通用的
    case UG
    case Search
    case Todo
    case VC
    case Minutes
    case CCM
    case OpenPlatform
    case Mail
    case Passport
    case Meego
    case Feed
    case Chat
    case Calendar
    case ClodStart
}

/// 预加载类型
public enum PreloadType: String {
    case OtherType              //其它
    case DocsType               //文档类型
    case ImageType              //图片类型
    case SDKType                //SDK初始化类型
    case DataType               //数据类型
    case BootTaskType           //启动任务类型
    case BootManagerConcurrent  //启动框架触发的异步并发任务
    case BootManagerAsync       //启动框架触发的异步串行任务
    case RunloopToolsType       //runlooptools触发的任务
}

/// 添加到调度队列时机
public enum PreloadMoment: String {
    case none               //默认
    case runloopIdle        //runloop闲时
    case viewDidAppear      //页面显示
    case Click              //点击
    case stopScroll         //停止滚动
    case cpuIdle            //cpu闲时
    case startOneMinute     //启动一分钟
}

//预加载任务
open class PreloadTask {
    //优先级，默认优先级中
    var priority: PreloadPriority = .middle
    //调度线程，默认子线程串行
    var scheduler: Scheduler = .async
    //作用域,默认全局
    var scope: TaskScope = .user
    // 任务的唯一标识-框架自动生成。
    var identify: TaskIdentify = PreloadTask.uIdentify()
    //具体任务
    var taskAction: TaskAction
    //回调task状态
    var stateCallBack: TaskStateCallBack?
    //场景
    var biz: PreloadBiz = .unKnown
    //预加载类型
    var preloadType: PreloadType = .OtherType
    //预处理名称
    var preloadName: String = ""
    //预加载时机
    var preloadMoment: PreloadMoment = PreloadMoment.none
    //任务类型
    var taskType: TaskType = .normalType
    //低端机是否可用
    var lowDeviceEnable: Bool = true
    //是否被丢弃
    var isCancelByHit: Bool = false
    var isCancelByLowDevice: Bool = false
    //是否被降级
    var priporityChangeType: PriporityChangeType = .noChange
    //是否有命中反馈
    var hasFeedback: Bool = true
    
    // App生命周期，是否只执行一次
    var runOnlyOnce: Bool = false
    // User生命周期，是否只执行一次
    var runOnlyOnceInUserScope: Bool = false

    //是否磁盘缓存
    var diskCache: Bool = false
    //磁盘缓存id - 用于磁盘缓存情况下本地统计命中率
    var diskCacheId: String?
    
    init(scope: TaskScope, taskAction: @escaping TaskAction, scheduler: Scheduler, biz: PreloadBiz, preloadType: PreloadType, stateCallBack: TaskStateCallBack?, preloadName: String, preloadMoment: PreloadMoment, lowDeviceEnable: Bool, diskCacheId: String?, hasFeedback: Bool, priority: PreloadPriority) {
        self.scope = scope
        self.taskAction = taskAction
        self.scheduler = scheduler
        self.biz = biz
        self.preloadType = preloadType
        self.stateCallBack = stateCallBack
        self.preloadName = preloadName
        self.preloadMoment = preloadMoment
        self.lowDeviceEnable = lowDeviceEnable
        self.diskCacheId = diskCacheId
        self.hasFeedback = hasFeedback
        self.priority = priority
    }
    
    ///执行任务
    func exec() {
        guard self.state == .await || self.state == .unStart || self.state == .start else { return }
        PreloadTracker.trackPreloadRun(preloadId: self.identify)
        let start = CACurrentMediaTime()
        self.state = .run
        self.taskAction()
        self.state = .end
        let timeCost = CACurrentMediaTime() - start
        PreloadTracker.trackPreloadSuccess(preloadId: self.identify, timeCost: timeCost)
    }
    
    ///task状态
    var state: TaskState = .unStart {
        didSet {
            guard oldValue != state else { return }
            //回调当前task的状态
            if let stateCallBack = self.stateCallBack {
                stateCallBack(state)
            }
        }
    }
    
    ///获取taskId
    @inline(__always)
    private static var bucket: Int32 = 0
    private static func uIdentify() -> String {
        return String(OSAtomicIncrement32(&bucket) & Int32.max)
    }
}

extension PreloadTask: CustomStringConvertible {
    public var description: String {
        return "priority:\(priority) - name:\(preloadName) -scheduler: \(scheduler) -diskCache: \(diskCache)"
    }
}

