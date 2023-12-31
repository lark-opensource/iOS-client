//
//  LocationTaskSettings.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 5/14/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSetting
import LKCommonsLogging

/// LocationTask 配置
struct LocationTaskSettingModel: SettingDecodable {
    fileprivate static let logger = Logger.log(LocationTaskSettingModel.self, category: "LarkCoreLocation")
    static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_core_location_task_config")
    /// 使用SDK返回坐标的最长缓存 单位秒
    let maxLocationCacheTime: Int?
    let defaultServiceType: LocationServiceType?
    /// 是否在后台访问 CLLocationManager.locationServicesEnabled() 为了处理 偶现 进程间卡死现象
    let servicesEnabledBackground: Bool?
    let forceServiceType: LocationServiceType?
    /// 开启高德地图风险检测 默认为false
    let enableDetectRiskOfFakeLocation: Bool?
    /// 开启后台获取CLLocationManager.locationServicesEnabled()后，主线程等待的最长时间
    let getServicesEnabledWaitTimeout: Int?
    /// 单次定位是否使用新版本的 位置更新算法
    let isUseNewUpdateLocationAlgorithm: Bool?
    /// "updateCurrentLocationTimeout": 单次定位task中， updateCurrentLocation时，old Location 保存的最长时间,单位 秒
    let updateCurrentLocationTimeout: TimeInterval?
}

protocol LocationTaskSetting {}
// https://cloud.bytedance.net/appSettings-v2/detail/config/161982/detail/basic
extension LocationTaskSetting {

    private var taskSettings: LocationTaskSettingModel? {
        let result: LocationTaskSettingModel?
        do {
            result = try SettingManager.shared.setting(with: LocationTaskSettingModel.self) //Global
        } catch {
            LocationTaskSettingModel.logger.error("LocationTaskSetting lark_core_location_task_config decode error: \(error)")
            result = nil
        }
        LocationTaskSettingModel.logger.info("LocationTaskSetting lark_core_location_task_config result: \(String(describing: result))")
        return result
    }

    var maxLocationCacheTime: Int {
        return taskSettings?.maxLocationCacheTime ?? 30
    }

    var defaultServiceType: LocationServiceType {
        return taskSettings?.defaultServiceType ?? .aMap
    }

    var servicesEnabledBackground: Bool {
        return taskSettings?.servicesEnabledBackground ?? false
    }

    var forceServiceType: LocationServiceType? {
        return taskSettings?.forceServiceType
    }
    var detectRiskOfFakeLocation: Bool {
        return taskSettings?.enableDetectRiskOfFakeLocation ?? false
    }
    /// 开启后台获取CLLocationManager.locationServicesEnabled()后，主线程等待的最长时间，如果获取失败，默认是1000
    var getServicesEnabledWaitTimeout: Int {
        return taskSettings?.getServicesEnabledWaitTimeout ?? 1000
    }

    var isUseNewUpdateAlgorithm: Bool {
        return taskSettings?.isUseNewUpdateLocationAlgorithm ?? false
    }

    var updateCurrentLocationTimeout: TimeInterval {
        return taskSettings?.updateCurrentLocationTimeout ?? 3
    }
}
