//
//  ManualOfflineConfig.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/21.
//  

import Foundation
import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra

public enum ManualOfflineConfig {
    public static func saveConfigToLocal(_ configDict: StructManuOfflieConfig) {

        DocsLogger.error("手动离线FG：\(configDict)", component: LogComponents.manuOffline)
        let configDic: [String: Any] = [
            "manual_offline_enabled": configDict.manualOfflineEnabled,
            "manual_offline_watch_max_num": configDict.manualOfflineWatchMaxNum,
            "manual_offline_suspend_time": configDict.manualOfflineSuspendTime,
            "doc_enabled": configDict.docEnabled,
            "drive_enabled": configDict.driveEnabled,
            "sheet_enabled": configDict.sheetEnabled,
            "bitable_enabled": configDict.bitableEnabled,
            "slide_enabled": configDict.slideEnabled,
            "mindnote_enabled": configDict.mindnoteEnabled,
            "guide_enabled": configDict.guideEnabled
        ]

        if let configString = JSON(configDic).rawString(),
            !configString.isEmpty {
            DocsLogger.info("manuOfflineFG:\(configString)", component: LogComponents.manuOffline)
            CCMKeyValue.globalUserDefault.set(configString, forKey: UserDefaultKeys.manualOfflineEnable)
        }
    }

    private static var configJson: JSON?

    private static let getConfigLock = NSLock()

    public static func getConfig() -> JSON {
        getConfigLock.lock()
        defer {
            getConfigLock.unlock()
        }
        if let config = configJson {
            return config
        }

        guard
            let configString = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.manualOfflineEnable),
            !configString.isEmpty
            else {
                let emptyConfig = JSON()
                configJson = emptyConfig
                return emptyConfig
        }

        let config = JSON(parseJSON: configString)
        configJson = config
        return config
    }

    public static func clear() {
        CCMKeyValue.globalUserDefault.removeObject(forKey: UserDefaultKeys.manualOfflineEnable)
        configJson = nil
    }

    /// 手动离线FG
    public static var enable: Bool {
        return DocsConfigManager.isShowOffline
    }

    /// 首页，离线新手引导
    public static var enableMainPageGuide: Bool {
        let config = getConfig()
        return config["guide_enabled"].boolValue
    }

    /// 监听的文档的数量，单位：篇
    public static var watchMaxNum: Int {
        let config = getConfig()
        return config["manual_offline_watch_max_num"].intValue
    }

    /// app切换到后台后经过多长时间暂停监听，回到前台重新监听，单位：ms
    public static var suspendTime: TimeInterval {
        let config = getConfig()
        return config["manual_offline_suspend_time"].doubleValue
    }

    public static func enableFileType(_ type: DocsType) -> Bool {
        guard enable else { return false } // 手动离线功能总开关

        let config = getConfig()
        switch type {
        case .doc, .file, .mediaFile, .sheet:
            return true
        case .bitable:
            return config["bitable_enabled"].boolValue
        case .slides:
            return config["slide_enabled"].boolValue
        case .mindnote:
            return config["mindnote_enabled"].boolValue
        case .docX:
            return LKFeatureGating.docxManualOfflineEnabled
        default:
            return false
        }
    }
}
