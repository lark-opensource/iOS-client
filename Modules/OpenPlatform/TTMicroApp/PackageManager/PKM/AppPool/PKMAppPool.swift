//
//  PKMAppPool.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/11/30.
//

import Foundation
import LKCommonsLogging

protocol PKMAppPoolProtocol {
    func add(apps: [PKMBaseMetaProtocol & PKMBaseMetaDBProtocol]) -> Bool
    func findAppWith(uniqueID: PKMUniqueID, appVersion: String?) -> PKMApp?
    func allApps(_ uniqueID: PKMUniqueID?) -> [String: [PKMApp]] 
    func appCount() -> UInt64
}

public protocol PKMAppPoolPluginProtocol {
    func findPluginWith(uniqueID: PKMUniqueID, requireVersion: String?) -> String?
    func updateSubscriptionBetween(hostAppID: String, pluginAppID: String, existe:Bool)
}

private let log = Logger.oplog(PKMAppPool.self, category: "PKMAppPool")

struct PKMApp {
    let pkmType: PKMType
    let uniqueID: PKMUniqueID
    let originalJSONString: String
    let lastUpdateTime: NSNumber?
    let appVersion: String
    let packageName: String?
    
    /// 判断是否已安装
    /// - Parameter targetPage: 目标页面，可以不传。如果传了需要判断打开该页面相关的包是否都已下载【分包逻辑】
    /// - Returns: 相关的包是否已安装
    func isInstalled(targetPage: String? = nil) -> Bool {
        //检查包名，必须存在才能继续判断。否则return false
        guard let packageName = packageName else { return false }
        let appType = pkmType.toAppType()
        let uniqueID = BDPUniqueID(appID: uniqueID.appID, identifier: uniqueID.identifier, versionType: .current, appType: appType)
        return BDPPackageLocalManager.isLocalPackageExsit(uniqueID, packageName: packageName, originalMetaStr: self.originalJSONString, targetPage: targetPage)
    }
}

class PKMAppPool: PKMAppPoolProtocol, PKMAppPoolPluginProtocol {
    private let pkmType: PKMType
    private let isPreview: Bool
    private let dbAccessor: PKMMetaAccessor
    private let semaphoreLock = DispatchSemaphore(value: 1)
    //内存里存一份最新版本的应用信息
    //应用ID:（版本，meta详情）
    //["cli_xxxxx":(1.0.0, "xxxxxxx")]
    #if ALPHA || DEBUG
    var latestAppMetaMap: [String: PKMApp] = [:]
    #else
    private var latestAppMetaMap: [String: PKMApp] = [:]
    #endif
    init(_ pkmType: PKMType, isPreview: Bool = false) {
        self.pkmType = pkmType
        self.isPreview = isPreview
        self.dbAccessor =  PKMMetaAccessor(type: pkmType, isPreview: isPreview)
    }
    
    //批量往应用池新内添加应用
    func add(apps: [PKMBaseMetaProtocol & PKMBaseMetaDBProtocol]) -> Bool {
        log.info("add apps with count:\(apps.count) and type:\(pkmType)")
        apps.forEach { app in
            let pkmType = self.pkmType
            let successBlock: ((NSNumber) -> Void) = { [weak self] lastUpdateTime in
                let packageName = (app as? PKMBaseMetaPkgProtocol)?.packageName()
                self?.updateAppMetaInMemoryWith(app: PKMApp(pkmType:pkmType,
                                                           uniqueID: app.pkmID,
                                                           originalJSONString: app.originalJSONString,
                                                           lastUpdateTime: lastUpdateTime,
                                                           appVersion: app.appVersion,
                                                           packageName: packageName))
            }
            if let error  = self.dbAccessor.saveMetaWith(baseMeta: app, successBlock: successBlock) {
                log.error("dbAccessor.saveMetaWith with error:\(error)")
            }
        }
        return true
    }
    
    /// 缓存数据到内存中
    /// - Parameters:
    ///   - appID: 需要缓存的数据应用ID
    ///   - appVersion: 需要缓存数据的应用版本
    ///   - originalJSONString: 需要缓存的数据详情，如果为nil，则删除原有的数据
    func updateAppMetaInMemoryWith(app: PKMApp, shouldRemove: Bool = false) {
        let queryKey = app.uniqueID.queryKey()
        let appVersion = app.appVersion
        let originalJSONString = app.originalJSONString
    
        log.info("updateAppMetaInMemoryWith queryKey:\(queryKey) and version:\(appVersion) with type:\(pkmType)")
        defer{
            self.semaphoreLock.signal()
        }
        self.semaphoreLock.wait()
        //如果有数据，检查一下看是否需要更新
        if let appInMemory = self.latestAppMetaMap[queryKey] {
            if shouldRemove == false {
                let appLastUpdateTime = app.lastUpdateTime?.intValue ?? 0
                let appInMemoryLastUpdateTime = appInMemory.lastUpdateTime?.intValue ?? 0
                //如果新增的时间戳更大（最近刚更新的），则更新内存数据
                if appLastUpdateTime > appInMemoryLastUpdateTime {
                    //更新数据
                    self.latestAppMetaMap[queryKey] = app
                    log.info("\(queryKey) existed with version: \(appInMemory.appVersion) but less than \(appVersion), try to replace it")
                } else {
                    log.info("\(queryKey) existed, skipped")
                }
            } else {
                //是否需要删除的版本，如果version匹配，删除内存数据
                if appVersion == appInMemory.appVersion {
                    self.latestAppMetaMap.removeValue(forKey: queryKey)
                }
            }
        //不存在直接添一条
        } else {
            //如果 originalJSONString 是存在的，则缓存一条数据
            self.latestAppMetaMap[queryKey] = app
            log.info("\(queryKey) doesn't exist in latestAppMetaMap, try to insert a record")
        }
    }
    
