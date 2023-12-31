//
//  TaskConfig.swift
//  LarkCache
//
//  Created by liuwanlin on 2020/8/18.
//

import Foundation

/// 清理任务配置
public struct CleanConfig {
    /// 全局配置
    public struct Global {
        /// 每次执行清理间隔时间（保证清理完成的时间间隔）
        public let cleanInterval: Int
        /// SDK任务执行任务耗时限制
        public let sdkTaskCostLimit: Int
        /// 所有任务耗时限制（包括sdk执行时间）
        public let taskCostLimit: Int
        /// 缓存数据保留时限（保留cacheTimeLimit以内的数据）
        public let cacheTimeLimit: Int
    }
    /// 客户端各缓存配置
    public struct CacheConfig {
        /// 缓存保留的数据时间限制（清理timeLimit之前的数据）单位 s
        public let timeLimit: Int
        /// 缓存保留的数据大小限制（清理大于sizeLimit的数据） 单位bytes
        public let sizeLimit: Int
        /// CacheConfig初始化方法
        public init(timeLimit: Int, sizeLimit: Int) {
            self.timeLimit = timeLimit
            self.sizeLimit = sizeLimit
        }
    }

    /// 是否是用户触发（例如如果是用户触发的，图片缓存就需要全部清理）
    public var isUserTriggered: Bool
    /// 全局配置段
    public let global: Global
    /// 客户端各个缓存配置
    public let cacheConfig: [String: CacheConfig]

    /// 构造方法
    /// - Parameters:
    ///   - cleanInterval: 每次执行清理间隔时间（保证清理完成的时间间隔）
    ///   - sdkTaskCostLimit: SDK任务执行任务耗时限制
    ///   - taskCostLimit: 所有任务耗时限制（包括sdk执行时间）
    ///   - cacheTimeLimit: 缓存数据保留时限（保留cacheTimeLimit以内的数据）
    ///   - cacheConfig: 客户端各个缓存配置（字典，key为缓存名称，value为缓存配置），对应的配置没有时会将数据全部清除
    public init(
        isUserTriggered: Bool = false,
        cleanInterval: Int = 86_400,
        sdkTaskCostLimit: Int = 30,
        taskCostLimit: Int = 60,
        cacheTimeLimit: Int = 86_400,
        cacheConfig: [String: CacheConfig] = [:]) {

        self.global = Global(
            cleanInterval: cleanInterval,
            sdkTaskCostLimit: sdkTaskCostLimit,
            taskCostLimit: taskCostLimit,
            cacheTimeLimit: cacheTimeLimit
        )

        self.cacheConfig = cacheConfig
        self.isUserTriggered = isUserTriggered
    }
}
