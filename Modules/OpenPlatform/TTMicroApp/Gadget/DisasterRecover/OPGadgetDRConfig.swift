//
//  OPGadgetDRConfig.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/17.
//

import Foundation
import OPFoundation
import LarkCache
import ECOInfra

/// 容灾等级，
/// all: 全部小程序
/// part 部分小程序，依赖于配置中appids
public enum DRLevel : String ,Equatable {
    case UNKNOWN = "UNKNOWN"
    case ALL = "ALL"
    case PART = "PART"
}

/// 容灾执行状态
/// 1: 执行中
/// 2: 执行完成
/// 3: 超时
public enum DRRunState : Int ,Equatable {
    case unknown = 0
    case running = 1
    case finished = 2
    case timeout = 3
}

/// 小程序容灾配置信息
final class OPGadgetDRConfig : NSObject {
    /// 容灾配置生效应用appId， 与``needRetainAppIds``互斥
    let appIdList : [String]
    /// 生效模块module name: "JSSDK", "PKM", "PRELOAD", "WARMBOOT"
    let modules : [String]
    /// 容灾配置结束时间, 单位：秒
    let endTimeStampSecond : Int64
    /// 生效级别，有两种类型，参考``DRLevel``
    let level : DRLevel
    /// 重试次数限制， 默认3次，仅仅用于server settting 配置
    let retryCountLimit :Int
    /// settings配置数据对应的md5信息
    let md5 : String
    /// 下发配置原始信息，用于恢复上次未完成任务
    private let origConfig: [String : AnyObject]?
    
    /// 执行次数，用于标记任务
    var executionCount: Int
    /// 触发场景，参考``DRTriggerScene``
    let triggerScene: DRTriggerScene
    /// 不能清理的小程序列表，与``appIdList``互斥
    let needRetainAppIds:[String]?
    /// 飞书设置入口，清理缓存回调，用于飞书设置入口手动操作回调逻辑
    var completion: CleanTask.Completion?
    /// 清理内容大小, 与``completion``配合使用
    var taskResult: TaskResult?
    
    /// setting 容灾配置保存到本地key ,``DRCacheConfig.cacheKey``
    let diskCacheKey: String?
    
