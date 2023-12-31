//
//  OPGadgetDRManager.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/17.
//

import Foundation
import OPFoundation
import Dispatch
import ECOProbe
import LarkCache
import LarkContainer

/// 小程序容灾方案技术文档：https://bytedance.feishu.cn/wiki/wikcnpqWa5lMPivtytV7Chy5oqg
/// setting 配置地址： https://cloud.bytedance.net/appSettings-v2/detail/config/173887/detail/whitelist-detail/88910

/// 容灾触发来源：
///  0. 未知来源，啥都不处理
///  1. 发布settings配置触发;
///  2. lark 设置清理缓存，用户手动触发；
///  3. 小程序菜单中清理缓存，用户手动触发
public enum DRTriggerScene : Int ,Equatable {
    case unknown = 0
    case serverSetting = 1
    case larkSetting = 2
    case gadgetMenuClearCache = 3
}


/// 每次容灾任务生命周期回调
protocol OPGadgetDRModuleGroupLifecycle : AnyObject {
    func finishModuleGroup(moduleGroup:OPGadgetDRModuleGroup)
}

/// 容灾框架
@objc public class OPGadgetDRManager: NSObject, OPGadgetDRModuleGroupLifecycle, OPDisasterRecoverProtocol{
    
    @objc public static let shareManager = OPGadgetDRManager()
    private var moduleGroups: [OPGadgetDRModuleGroup] = []
    private var finishedModuleGroups: [OPGadgetDRModuleGroup] = []
    private var allFinishCallBack:[() -> Void] = []
    private let serizeralQueue = DispatchQueue(label: "openplatform.gadget.disasterrecover",qos: .default)
    private let lock: OPGadgetDRRecursiveLock = OPGadgetDRRecursiveLock()
    
    /// 表明当前没有登录，所有任务需要登录后执行
    /// 飞书设置触发清理有可能比较早，如果早于登录，就不执行容灾中清理逻辑，按照老逻辑执行
    @objc public var isFinishLogin : Bool = false
    
    /// 容灾配置全局开关
    private var featureSwitch: DRFeatureSwitchConfig = DRFeatureSwitchConfig(config: nil)
    
    @objc public static func sharedPlugin() -> BDPBasePluginDelegate! {
        return Self.shareManager
    }
    
    override init() {
        // 注册容灾模块可以清理的模块
        OPGadgetDRModuleGroup.registerDRModule(OPGadgetDRJSSDKModule.self)
        OPGadgetDRModuleGroup.registerDRModule(OPGadgetDRPKMModule.self)
        OPGadgetDRModuleGroup.registerDRModule(OPGadgetDRPreloadModule.self)
        OPGadgetDRModuleGroup.registerDRModule(OPGadgetDRWarmBootModule.self)
        super.init()
    }
    
    
    /// 注册全部容灾任务回调
    /// - Parameter finishCallback: 容灾回调
    @objc public func registerDRFinished(_ finishCallback: @escaping () -> Void) {
        lock.sync {
            // 加锁强制判断当前是否有容灾任务在执行，没有直接返回；
            // 有的话加入队列等待回调
            if moduleGroups.isEmpty {
                finishCallback()
            }else {
                allFinishCallBack.append(finishCallback)
            }
        }
    }
    
    
    /// 获取不需要清理应用的appIds，两类应用：主导航应用 和 后台播放引用
    /// - Returns: 不需要清理应用的Appids
    func getAllNotClearGadgetIds() -> [String]? {
        guard let allAliveAppIds = BDPWarmBootManager.shared().aliveAppUniqueIdSet else {
            return nil
        }
        var notClearGadgetIds: [String] = []
        allAliveAppIds.forEach { uniqueID in
            if BDPWarmBootManager.shared().isAutoDestroyEnable(with: uniqueID) || OPGadgetRotationHelper.isTabGadget(uniqueID) {
                if !uniqueID.appID.isEmpty {
                    notClearGadgetIds.append(uniqueID.appID)
                }
            }
        }
        return notClearGadgetIds
    }
    
