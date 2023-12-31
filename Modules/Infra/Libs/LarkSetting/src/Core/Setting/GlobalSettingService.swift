//
//  GlobalSettingService.swift
//  LarkSetting
//
//  Created by ByteDance on 2023/12/4.
//

import Foundation
import LKCommonsLogging


public protocol GlobalSettingService {
    /// Setting 更新通用方法,
    /// 调用方: 登录流程、Setting拉取
    func settingUpdate(settings: [String: String], id: String, sync: Bool)

    /// 异步队列中有序更新一个setting key的值
    func updateSettingValue(with id: String, and key: String, value newValue: String)
}

struct GlobalSettingServiceImpl {
    static let SettingUpdateQueue = DispatchQueue(label: "setting.update.queue")
    static let logger = Logger.log(GlobalSettingServiceImpl.self, category: "GlobalSettingService")

    private func settingUpdateInner(settings: [String: String], id: String, sync: Bool) {
        let startTime = Date()
        SettingStorage.update(settings, id: id)
        if let feature = try? SettingStorage.setting(with: id,
                                                     type: LarkFeature.self,
                                                     key: LarkFeature.settingKey.stringValue) {
            FeatureGatingStorage.update(with: feature, and: id)
        }
        let endTime = Date()
        let timeCostMs = endTime.timeIntervalSince(startTime) * 1000
        Self.logger.debug("settingUpdate: id: \(id), sync: \(sync), cost: \(timeCostMs)ms")
        if sync {
            FeatureGatingSyncEventCollector.shared.syncCost(id, timeCostMs)
        }
    }
}

extension GlobalSettingServiceImpl: GlobalSettingService {

    /// Setting 更新通用方法,
    /// 调用方: 登录流程、Setting拉取
    func settingUpdate(settings: [String: String], id: String, sync: Bool = true) {
        if sync {
            settingUpdateInner(settings: settings, id: id, sync: sync)
        }else {
            // 异步队列有序更新
            Self.SettingUpdateQueue.async {
                settingUpdateInner(settings: settings, id: id, sync: sync)
            }
        }
    }

    /// 异步队列中有序更新一个setting key的值
    func updateSettingValue(with id: String, and key: String, value newValue: String) {
        Self.SettingUpdateQueue.async {
            SettingStorage.updateSettingValue(newValue, with: id, and: key)
        }
    }
}