    private static let retryDefaultCount: Int = 3
    
    
    /// 根据sever setting 生成可清理内容的配置信息
    /// - Parameter config: server setting dict, ref 'disaster_recover_cofig' settings
    init(config: [String : AnyObject], md5: String, cacheKey:String?) {
        origConfig = config
        executionCount = 0
        needRetainAppIds = nil
        completion = nil
        taskResult = nil
        triggerScene = .serverSetting
        appIdList = Self.parseAppIds(config: config)
        modules = config["modules"] as? [String] ?? [""]
        endTimeStampSecond = config["endTimeStampSecond"] as? Int64 ?? 0
        let levelStr = config["level"] as? String ?? ""
        level = DRLevel(rawValue: levelStr) ?? .UNKNOWN
        retryCountLimit = config["retryCountLimit"] as? Int ?? OPGadgetDRConfig.retryDefaultCount
        self.md5 = md5
        diskCacheKey = cacheKey
        super.init()
    }
    
    
    /// 用户手动触发小程序“清理缓存按钮”，清理当前小程序相关内容
    /// - Parameter uniqueID: 当前小程序的``OPAppUniqueID``
    init(uniqueID: OPAppUniqueID, sameTabPKM: Bool) {
        let curAppId = uniqueID.appID.isEmpty ? "" : uniqueID.appID
        appIdList = [curAppId]
        // 与主导航小程序有相同的包，不清理PKM
        if sameTabPKM {
            modules = [DRModuleName.PRELOAD.rawValue, DRModuleName.WARMBOOT.rawValue]
        }else {
            modules = [DRModuleName.PKM.rawValue, DRModuleName.PRELOAD.rawValue, DRModuleName.WARMBOOT.rawValue]
        }
        endTimeStampSecond = 0
        level = .PART
        retryCountLimit = 0
        md5 = ""
        origConfig = nil
        executionCount = 0
        triggerScene = .gadgetMenuClearCache
        needRetainAppIds = nil
        completion = nil
        taskResult = nil
        diskCacheKey = nil
        super.init()
    }
    
    
    /// 判断appids 是否为空
    /// - Parameter appIds: appids
    /// - Returns: true ,false
    class func isEmptyAppIds(appIds:[String]?) -> Bool {
        guard let safeAppIds = appIds else {
            return true
        }
        return safeAppIds.isEmpty
    }
    
    
    /// 手动触发飞书-->设置-->通用-->清理缓存 生成对应的配置信息
    /// - Parameters:
    ///   - needRetainAppIds: 不需要清理小程序的Appids， 注意是``String``，内部根据配置做好容错处理
    ///   - completion: 清理触发时会携带回调block ， 用户任务完成后触发回调
    init(needRetainAppIds:[String]?, completion: @escaping CleanTask.Completion) {
        appIdList = []
        if Self.isEmptyAppIds(appIds: needRetainAppIds)  {
            modules = [DRModuleName.JSSDK.rawValue, DRModuleName.PKM.rawValue, DRModuleName.PRELOAD.rawValue, DRModuleName.WARMBOOT.rawValue]
        }else {
            modules = [DRModuleName.PKM.rawValue, DRModuleName.PRELOAD.rawValue, DRModuleName.WARMBOOT.rawValue]
        }
        endTimeStampSecond = 0
        level = .ALL
        retryCountLimit = 0
        md5 = ""
        origConfig = nil
        executionCount = 0
        triggerScene = .larkSetting
        self.needRetainAppIds = needRetainAppIds
        self.completion = completion
        taskResult = nil
        diskCacheKey = nil
        super.init()
    }
    
    
    /// 校验两个配置信息是否完全一致
    /// - Parameter newConfig: 需要比较的配置
    /// - Returns: true / false
    func isEqualConfig(_ newConfig: OPGadgetDRConfig?) -> Bool {
        guard let safeConfig = newConfig else {
            return false
        }
        if self.level != safeConfig.level || triggerScene != safeConfig.triggerScene{
            return false
        }
        
        if endTimeStampSecond != safeConfig.endTimeStampSecond {
            return false
        }
        
        if self.modules != safeConfig.modules {
            return false
        }
        
        if self.appIdList != safeConfig.appIdList {
            return false
        }
        return true
    }
    
    /// 解析服务端配置中的’appList‘信息，组装成``[String]`` 类型
    /// - Parameter config: 服务端下发配置
    /// - Returns: 返回``[String]`` 类型的Appids 列表
    class func parseAppIds(config: [String : AnyObject]) -> [String] {
        guard let appList = config["appList"] as? [[String : AnyObject]] else {
            return []
        }
        var allAppIds: [String] = []
        appList.forEach { listItem in
            if let appId = listItem["appId"] as? String, !appId.isEmpty {
                allAppIds.append(appId)
            }
        }
        return allAppIds
    }
    
    
    /// 校验服务端下发配置是否在有效期内，如果超过了有效期，并且之前也没有触发过容灾，就不执行容灾任务
    /// - Returns: true , false
    func isValidateTime() -> Bool {
        if endTimeStampSecond == 0 {
            return false
        }
        
        let endStr = endTimeStampSecond.description
        let nowTime = Int64(Date().timeIntervalSince1970)
        let nowStr = nowTime.description
        // 校验有效时间的位数，如果位数不一致，认为配置错误，不生效
        if endStr.count != nowStr.count {
            return false
        }
        
        return nowTime <= endTimeStampSecond
    }
    
    
    /// 生成服务端settings容灾执行信息，用于记录最近一次容灾状态，防止同一个容灾执行多次
    /// - Parameters:
    ///   - executionCount: 容灾执行次数，>=3次容灾就不再执行
    ///   - state: 执行状态，1
    /// - Returns: 容灾执行信息
    func buildSettingsDRInfo(state: DRRunState) -> [String : Any]? {
        guard let safeConfig = origConfig , !md5.isEmpty else {
            return nil
        }
        let drCacheInfo: [String : Any] = ["md5": md5,
                                           "executionCount": executionCount,
                                           "state": state.rawValue,
                                           "setting": safeConfig]
        return drCacheInfo
    }
    
    
    /// 生成monitor 参数信息
    /// - Parameter state: 当前执行状态
    /// - Returns: monitor 参数
    func drMonitorParams() -> [String : Any]? {
        let drCacheInfo: [String : Any] = ["level": level.rawValue,
                                           "triggerScene": triggerScene.rawValue,
                                           "modules": modules,
                                           "appIdList" : appIdList,
                                           "needRetainAppIds": needRetainAppIds ?? [""]
        ]
        return drCacheInfo
    }
    
}


