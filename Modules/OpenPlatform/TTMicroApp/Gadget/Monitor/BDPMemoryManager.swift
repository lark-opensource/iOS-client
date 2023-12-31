//
//  BDPMemoryManager.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/7/8.
//

import Foundation
import LKCommonsLogging
import ECOInfra
import ECOProbe
import Heimdallr
import OPFoundation

enum BDPTriggerMemoryCleanScene: String {
    case API
    case sysMemoryWarning
    case renderCrash
    case slardarMemoryWarning
}

private let triggerByAPI = "specific_api"
private let triggerBySlardarMemoryWarning = "memory_warning"
private let triggerByRenderCrash = "render_crash"


@objc public final class BDPMemoryManager: NSObject {
    private let log = Logger.oplog(BDPMemoryManager.self, category: "BDPMemoryManager")
    private var isAddNoti = false
    
    @objc public static let sharedInstance: BDPMemoryManager = BDPMemoryManager()

    @objc public func startCleanMonitor(){
        guard let settings = settings else {
            log.warn("get nil settings from openplatform_gadget_memory_optimize")
            return
        }
        log.info("openplatform_gadget_memory_optimize settings value is \(settings)")
        if(!enableMemoryClean){
            return
        }
        guard let triggerScenes = triggerScenes, triggerScenes.contains(triggerBySlardarMemoryWarning) else {
            return
        }
        if(isAddNoti){
            //避免切租户反复监听
            return
        }
        //slardar memory warning from Lark iOS 内存压力监听方案: https://bytedance.feishu.cn/wiki/wikcnBptylmllRsEZDSQ0WkzcFg
        NotificationCenter.default.addObserver(self, selector: #selector(self.triggerMemoryCleanWithMemoryWarning), name: NSNotification.Name(rawValue: KHMDMemoryMonitorMemoryWarningNotificationName), object: nil)
        isAddNoti = true
    }
        
    @objc public func shouldTriggerBackgroundGadgetMemoryClean(uniqueId: BDPUniqueID) -> Bool{
        let shouldTriggerMemoryCleanByRenderCrash = shouldTriggerMemoryCleanByRenderCrash(uniqueId: uniqueId)
        if !shouldTriggerMemoryCleanByRenderCrash {
            return false
        }
        if let renderCrashShouldCleanActions = renderCrashShouldCleanActions {
            return renderCrashShouldCleanActions.contains("background_gadget")
        } else {
            return false
        }
    }
    
    @objc public func shouldTriggerPreloadRenderMemoryClean(uniqueId: BDPUniqueID) -> Bool{
        let shouldTriggerMemoryCleanByRenderCrash = shouldTriggerMemoryCleanByRenderCrash(uniqueId: uniqueId)
        if !shouldTriggerMemoryCleanByRenderCrash {
            return false
        }
        if let renderCrashShouldCleanActions = renderCrashShouldCleanActions {
            return renderCrashShouldCleanActions.contains("preloaded_render")
        } else {
            return false
        }
    }
    
    @objc public func shouldReloadAfterCrash(appID: String) -> Bool{
        if(!foregroundReloadEnable){
            return false
        }
        if let foregroundReloadAppIds = foregroundReloadAppIds {
            if foregroundReloadAppIds.contains(appID){
                return true
            }
            if foregroundReloadAppIds.count == 1 && foregroundReloadAppIds[0] == "*"{
                return true
            }
        }
        return false
    }

    @objc public func triggerMemoryCleanByRenderCrash(){
        if(!enableMemoryClean){
            return
        }
        log.info("triggerMemoryCleanByRenderCrash")
        let monitor = OPMonitor(EPMClientOpenPlatformCommonPerformanceCode.trigger_gadget_memory_optimize).timing()
        let monitorDic = cleanWithActions(cleanActions: renderCrashShouldCleanActions, scene: triggerByRenderCrash)

        monitor.setResultTypeSuccess()
            .addMap(monitorDic)
            .addCategoryValue("trigger_scene", triggerByRenderCrash)
            .timing()
            .setPlatform([.tea, .slardar])
            .flush()
    }

    
    public func triggerMemoryCleanByAPI(name: String){
        if(!enableMemoryClean){
            return
        }
        HMDOOMCrashDetector.triggerCurrentEnvironmentInformationSaving(withAction: name)
        
        guard let triggerScenes = triggerScenes, triggerScenes.contains(triggerByAPI) else {
            return
        }
        guard let allowAPIList = APIList, allowAPIList.contains(name) else {
            return
        }
        let memoryBytes_before = hmd_getMemoryBytes()
        let appMemory_before = memoryBytes_before.appMemory/1024/1024
        let availabelMemory_before = memoryBytes_before.availabelMemory/1024/1024
        
        ///API 场景下 飞书使用内存少于 阈值 且 设备剩余内存大于 阈值，则可不回收内存
        if appMemory_before < lark_memory_threshold_value && availabelMemory_before > system_remain_memory_threshold_value {
            log.info("memory is enough, will not triggerMemoryCleanByAPI \(appMemory_before) MB \(availabelMemory_before) MB")
            return
        }
        log.info("triggerMemoryCleanByAPI \(name)")
        let monitor = OPMonitor(EPMClientOpenPlatformCommonPerformanceCode.trigger_gadget_memory_optimize).timing()
        let monitorDic = cleanWithActions(cleanActions: APIShouldCleanActions, scene: triggerByAPI)

        monitor.setResultTypeSuccess()
            .addMap(monitorDic)
            .addCategoryValue("trigger_scene", triggerByAPI)
            .setPlatform([.tea, .slardar])
            .timing()
            .flush()
    }
    
                
}

 
extension BDPMemoryManager {
    @objc private func triggerMemoryCleanWithMemoryWarning(_ noti: NSNotification){
        guard let triggerScenes = triggerScenes, triggerScenes.contains(triggerBySlardarMemoryWarning),let memoryWarningShouldCleanActions = memoryWarningShouldCleanActions else {
            return
        }
        let userInfo = noti.userInfo
        let memoryPressureTypeValue = userInfo?["type"] as? Int32
        ///https://bytedance.feishu.cn/wiki/wikcnBptylmllRsEZDSQ0WkzcFg
        ///8 收到内存警告 (现有逻辑： BDPWarmBootManager 会回收所有应被回收的小程序)
        ///32 收到内存压力告警MemoryPressure4，随时有可能OOM
        ///128 收到内存压力告警MemoryPressure16，随时有可能OOM
        log.warn("get slardar memory warning for pressure \(memoryPressureTypeValue ?? -1)")
        if memoryPressureTypeValue != 8 && memoryPressureTypeValue != 32 && memoryPressureTypeValue != 128 {
            return
        }
        
        log.info("triggerMemoryCleanWithMemoryWarning")
        executeOnMainQueueAsync{
            let monitorDic = self.cleanWithActions(cleanActions: memoryWarningShouldCleanActions, scene: triggerBySlardarMemoryWarning)
            let monitor = OPMonitor(EPMClientOpenPlatformCommonPerformanceCode.trigger_gadget_memory_optimize).timing()
            monitor.setResultTypeSuccess()
                .addMap(monitorDic)
                .addCategoryValue("trigger_scene", triggerBySlardarMemoryWarning)
                .setPlatform([.tea, .slardar])
                .timing()
                .flush()
        }
        
    }
    
