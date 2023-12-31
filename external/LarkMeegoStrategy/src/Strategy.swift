import Foundation
import LarkMeegoStorage

// 具体策略配置详见：https://cloud.bytedance.net/appSettings-v2/detail/config/170800/detail/status

public enum TriggerCondition {
    /// 入口点击量/场景曝光量 触发预请求最小阈值
    case sceneExposureCount(Int)

    /// 入口点击率/场景曝光率，范围为 [0, 100]
    case sceneExposureRate(Double)
}

public struct PreRequestConfig {
    // path 正则表达式
    public let pathRegex: String

    // 缓存时长（s）
    public let expiredSeconds: Int

    // 按场景的触发条件
    public let triggerConditions: [LarkScene: [TriggerCondition]]

    public init(rawConfig: [String: Any]) throws {
        guard let pathRegex = rawConfig["path_regex"] as? String,
              let expireSeconds = rawConfig["expired_seconds"] as? Int,
              rawConfig["message"] != nil || rawConfig["messageCard"] != nil
        else {
            throw NSError(domain: "PreRequestConfig Construction", code: -1)
        }
        self.pathRegex = pathRegex
        self.expiredSeconds = expireSeconds
        var triggerConditions: [LarkScene: [TriggerCondition]] = [:]

        func fillConditions(_ rawConditions: [String: Any], whichScene: LarkScene) {
            var conditions: [TriggerCondition] = []
            if let sceneExposureCount = rawConditions["scene_exposure_count_threshold"] as? Int {
                conditions.append(.sceneExposureCount(sceneExposureCount))
            }
            if let sceneExposureRate = rawConditions["scene_exposure_rate_threshold"] as? Double {
                conditions.append(.sceneExposureRate(sceneExposureRate))
            }
            triggerConditions[whichScene] = conditions
        }
        if let message = rawConfig["message"] as? [String: Any] {
            fillConditions(message, whichScene: .message)
        }
        if let messageCard = rawConfig["message_card"] as? [String: Any] {
            fillConditions(messageCard, whichScene: .messageCard)
        }
        self.triggerConditions = triggerConditions
    }
}

public struct StrategyConfig {
    /// 时间窗口长度，单位（天），用来分析用户在该时间窗口内的行为
    public let timeWindowForAnalyze: Int

    /// meego 在 lark 中的场景，用来统计 lark 不同场景下的数据
    public let larkScene: [String: LarkScene]

    /// 预请求配置
    public let preRequestConfigs: [MeegoScene: PreRequestConfig]

    public init(rawConfig: [String: Any]) {
        timeWindowForAnalyze = (rawConfig["time_window_for_analyze"] as? Int) ?? 7
        if let rawLarkScene = rawConfig["lark_scene"] as? [String: String] {
            larkScene = rawLarkScene.compactMapValues { LarkScene(rawValue: $0) }
        } else {
            larkScene = [:]
        }
        var preRequestConfigs: [MeegoScene: PreRequestConfig] = [:]
        if let detail = (rawConfig["pre_request_config"] as? [String: Any])?["detail"] as? [String: Any],
           let preRequestConfig = try? PreRequestConfig(rawConfig: detail) {
            preRequestConfigs[.detail] = preRequestConfig
        }
        if let singleView = (rawConfig["pre_request_config"] as? [String: Any])?["singleView"] as? [String: Any],
           let preRequestConfig = try? PreRequestConfig(rawConfig: singleView) {
            preRequestConfigs[.singleView] = preRequestConfig
        }
        self.preRequestConfigs = preRequestConfigs
    }
}
