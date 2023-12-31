//
//  PreloadSettingsManager.swift
//  Lark
//
//  Created by huanglx on 2023/2/13.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import ThreadSafeDataStructure

///外部注入settings配置
public class PreloadSettingsManager {
    
    public static var preloadConfig: SafeDictionary<String, Any> = [:] + .readWriteLock
    public static var deviceClassify: SafeDictionary<String, Any> = [:] + .readWriteLock
        
    ///获取预加载频次的最短使用时间，单位分钟
    static func feedbackMinTime() -> Double {
        if let feedbackMinTime = preloadConfig["feedbackMinTime"] as? Double {
            return feedbackMinTime
        } else {
            return 1
        }
    }
    
    ///是否添加限制条件
    static func enableChecker() -> Bool {
        if let enableChecker = preloadConfig["enableChecker"] as? Bool {
            return enableChecker
        } else {
            return false
        }
    }
    
    ///是否使用预加载框架
    static func enablePreload() -> Bool {
        if let enablePreload = preloadConfig["enablePreload"] as? Bool {
            return enablePreload
        } else {
            return false
        }
    }
    
    ///是否是低端机
    static func isLowDevice() -> Bool {
        if let mobileClassify = deviceClassify["mobileClassify"] as? String {
            if mobileClassify == "mobile_classify_low" {
                return true
            }
        }
        return false
    }
    
    ///是否允许后进先出
    static func enableLIFO() -> Bool {
        if let enableLIFO = preloadConfig["enableLIFO"] as? Bool {
            return enableLIFO
        } else {
            return false
        }
    }
    
    ///获取lite生效的最高分数，默认7.9低端机
    public static func liteEnableDeviceScore() -> Double {
        if let liteEnableDeviceScore = preloadConfig["liteEnableDeviceScore"] as? Double {
            return liteEnableDeviceScore
        } else {
            return 7.9
        }
    }
    