    private func shouldTriggerMemoryCleanByRenderCrash(uniqueId: BDPUniqueID) -> Bool{
        if(!enableMemoryClean){
            return false
        }
        guard let triggerScenes = triggerScenes, triggerScenes.contains(triggerByRenderCrash) else {
            return false
        }

        if let appIDWhiteList = appIDWhiteList, appIDWhiteList.contains(uniqueId.appID) {
            return false
        }
        
        return true
    }
    
    private func cleanWithActions(cleanActions: [String]?, scene: String) -> [String:Any]? {
        let memoryBytes_before = hmd_getMemoryBytes()
        let appMemory_before = memoryBytes_before.appMemory/1024/1024
        let availabelMemory_before = memoryBytes_before.availabelMemory/1024/1024

        guard let cleanActions = cleanActions, cleanActions.count != 0 else {
            return [:]
        }

        var resultDic = [String:Any]()
        
        var beforeCacheNum:Int32 = Int32.max
        var afterCacheNum: Int32 = Int32.max
        if cleanActions.contains("background_gadget") {
            resultDic = resultDic.merging(["background_gadget":true]){ $1 }
            BDPWarmBootManager.shared().cleanCacheWithoutappIDs(appIDWhiteList) { before, after in
                beforeCacheNum = before
                afterCacheNum = after
            }
        }
        if cleanActions.contains("preloaded_worker") {
            BDPJSRuntimePreloadManager.releaseAllPreloadRuntime(withReason: scene)
            resultDic = resultDic.merging(["preloaded_worker":true]){ $1 }

        }
        if cleanActions.contains("preloaded_render") {
            BDPAppPageFactory.releaseAllPreloadedAppPage(withReason: scene)
            resultDic = resultDic.merging(["preloaded_render":true]){ $1 }

        }

        ///上述回收触发后，需要大概10s才能真正降低内存，有一定的延时，因此实际回收内存不好评估，不埋了，根据清理的小程序个数、预加载来估算
        resultDic = resultDic.merging([
            "warm_gadget_num_before": beforeCacheNum,
            "warm_gadget_num_after": afterCacheNum,
            "app_memory_before": appMemory_before,
            "sys_remain_memory_before": availabelMemory_before,
        ]){ $1 }
        
        return resultDic
    }
}

//settings
extension BDPMemoryManager {
    private var settings: [String: Any]? {
        guard let s = ECOConfig.service().getLatestDictionaryValue(for: "openplatform_gadget_memory_optimize") else {
            return nil
        }
        return s
    }

