//
//  StrategyService.swift
//  LarkMeegoStrategy
//
//  Created by shizhengyu on 2023/4/5.
//

import Foundation
import LarkMeegoLogger
import ThreadSafeDataStructure
import LarkContainer
import LarkAccountInterface
import LarkMeegoStorage
import RxSwift
import LarkSetting
import LKCommonsTracker
import TTReachability

public enum UserExposeType {
    /// 入口曝光
    case entrance(LarkScene)
    /// 场景曝光
    case scene(_ rawLarkScene: String)
}

/// Meego 策略服务接口
public protocol MeegoStrategyService {
    /// 注册一个执行器
    func register(with executors: [any Executor])

    /// 反注册一个执行器
    func unregister(with executors: [any Executor])

    /// meego 入口/场景曝光
    func expose(with url: URL, type: UserExposeType)
}

let strategyQueue = DispatchQueue(label: "lark.meego.strategy.queue", qos: .background)
let strategyQueueWrapper = SerialDispatchQueueScheduler(queue: strategyQueue, internalSerialQueueName: strategyQueue.label)

private enum Agreement {
    static let mills4Day = 24 * 60 * 60 * 1000
    static let strategyConfigKey = "meego_user_strategy_config"
}

/// 设备评分类型
public enum MeegoDeviceClassify {
    case high
    case middle
    case low
    case unclassify

    var isNotLowDevice: Bool {
        return self != .low
    }
}

public protocol MeegoStrategyServiceDependency {
    var currentDeviceClassify: MeegoDeviceClassify { get }
}

/// Meego 策略服务实现
class MeegoStrategyServiceImpl: MeegoStrategyService {
    private enum UserTrackerAgreement {
        static let eventKey = "meego_user_track"
        static let sceneKey = "scene"
        static let actionKey = "action"
    }

    private let userResolver: UserResolver
    private let passportUserService: PassportUserService
    private let settingService: SettingService
    private let dependency: MeegoStrategyServiceDependency

