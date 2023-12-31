//
//  PreloadTracker.swift
//  Lark
//
//  Created by huanglx on 2023/2/6.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsTracker
import ThreadSafeDataStructure
import LarkStorage
import LKCommonsLogging

/*
    预处理埋点-https://bytedance.feishu.cn/wiki/B6UEw78TzixieTkyRm0chGiRn6b
        1- 预处理埋点上报。
        2- 预处理命中率本地计算
            2-1：内存缓存的命中率本地计算。入口维度 & 业务功能
            2-2：磁盘缓存的命中率本地计算。入口维度 & 业务功能
 */
final class PreloadTracker {
    //存放预处理埋点信息
    static private var trackInfoMap: SafeDictionary<String, PreloadTrackerInfo> = [:] + .readWriteLock
    //内存缓存预处理的name
    static private var memoryCacheNameArray: SafeArray<String> = [] + .readWriteLock
    //是否同步过缓存-每次生命周期第一次添加预加载任务时同步
    static private var hasSynchCache: Bool = false
    
    //存放当前生命周期磁盘预处理埋点信息
    static private var diskCacheTrackInfoMap: SafeDictionary<String, PreloadDiskCacheInfo> = [:] + .readWriteLock
    
    //存放历史磁盘预处理埋点信息
    static private var historyDiskCacheTrackInfoMap: SafeDictionary<String, PreloadDiskCacheInfo> = [:] + .readWriteLock
    
    //存放内存缓存历史添加和命中信息
    static private var historyMemeoryCacheInfos: SafeDictionary<String, PreloadMemeoryCacheInfo> = [:] + .readWriteLock
    
    //磁盘缓存的预处理key
    static private let diskCacheTempTrackInfoKey = "preload_diskCacheTempTrackInfoKey"
    //历史磁盘缓存的预处理key
    static private let historyDiskCacheTrackInfoKey = "preload_historyDiskCacheTrackInfoKey"
    //内存缓存命中率持久化key
    static private let historyMemoryCacheInfoKey = "preload_historyMemoryCacheInfoKey"
   
    //磁盘缓存命中率
    //-入口命中率-[名称:(命中率, 精度, 业务依赖度)]
    static var diskCacheHitRate: SafeDictionary<String, (Double, Double, Double)> = [:] + .readWriteLock
    //-业务功能命中率-[业务:[功能:(命中率,精度)]]
    static var diskCacheBizTypeHitRate: SafeDictionary<String, [String : (Double, Double)]> = [:] + .readWriteLock
    
    //内存缓存命中率
    //-入口命中率-[名称:(命中率,精度,业务依赖度)]]
    static var memoryCacheHitRate: SafeDictionary<String, (Double, Double, Double)> = [:] + .readWriteLock
    //-业务功能命中率-[业务:[功能:(命中率,精度)]]
    static var memoryCacheBizTypeHitRate: SafeDictionary<String, [String : (Double, Double)]> = [:] + .readWriteLock
    
    //磁盘缓存id和预加载id映射
    static var preloadIdKVs: SafeDictionary<String, TaskIdentify> = [:] + .readWriteLock
    
    //第一次预加载的时间
    static var startPreloadTrackerTime: TimeInterval = CACurrentMediaTime()
    
    private static var logger = Logger.log(PreloadTaskQueue.self)
    private static var store = KVStores.udkv(space: .global, domain: Domain.biz.core)
    
    //添加预处理的个数以100的个数作为精度度量，精度越高可信度越高。
    private static var precision: Double = 100
    
    //MARK: 埋点统计
    //注册预加载任务
    static func trackPreloadRegist(preloadName: String,
                                   priority: PreloadPriority,
                                   preloadId: String,
                                   biz: PreloadBiz,
                                   preloadType: PreloadType,
                                   moment: PreloadMoment? = PreloadMoment.none) {
        let trackerInfo = PreloadTrackerInfo(identify: preloadId)
        trackerInfo.preloadName = preloadName
        trackerInfo.biz = biz
        trackerInfo.preloadType = preloadType
        trackerInfo.moment = moment
        trackerInfo.priority = priority
        trackerInfo.identify = preloadId
        trackerInfo.taskState = .unStart
        trackerInfo.taskType = .registType
        self.trackInfoMap[preloadId] = trackerInfo
    }
    