    /// 获取应用信息
    /// - Parameters:
    ///   - uniqueID: 应用的ID
    ///   - appVersion: 应用版本（若传空，返回最大的）
    /// - Returns: 返回meta信息
    func findAppWith(uniqueID: PKMUniqueID, appVersion: String?) -> PKMApp? {
        let identifier = uniqueID.queryKey()
        //先从内存中寻找，如果有直接返回
        if let appInMemory = self.latestAppMetaMap[identifier]  {
            //如果版本匹配，又或者外部不需要具体版本时，直接返回数据
            if appInMemory.appVersion == appVersion {
                return appInMemory
            } else if appVersion == nil {
                return appInMemory
            }
        }
        let allMetas = self.dbAccessor.getAllMetasWithDetailDESCByTimestampBy(identifier)
        // biz_type, meta, app_id, app_version, pkg_name, update_time"
        var matchedResult = allMetas.first
        if allMetas.count > 0 {
            //找到版本匹配的meta原始数据
            if let appVersion = appVersion {
                //如果 appVersion 不为空，则一定需要返回匹配后的结果
                let metasAfterMatched = allMetas.filter { $0.3 == appVersion }
                // 若metasAfterMatched为空（没有匹配到对应版本的meta数据）则返回 nil
                matchedResult = metasAfterMatched.first
            }
        }
        //找到对应的结果，检查一下是否需要写入到内存
        if let matchedResult = matchedResult {

            let pkmApp = PKMApp(pkmType:pkmType,
                                uniqueID: uniqueID,
                                originalJSONString: matchedResult.1,
                                lastUpdateTime: matchedResult.5,
                                appVersion: matchedResult.3,
                                packageName: matchedResult.4)
            updateAppMetaInMemoryWith(app: pkmApp)
            return pkmApp
        }
        return nil
    }
    
    func appCount() -> UInt64 {
        let appCount = self.dbAccessor.getCount()
        log.info("get appCount:\(appCount) with type:\(pkmType)")
        return appCount
    }
    
    func remove(apps: [PKMBaseMetaProtocol & PKMBaseMetaDBProtocol]) -> Bool {
        log.info("remove apps with pkg info:\(apps.count) with type:\(pkmType)")
        self.dbAccessor.removeMetas(metas: apps)
        //需要清洗一下内存数据，如果之前被缓存了。则需要更新
        apps.forEach { app in
            let packageName = (app as? PKMBaseMetaPkgProtocol)?.packageName()
            updateAppMetaInMemoryWith(app: PKMApp(pkmType:pkmType,
                                                  uniqueID: app.pkmID,
                                                  originalJSONString: app.originalJSONString,
                                                  lastUpdateTime: nil,
                                                  appVersion: app.appVersion,
                                                  packageName: packageName), shouldRemove: true)
        }
        return true
    }
    
    /// 返回本地所有的应用，按版本降序排布
    /// - Returns: ["cli_xxx":  [PKMApp]]
    func allApps(_ uniqueID: PKMUniqueID? = nil) -> [String: [PKMApp]] {
        log.info("get all apps from db with type:\(pkmType)")
        var allAppMap: [String: [PKMApp]] = [:]
        let identifier = uniqueID?.queryKey()
        // biz_type, meta, app_id, app_version, pkg_name, update_time"
        self.dbAccessor.getAllMetasWithDetailDESCByTimestampBy(identifier).forEach { meta in
            var metaList = allAppMap[meta.2] ?? []
            //添加（版本、meta原始string）
            let pkmApp = PKMApp(pkmType:pkmType,
                                uniqueID: PKMUniqueID(appID: meta.2, identifier: uniqueID?.identifier),
                                originalJSONString: meta.1,
                                lastUpdateTime: meta.5,
                                appVersion: meta.3,
                                packageName: meta.4)
            metaList.append(pkmApp)
            allAppMap[meta.2] = metaList
        }
        return allAppMap
    }
    
    func findPluginWith(uniqueID: PKMUniqueID, requireVersion: String?) -> String? {
        return nil
    }
    
    func updateSubscriptionBetween(hostAppID: String, pluginAppID: String, existe:Bool) {
        
    }
}