/// 组装容灾本地配置信息，用于容灾过滤
internal final class DRCacheConfig {
    let md5: String
    let executionCount: Int
    let state: DRRunState
    
    /// 服务端setting 容灾缓存key
    static let settingDRCacheKey = "gadget_disaster_recovery"
    
    /// 服务端配置触发容灾执行情况本地持久化，根据本地持久化信息烦序列化之前执行状态
    /// - Parameter config: 本地持久化信息
    init?(_ config: [String : Any]) {
        guard let md5 = config["md5"] as? String, let executionCount = config["executionCount"] as? Int, let stateValue = config["state"] as? Int, let state = DRRunState(rawValue: stateValue) else {
            return nil
        }
    
        self.md5 = md5
        self.executionCount = executionCount
        self.state = state
    }
    
    
    /// 缓存配置key ，userId 和``settingDRCacheKey``拼装组成
    /// - Parameter userId: 用户id
    /// - Returns: cache key
    static func cacheKey(_ userId: String) -> String {
        return "\(userId)_\(Self.settingDRCacheKey)"
    }
    
    /// 获取本地执行过的容灾记录信息
    /// - Returns: ``DRCacheConfig`` model
    static func getLocalDRConfig(cacheKey: String) -> DRCacheConfig? {
        guard let previousDrConfig = LSUserDefault.dynamic.getDictionary(forKey: cacheKey) else {
            return nil
        }
        return DRCacheConfig(previousDrConfig)
    }
    
    /// 持久化setting 容灾执行信息
    /// - Parameters:
    ///   - config: 容灾setting 配置``OPGadgetDRConfig``
    ///   - state: 执行状态 ``DRRunState``
    static func storeDRConfig(config: OPGadgetDRConfig, state: DRRunState) {
        let drCacheInfo = config.buildSettingsDRInfo(state: state)
        if let cacheInfo = drCacheInfo, let diskCacheKey = config.diskCacheKey {
            LSUserDefault.dynamic.setDictionary(cacheInfo, forKey: diskCacheKey)
            OPGadgetDRLog.logger.info("store config, scene:\(cacheInfo)")
        }
    }
}


/// 容灾配置开关的相关配置
final class DRFeatureSwitchConfig  {
    /// 总开关
    let enable: Bool
    /// 超时时间，单位（秒）, 用于容灾任务超时，默认是5s
    let timeoutSeconds: Double
    // Settings 容灾入口开关
    let settingsDREnable: Bool
    /// Lark 设置容灾入口开关
    let larkSettingDREnable: Bool
    /// 小程序菜单容灾入口开关
    let gadgetMenuDREnable: Bool
    /// 容灾后触发 JSSDK 更新
    let fetchJSSDKUpdateAfterDR: Bool
    
    private static let defaultTimeOutSeconds: Double = 5.0
    
    init(config: [String : Any]?) {
        guard let safeCofig = config else {
            enable = false
            timeoutSeconds = DRFeatureSwitchConfig.defaultTimeOutSeconds
            settingsDREnable = false
            larkSettingDREnable = false
            gadgetMenuDREnable = false
            fetchJSSDKUpdateAfterDR = false
            return
        }
        enable = safeCofig["enable"] as? Bool ?? false
        timeoutSeconds = safeCofig["timeoutSeconds"] as? Double ?? DRFeatureSwitchConfig.defaultTimeOutSeconds
        settingsDREnable = safeCofig["settingsDREnable"] as? Bool ?? false
        larkSettingDREnable = safeCofig["larkSettingDREnable"] as? Bool ?? false
        gadgetMenuDREnable = safeCofig["gadgetMenuDREnable"] as? Bool ?? false
        fetchJSSDKUpdateAfterDR = safeCofig["fetchJSSDKUpdateAfterDR"] as? Bool ?? false
    }
}
