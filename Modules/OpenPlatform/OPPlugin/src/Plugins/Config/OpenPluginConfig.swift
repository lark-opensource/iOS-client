//
//  OpenPluginConfig.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import ECOProbe
import LarkContainer

// 错误码
enum OpenPluginConfigErrorCode : Int {
    case getFailed = 60801 // 获取config失败
}

final class OpenPluginConfig: OpenBasePlugin {

    // 错误message - 获取 config 失败
    static let kOpenPluginConfigGetFailedMsg = "Get config failed"
    // 缓存时间 10 min
    static let kOpenPluginConfigCacheTime = 10 * 60
    // 时间戳key
    static let kOpenPluginConfigCacheLastTimeKey = "lastCacheTime"
    // config key
    static let kOpenPluginConfigCacheConfigKey = "config"
    // 缓存key
    static let kOpenPluginConfigCacheKey = "env.config"

    func getEnvVariable(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetEnvVariableResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        // 优先判断缓存，有缓存，并且在缓存时效内，直接使用缓存
        let cacheDict = _getCacheTimeAndConfigWithUniqueID(uniqueID: uniqueID, context: context)
        let cacheTime = cacheDict?[OpenPluginConfig.kOpenPluginConfigCacheLastTimeKey] as? Double ?? 0.0
        let config = cacheDict?[OpenPluginConfig.kOpenPluginConfigCacheConfigKey] as? [AnyHashable : Any]
        let pastTime = ProcessInfo.processInfo.systemUptime - cacheTime
        if let conf = config,
           pastTime > 0,
           Int(pastTime) < OpenPluginConfig.kOpenPluginConfigCacheTime {
            let callbackInfo = OpenAPIGetEnvVariableResult(config: conf)
            callback(.success(data: callbackInfo))
            return
        }

        EMARequestUtil.fetchEnvVariable(by: uniqueID) { [weak self] (config, error) in
            if let error = error as NSError? {
                context.apiTrace.error("fetchEnvVariable error code:\(error.code) msg:\(error.localizedDescription)")
                let error = OpenAPIError(code: GetEnvVariableErrorCode.getConfigFail)
                    .setError(error)
                    .setOuterCode(OpenPluginConfigErrorCode.getFailed.rawValue)
                    .setOuterMessage("Get config failed")
                callback(.failure(error: error))
                return
            }
            context.apiTrace.info("fetchEnvVariable successm, configCount=\(config?.count ?? 0)")
            let callbackInfo = OpenAPIGetEnvVariableResult(config: config ?? [:])
            callback(.success(data: callbackInfo))
            self?._cacheConfig(config: config, uniqueID: uniqueID, context: context)
        }

    }

    // 获取缓存的time和config，以用户+appID维度
    func _getCacheTimeAndConfigWithUniqueID(uniqueID: OPAppUniqueID, context: OpenAPIContext) -> [AnyHashable: Any]? {
        guard uniqueID.isValid() else {
            context.apiTrace.error("OpenPluginConfig uniqueID invalid \(uniqueID)")
            return nil
        }
        let cacheKey = OpenPluginConfig.kOpenPluginConfigCacheKey.appending(uniqueID.appID)
        // storage 是以用户维度做区分
        guard let storageModule = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol else {
            context.apiTrace.error("OpenPluginConfig BDPStorageModuleProtocol is nil for \(uniqueID)")
            return nil
        }
        let storage = storageModule.sharedLocalFileManager().kvStorage
        return storage.object(forKey: cacheKey) as? [AnyHashable : Any]
    }

    /// 缓存config，同时会带上time，以用户+appID维度
    func _cacheConfig(config: [AnyHashable: Any]?, uniqueID: OPAppUniqueID, context: OpenAPIContext) -> Void {
        guard let config = config else {
            context.apiTrace.error("OpenPluginConfig _cacheConfig config is nil")
            return
        }
        if !uniqueID.isValid() {
            context.apiTrace.error("OpenPluginConfig _cacheConfig uniqueID invalid \(uniqueID)")
            return
        }
        let cacheKey = OpenPluginConfig.kOpenPluginConfigCacheKey.appending(uniqueID.appID)
        let time = ProcessInfo.processInfo.systemUptime
        let cacheDict: [String: Any] = [
            OpenPluginConfig.kOpenPluginConfigCacheLastTimeKey: time,
            OpenPluginConfig.kOpenPluginConfigCacheConfigKey: config
        ]
        guard let storageModule = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol  else {
            context.apiTrace.error("OpenPluginConfig _cacheConfig BDPStorageModuleProtocol is nil for \(uniqueID)")
            return
        }
        let storage = storageModule.sharedLocalFileManager().kvStorage
        storage.setObject(cacheDict, forKey: cacheKey)
    }

    func getKAInfo(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetKAInfoResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        guard let appEnginePlugin = BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate,
              let onlineConfig = appEnginePlugin.onlineConfig else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("onlineConfig is nil")
            callback(.failure(error: error))
            return
        }
        if !onlineConfig.isApiAvailable("getKAInfo", for: uniqueID) {
            context.apiTrace.warn("getKAInfo is not available")
            let error = OpenAPIError(code: GetKAInfoErrorCode.appNotInOklist)
                .setMonitorMessage("getKAInfo is not available")
            callback(.failure(error: error))
            return
        }
        callback(.success(data: OpenAPIGetKAInfoResult(channel: appEnginePlugin.config?.channel ?? "")))
    }

    func getServerTime(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetServerTimeResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        let ntpTime = SwiftBridge.ntpTime()
        context.apiTrace.info("getServerTime, uniqueID=\(uniqueID), appType=\(uniqueID.appType), nptTime=\(ntpTime)")

        if ntpTime < 1 {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("getServerTime failed because nptTime < 1, \(ntpTime)")
            callback(.failure(error: error))
            return
        }
        callback(.success(data: OpenAPIGetServerTimeResult(time: Int(ntpTime * 1000))))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "getEnvVariable", pluginType: Self.self, resultType: OpenAPIGetEnvVariableResult.self) { (this, _, context, gadgetContext, callback) in
            
            this.getEnvVariable(context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "getKAInfo", pluginType: Self.self, resultType: OpenAPIGetKAInfoResult.self) { (this, _, context, gadgetContext, callback) in
            
            this.getKAInfo(context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "getServerTime", pluginType: Self.self, resultType: OpenAPIGetServerTimeResult.self) { (this, _, context, gadgetContext, callback) in
            
            this.getServerTime(context: context, gadgetContext: gadgetContext, callback: callback)
        }

    }
}