    // 添加任务到调度队列
    static func trackPreloadAwaitExecute(preloadName: String,
                                         priority: PreloadPriority,
                                         priporityChangeType: PriporityChangeType,
                                         preloadId: String,
                                         diskCache: Bool,
                                         cacheId: String?,
                                         bizTypeHitRate: Double?,
                                         entranceHitRate: Double?,
                                         feedbackCount: Double?,
                                         bizTypePrecision: Double?,
                                         entrancePrecision: Double?,
                                         entranceDependValue: Double?,
                                         biz: PreloadBiz,
                                         preloadType: PreloadType,
                                         isCancelByLowDevice: Bool,
                                         hasFeedback: Bool,
                                         scope: TaskScope,
                                         moment: PreloadMoment? = PreloadMoment.none) {
        var taskType: TaskType = .normalType
        if let trackInfo = self.trackInfoMap[preloadId] { //如果存在，代表注册方式任务，修改任务状态
            trackInfo.taskState = .await
            taskType = .registType
            trackInfo.diskCacheId = cacheId
            trackInfo.bizTypeHitRate = bizTypeHitRate
            trackInfo.entranceHitRate = entranceHitRate
            trackInfo.feedbackCount = feedbackCount
            trackInfo.bizTypePrecision = bizTypePrecision
            trackInfo.entrancePrecision = entrancePrecision
            trackInfo.priporityChangeType = priporityChangeType
            trackInfo.isCancelByLowDevice = isCancelByLowDevice
            trackInfo.scope = scope
            trackInfo.hasFeedback = hasFeedback
        } else {
            let trackerInfo = PreloadTrackerInfo(identify: preloadId)
            trackerInfo.preloadName = preloadName
            trackerInfo.biz = biz
            trackerInfo.preloadType = preloadType
            trackerInfo.moment = moment
            trackerInfo.priority = priority
            trackerInfo.identify = preloadId
            trackerInfo.taskState = .await
            trackerInfo.diskCache = diskCache
            trackerInfo.priporityChangeType = priporityChangeType
            trackerInfo.diskCacheId = cacheId
            trackerInfo.bizTypeHitRate = bizTypeHitRate
            trackerInfo.entranceHitRate = entranceHitRate
            trackerInfo.feedbackCount = feedbackCount
            trackerInfo.bizTypePrecision = bizTypePrecision
            trackerInfo.entrancePrecision = entrancePrecision
            trackerInfo.isCancelByLowDevice = isCancelByLowDevice
            trackerInfo.scope = scope
            trackerInfo.hasFeedback = hasFeedback
            self.trackInfoMap[preloadId] = trackerInfo
        }
        //磁盘缓存数据，需要业务方添加预加载的时候制定是磁盘缓存并且提供缓存id。-仅有命中反馈的缓存
        if diskCache, let cacheId = cacheId, hasFeedback {
            self.diskCacheTrackInfoMap[cacheId] = PreloadDiskCacheInfo(preloadName: preloadName,preloadBiz: biz.rawValue, preloadType: preloadType.rawValue)
            self.preloadIdKVs[cacheId] = preloadId
        }
        //缓存内存缓存预加载name-仅有命中反馈的缓存。
        if !diskCache, hasFeedback, !self.memoryCacheNameArray.contains(preloadName) {
            self.memoryCacheNameArray.append(preloadName)
        }
        let params: [String: Any] = ["preloadName": preloadName,
                                     "biz": biz ,
                                     "preloadType": preloadType ,
                                     "moment": moment ?? PreloadMoment.none,
                                     "priority": priority.rawValue,
                                     "priporityChangeType": priporityChangeType,
                                     "isCancelByLowDevice": "\(isCancelByLowDevice)",
                                     "taskType": taskType,
                                     "userDiskCache": "\(cacheId != nil)",
                                     "diskCacheId": cacheId ?? "",
                                     "scope": scope,
                                     "hasFeedback": hasFeedback,
                                     "bizTypeHitRate": bizTypeHitRate ?? -1,
                                     "entranceHitRate": entranceHitRate ?? -1,
                                     "bizTypePrecision": bizTypePrecision ?? -1,
                                     "entrancePrecision": entrancePrecision ?? -1,
                                     "entranceDependValue": entranceDependValue ?? -1,
                                     "feedbackCount": feedbackCount ?? -1]
        Tracker.post(TeaEvent("perf_preload_addTask_dev", params: params))
        PreloadTracker.logger.info("preload_addTask_\(params)")
    }
    
