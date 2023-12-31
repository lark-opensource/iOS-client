//
//  UpgradeTracker.swift
//  LarkVersion
//
//  Created by liuxianyu on 2021/7/26.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkReleaseConfig
import LarkStorage

enum UpgradePopupType: String {
    case mandatoryUpgrade = "mandatory_upgrade"
    case nonMandatoryUpgrade = "non_mandatory_upgrade"
    case test
}

enum TestFlightUpgradePopupType: String {
    case appstoreUpgrade = "new"      //无飞书体验版，新下载
    case testFlightUpgrade = "update" //有飞书体验版版，需要升级
}

enum TestFlightUpgradeClickType: String {
    case appstoreClick = "appstore"      //无TestFlight，前往appstore
    case downloadClick = "download"      //有TestFlight，点击下载飞书体验版
    case cancleClick = "cancel"          //取消
}

enum UpgradePopupMode: String {
    case auto
    case click
}

enum UpgradePopupClick: String {
    case cancel
    case upgrade
}

enum KAUpgradeData {
    @KVConfig(key: KVKeys.Version.kaDeployStrategyIdKey, store: KVStores.Version.glboal)
    static var kaDeployStrategyId: String

    @KVConfig(key: KVKeys.Version.kaDeployTicketIdKey, store: KVStores.Version.glboal)
    static var kaDeployTicketId: String

    @KVConfig(key: KVKeys.Version.planIdKey, store: KVStores.Version.glboal)
    static var planId: String

    @KVConfig(key: KVKeys.Version.KAOldVerisonKey, store: KVStores.Version.glboal)
    static var KAOldVerison: String
}

final class UpgradeTracker {
    /// 应用内升级提示弹窗页面
    static func trackPublicUpgradePopupView(popupType: UpgradePopupType,
                                            popupMode: UpgradePopupMode) {
        let params = ["popup_type": popupType.rawValue,
                      "popup_mode": popupMode.rawValue]
        Tracker.post(TeaEvent(Homeric.PUBLIC_UPGRADE_POPUP_VIEW,
                              params: params))
    }

    /// 在页面的点击
    static func trackPublicUpgradePopupClick(popupClick: UpgradePopupClick,
                                             popupType: UpgradePopupType,
                                             popupMode: UpgradePopupMode) {
        let params = ["click": popupClick.rawValue,
                      "popup_type": popupType.rawValue,
                      "popup_mode": popupMode.rawValue,
                      "target": "none"]
        Tracker.post(TeaEvent(Homeric.PUBLIC_UPGRADE_POPUP_CLICK,
                              params: params))
    }

    static func trackUpgradeAction() {
        Tracker.post(TeaEvent(Homeric.UPGRADE_ACTION))
    }

    static func trackShowUpgradeView() {
        Tracker.post(TeaEvent(Homeric.UPGRADE_POPUP))
    }

    static func trackKAUpgrade() {
        guard ReleaseConfig.isKA,
              let newVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }

        let oldVersion = KAUpgradeData.KAOldVerison
        guard !oldVersion.isEmpty else {
            // 全新安装没有旧版本，写入一个当前版本
            KAUpgradeData.KAOldVerison = newVersion
            return
        }
        
        let newMajorVerison = newVersion[..<(newVersion.lastIndex(of: ".") ?? newVersion.endIndex)]
        let oldMajorVerison = oldVersion[..<(oldVersion.lastIndex(of: ".") ?? oldVersion.endIndex)]
        if newMajorVerison.compare(oldMajorVerison, options: .numeric) == .orderedDescending {
            Tracker.post(TeaEvent(Homeric.INFRA_CLIENT_KA_UPGRADING_EVENT,
                                  params: ["ka_deploy_strategy_id": KAUpgradeData.kaDeployStrategyId,
                                           "ka_deploy_ticket_id": KAUpgradeData.kaDeployTicketId,
                                           "plan_id": KAUpgradeData.planId]))
            KAUpgradeData.KAOldVerison = newVersion
        }
    }
    
    //有TestFlight，在「feed流」主页面飞书体验版引导下载弹窗的展示事件
    static func trackPublicDemoDownloadView() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_DEMO_DOWNLOAD_VIEW,
                              params: trackPublicTestFlightViewParam()))
    }
    
    //无TestFlight，在「feed流」主页面TestFlight引导下载弹窗的展示事件
    static func trackPublicTestflightDownloadView() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_TESTFLIGHT_DOWNLOAD_VIEW,
                              params: trackPublicTestFlightViewParam()))
    }
    
    //无TestFlight，下载TestFlight后，在「feed流」主页面飞书体验版引导下载弹窗的展示事件
    static func trackPublicTestflightDownloadAfterView() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_TESTFLIGHT_DOWNLOAD_AFTER_VIEW,
                              params: trackPublicTestFlightViewParam()))
    }
    
    //有TestFlight，在「feed流」主页面飞书体验版引导下载弹窗的动作事件
    static func trackPublicDemoDownloadClick(clickType: TestFlightUpgradeClickType) {
        Tracker.post(TeaEvent(Homeric.PUBLIC_DEMO_DOWNLOAD_CLICK,
                              params: trackPublicTestFlightClickParam(clickType: clickType)))
    }
    
    //无TestFlight，在「feed流」主页面TestFlight引导下载弹窗的动作事件
    static func trackPublicTestflightDownloadClick(clickType: TestFlightUpgradeClickType) {
        Tracker.post(TeaEvent(Homeric.PUBLIC_TESTFLIGHT_DOWNLOAD_CLICK,
                              params: trackPublicTestFlightClickParam(clickType: clickType)))
    }
    
    //无TestFlight，下载TestFlight后，在「feed流」主页面飞书体验版引导下载弹窗的动作事件
    static func trackPublicTestflightDownloadAfterClick(clickType: TestFlightUpgradeClickType) {
        Tracker.post(TeaEvent(Homeric.PUBLIC_TESTFLIGHT_DOWNLOAD_AFTER_CLICK,
                              params: trackPublicTestFlightClickParam(clickType: clickType)))
    }
    
    static func trackPublicTestFlightViewParam() -> [AnyHashable : Any] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "none"
        let popupType: TestFlightUpgradePopupType = isTestFlightVersion() ? .testFlightUpgrade : .appstoreUpgrade
        return ["type": popupType.rawValue, "version": version]
    }
    
    static func trackPublicTestFlightClickParam(clickType: TestFlightUpgradeClickType) -> [AnyHashable : Any] {
        var param = trackPublicTestFlightViewParam()
        param["click"] = clickType.rawValue
        return param
    }
    
    // 是否是TestFlight下载的飞书版本
    static func isTestFlightVersion() -> Bool {
        let channelTF = Bundle.main.infoDictionary?["DOWNLOAD_CHANNEL"] as? String ?? ""
        return channelTF == "testflight"
    }
}