    @objc public var enableMemoryClean: Bool {
        guard let s = settings, let enable = s["enable"] as? Bool else {
            return false
        }
        return enable
    }
    
    @objc public var backgroundCleanCountEnable: Bool {
        guard let s = settings, let backgroundCleanCountEnable = s["backgroundCleanCountEnable"] as? Bool else {
            return false
        }
        return backgroundCleanCountEnable
    }
    
    @objc public var tabReloadEnable: Bool {
        guard let s = settings, let tabReloadEnable = s["tabReloadEnable"] as? Bool else {
            return false
        }
        return tabReloadEnable
    }

    
    @objc public var maxReloadCount: Int {
        guard let s = settings, let maxReloadCount = s["maxReloadCount"] as? Int else {
            return 3
        }
        return maxReloadCount
    }
    
    private var triggerScenes : [String]? {
        guard let s = settings, let trigger_scenes = s["trigger_scene"] as? [String] else {
            return nil
        }
        return trigger_scenes
    }

    
    private var APIList : [String]? {
        guard let s = settings, let specific_api = s[triggerByAPI] as? [String: Any], let api_list = specific_api["api_list"] as? [String]? else {
            return nil
        }
        return api_list
    }
    
    private var lark_memory_threshold_value : Int {
        guard let s = settings, let specific_api = s[triggerByAPI] as? [String: Any], let lark_memory_threshold_value = specific_api["lark_memory_threshold_value"] as? Int else {
            return Int.max
        }
        return lark_memory_threshold_value
    }
    
    private var system_remain_memory_threshold_value : Int {
        guard let s = settings, let specific_api = s[triggerByAPI] as? [String: Any], let system_remain_memory_threshold_value = specific_api["system_remain_memory_threshold_value"] as? Int else {
            return 0
        }
        return system_remain_memory_threshold_value
    }

    
    private var appIDWhiteList : [String]? {
        guard let s = settings, let app_id_white_list = s["app_id_white_list"] as? [String]? else {
            return nil
        }
        return app_id_white_list
    }
    
    private var APIShouldCleanActions: [String]? {
        guard let s = settings, let specific_api = s[triggerByAPI] as? [String: Any], let should_clean = specific_api["should_clean"] as? [String]? else {
            return nil
        }
        return should_clean
    }
    
    private var memoryWarningShouldCleanActions: [String]? {
        guard let s = settings, let memory_warning = s[triggerBySlardarMemoryWarning] as? [String: Any], let should_clean = memory_warning["should_clean"] as? [String]? else {
            return nil
        }
        return should_clean
    }
    
    private var renderCrashShouldCleanActions: [String]? {
        guard let s = settings, let render_crash = s[triggerByRenderCrash] as? [String: Any], let should_clean = render_crash["should_clean"] as? [String]? else {
            return nil
        }
        return should_clean
    }

    private var foregroundReloadEnable : Bool {
        guard let s = settings, let enable = s["foregroundReloadEnable"] as? Bool else {
            return false
        }
        return enable
    }
    
    private var foregroundReloadAppIds : [String]? {
        guard let s = settings, let foregroundReloadAppIds = s["foregroundReloadAppIds"] as? [String]? else {
            return nil
        }
        return foregroundReloadAppIds
    }




}
