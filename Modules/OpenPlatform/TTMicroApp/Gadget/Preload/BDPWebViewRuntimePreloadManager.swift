//
//  BDPWebViewRuntimePreloadManager.swift
//  TTMicroApp
//
//  Created by justin on 2022/9/19.
//

import Foundation
import OPSDK
import ECOInfra
import ECOProbe


@objcMembers public final class BDPWebViewRuntimePreloadManager : NSObject {

    // 收集小程序信息开关是否打开
    private static func enableGadgetLaunchInfo() -> Bool {
        BDPPreloadHelper.recordAppLaunchInfoEnable()
    }

    /// 记录小程序历史打开信息
    /// - Parameters:
    ///   - topN: 最近几个
    ///   - lastFewDays: 最近几天
    /// - Returns: 返回打开小程序的app_id
    private static func gadgetLaunchInfo(_ topN: Int, lastFewDays: Int) -> [String]? {
        if lastFewDays < 1 {
            return nil
        }
        // 校验小程序信息收集功能是否打开
        if !enableGadgetLaunchInfo() {
            return nil
        }

        guard let launchAccessor = LaunchInfoAccessorFactory.launchInfoAccessor(type: .gadget) else {
            return nil
        }

        return launchAccessor.queryTop(most: topN, beforeDays: lastFewDays)
    }
    /// 是否关闭预加载
    /// - Parameters:
    ///   - preloadScene: 预加载场景
    ///   - settingSceneKey: 预加载场景对应setting 配置key
    /// - Returns: 默认false，不关闭(允许预加载)，满足setting 条件时才会关闭预加载
    private static func disablePreload(_ preloadScene: String, settingSceneKey: String) -> Bool {
        // 如果FG禁用预加载使用率优化, 关闭预加功能也关闭，返回false
        if OPSDKFeatureGating.disablePreloadUsePercent() {
            return true
        }
        if OPGadgetDRManager.shareManager.isDRRunning(){
            return true
        }
        guard let disableScenes = scenesForDisable(settingSceneKey), disableScenes.contains(preloadScene) else {
            return false
        }
        // 最近N天内打开小程序数量小于等于0 ，不预加载
        guard let launchInfo = gadgetLaunchInfo(1, lastFewDays: lastFewDayForDisable()) , launchInfo.count <= 0 else {
            return false
        }
        return true
    }

    /// webview 的预加载是否关闭
    /// - Parameter preloadScene: 预加载场景
    /// - Returns: 是否关闭
    public static func disableWebViewPreload(_ preloadScene: String) -> Bool {
        return disablePreload(preloadScene, settingSceneKey: "render_disable_scenes")
    }
    /// runtime 的预加载是否关闭
    /// - Parameter preloadScene: 预加载场景
    /// - Returns: 是否关闭
    public static func disableRuntimePreload(_ preloadScene: String) -> Bool {
        return disablePreload(preloadScene, settingSceneKey: "worker_disable_scenes")
    }

    /// webview & jsruntime 预加载统计埋点上报，用于统计预加载命中使用率情况
    /// - Parameters:
    ///   - preloadScene: 预加载场景
    ///   - params: 其他埋点参数
    ///
    /// - 参考：`https://bytedance.feishu.cn/docx/Txgud1ziAoQFL6xj2QdcvpGIn1c`
    public class func monitorEvent(_ preloadScene: String?, params:[String:Any]?){
        // 如果FG禁用预加载使用率优化, 预加载埋点上报功能也关闭
        if OPSDKFeatureGating.disablePreloadUsePercent() {
            return
        }
        
        OPMonitor("op_render_worker_preload")
            .addCategoryValue("preload_scene",preloadScene)
            .addMap(params)
            .flush()
    }
}

extension BDPWebViewRuntimePreloadManager {

    public static var disableSettings: [String: Any]? {
        guard let settings = ECOConfig.service().getDictionaryValue(for: "openplatform_gadget_disable_preload_webviewruntime") else {
            return nil
        }
        return settings
    }

    /// 最近N天没有数据，根据场景禁用预加载
    /// - Returns: 读取本地N天小程使用信息
    public static func lastFewDayForDisable() -> Int {
        guard let settings = disableSettings, let latestDay = settings["last_few_days"] as? Int else {
            return 0
        }
        return latestDay
    }

    /// 哪些场景会禁用预加载
    /// - Parameter settingSceneKey: 禁用预加载场景对应的setting key
    /// - Returns: 禁用的预加载场景，数组类型
    public static func scenesForDisable(_ settingSceneKey: String) -> [String]? {
        guard let settings = disableSettings, let preloadScenes = settings[settingSceneKey] as? [String] else {
            return nil
        }
        return preloadScenes
    }
}
