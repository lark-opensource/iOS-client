//
//  PreloadDiskCacheModel.swift
//  LarkPreload
//
//  Created by huanglx on 2023/6/20.
//

import Foundation
import LarkStorage

/// 预处理埋点信息
class PreloadTrackerInfo {
    //优先级，默认优先级中
    var priority: PreloadPriority = .middle
    //调度线程，默认主线程
    var scheduler: Scheduler = .async
    //任务的唯一标识
    var identify: TaskIdentify
    //场景
    var biz: PreloadBiz = .unKnown
    //预加载类型
    var preloadType: PreloadType = .OtherType
    //预处理名称
    var preloadName: String = ""
    //预加载时机
    var moment: PreloadMoment? = Optional.none
    //Trigger时间
    var triggerTime: TimeInterval
    //任务状态
    var taskState: TaskState = .unStart
    //任务作用域
    var scope: TaskScope = .user
    //优先级变更类型
    var priporityChangeType: PriporityChangeType = .noChange
    //是否命中
    var isHit: Bool = false
    //是否因为低端机被禁用
    var isCancelByLowDevice: Bool = false
    //任务类型
    var taskType: TaskType = .normalType
    //磁盘缓存id
    var diskCacheId: String?
    //历史业务功能命中率
    var bizTypeHitRate: Double?
    //历史入口命中率
    var entranceHitRate: Double?
    //获取预加载频次
    var feedbackCount: Double?
    //业务命中率精度
    var bizTypePrecision: Double?
    //入口命中率精度
    var entrancePrecision: Double?
    //等待调度时长
    var waitScheduleInterval: TimeInterval?
    //等待执行时长
    var waitRunInterval: TimeInterval?
    //执行时长
    var executeCost: TimeInterval?
    //命中时长
    var hitInterval: TimeInterval?
    //是否有命中反馈
    var hasFeedback: Bool = true
    
    ///磁盘缓存相关
    //创建时间戳
    var createTime: TimeInterval = NSDate().timeIntervalSince1970
    //是否磁盘缓存
    var diskCache: Bool = false
    
    init(identify: String) {
        self.identify = identify
        self.triggerTime = CACurrentMediaTime()
    }
}

//MARK: 磁盘缓存持久化Model
///磁盘缓存预处理信息
struct PreloadDiskCacheInfo: Codable {
    //预处理名称
    var preloadName: String
    //预处理所属业务
    var preloadBiz: String
    //预处理类型
    var preloadType: String
    //创建时间戳
    var createTime: TimeInterval = NSDate().timeIntervalSince1970
    //是否命中
    var isHit: Bool = false
    init(preloadName: String, preloadBiz: String, preloadType: String) {
        self.preloadName = preloadName
        self.preloadBiz = preloadBiz
        self.preloadType = preloadType
    }
}

extension PreloadDiskCacheInfo: KVNonOptionalValue {
    public typealias StoreWrapped = Self
}

//MARK: 内存缓存持久化model
struct PreloadMemeoryCacheInfo: Codable {
    //预处理名称
    var preloadName: String
    //预处理所属业务
    var preloadBiz: String
    //预处理类型
    var preloadType: String
    //添加预处理个数
    var addPreloadCount: Int = 0
    //命中预处理个数
    var hitPreloadCount: Int = 0
    //历史添加预处理数
    var historyAddPreloadCount: Int = 0
    //历史命中预处理个数
    var historyHitPreloadCount: Int = 0
    //创建时间戳
    var createTime: TimeInterval = NSDate().timeIntervalSince1970
    init(preloadName: String, addPreloadCount: Int, hitPreloadCount: Int,  preloadBiz: String, preloadType: String) {
        self.preloadName = preloadName
        self.addPreloadCount = addPreloadCount
        self.hitPreloadCount = hitPreloadCount
        self.preloadBiz = preloadBiz
        self.preloadType = preloadType
    }
}

extension PreloadMemeoryCacheInfo: KVNonOptionalValue {
    public typealias StoreWrapped = Self
}