    //开始调度预加载
    static func trackPreloadExecute(preloadId: String) {
        if let trackInfo = self.trackInfoMap[preloadId] {
            trackInfo.taskState = .start
            trackInfo.waitScheduleInterval = CACurrentMediaTime() - trackInfo.triggerTime
        }
    }
    
    //执行预加载-在线程中执行
    static func trackPreloadRun(preloadId: String) {
        if let trackInfo = self.trackInfoMap[preloadId] {
            trackInfo.taskState = .run
            trackInfo.waitRunInterval = CACurrentMediaTime() - trackInfo.triggerTime
        }
    }
    
    // 预加载成功
    static func trackPreloadSuccess(preloadId: String, timeCost: TimeInterval) {
        if let trackInfo = self.trackInfoMap[preloadId] {
            trackInfo.taskState = .end
            trackInfo.executeCost = timeCost
            let params: [String: Any] = ["preloadName": trackInfo.preloadName,
                                         "biz": trackInfo.biz ,
                                         "preloadType": trackInfo.preloadType ,
                                         "moment": trackInfo.moment ?? PreloadMoment.none,
                                         "priority": trackInfo.priority.rawValue,
                                         "priporityChangeType": trackInfo.priporityChangeType,
                                         "taskType": trackInfo.taskType,
                                         "userDiskCache": "\(trackInfo.diskCacheId != nil)",
                                         "diskCacheId": trackInfo.diskCacheId ?? "",
                                         "bizTypeHitRate": trackInfo.bizTypeHitRate ?? -1,
                                         "entranceHitRate": trackInfo.entranceHitRate ?? -1,
                                         "bizTypePrecision": trackInfo.bizTypePrecision ?? -1,
                                         "entrancePrecision": trackInfo.entrancePrecision ?? -1,
                                         "feedbackCount": trackInfo.feedbackCount ?? -1,
                                         "waitScheduleInterval": trackInfo.waitScheduleInterval ?? 0,
                                         "waitRunInterval": trackInfo.waitRunInterval ?? 0,
                                         "scope": trackInfo.scope,
                                         "hasFeedback": trackInfo.hasFeedback,
                                         "executeCost": trackInfo.executeCost ?? 0]
            Tracker.post(TeaEvent("perf_preload_success_dev", params: params))
            PreloadTracker.logger.info("preload_preloadSuccess_\(params)")
        }
    }
    
    //任务被跳过
    static func trackSkipTask(taskId: TaskIdentify) {
        if let trackInfo = self.trackInfoMap[taskId] {
            var skipCause: String = ""
            if trackInfo.isCancelByLowDevice {
                skipCause = "SkipTask_byLowDevice"
            }
            if trackInfo.priporityChangeType == .cancelBySampling {
                skipCause = "SkipTask_bySampling"
            }
            if trackInfo.priporityChangeType == .cancelByFeedbackCount {
                skipCause = "SkipTask_byFeedbackCount"
            }
            if trackInfo.priporityChangeType == .cancelByLowHitRate {
                skipCause = "SkipTask_byLowRite"
            }
            PreloadTracker.logger.info("preload_\(skipCause)")
        }
    }
    
    //取消预加载
    static func trackPreloadCancel(preloadId: String) {
        if let trackInfo = self.trackInfoMap[preloadId] {
            trackInfo.taskState = .cancel
            let params: [String: Any] = ["preloadName": trackInfo.preloadName,
                                         "biz": trackInfo.biz ,
                                         "preloadType": trackInfo.preloadType ,
                                         "moment": trackInfo.moment ?? PreloadMoment.none,
                                         "priority": trackInfo.priority.rawValue,
                                         "taskType": trackInfo.taskType]
            Tracker.post(TeaEvent("perf_preload_cancel_dev", params: params))
        }
    }
    
