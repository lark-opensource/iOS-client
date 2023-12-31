//
//  PreloadHitRateManager.swift
//  LarkPreload
//
//  Created by huanglx on 2023/9/18.
//

import Foundation
import ThreadSafeDataStructure

/*
    预加载命中率优化- https://bytedance.feishu.cn/wiki/BBd3wQURnizgpQkfc2Lcs5xAnEg
    CCM预加载命中率优化实践 - https://bytedance.feishu.cn/wiki/RfXqwOYKMibKVgkyh5qc2R66nIh
    预加载命中率优化管理器
 */
class PreloadHitRateManager {
    // 单例
    static let shared = PreloadHitRateManager()
    ///命中率低被取消的task
    var cancelByLowRateTasks: SafeArray<PreloadTask> = [] + .readWriteLock
    ///降采样dic [点位名称: 添加的任务数]
    var downSamplingDic: SafeDictionary<String, Int> = [:] + .readWriteLock
    
    /*
    通过命中率/使用频次调整优先级
     -return 1.业务维度命中率。 2.入口维度命中率。 3.使用频次。 4.业务维度命中率精度。 5.入口维度命中率精度。 6.入口维度业务依赖度
    */
    func adjustPriporty(task: PreloadTask) -> (bizTypeHitRate: Double?, entranceHitRate: Double?, feedbackCount: Double?, bizTypePrecision: Double?, entrancePrecision: Double?, entranceDependValue: Double?) {
        //只对有feedback的预加载进行调整等级，否则都返回-1.
        guard task.hasFeedback else {
            return (-1, -1, -1, -1, -1, -1)
        }
        //业务预加载类型，用于动态读取setting配置。
        let bizPreloadType = "\(task.biz)_\(task.preloadType)"
        
        //业务维度
        var bizTypeHitRate: Double?     //命中率
        var bizTypePrecision: Double?   //精度
        //入口维度
        var entranceHitRate: Double?     //命中率
        var entrancePrecision: Double?   //精度
        var entranceDependValue: Double? //业务依赖度
        
        //是否使用bizType维度命中率
        var useBizTypeRate: Bool = false
        //获取最终采用的命中率
        var hitRate: Double?
        //获取指定维度的本地命中率，并且验证验证命中率精度是否可用，优先采用入口命中率，如果精准度不够（上报的数量少）则降级成业务命中率。
        if task.diskCache {  //磁盘缓存的预处理
            //业务命中率
            bizTypeHitRate = PreloadTracker.diskCacheBizTypeHitRate[task.biz.rawValue]?[task.preloadType.rawValue]?.0
            //业务命中精度
            bizTypePrecision = PreloadTracker.diskCacheBizTypeHitRate[task.biz.rawValue]?[task.preloadType.rawValue]?.1
            //入口命中率
            entranceHitRate = PreloadTracker.diskCacheHitRate[task.preloadName]?.0
            //入口命中精度
            entrancePrecision = PreloadTracker.diskCacheHitRate[task.preloadName]?.1
            //入口业务依赖度
            entranceDependValue = PreloadTracker.diskCacheHitRate[task.preloadName]?.2
            
            //使用点位命中率条件：精度满足，或者命中率高于禁用命中率
            if let entranceHitRate = entranceHitRate, entranceHitRate > PreloadSettingsManager.cancelHitRate(bizPreloadType: bizPreloadType) {
                hitRate = entranceHitRate
            } else if let precision = entrancePrecision, precision >  PreloadSettingsManager.adjustPrecision(bizPreloadType: bizPreloadType) {
                hitRate = entranceHitRate
            } else if let precision = bizTypePrecision, precision >  PreloadSettingsManager.adjustBizTypePrecison(bizPreloadType: bizPreloadType) { //使用业务命中率条件: 不满足入口命中率条件，并且业务精度满足
                hitRate = bizTypeHitRate
                useBizTypeRate = true
            }
        } else { //内存缓存的预处理
            //业务命中
            bizTypeHitRate = PreloadTracker.memoryCacheBizTypeHitRate[task.biz.rawValue]?[task.preloadType.rawValue]?.0
            //业务命中精度
            bizTypePrecision = PreloadTracker.memoryCacheBizTypeHitRate[task.biz.rawValue]?[task.preloadType.rawValue]?.1
            //入口命中
            entranceHitRate = PreloadTracker.memoryCacheHitRate[task.preloadName]?.0
            //入口命中精度
            entrancePrecision = PreloadTracker.memoryCacheHitRate[task.preloadName]?.1
            //入口业务依赖度
            entranceDependValue = PreloadTracker.memoryCacheHitRate[task.preloadName]?.2
            
            //使用点位命中率条件：精度满足，或者命中率高于禁用命中率
            if let entranceHitRate = entranceHitRate, entranceHitRate > PreloadSettingsManager.cancelHitRate(bizPreloadType: bizPreloadType) {
                hitRate = entranceHitRate
            } else if let precision = entrancePrecision, precision > PreloadSettingsManager.adjustPrecision(bizPreloadType: bizPreloadType) {
                hitRate = entranceHitRate
            } else if let precision = bizTypePrecision, precision > PreloadSettingsManager.adjustBizTypePrecison(bizPreloadType: bizPreloadType) { //使用业务命中率条件: 不满足入口命中率条件，并且业务精度满足
                hitRate = bizTypeHitRate
                useBizTypeRate = true
            }
        }
        
        //获取预加载频次
        let feedbackCount = PreloadFeedbackAnalysis.feedbackInfo[task.biz.rawValue]?[task.preloadType.rawValue]
        
        if PreloadSettingsManager.enableChangePriority(bizPreloadType: bizPreloadType, preloadName: task.preloadName) { //是否允许调级
            if PreloadSettingsManager.useFeedbackCountAdjust(bizPreloadType: bizPreloadType), let feedbackCount = feedbackCount { //根据使用频次进行优先级调整
                self.changePripoityByFeedbackCount(task: task, feedbackCount: feedbackCount, bizPreloadType: bizPreloadType)
            } else { //根据命中率进行优先级调整
                //采样优化
                if self.canDownsampling(entranceDependValue: entranceDependValue, entranceHitRate: entranceHitRate, bizPreloadType: bizPreloadType) {
                    self.downSampling(task: task, bizPreloadType: bizPreloadType)
                } else {//通过本地命中率优化
                    self.changePriorityByHitRate(task: task, hitRate: hitRate, bizPreloadType: bizPreloadType, useBizTypeRate: useBizTypeRate)
                }
            }
        }
        return (bizTypeHitRate, entranceHitRate, feedbackCount, bizTypePrecision, entrancePrecision, entranceDependValue)
    }
    