    /// 校验server setting 是否可以发起容灾
    /// 同一个容灾配置执行超过3次，不再触发容灾；容灾配置生效已经过期，并且之前没有执行过就不再触发
    /// - Parameters:
    ///   - settingConfig: settings 解析 ``OPGadgetDRConfig`` model
    ///   - preDRCacheConfig: 本地缓存配置
    /// - Returns: $0 是否可以容灾，$1 同一个配置是第几次容灾，不同配置时值为0
    func compareConfig(settingConfig: OPGadgetDRConfig, preDRCacheConfig: DRCacheConfig?) -> (Bool, Int) {
        var executionCount: Int = 0
        if let preConfig = preDRCacheConfig, preConfig.md5 == settingConfig.md5 {
            if preConfig.state == .finished {
                OPGadgetDRLog.logger.info("DisasterRecover had finished")
                return (false, executionCount)
            }
            executionCount = preConfig.executionCount
        }
        
        if executionCount >= settingConfig.retryCountLimit {
            OPGadgetDRLog.logger.info("trigger disaster recover failed for config is over \(settingConfig.retryCountLimit) times!")
            return (false, executionCount)
        }else if !settingConfig.isValidateTime()  {
            OPGadgetDRLog.logger.info("trigger disaster recover failed for config is time invalidate!")
            return (false, executionCount)
        }
        return (true, executionCount)
    }
    
    
    /// 以当前容灾配置为准：获取当前最新容灾setting 配置
    /// 1.如果为空就不执行容灾；
    /// 2.如果不为空，比较和之前是否一样；不一样执行当前配置容灾；如果一样需要过滤是否超出时间和超过次数限制
    /// 根据setting 配置校验是否需要触发容灾
    /// - Parameter settings: setting 容灾配置
    @objc public func settingUpdateForDR(_ settings:[String : AnyObject]?, md5:String?, userID:String){
        guard let safeSettings = settings, let safeMD5 = md5 else {
            OPGadgetDRLog.logger.info("trigger failed for config is nil.")
            return
        }
        
        //如果内存中存在打开小程序，就不执行容灾
        if BDPWarmBootManager.shared().hasCacheData() {
            OPGadgetDRLog.logger.info("trigger disaster recover failed is there warmboot gadget.")
            return
        }
        
        let cacheKey = DRCacheConfig.cacheKey(userID)
        let settingConfig = OPGadgetDRConfig(config: safeSettings, md5: safeMD5, cacheKey: cacheKey)
        let preCacheConfig = DRCacheConfig.getLocalDRConfig(cacheKey: cacheKey)
        let (canDR, executionCount) = compareConfig(settingConfig: settingConfig, preDRCacheConfig: preCacheConfig)
        if !canDR {
            return
        }
        
        settingConfig.executionCount = executionCount + 1
        triggerDRModule(moduleConfig: settingConfig, triggerScene: .serverSetting)
    }
    
    
    
    /// 当前小程序是否与主导航小程序有相同的PKM（Meta & package）
    /// - Parameter uniqueID: 当前小程序 uniqueID
    /// - Returns: true , 相同； false 不同
    func hasSameTabGadgetPKM(uniqueID: OPAppUniqueID) -> Bool {
        guard let allAliveAppIds = BDPWarmBootManager.shared().aliveAppUniqueIdSet else {
            return false
        }
        
        var isSame = false
        for liveUniqueID in allAliveAppIds {
            if OPGadgetRotationHelper.isTabGadget(liveUniqueID), liveUniqueID.appID == uniqueID.appID {
                isSame = true
                break
            }
        }
        return isSame
    }
    
    
    /// 小程序菜单栏中清理缓存触发，
    /// 过滤条件：当前小程序不是主导航小程序会触发清理
    /// - Parameter uniqueID: 当前小程id 信息
    @objc public func menuCleanCacheForDR(_ uniqueID: OPAppUniqueID?) {
        guard let safeUniqueID = uniqueID else {
            OPGadgetDRLog.logger.info("trigger disaster recover failed for uniqueID is nil.")
            return
        }
        
        if OPGadgetRotationHelper.isTabGadget(safeUniqueID) {
            OPGadgetDRLog.logger.info("rigger disaster recover failed for uniqueID app is tab gadget.")
            return
        }
        let sameTabPKM = hasSameTabGadgetPKM(uniqueID: safeUniqueID)
        let menuConfig = OPGadgetDRConfig(uniqueID: safeUniqueID, sameTabPKM: sameTabPKM)
        triggerDRModule(moduleConfig: menuConfig, triggerScene: .gadgetMenuClearCache)
    }
    
    /// 手动触发飞书-->设置-->通用-->清理缓存
    /// 过滤条件：主导航小程序、后台播放是JSSDK不会清理，并且对应小程序PKM、PRELOAD、WARMBOOT 不会被清理；
    /// 过滤条件以外小程序的PKM、PRELOAD、WARMBOOT 都会被清理
    public func larkSettingClearCache(completion: @escaping CleanTask.Completion) {
        let allNotClearAppIds = getAllNotClearGadgetIds()
        let config = OPGadgetDRConfig(needRetainAppIds: allNotClearAppIds, completion: completion)
        triggerDRModule(moduleConfig: config, triggerScene: .larkSetting)
    }
    