    //预加载命中-内存缓存
    static func trackPreloadHit(preloadId: String, hitPreload: Bool, diskCacheId: String? = nil) {
        if let trackInfo = self.trackInfoMap[preloadId] {
            PreloadFeedbackAnalysis.feedbackPreload(preloadName: trackInfo.preloadName, preloadBiz: trackInfo.biz, preloadType: trackInfo.preloadType)
            //对于一次预加载多次使用的情况，多次使用认为一次使用
            /*guard !trackInfo.isHit else {
                PreloadTracker.logger.info("preload_trackPreloadRepeatHit_\(trackInfo)")
                return
            }*/
            trackInfo.hitInterval = CACurrentMediaTime() - trackInfo.triggerTime
            let params: [String: Any] = ["preloadName": trackInfo.preloadName,
                                         "biz": trackInfo.biz ,
                                         "preloadType": trackInfo.preloadType,
                                         "moment": trackInfo.moment ?? PreloadMoment.none,
                                         "priority": trackInfo.priority.rawValue,
                                         "priporityChangeType": trackInfo.priporityChangeType,
                                         "taskType": trackInfo.taskType,
                                         "taskState": trackInfo.taskState,
                                         "waitScheduleInterval": trackInfo.waitScheduleInterval ?? 0,
                                         "waitRunInterval": trackInfo.waitRunInterval ?? 0,
                                         "executeCost": trackInfo.executeCost ?? 0,
                                         "hitInterval": trackInfo.hitInterval ?? 0,
                                         "userDiskCache": "\(diskCacheId != nil)",
                                         "diskCacheId": diskCacheId ?? "",
                                         "hitPreload": hitPreload,
                                         "repeatHit": trackInfo.isHit,
                                         "hasFeedback": trackInfo.hasFeedback,
                                         "bizTypeHitRate": trackInfo.bizTypeHitRate ?? -1,
                                         "entranceHitRate": trackInfo.entranceHitRate ?? -1,
                                         "feedbackCount": trackInfo.feedbackCount ?? -1,"bizTypePrecision": trackInfo.bizTypePrecision ?? -1,
                                         "entrancePrecision": trackInfo.entrancePrecision ?? -1,]
            Tracker.post(TeaEvent("perf_preload_hit_dev", params: params))
            PreloadTracker.logger.info("preload_trackPreloadHit_\(params)")
            trackInfo.isHit = true
        }
    }
    
    //同步数据
    static func synchCache() {
        //在第一次添加预加载任务时，同步磁盘缓存数据，获取预加载命中率
        if !self.hasSynchCache {
            self.hasSynchCache = true
            self.synchHistoryDiskCache()
            self.loadDiskCacheHitRate()
            self.loadMemoryCacheHitRate()
            //获取预加载反馈分析信息
            PreloadFeedbackAnalysis.loadFeedbackAnalysisInfo()
            PreloadTracker.logger.info("preload_synchCache")
        }
    }
    
