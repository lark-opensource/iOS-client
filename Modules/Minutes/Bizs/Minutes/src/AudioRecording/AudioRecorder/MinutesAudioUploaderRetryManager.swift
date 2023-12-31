//
//  MinutesAudioUploaderRetryManager.swift
//  Minutes
//
//  Created by yangyao on 2023/3/28.
//

import Foundation
import LarkSetting
import MinutesFoundation

struct AudioUploaderRetryRequest {
    // 重试类型
    enum RetryType {
        case common   // 常规
        case network  // 网络
    }
    let reqID: String
    let type: RetryType
}

struct AudioUploaderRetryResponse {
    let shouldRetry: Bool
    let retryInterval: Double?
    let rawRetryInterval: Double?
}

struct AudioUploaderRetryStrategy {
    enum RetryMethod {
        case linearRetry(interval: Double) // 线性重试
        case exponentialRetry // 指数间隔重试
        case notRetry     // 不重试
    }

    let method: RetryMethod
    let maxRetryCount: Int
}

struct RetryConfig {
    let interval: Double
    let maxCount: Int
}


let DefaultExponentialRetryCount = 2
let DefaultLinearRetryCount = Int.max
let DefaultLinearRetryInterval: Double = 5.0

class AudioUploaderRetryManager {
    let randomMaxSec: Double = 2.0
    // 最大重试间隔
    let maxRetrySeconds: Double = 30.0
    
    var cachedRetryCnt: [String: Int] = [:]

    var retryStrategy: [AudioUploaderRetryRequest.RetryType: AudioUploaderRetryStrategy] =
    [
        // 常规分片，最多2次
        .common: AudioUploaderRetryStrategy(method: .exponentialRetry, maxRetryCount: DefaultExponentialRetryCount),
        // 网络，设定 5s 重试，不限次数
        .network: AudioUploaderRetryStrategy(method: .linearRetry(interval: DefaultLinearRetryInterval), maxRetryCount: DefaultLinearRetryCount)
    ]


    func query(with request: AudioUploaderRetryRequest) -> AudioUploaderRetryResponse {
        if let config = linearConfig {
            retryStrategy[.network] = AudioUploaderRetryStrategy(method: .linearRetry(interval: config.interval), maxRetryCount: config.maxCount)
        }
        if let config = exponentialConfig {
            retryStrategy[.common] = AudioUploaderRetryStrategy(method: .exponentialRetry, maxRetryCount: config.maxCount)
        }
        MinutesLogger.upload.info("retry config updated: \(retryStrategy)")

        let reqID = request.reqID
        var count = cachedRetryCnt[reqID] ?? 0
        count += 1
        cachedRetryCnt[reqID] = count
        if let retryer = retryStrategy[request.type] {
            if count > retryer.maxRetryCount {
                return response(with: false, retryCount: nil)
            }
            switch retryer.method {
            case let .linearRetry(interval):
                var retryInterval = interval + random
                retryInterval = retryInterval < maxRetrySeconds ? retryInterval : maxRetrySeconds
                return AudioUploaderRetryResponse(shouldRetry: true, retryInterval: retryInterval, rawRetryInterval: interval)
            case .exponentialRetry:
                return response(with: true, retryCount: count)
            case .notRetry:
                return response(with: false, retryCount: nil)
            }
        }
        return response(with: false, retryCount: nil)
    }
    
    func response(with shouldRetry: Bool, retryCount: Int?) -> AudioUploaderRetryResponse {
        guard shouldRetry == true else {
            return AudioUploaderRetryResponse(shouldRetry: false, retryInterval: nil, rawRetryInterval: nil)
        }
        let count = Double(retryCount ?? 1)
        let rawRetryInterval = Double(pow(2, count))
        var retryInterval = rawRetryInterval + random
        retryInterval = retryInterval < maxRetrySeconds ? retryInterval : maxRetrySeconds
        let res = AudioUploaderRetryResponse(shouldRetry: true, retryInterval: retryInterval, rawRetryInterval: rawRetryInterval)
        return res
    }
    
    var random: Double {
        Double.random(in: 0..<randomMaxSec)
    }

    func clean() {
        cachedRetryCnt.removeAll()
    }

    lazy var linearConfig: RetryConfig? = {
        if let settings = try? SettingManager.shared.setting(with: .make(userKeyLiteral: "vc_minutes_record_upload_config")) {
            if let config = settings["linear"] as? [String: Int] {
                MinutesLogger.upload.info("linear config: \(config)")
                var interval: Double = DefaultLinearRetryInterval
                if let val = config["interval"] {
                    interval = Double(val)
                }
                interval = (interval == -1) ? DefaultLinearRetryInterval : interval

                var maxCount = config["max_count"] ?? DefaultLinearRetryCount
                maxCount = (maxCount == -1) ? DefaultLinearRetryCount : maxCount
                return RetryConfig(interval: interval, maxCount: maxCount)
            }
        }
        return nil
    }()

    lazy var exponentialConfig: RetryConfig? = {
        if let settings = try? SettingManager.shared.setting(with: .make(userKeyLiteral: "vc_minutes_record_upload_config")) {
            if let config = settings["exponential"] as? [String: Int] {
                MinutesLogger.upload.info("exponential config: \(config)")
                var maxCount = config["max_count"] ?? DefaultExponentialRetryCount // 默认
                maxCount = (maxCount == -1) ? DefaultLinearRetryCount : maxCount
                return RetryConfig(interval: 0, maxCount: maxCount)
            }
        }
        return nil
    }()
}