    private var preRequestExecutors: SafeDictionary<MeegoScene, any Executor> = [:] + .readWriteLock
    private var pattern2regexCache: SafeDictionary<String, NSRegularExpression> = [:] + .readWriteLock
    private lazy var userTrackStorage: UserTrackStorage = {
        return UserTrackStorage(associatedUserId: self.passportUserService.user.userID)
    }()
    private var rawStrategyConfig: [String: Any]? {
        return try? settingService.setting(with: Agreement.strategyConfigKey)
    }
    private var strategyConfig: StrategyConfig?

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        settingService = try userResolver.resolve(assert: SettingService.self)
        passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        dependency = try userResolver.resolve(assert: MeegoStrategyServiceDependency.self)
    }

    func register(with executors: [any Executor]) {
        for executor in executors.filter { $0.type == .preRequest } {
            preRequestExecutors[executor.scope] = executor
        }
    }

    func unregister(with executors: [any Executor]) {
        for executor in executors.filter { $0.type == .preRequest } {
            preRequestExecutors.removeValue(forKey: executor.scope)
        }
    }

    func expose(with url: URL, type: UserExposeType) {
        guard !FeatureGating.get(by: FeatureGating.disableMeegoUserTrack, userResolver: userResolver) else {
            return
        }
        strategyQueue.async {
            let currentTimestampMills = Int(Date().timeIntervalSince1970 * 1000)

            if self.strategyConfig == nil, let rawConfig = self.rawStrategyConfig {
                MeegoLogger.debug("get strategy raw configs = \(rawConfig)", customPrefix: loggerPrefix)
                self.strategyConfig = StrategyConfig(rawConfig: rawConfig)

                // 首次加载策略数据会自动清理两倍分析窗口时间前的用户分析数据，避免存储无限膨胀
                if let timeWindowForAnalyze = self.strategyConfig?.timeWindowForAnalyze {
                    self.userTrackStorage.delete(until: Int64(currentTimestampMills - 2 * timeWindowForAnalyze * Agreement.mills4Day))
                }
            }
            guard let strategyConfig = self.strategyConfig else {
                return
            }

            let range = NSRange(location: 0, length: url.path.utf16.count)
            switch type {
            case .entrance(let larkScene):
                for (meegoScene, preRequestConfig) in strategyConfig.preRequestConfigs {
                    var regex = self.pattern2regexCache[preRequestConfig.pathRegex]
                    if regex == nil {
                        regex = try? NSRegularExpression(pattern: preRequestConfig.pathRegex)
                        self.pattern2regexCache[preRequestConfig.pathRegex] = regex
                    }
                    let executorContext = ExecutorContext(url: url, larkScene: larkScene, meegoScene: meegoScene, strategy: strategyConfig)
                    guard regex?.firstMatch(in: url.path, range: range) != nil else {
                        continue
                    }
                    // 用户行为统计
                    _ = self.userTrackStorage.add(
                        with: larkScene,
                        meegoScene: meegoScene,
                        userActivity: .exposeEntrance,
                        timestampMills: Int64(currentTimestampMills)
                    ).subscribe(onNext: { _ in
                        StrategyTracker.userTrack(
                            larkScene: larkScene,
                            meegoScene: meegoScene,
                            userActivity: .exposeEntrance,
                            url: url.absoluteString
                        )
                    })
                    // 规则匹配，执行预请求
                    if FeatureGating.get(by: FeatureGating.enableBizPreRequest, userResolver: self.userResolver) {
                        // 上线权重分系统前，针对 WIFI 和高端机用户进行定向策略优化
                        let isInWIFI = TTReachability.forInternetConnection().currentReachabilityStatus() == .ReachableViaWiFi
                        if self.dependency.currentDeviceClassify.isNotLowDevice && isInWIFI {
                            self.preRequestExecutors[meegoScene]?.execute(with: executorContext)
                            continue
                        }
                        guard let conditions = preRequestConfig.triggerConditions[larkScene], !conditions.isEmpty else {
                            continue
                        }
                        let analysisTimeWindow = strategyConfig.timeWindowForAnalyze * Agreement.mills4Day
                        let entranceExposeCountOb = self.userTrackStorage.count(
                            since: Int64(currentTimestampMills - analysisTimeWindow),
                            larkScene: larkScene,
                            meegoScene: meegoScene,
                            userActivity: .exposeEntrance
                        )
                        let sceneExposeCountOb = self.userTrackStorage.count(
                            since: Int64(currentTimestampMills - analysisTimeWindow),
                            larkScene: larkScene,
                            meegoScene: meegoScene,
                            userActivity: .exposeScene
                        )
                        _ = Observable
                            .zip(entranceExposeCountOb, sceneExposeCountOb)
                            .observeOn(strategyQueueWrapper)
                            .filter({ (entranceExposeCount, sceneExposeCount) in
                                let unqualifiedConditions = conditions.filter { condition in
                                    switch condition {
                                    case .sceneExposureCount(let threshold):
                                        return sceneExposeCount < threshold
                                    case .sceneExposureRate(let threshold) where entranceExposeCount > 0:
                                        return (Double(sceneExposeCount) / Double(entranceExposeCount)) * 100 < threshold
                                    @unknown default: return false
                                    }
                                }
                                if !unqualifiedConditions.isEmpty {
                                    MeegoLogger.debug("pre-request conditions not met, due to \(unqualifiedConditions), url = \(url.absoluteString)", customPrefix: loggerPrefix)
                                }
                                return unqualifiedConditions.isEmpty
                            })
                            .subscribe(onNext: { [weak self] _ in
                                self?.preRequestExecutors[meegoScene]?.execute(with: executorContext)
                            }, onError: { e in
                                MeegoLogger.error("prepare preRequest context failed, error = \(e.localizedDescription)", customPrefix: loggerPrefix)
                            })
                    }
                }
            case .scene(let rawLarkScene) where !strategyConfig.larkScene.isEmpty:
                if let larkScene = strategyConfig.larkScene[rawLarkScene] {
                    for (meegoScene, preRequestConfig) in strategyConfig.preRequestConfigs {
                        var regex = self.pattern2regexCache[preRequestConfig.pathRegex]
                        if regex == nil {
                            regex = try? NSRegularExpression(pattern: preRequestConfig.pathRegex)
                            self.pattern2regexCache[preRequestConfig.pathRegex] = regex
                        }
                        if regex?.firstMatch(in: url.path, range: range) != nil {
                            // 用户行为统计
                            _ = self.userTrackStorage.add(
                                with: larkScene,
                                meegoScene: meegoScene,
                                userActivity: .exposeScene,
                                timestampMills: Int64(currentTimestampMills)
                            ).subscribe(onNext: { _ in
                                StrategyTracker.userTrack(
                                    larkScene: larkScene,
                                    meegoScene: meegoScene,
                                    userActivity: .exposeScene,
                                    url: url.absoluteString
                                )
                            })
                        }
                    }
                } else {
                    MeegoLogger.debug("escaped lark scene: \(rawLarkScene)", customPrefix: loggerPrefix)
                    StrategyTracker.monitor(with: rawLarkScene, url: url.absoluteString)
                }
                // unknown 来源暂时不处理
                break
            @unknown default: break
            }
        }
    }
}