    //判断是否需要采样,需要满足业务依赖值高于平均值，并且命中率小于禁用的阈值
    private func canDownsampling(entranceDependValue: Double?, entranceHitRate: Double?, bizPreloadType: String) -> Bool {
        if let entranceDependValue = entranceDependValue, let entranceHitRate = entranceHitRate, entranceDependValue > PreloadSettingsManager.dependValue(bizPreloadType: bizPreloadType), entranceHitRate < PreloadSettingsManager.cancelHitRate(bizPreloadType: bizPreloadType) {
            return true
        }
        return false
    }
    
    //任务采样-单个入口每执行n个会被采样一个
    private func downSampling(task: PreloadTask, bizPreloadType: String) {
        //被采样的间隔
        let downSamplingValue = PreloadSettingsManager.downSamplingValue(bizPreloadType: bizPreloadType)
        //采样逻辑
        if let taskIndex = self.downSamplingDic[task.preloadName], downSamplingValue > 0 {
            if taskIndex % downSamplingValue == 0 {
                //被采样取消预加载
                task.isCancelByHit = true
                task.priporityChangeType = .cancelBySampling
                self.cancelByLowRateTasks.append(task)
            }
            let newTaskIndex = taskIndex + 1
            self.downSamplingDic[task.preloadName] = newTaskIndex
        } else {
            self.downSamplingDic[task.preloadName] = 1
        }
    }
       
    //基于单位时间使用次数优化
    private func changePripoityByFeedbackCount(task: PreloadTask, feedbackCount: Double, bizPreloadType: String) {
        if feedbackCount >= 0, feedbackCount < PreloadSettingsManager.cancelFeedbackCount(bizPreloadType: bizPreloadType) { //取消预加载
            task.isCancelByHit = true
            task.priporityChangeType = .cancelByFeedbackCount
            self.cancelByLowRateTasks.append(task)
        } else if feedbackCount >= PreloadSettingsManager.cancelFeedbackCount(bizPreloadType: bizPreloadType), feedbackCount < PreloadSettingsManager.downFeedbackCount(bizPreloadType: bizPreloadType) { //降低优先级
            task.priority = .low
            task.priporityChangeType = .downToLow
        } else if feedbackCount >= PreloadSettingsManager.upFeedbackCount(bizPreloadType: bizPreloadType) {//升高优先级
            task.priority = .hight
            task.priporityChangeType = .upToHight
        }
    }
    
    //基于本地命中率优化
    private func changePriorityByHitRate(task: PreloadTask, hitRate: Double?, bizPreloadType: String, useBizTypeRate: Bool) {
        var cancelHitRate: Double
        var downPriorityHitRate: Double
        var upPriporityHitRate: Double
        //如果采用业务功能命中率，切换到业务功能相关的阈值
        if useBizTypeRate {
            cancelHitRate = PreloadSettingsManager.cancelBizTypeHitRate(bizPreloadType: bizPreloadType)
            downPriorityHitRate = PreloadSettingsManager.downPriorityBizTypeHitRate(bizPreloadType: bizPreloadType)
            upPriporityHitRate = PreloadSettingsManager.upPriporityBizTypeHitRate(bizPreloadType: bizPreloadType)
        } else {
            cancelHitRate = PreloadSettingsManager.cancelHitRate(bizPreloadType: bizPreloadType)
            downPriorityHitRate = PreloadSettingsManager.downPriorityHitRate(bizPreloadType: bizPreloadType)
            upPriporityHitRate = PreloadSettingsManager.upPriporityHitRate(bizPreloadType: bizPreloadType)
        }
        if let hitRate = hitRate { //精准禁用
            //低于丢失阈值，大于0兼容遗漏命中反馈的情况，丢弃此次预加载，
            if hitRate >= 0, hitRate < cancelHitRate {
                task.isCancelByHit = true
                task.priporityChangeType = .cancelByLowHitRate
                self.cancelByLowRateTasks.append(task)
            } else if hitRate >= cancelHitRate, hitRate < downPriorityHitRate {// 低于降低预加载命中阈值降低预加载优先级
                task.priority = .low
                task.priporityChangeType = .downToLow
            } else if hitRate >= upPriporityHitRate {//高于提高预加载命中率阈值，升高预加载优先级
                task.priority = .hight
                task.priporityChangeType = .upToHight
            }
        }
    }
}