    ///lite是否生效
    static func liteEnable() -> Bool {
        if let deviceScore = deviceClassify["cur_device_score"] as? Double {
            if deviceScore < self.liteEnableDeviceScore() {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    ///是否切后台暂停
    static func pauseByBackground() -> Bool {
        if let pauseByBackground = preloadConfig["pauseByBackground"] as? Bool {
            return pauseByBackground
        } else {
            return false
        }
    }
    
    //MARK: 命中率调整
    ///是否允许预处理更改优先级
    static func enableChangePriority(bizPreloadType: String, preloadName: String) -> Bool {
        //如果命中黑名单，不进行优先级调整
        if self.checkIsHitBlackList(bizPreloadType: bizPreloadType, preloadName: preloadName) {
            return false
        }
        //判断是否开启配置。
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let enableChangePriority = customPreloadConfig["enableChangePriority"] as? Bool {
            return enableChangePriority
        }
        if let enableChangePriority = preloadConfig["enableChangePriority"] as? Bool {
            return enableChangePriority
        }
        return false
    }
    
    ///是否使用业务使用频次为调整优先级方案。
    static func useFeedbackCountAdjust(bizPreloadType: String) -> Bool {
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let useFeedbackCountAdjust = customPreloadConfig["useFeedbackCountAdjust"] as? Bool {
            return useFeedbackCountAdjust
        }
        if let useFeedbackCountAdjust = preloadConfig["useFeedbackCountAdjust"] as? Bool {
            return useFeedbackCountAdjust
        }
        return false
    }
    
    ///获取调整等级的精度值。
    static func adjustPrecision(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let adjustPrecision = customPreloadConfig["adjustPrecision"] as? Double {
            return adjustPrecision
        }
        return preloadConfig["adjustPrecision"] as? Double ?? 1
    }
    
    ///获取调整等级的业务精度值
    static func adjustBizTypePrecison(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let adjustBizTypePrecison = customPreloadConfig["adjustBizTypePrecison"] as? Double {
            return adjustBizTypePrecison
        }
        return preloadConfig["adjustBizTypePrecison"] as? Double ?? 1
    }
    
    ///取消预处理命中率阈值
    static func cancelHitRate(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let cancelPreloadHitRate = customPreloadConfig["cancelPreloadHitRate"] as? Double {
            return cancelPreloadHitRate
        }
        // disable-lint: magic number
        return preloadConfig["cancelPreloadHitRate"] as? Double ?? 0.1
        // enable-lint: magic number
    }
    
    ///降低优先级预加载命中率阈值
    static func downPriorityHitRate(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let downPriorityHitRate = customPreloadConfig["downPriorityHitRate"] as? Double {
            return downPriorityHitRate
        }
        // disable-lint: magic number
        return preloadConfig["downPriorityHitRate"] as? Double ?? 0.3
        // enable-lint: magic number
    }
    
    ///升高优先级预加载命中率阈值
    static func upPriporityHitRate(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let upPriporityHitRate = customPreloadConfig["upPriporityHitRate"] as? Double {
            return upPriporityHitRate
        }
        // disable-lint: magic number
       return preloadConfig["upPriporityHitRate"] as? Double ?? 0.7
        // enable-lint: magic number
    }
    
    ///取消预处理命中率阈值
    static func cancelBizTypeHitRate(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let cancelPreloadHitRate = customPreloadConfig["cancelBizTypeHitRate"] as? Double {
            return cancelPreloadHitRate
        }
        // disable-lint: magic number
        return preloadConfig["cancelBizTypeHitRate"] as? Double ?? 0.1
        // enable-lint: magic number
    }
    
    ///降低优先级预加载命中率阈值
    static func downPriorityBizTypeHitRate(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let downPriorityHitRate = customPreloadConfig["downPriorityBizTypeHitRate"] as? Double {
            return downPriorityHitRate
        }
        // disable-lint: magic number
        return preloadConfig["downPriorityBizTypeHitRate"] as? Double ?? 0.3
        // enable-lint: magic number
    }
    
    ///升高优先级预加载命中率阈值
    static func upPriporityBizTypeHitRate(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let upPriporityHitRate = customPreloadConfig["upPriporityBizTypeHitRate"] as? Double {
            return upPriporityHitRate
        }
        // disable-lint: magic number
       return preloadConfig["upPriporityBizTypeHitRate"] as? Double ?? 0.7
        // enable-lint: magic number
    }
    
    ///业务依赖值
    static func dependValue(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let dependValue = customPreloadConfig["dependValue"] as? Double {
            return dependValue
        }
        // disable-lint: magic number
       return preloadConfig["dependValue"] as? Double ?? 0.7
        // enable-lint: magic number
    }
    
    ///降采样值-执行n个丢弃一个。
    static func downSamplingValue(bizPreloadType: String) -> Int {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let downSamplingValue = customPreloadConfig["downSamplingValue"] as? Int {
            return downSamplingValue
        }
        // disable-lint: magic number
        return preloadConfig["downSamplingValue"] as? Int ?? 10
        // enable-lint: magic number
    }
    
    ///取消预处理feedbackCount
    static func cancelFeedbackCount(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let cancelFeedbackCount = customPreloadConfig["cancelFeedbackCount"] as? Double {
            return cancelFeedbackCount
        }
        // disable-lint: magic number
        return preloadConfig["cancelFeedbackCount"] as? Double ?? 0.1
        // enable-lint: magic number
    }
    
    ///降低优先级预加载feedbackCount
    static func downFeedbackCount(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let downFeedbackCount = customPreloadConfig["downFeedbackCount"] as? Double {
            return downFeedbackCount
        }
        // disable-lint: magic number
        return preloadConfig["downFeedbackCount"] as? Double ?? 0.3
        // enable-lint: magic number
    }
    
    ///升高优先级预加载feedbackCount
    static func upFeedbackCount(bizPreloadType: String) -> Double {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let upFeedbackCount = customPreloadConfig["upFeedbackCount"] as? Double {
            return upFeedbackCount
        }
        // disable-lint: magic number
       return preloadConfig["upFeedbackCount"] as? Double ?? 0.7
        // enable-lint: magic number
    }
    
    //MARK: 防饿死机制配置
    //防饿死触发的监测周期,值大于0开启监听。
    static func preventStarveCycleCount() -> Int {
        // disable-lint: magic number
       return preloadConfig["preventStarveCycleCount"] as? Int ?? 0
        // enable-lint: magic number
    }
    
    //防饿死开启时间
    static func preventStarveOpenTime() -> Double {
        // disable-lint: magic number
        return preloadConfig["preventStarveOpenTime"] as? Double ?? 2.0
        // enable-lint: magic number
    }
    
    //MARK: 打散逻辑配置
    //触发任务打散逻的任务堆积个数
    static func taskBreakUpPendingCount() -> Int {
        // disable-lint: magic number
       return preloadConfig["taskBreakUpPendingCount"] as? Int ?? 0
        // enable-lint: magic number
    }
    
    ///获取任务之前的打散间隔
    static func getTaskDuration() -> Double {
        let currentDeviceConfig = self.getCurrentDeviceConfig()
        return currentDeviceConfig?["duration"] as? Double ?? 0.5
    }
    
    //MARK:CPU和内存的阈值
    ///获取cpu和内存配置的阈值
    static func getCpuAndMemoryValue() -> [String: Any] {
        let currentDeviceConfig = self.getCurrentDeviceConfig()
        let result = ["cpuLimit_hight": currentDeviceConfig?["cpuLimit_hight"] as? Double ?? 0.85,
                      "cpuLimit_middle": currentDeviceConfig?["cpuLimit_middle"] as? Double ?? 0.82,
                      "cpuLimit_low": currentDeviceConfig?["cpuLimit_low"] as? Double ?? 0.8,
                      "memoryLimit_hight": currentDeviceConfig?["memoryLimit_hight"] as? Int ?? 110,
                      "memoryLimit_middle": currentDeviceConfig?["memoryLimit_middle"] as? Int ?? 130,
                      "memoryLimit_low": currentDeviceConfig?["memoryLimit_low"] as? Int ?? 150] as [String : Any]
        return result
    }
    
    //MARK: 线程池配置
    ///获取线程最大并发数
    static func getMaxCurrentCount() -> Int {
        let currentDeviceConfig = self.getCurrentDeviceConfig()
        return currentDeviceConfig?["concurrentCount"] as? Int ?? 4
    }
    
    ///最大串行个数
    static func getMaxOperationCount() -> Int {
        let currentDeviceConfig = self.getCurrentDeviceConfig()
        return currentDeviceConfig?["maxOperationCount"] as? Int ?? 5
    }
    
    ///最大串行队列个数
    static func getMaxQueueCount() -> Int {
        let currentDeviceConfig = self.getCurrentDeviceConfig()
        return currentDeviceConfig?["maxQueueCount"] as? Int ?? 6
    }
    
    //MARK: 其它配置
    ///获取磁盘缓存天数
    static func getDiskCacheDayCount() -> Int {
        let currentDeviceConfig = self.getCurrentDeviceConfig()
        return currentDeviceConfig?["diskCacheDayCount"] as? Int ?? 3
    }
    
    ///获取内存缓存命中率持久化时间（第一次添加预加载到持久化命中率时间）
    static func getMemoryCacheHitRateStoreTime() -> Int {
        let currentDeviceConfig = self.getCurrentDeviceConfig()
        return currentDeviceConfig?["memoryCacheHitRateStoreTime"] as? Int ?? 60
    }
    
    ///判断是否命中黑名单
    static func checkIsHitBlackList(bizPreloadType: String, preloadName: String) -> Bool {
        //优先取自定义配置
        if let customPreloadConfig = preloadConfig[bizPreloadType] as? Dictionary<String, Any>, let blackList = customPreloadConfig["blackList"] as? [String] {
            return blackList.contains(preloadName)
        }
        //取默认配置
        if let blackList = preloadConfig["blackList"] as? [String] {
            return blackList.contains(preloadName)
        }
       return false
    }
    
    
    ///获取当前设备配置
    static func getCurrentDeviceConfig() -> [String: Any]? {
        let mobileClassify = deviceClassify["mobileClassify"] as? String
        var currentDeviceConfig: [String: Any]?
        if let mobileClassify = mobileClassify {
            if mobileClassify == "mobile_classify_high" {
                currentDeviceConfig = preloadConfig["highDevice"] as? [String: Any]
            }
            if mobileClassify == "mobile_classify_mid" {
                currentDeviceConfig = preloadConfig["middleDevice"] as? [String: Any]
            }
            if mobileClassify == "mobile_classify_low" {
                currentDeviceConfig = preloadConfig["lowDevice"] as? [String: Any]
            }
        }
        return currentDeviceConfig
    }
}
