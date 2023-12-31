//
//  RecentOfflineConfig.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/6/18.
//  

import Foundation
import SKInfra

extension OpenAPI {
    public struct RecentCacheConfig {
        /// 是否enable 离线缓存
        public static var isEnable: Bool {
            return SettingConfig.offlineCacheConfig?.offlineCacheEnable ?? false
        }
        public static var preloadPictureWifiOnly: Bool {
            return SettingConfig.offlineCacheConfig?.preloadImageOnlyWifi ?? true
        }
        /// 是否只在wifi下执行预加载clientVar
        public static var isPreloadClientVarOnlyInWifi: Bool {
            return SettingConfig.offlineCacheConfig?.onlyWifi ?? true
        }
        ///每次最多预加载多少篇
        public static var preloadClientVarNumber: Int {
            return SettingConfig.offlineCacheConfig?.recentListPreloadClientvarNumber ?? 30
        }
        ///clientvar更新时间间隔
        public static var updateClientvarFrequency: Int {
            return SettingConfig.offlineCacheConfig?.updateClientVarFrequency ?? 43200
        }
    }
}