    /*
     预加载命中-磁盘缓存
        -如果传入taskId说明命中当前生命周期的缓存。
        -如果没有传入taskId说明命中的是历史的磁盘缓存。
    */
    static func trackPreloadHitForDiskCache(diskCacheId: String, preloadBiz: PreloadBiz, preloadType: PreloadType, hitPreload: Bool) {
        self.synchCache()
        //上报埋点
        if let taskId = self.preloadIdKVs[diskCacheId] {//命中当前生命周期的预处理
            self.trackPreloadHit(preloadId: taskId, hitPreload: hitPreload, diskCacheId: diskCacheId)
        } else { //命中历史磁盘缓存
            var preloadName: String = ""
            if let preloadDiskCacheInfo = self.historyDiskCacheTrackInfoMap[diskCacheId] {
                let hitInterval = CACurrentMediaTime() - preloadDiskCacheInfo.createTime
                let params: [String: Any] = ["preloadName": preloadDiskCacheInfo.preloadName,
                                             "biz": preloadBiz,
                                             "preloadType": preloadType,
                                             "diskCacheId": diskCacheId,
                                             "hitPreload": hitPreload,
                                             "hitInterval": hitInterval,
                                             "repeatHit": preloadDiskCacheInfo.isHit,
                                             "userDiskCache": "true"]
                Tracker.post(TeaEvent("perf_preload_hit_dev", params: params))
                preloadName = preloadDiskCacheInfo.preloadName
            } else {
                let params: [String: Any] = ["diskCacheId": diskCacheId,
                                             "biz": preloadBiz,
                                             "preloadType": preloadType,
                                             "hitPreload": hitPreload,
                                             "userDiskCache": "true"]
                Tracker.post(TeaEvent("perf_preload_hit_dev", params: params))
            }
            PreloadFeedbackAnalysis.feedbackPreload(preloadName: preloadName, preloadBiz: preloadBiz, preloadType: preloadType)
            PreloadTracker.logger.info("preload_trackPreloadHitForDiskCache")
        }
        
        //更新缓存命中
        if var trackInfo = self.historyDiskCacheTrackInfoMap[diskCacheId] {//命中历史磁盘缓存
            trackInfo.isHit = true
            self.historyDiskCacheTrackInfoMap[diskCacheId] = trackInfo
        }
        if var trackInfo = self.diskCacheTrackInfoMap[diskCacheId] {//命中当前磁盘缓存
            trackInfo.isHit = true
            self.diskCacheTrackInfoMap[diskCacheId] = trackInfo
        }
    }
    
    //MARK: 磁盘缓存相关
    ///数据存盘-切换到后台时持久化
    static func storeToDisk() {
        self.storeDiskCacheTrackInfo()
        self.storeMemeoryCacheTrackInfo()
        PreloadTracker.logger.info("preload_storeToDisk")
    }
    
    //统计当前生命周期内存缓存的预加载命中率，存盘。
    static func storeMemeoryCacheTrackInfo() {
        //统计内存缓存的命中率
        self.memoryCacheNameArray.forEach { name in
            var preloadBiz = ""
            var preloadType = ""
            //同一预加载总任务数
            let preloadTrackInfo = trackInfoMap.values.filter { trackerInfo in
                trackerInfo.preloadName == name
            }
            //预加载命中
            let preloadHitTrackInfo = preloadTrackInfo.filter { trackerInfo in
                trackerInfo.isHit == true
            }
            //获取业务和类型
            if let first = preloadTrackInfo.first {
                preloadBiz = first.biz.rawValue
                preloadType = first.preloadType.rawValue
            }
            
            //有历史缓存
            if var memeoryCacheInfo = self.historyMemeoryCacheInfos.first(where: { prelodName, _ in
                prelodName == name
            })?.value {
                memeoryCacheInfo.addPreloadCount = preloadTrackInfo.count
                memeoryCacheInfo.hitPreloadCount = preloadHitTrackInfo.count
                memeoryCacheInfo.preloadType = preloadType
                memeoryCacheInfo.preloadBiz = preloadBiz
                self.historyMemeoryCacheInfos[name] = memeoryCacheInfo
            } else { //没有历史缓存
                let trackerInfo = PreloadMemeoryCacheInfo(preloadName: name, addPreloadCount: preloadTrackInfo.count, hitPreloadCount: preloadHitTrackInfo.count, preloadBiz: preloadBiz, preloadType: preloadType)
                self.historyMemeoryCacheInfos[name] = trackerInfo
            }
        }
        PreloadTracker.logger.info("preload_storePreloadRate_\(self.historyMemeoryCacheInfos)")
        //本地持久化命中率
        //safeDic不支持持久化，需要转换正普通的dic
        let storeCacheInfos = self.convertSafeDicToNormal(safeDic: self.historyMemeoryCacheInfos)
        self.store.set(storeCacheInfos, forKey: self.historyMemoryCacheInfoKey)
    }

    //持久化当前生命周期和历史的磁盘预处理数据.
    static func storeDiskCacheTrackInfo() {
        //持久化当前生命周期磁盘缓存预加载信息
        if !diskCacheTrackInfoMap.isEmpty {
            let storeTrackInfoMap = self.convertSafeDicToNormal(safeDic: diskCacheTrackInfoMap)
            self.store.set(storeTrackInfoMap, forKey: self.diskCacheTempTrackInfoKey)
        }
        //更新历史缓存预加载信息
        if !historyDiskCacheTrackInfoMap.isEmpty {
            let storeTrackInfoMap = self.convertSafeDicToNormal(safeDic: historyDiskCacheTrackInfoMap)
            self.store.set(storeTrackInfoMap, forKey: self.historyDiskCacheTrackInfoKey)
        }
    }

