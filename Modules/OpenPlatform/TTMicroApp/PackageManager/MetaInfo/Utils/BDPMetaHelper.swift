//
//  BDPMetaHelper.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/9/6.
//  Meta工具类.

import Foundation
import ECOInfra
import LarkContainer

/// 小程序meta批量拉取工具类
public final class BDPBatchMetaHelper {
    public static func batchMetaConfig() -> BDPBatchMetaConfig {
        let configService = Injected<ECOConfigService>().wrappedValue
        let meta_expiration_time_setting = configService.getLatestDictionaryValue(for: "meta_expiration_time_setting")
        let batchMetaConfig = meta_expiration_time_setting?["batch_meta_config"] as? [String : Any]
        return BDPBatchMetaConfig(settings: batchMetaConfig)
    }
}

public enum BatchLaunchScene: String {
    case preloadLaunch = "preload_launch"
    case gadgetLaunch = "gadget_launch"
}

@objcMembers
public final class BDPBatchMetaHelperBridge: NSObject {
    public static func batchMetaDelaySeconds() -> Int {
        BDPBatchMetaHelper.batchMetaConfig().batchMetaDelaySeconds
    }
}

/// Settings中batch_meta_config配置
public struct BDPBatchMetaConfig {
    // 功能总入口，表示是否开启批量获取能力
    public let enable: Bool
    // 是否打开小程序开启时批量拉取的入口
    public let enableOnLaunchGadget: Bool
    // 是否打开飞书开启时批量拉取的入口
//    let enableOnLaunchApp: Bool
    // 当前批量拉取的meta数据版本标记位，用于降级
    public let batchMetaVersion: Int
    // 批量请求时最多不超过X个小程序
    let batchMetaCountConfig: BDPBatchMetaCountConfig
    // 延迟发起批量请求(默认值10秒)
    public let batchMetaDelaySeconds: Int

    public init(settings: [String : Any]?) {
        enable = settings?["enable"] as? Bool ?? false
        enableOnLaunchGadget = settings?["enable_on_launch_gadget"] as? Bool ?? false
//        enableOnLaunchApp = settings?["enable_on_launch_app"] as? Bool ?? false
        batchMetaVersion = settings?["batch_meta_version"] as? Int ?? 1
        batchMetaCountConfig = BDPBatchMetaCountConfig(settings: settings?["batch_meta_max_count"] as? [String : Any])
        batchMetaDelaySeconds = settings?["batch_meta_delay_seconds"] as? Int ?? Int.BatchMetaDelaySeconds
    }
}

//批量请求时最多不超过X个小程序
struct BDPBatchMetaCountConfig {
    // 默认场景(默认值50)
    public let defaultCount: Int
    // 小程序异步启动场景(默认值50)
    public let gadgetLaunch: Int
    // 飞书启动时的场景(默认值100)
    public let preloadLaunch: Int

    public init(settings: [String : Any]?) {
        defaultCount = settings?["default"] as? Int ?? Int.BatchMetaDefault
        gadgetLaunch = settings?[BatchLaunchScene.gadgetLaunch.rawValue] as? Int ?? defaultCount
        preloadLaunch = settings?[BatchLaunchScene.preloadLaunch.rawValue] as? Int ?? defaultCount
    }
    
    public func countWithScene(_ scene: BatchLaunchScene) -> Int {
        switch scene {
        case .preloadLaunch:
            return preloadLaunch
        case .gadgetLaunch:
            return gadgetLaunch
        }
        
    }
}

fileprivate extension Int {
    // 批量拉取meta默认值===start===
    static let BatchMetaDefault = 50
    static let BatchMetaDelaySeconds = 10
    // 批量拉取meta默认值===end===
}