    /// 触发容灾任务
    /// - Parameters:
    ///   - moduleConfig: 触发配置，setting 或者手动
    ///   - triggerScene: 触发来源，``DRTriggerScene``
    func triggerDRModule(moduleConfig: OPGadgetDRConfig?, triggerScene: DRTriggerScene) {
        guard let safeModuleCofig = moduleConfig , triggerScene != .unknown else {
            OPGadgetDRLog.logger.info("trigger disaster recover failed for config is nil!")
            return
        }
        serizeralQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            // 相同的配置已经开始执行就直接返回
            var hasSameDR = false
            self.lock.sync {
                for groupItem in self.moduleGroups {
                    if safeModuleCofig.isEqualConfig(groupItem.moduleConfig) {
                        hasSameDR = true
                        break
                    }
                }
            }
            if hasSameDR {
                OPGadgetDRLog.logger.warn("trigger disaster recover failed for same config and \(triggerScene) scene")
                return
            }
            
            let drModuleGroup = OPGadgetDRModuleGroup(moduleConfig: safeModuleCofig)
            drModuleGroup.groupLifeCycle = self
            var groupsCount = 0
            self.lock.sync {
                self.moduleGroups.append(drModuleGroup)
                groupsCount = self.moduleGroups.count
            }
            // 当前只有一个任务，立即开始，否则加入队列中，等待其他任务执行完成后开始执行
            if groupsCount == 1 {
                drModuleGroup.executeModule()
            }
        }
    }
    
    
    /// 一次容灾任务执行完成回调
    /// - Parameter moduleGroup: 容灾任务，group 中包含多个 ``OPGadgetDRModule``
    func finishModuleGroup(moduleGroup:OPGadgetDRModuleGroup) {
        self.serizeralQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            var nextModuleGroup : OPGadgetDRModuleGroup? = nil
            self.lock.sync {
                if self.moduleGroups.contains(moduleGroup) {
                    self.moduleGroups.lf_remove(object: moduleGroup)
                }
                if !self.moduleGroups.isEmpty {
                    nextModuleGroup =  self.moduleGroups.first
                }
            }
            
            
            if let willRunModuleGroup = nextModuleGroup {
                willRunModuleGroup.executeModule()
            }else {
                self.lock.sync {
                    self.allFinishCallBack.forEach { finsihcallBlock in
                        finsihcallBlock()
                    }
                    self.allFinishCallBack.removeAll()
                }
                OPGadgetDRLog.logger.info("All trigger disaster recover finished.")
            }
        }
    }
    
    
    /// 是否有容灾任务在执行
    /// - Returns: true / false
    @objc public func isDRRunning() -> Bool {
        if !enableDR() {
            OPGadgetDRLog.logger.info("Current DR is not Open!")
            return false
        }
        
        var isRunning = false
        lock.sync {
            isRunning = self.moduleGroups.isEmpty ? false : true
        }
        return isRunning
    }
    
    
    /// 全局是否允许容灾
    /// - Returns: true / false
    @objc public func enableDR() -> Bool {
        var enable = false
        lock.sync {
            enable = self.featureSwitch.enable
        }
        return enable
    }
    
    /// server setting 是否允许容灾
    /// - Returns: true / false
    @objc public func enableServerSettingsDR() -> Bool {
        var serverEnable = false
        lock.sync {
            serverEnable = self.featureSwitch.enable && self.featureSwitch.settingsDREnable
        }
        return serverEnable
    }
    
    /// lark 设置 是否允许执行容灾逻辑
    /// - Returns: true / false
    @objc public func enableLarkSettingDR() -> Bool {
        var larkSettingEnable = false
        lock.sync {
            larkSettingEnable = self.featureSwitch.enable && self.featureSwitch.larkSettingDREnable
        }
        return larkSettingEnable
    }
    
    /// 小程序菜单入口是否允许执行容灾逻辑
    /// - Returns: true / false
    @objc public func enableGadgetMenuDR() -> Bool {
        var menuEnable = false
        lock.sync {
            menuEnable = self.featureSwitch.enable && self.featureSwitch.gadgetMenuDREnable
        }
        return menuEnable
    }
    
    /// 小程序容灾时JSSDK是否允许升级
    /// - Returns: true / false
    @objc public func enableJSSDKUpdateAfterDR() -> Bool {
        var  jssdkUpdateEnable = false
        lock.sync {
            jssdkUpdateEnable = self.featureSwitch.enable && self.featureSwitch.fetchJSSDKUpdateAfterDR
        }
        return jssdkUpdateEnable
    }
    
    
    /// 容灾超时时间，默认 5s
    /// - Returns: timeout seconds
    func timeoutSeconds() -> Double {
        var timout :Double = 0
        lock.sync {
            timout = self.featureSwitch.timeoutSeconds
        }
        return timout
    }

    /// 更新容灾开关配置，冷启动登录成功或者切换租户时触发
    @objc public func updateDRSwitch() {
        let switchConfig = OPGadgetDRManager.safeConfigService()?.getLatestDictionaryValue(for: "miniapp_disaster_recover_feature_switch")
        lock.sync {
            self.featureSwitch = DRFeatureSwitchConfig.init(config: switchConfig)
        }
    }
    
    /// 调用ECOConfig.service()时Injected包含两次强解包，返回Optional类型避免强解包crash
    /// - Returns: nil 或者 ECOConfigService 实现
    @objc public static func safeConfigService() -> ECOConfigService? {
        let userResovler = OPUserScope.userResolver()
        return userResovler.resolve(ECOConfigService.self)
    }
}