    //同步历史磁盘缓存预处理数据，上次生命周期同步到历史数据中，并且过滤掉n天之前的数据
    static func synchHistoryDiskCache() {
        //上次生命周期数据
        let tempKey = KVKey<[String: PreloadDiskCacheInfo]?>(self.diskCacheTempTrackInfoKey)
        let preDiskCache: [String: PreloadDiskCacheInfo]? = self.store.value(forKey: tempKey)
        
        //总的数据
        let historyKey = KVKey<[String: PreloadDiskCacheInfo]?>(self.historyDiskCacheTrackInfoKey)
        let totalDiskCache: [String: PreloadDiskCacheInfo]? = self.store.value(forKey: historyKey)
        if let totalDiskCache = totalDiskCache {
            self.convertNormalDicToSafe(normalDic: totalDiskCache, safeDic: self.historyDiskCacheTrackInfoMap)
        }
        //如果上次和历史都有数据，把上次生命周期的数据x同步到总数据中
        if let preDiskCache = preDiskCache, let totalDiskCache = totalDiskCache {
            var totalDiskCache = totalDiskCache
            totalDiskCache.merge(preDiskCache){ (_, new) in new }
            self.convertNormalDicToSafe(normalDic: totalDiskCache, safeDic: self.historyDiskCacheTrackInfoMap)
        }
        //如果上次有数据，没有总数据，把上次生命周期的数据记录为总数据
        else if totalDiskCache == nil, let preDiskCache = preDiskCache {
            self.convertNormalDicToSafe(normalDic: preDiskCache, safeDic: self.historyDiskCacheTrackInfoMap)
        }
        //过滤n天内的数据
        self.historyDiskCacheTrackInfoMap = self.historyDiskCacheTrackInfoMap.filter { _, trackerInfo in
            let dayCount: Int = PreloadSettingsManager.getDiskCacheDayCount()
            // disable-lint: magic number
            let daySeconds = 3600 * 24.0
            // enable-lint: magic number
            return NSDate().timeIntervalSince1970 - trackerInfo.createTime < daySeconds * Double(dayCount)
        }
        //清除上次数据
        self.store.removeValue(forKey: self.diskCacheTempTrackInfoKey)
        //持久化历史数据。
        let cacheInfoMap = self.convertSafeDicToNormal(safeDic: self.historyDiskCacheTrackInfoMap)
        self.store.set(cacheInfoMap, forKey: self.historyDiskCacheTrackInfoKey)
    }
    
    //MARK: 命中率计算
    ///获取内存缓存命中率
    static func loadMemoryCacheHitRate() {
        if var memeoryCacheInfos: [String: PreloadMemeoryCacheInfo] = self.store.value(forKey: self.historyMemoryCacheInfoKey) {
            //过滤n天内的数据
            memeoryCacheInfos = memeoryCacheInfos.filter { _, trackerInfo in
                let dayCount: Int = PreloadSettingsManager.getDiskCacheDayCount()
                // disable-lint: magic number
                let daySeconds = 3600 * 24.0
                // enable-lint: magic number
                return NSDate().timeIntervalSince1970 - trackerInfo.createTime < daySeconds * Double(dayCount)
            }
            
            //业务+功能为维度计算命中率的数据结构 [biz:[type:[cacheInfo]]]
            var bizTypeCacheInfo: [String: [String: [PreloadMemeoryCacheInfo]]] = [:]
           
            memeoryCacheInfos.forEach {preloadName, cacheInfo in
                //以入口为维度计算
                var cacheInfoCopy = cacheInfo
                cacheInfoCopy.historyHitPreloadCount = cacheInfo.hitPreloadCount + cacheInfo.historyHitPreloadCount
                cacheInfoCopy.historyAddPreloadCount = cacheInfo.historyAddPreloadCount + cacheInfo.addPreloadCount
                cacheInfoCopy.hitPreloadCount = 0
                cacheInfoCopy.addPreloadCount = 0
                memeoryCacheInfos[preloadName] = cacheInfoCopy
                if cacheInfoCopy.historyAddPreloadCount > 0 {
                    self.memoryCacheHitRate[preloadName] = (Double(cacheInfoCopy.historyHitPreloadCount) / Double(cacheInfoCopy.historyAddPreloadCount), Double(cacheInfoCopy.historyAddPreloadCount) / precision,
                        Double(cacheInfoCopy.historyHitPreloadCount) / precision)
                }
                
                //以业务+类型为维度组装数据结构[biz:[type:[cacheInfo]]]
                let preloadBiz = cacheInfoCopy.preloadBiz
                let preloadType = cacheInfoCopy.preloadType
                if let bizValue = bizTypeCacheInfo[preloadBiz], let typeValue = bizValue[preloadType] {
                    var typeValueCopy = typeValue
                    var bizValueCopy = bizValue
                    typeValueCopy.append(cacheInfoCopy)
                    bizValueCopy[preloadType] = typeValueCopy
                    bizTypeCacheInfo[preloadBiz] = bizValueCopy
                } else if let bizValue = bizTypeCacheInfo[preloadBiz] {
                    var bizValueCopy = bizValue
                    bizValueCopy[preloadType] = [cacheInfoCopy]
                    bizTypeCacheInfo[preloadBiz] = bizValueCopy
                } else {
                    bizTypeCacheInfo[preloadBiz] = [preloadType:[cacheInfoCopy]]
                }
            }
            
            //统计以业务+类型为维度的命中率 [biz:[type: rate]]
            var bizTypeRate: [String:[String : (Double, Double)]] = [:]
            //先过滤所有的业务
            bizTypeCacheInfo.forEach { (bizValue: String, typeValue: [String : [PreloadMemeoryCacheInfo]]) in
                //再过滤业务所有的预加载类型。
                typeValue.forEach { (preloadType: String, cacheInfos: [PreloadMemeoryCacheInfo]) in
                    var hitCount = 0
                    var addCount = 0
                    //统计每个类型的所有添加数和命中数
                    cacheInfos.forEach { cacheInfo in
                        hitCount += cacheInfo.historyHitPreloadCount
                        addCount += cacheInfo.historyAddPreloadCount
                    }
                    if addCount > 0 {
                        //统计出命中率，并且封装到数据结构中
                        let rate = Double(hitCount) / Double(addCount)
                        if let rateValue = bizTypeRate[bizValue] {
                            var rateValueCopy = rateValue
                            rateValueCopy[preloadType] = (rate, Double(addCount) / precision)
                            bizTypeRate[bizValue] = rateValueCopy
                        } else {
                            bizTypeRate[bizValue] = [preloadType : (rate, Double(addCount) / precision)]
                        }
                    }
                }
            }
            //转换成安全字典-否则会有多线程的问题。
            self.convertNormalDicToSafe(normalDic: bizTypeRate, safeDic: self.memoryCacheBizTypeHitRate)
            self.convertNormalDicToSafe(normalDic: memeoryCacheInfos, safeDic: self.historyMemeoryCacheInfos)
            PreloadTracker.logger.info("preload_loadMemoryCacheHitRate_\(self.memoryCacheHitRate)")
        }
    }

    ///磁盘缓存命中率
    static func loadDiskCacheHitRate() {
        var diskCacheHitRate: [String: (Double, Double, Double)] = [:]
        var preloadNameSet: Set<String> = []
        
        //查找所有的预加载名称
        self.historyDiskCacheTrackInfoMap.values.forEach { trackInfo in
            preloadNameSet.insert(trackInfo.preloadName)
        }
        //按名称分类统计命中率
        preloadNameSet.forEach { preloadName in
            //过滤同一名称的预加载
            let preloadTrackInfo = self.historyDiskCacheTrackInfoMap.values.filter { trackerInfo in
                trackerInfo.preloadName == preloadName
            }
            //过滤命中数
            let preloadTrackHitInfo = preloadTrackInfo.filter { trackerInfo in
                trackerInfo.isHit == true
            }
            //统计命中率，name作为key
            if Double(preloadTrackInfo.count) > 0 {
                diskCacheHitRate[preloadName] = (Double(preloadTrackHitInfo.count) / Double(preloadTrackInfo.count), Double(preloadTrackInfo.count) / precision, Double(preloadTrackHitInfo.count) / precision)
            }
        }
        
        //业务+功能为维度数据结构 [biz:[type:[cacheInfo]]]
        var bizTypeCacheInfo: [String: [String: [PreloadDiskCacheInfo]]] = [:]
        self.historyDiskCacheTrackInfoMap.values.forEach { cacheInfo in
            //以业务+类型为维度组装数据结构[biz:[type:[cacheInfo]]]
            let cacheInfoCopy = cacheInfo
            let preloadBiz = cacheInfoCopy.preloadBiz
            let preloadType = cacheInfoCopy.preloadType
            if let bizValue = bizTypeCacheInfo[preloadBiz], let typeValue = bizValue[preloadType] {
                var typeValueCopy = typeValue
                var bizValueCopy = bizValue
                typeValueCopy.append(cacheInfoCopy)
                bizValueCopy[preloadType] = typeValueCopy
                bizTypeCacheInfo[preloadBiz] = bizValueCopy
            } else if let bizValue = bizTypeCacheInfo[preloadBiz] {
                var bizValueCopy = bizValue
                bizValueCopy[preloadType] = [cacheInfoCopy]
                bizTypeCacheInfo[preloadBiz] = bizValueCopy
            } else {
                bizTypeCacheInfo[preloadBiz] = [preloadType:[cacheInfoCopy]]
            }
        }
        
        //统计以业务+类型为维度的命中率 [biz:[type: (rate,precision)]]
        var bizTypeRate: [String:[String : (Double, Double)]] = [:]
        //遍历所有业务
        bizTypeCacheInfo.forEach { (bizValue: String, typeValue: [String : [PreloadDiskCacheInfo]]) in
            //遍历业务下的所有预加载类型
            typeValue.forEach { (preloadType: String, cacheInfos: [PreloadDiskCacheInfo]) in
                //过滤命中的个数和总个数
                let hitArray = cacheInfos.filter { cacheInfo in
                    cacheInfo.isHit == true
                }
                let hitCount = hitArray.count
                let addCount = cacheInfos.count
                if addCount > 0 {
                    //计算命中率并且封装到数据结构中
                    let rate = Double(hitCount) / Double(addCount)
                    if let rateValue = bizTypeRate[bizValue] {
                        var rateValueCopy = rateValue
                        rateValueCopy[preloadType] = (rate, Double(addCount) / precision)
                        bizTypeRate[bizValue] = rateValueCopy
                    } else {
                        bizTypeRate[bizValue] = [preloadType : (rate, Double(addCount) / precision)]
                    }
                }
            }
        }
        //转换成安全字典
        self.convertNormalDicToSafe(normalDic: bizTypeRate, safeDic: self.diskCacheBizTypeHitRate)
        self.convertNormalDicToSafe(normalDic: diskCacheHitRate, safeDic: self.diskCacheHitRate)
        PreloadTracker.logger.info("preload_loadDiskCacheHitRate_\(diskCacheHitRate)")
    }
    
    //安全字典转换成普通字典
    static func convertSafeDicToNormal<T>(safeDic: SafeDictionary<String, T>) -> [String: T] {
        var normalDic: [String: T] = [:]
        safeDic.forEach { key, value in
            normalDic[key] = value
        }
        return normalDic
    }
    
    //普通字典转换成安全字典
    static func convertNormalDicToSafe<T>(normalDic: [String: T], safeDic: SafeDictionary<String, T>) {
        safeDic.removeAll()
        normalDic.forEach { key, value in
            safeDic[key] = value
        }
    }

    //清除user生命周期的埋点数据-后期再补充
    static func clearUserScopDate(){
    }
}

extension PreloadTrackerInfo: CustomStringConvertible {
    public var description: String {
        return "priority:\(priority) - name:\(preloadName) -priporityChangeType:\(priporityChangeType) -waitScheduleInterval:\(waitScheduleInterval ?? -1) -waitRunInterval:\(waitRunInterval ?? -1) -executeCost:\(executeCost ?? -1)"
    }
}
