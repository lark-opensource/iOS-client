//
//  OPDynamicComponentManager.swift
//  OPDynamicComponent
//
//  Created by Nicholas Tau on 2021/11/4.
//

import Foundation
import TTMicroApp
import LKCommonsLogging
import ECOProbe
import OPSDK
import ObjectiveC
import LarkSetting

private class OPDynamicComponentLoaderListener: OPAppLoaderMetaAndPackageEvent {
    let completeBlock: innerCompleteCallback?
    let uniqueID: OPAppUniqueID
    init(_ uniqueID: OPAppUniqueID, completeBlock: innerCompleteCallback?) {
        self.uniqueID = uniqueID
        self.completeBlock = completeBlock
    }
    
    func onMetaLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, meta: OPBizMetaProtocol?, error: OPError?, fromCache: Bool) {
        //正常加载时需要回掉
        if strategy == .normal {
            completeBlock?(meta, error, .meta, strategy)
        }
    }
    func onPackageLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, error: OPError?) {
        let metaProvider = OPDynamicComponentMetaProvider(builder: OPDynamicComponentMetaBuilder())
        var meta: OPBizMetaProtocol? = nil
        do {
            meta = try metaProvider.getLocalMeta(with: uniqueID)
        } catch {
            logger.error("meta fetch error with\(uniqueID), error:\(error)")
        }
        completeBlock?(meta, error, .pkg, strategy)
    }
    
}

extension OPAppUniqueID {
    var appIDidentifierForComponent: String {
        get {
            if self.appType == .dynamicComponent {
                return "\(self.appID)_\(self.requireVersion)"
            } else {
                return self.appID
            }
        }
    }
}

private let logger = Logger.oplog(OPDynamicComponentManager.self)

@objcMembers
public final class OPDynamicComponentManager: NSObject, OPDynamicComponentManagerProtocol {
    private var loaderMap: [String: (OPDynamicComponentMeta?, OPDynamicComponentLoader?)] = [:]
    
    private let loaderLock: NSLock = NSLock()
    
    public static let sharedInstance = OPDynamicComponentManager()
    
    /// 为宿主准备动态组件
    /// - Parameters:
    ///   - componentAppID: 动态组件的 appID
    ///   - requireVersion: 动态组件的 版本
    ///   - hostAppID: 宿主小程序的 appID
    ///   - previewToken: 如果是小程序预览模式，需要传递。可以为空
    ///   - completeBlock: callback
    public func prepareDynamicComponent(componentAppID: String,
                                        requireVersion: String,
                                        hostAppID: String,
                                        previewToken: String?,
                                        completeBlock: completeCallback?){
        var versionType: OPAppVersionType = .current
        if let _ = previewToken {
            versionType = .preview
        }
        let uniqueId = OPAppUniqueID(appID: componentAppID,
                                     identifier: nil,
                                     versionType: versionType,
                                     appType: .dynamicComponent,
                                     instanceID: hostAppID)
        uniqueId.requireVersion = requireVersion
        
        self.loaderLock.lock()
        let loader =  OPDynamicComponentLoader(uniqueID: uniqueId,
                                               previewToken: previewToken ?? "")
        //先存一下，防止 loader 提前释放
        self.loaderMap[uniqueId.appIDidentifierForComponent] = (nil, loader)
        self.loaderLock.unlock()
        let listener = OPDynamicComponentLoaderListener(uniqueId) { [weak self](meta, error, state, strategy) in
            //外部业务只需要关注普通加载流程
            if strategy == .normal {
                //回调可以安全触发 UI 操作
                let componentMeta = meta as? OPDynamicComponentMeta
                //只有在meta阶段且离线包场景，需要在内存缓存
                if let self = self,
                    let componentMeta = componentMeta,
                   state == .meta {
                    self.loaderLock.lock()
                    //覆盖一下之前 dictionary 里的数据
                    self.loaderMap[uniqueId.appIDidentifierForComponent] = (componentMeta, loader)
                    self.loaderLock.unlock()
                }
                DispatchQueue.main.async {
                    completeBlock?(error, state, componentMeta)
                }
            }
        }
        loader?.loadMetaAndPackage(listener: listener)
    }
    
    /// 预加载的方法，收到预推后执行该方法predownload离线包
    ///  - Parameters:
    ///  - componentAppID: 动态组件的 appID
    ///   - requireVersion: 动态组件的 版本
    ///   - hostAppID: 宿主小程序的 appID
    public func preloadDynamicComponentWith(componentAppID: String,
                                            requireVersion: String,
                                            hostAppID: String,
                                            completeBlock: completeCallback?) {
        let uniqueId = OPAppUniqueID(appID: componentAppID,
                                     identifier: nil,
                                     versionType: .current,
                                     appType: .dynamicComponent,
                                     instanceID: hostAppID)
        uniqueId.requireVersion = requireVersion
        
        self.loaderLock.lock()
        let (existeMeta, loader) = loaderMap[uniqueId.appIDidentifierForComponent] ?? (nil, OPDynamicComponentLoader(uniqueID: uniqueId, previewToken: ""))
        //先存一下，防止 loader 提前释放
        self.loaderMap[uniqueId.appIDidentifierForComponent] = (existeMeta, loader)
        self.loaderLock.unlock()
        let listener = OPDynamicComponentLoaderListener(uniqueId) { [weak self](meta, error, state, strategy) in
            if (strategy == .preload && state == .pkg)
                || error != nil {
                //回调可以安全触发 UI 操作
                let componentMeta = meta as? OPDynamicComponentMeta
                if error != nil {
                    self?.loaderLock.lock()
                    self?.loaderMap.removeValue(forKey: uniqueId.appIDidentifierForComponent)
                    self?.loaderLock.unlock()
                }
                DispatchQueue.main.async {
                     completeBlock?(error, state, componentMeta)
                }
            }
        }
        loader?.preloadMetaAndPackage(listener: listener)
    }
    
    public func getComponentResourceByPath(path: String, previewToken: String? , componentID: String, requireVersion: String) -> Data? {
        var versionType: OPAppVersionType = .current
        if let _ = previewToken {
            versionType = .preview
        }
        var resource: Data? = nil
        let uniqueID = OPAppUniqueID(appID: componentID,
                                     identifier: nil,
                                     versionType: versionType,
                                     appType: .dynamicComponent)
        uniqueID.requireVersion = requireVersion
        let metaProvider = OPDynamicComponentMetaProvider(builder: OPDynamicComponentMetaBuilder())
        var localMeta: OPDynamicComponentMeta? = nil
        do {
            localMeta = try metaProvider.getLocalMeta(with: uniqueID) as? OPDynamicComponentMeta
        } catch {
            logger.error("meta fetch error with\(uniqueID), error:\(error)")
        }
        if let  localMeta = localMeta {
            let packageContext =  BDPPackageContext(appMeta: localMeta.appMetaAdapter,
                                                    packageType: .pkg,
                                                    packageName: nil,
                                                    trace: tracing(uniqueID))
            let fileHandle = BDPPackageStreamingFileHandle(afterDownloadedWith: packageContext)
            fileHandle.readData(withFilePath: path,
                                syncIfDownloaded: true,
                                dispatchQueue: nil, completion: {  error, pkgName, data in
                guard let data = data else {
                    logger.error("getComponentResourceByPath error with\(uniqueID), data is nil, error:\(error)")
                    return
                }
                //返回包内资源
                resource = data
            })
        }
        return resource
    }
    
    private func tracing(_ uniqueID: BDPUniqueID) -> BDPTracing {
        let tracingManager = BDPTracingManager.sharedInstance()
        return tracingManager.getTracingBy(uniqueID) ?? tracingManager.generateTracing(by: uniqueID)
    }
    
    public func cleanDynamicCompoments(){
        let configService: ECOConfigService = ECOConfig.service()
        guard let expiredSettingDic = configService.getLatestDictionaryValue(for: "meta_expiration_time_setting"),
              let pluginExpirationConfig = expiredSettingDic["plugin_expiration_config"] as? [String : Any]  else {
                  logger.warn("cleanDynamicCompomentWithPolicy with warnning, config ")
                  return
        }
        if OPDynamicComponentHelper.enableDynamicComponent() {
            let delaySeconds = TimeInterval(pluginExpirationConfig["clean_delay_seconds"] as? Int ?? Int.max)
            DispatchQueue.global().asyncAfter(deadline: .now() + delaySeconds) {
                self.cleanComponentsWithPolicy(pluginExpirationConfig)
            }
        } else {
            logger.warn("cleanDynamicCompomentWithPolicy terminated, feature is disable")
        }
    }
    
    private func cleanComponentsWithPolicy(_ pluginExpirationConfig: [String: Any]) {
        let metaProvider = OPDynamicComponentMetaProvider(builder: OPDynamicComponentMetaBuilder())
        guard let allMetas = try? metaProvider.getAllMetas()  else {
            logger.error("cleanDynamicCompomentWithPolicy with exception, allMetas is nil")
            return
        }
        logger.info("cleanComponentsWithPolicy->pluginExpirationConfig:\(pluginExpirationConfig)")
        //用来存储meta，key为appID，值为所有本地 appID 对应的 meta 列表
        var allMetasMap:[String: [OPBizMetaProtocol]] = [:]
        allMetas.forEach{ bizMeta in
            var allMetaListWithAppID: [OPBizMetaProtocol] = allMetasMap[bizMeta.appID] ?? []
            allMetaListWithAppID.append(bizMeta)
            allMetasMap[bizMeta.appID] = allMetaListWithAppID
        }
        logger.info("cleanComponentsWithPolicy->allMetasMap:\(allMetasMap)")
        //存放所有需要被清理的插件列表
        var allMetasShouldBeClean: [OPBizMetaProtocol] = []
        //再循环遍历一次，这次需要把插件排序。并且找出需要被清理的插件
        allMetasMap.forEach { appID, metaList in
            logger.info("cleanComponentsWithPolicy->begin check with:\(appID)")
            //按照timestamp的大小，降序排列。最新更新的放在最前面
            let sortedMetaList = metaList.sorted(by: { (first, second) in
                first.getLastUpdateTimestamp().intValue > second.getLastUpdateTimestamp().intValue
            })
            logger.info("cleanComponentsWithPolicy->sortedMetaList->\(sortedMetaList)")
            //根据配置获取配置的 max_capacity
            let maxCapacity = ((pluginExpirationConfig[appID] ?? pluginExpirationConfig) as? [String: Any])?["max_capacity"] as? Int ?? Int.max
            logger.info("cleanComponentsWithPolicy->maxCapacity:\(maxCapacity) for appID:\(appID)")
            //起始标记
            var startIndex = maxCapacity
            //如果当前列表有超出 maxCapacity 的内容，需要添加到待清理名单
            while startIndex < sortedMetaList.count {
                logger.info("cleanComponentsWithPolicy->meta should be clean:\(sortedMetaList[startIndex])")
                allMetasShouldBeClean.append(sortedMetaList[startIndex])
                startIndex += 1
            }
            logger.info("cleanComponentsWithPolicy->end check with:\(appID)")
        }
        logger.info("cleanComponentsWithPolicy->allMetasShouldBeClean:\(allMetasShouldBeClean)")
        //可以开始清理了
        allMetasShouldBeClean.forEach { metaToBeClean in
            //指定清理的插件版本
            metaToBeClean.uniqueID.requireVersion = metaToBeClean.applicationVersion
            //如果当前没有被使用，则需要被清理
            let (preparedMeta, _) = self.loaderMap[metaToBeClean.uniqueID.appIDidentifierForComponent] ?? (nil, nil)
            if preparedMeta != nil {
                logger.warn("cleanComponentsWithPolicy->preparedMeta is not nil, package can't be clean:\(metaToBeClean)")
                return
            }
            //清理插件Meta
            logger.info("cleanComponentsWithPolicy->begin delete local meta with uniqueID:\(metaToBeClean.uniqueID)")
            metaProvider.deleteLocalMeta(with: metaToBeClean.uniqueID)
            logger.info("cleanComponentsWithPolicy->end delete local meta with uniqueID:\(metaToBeClean.uniqueID)")
            //准备清理插件包
            guard let componentMeta = metaToBeClean as? OPDynamicComponentMeta  else {
                logger.warn("metaToBeClean can't cast to OPDynamicComponentMeta, data type exception:\(metaToBeClean)")
                return
            }
            let packageContext = BDPPackageContext(appMeta: componentMeta.appMetaAdapter,
                                                   packageType: .pkg,
                                                   packageName: nil,
                                                   trace: tracing(componentMeta.uniqueID))
            logger.info("cleanComponentsWithPolicy->begin delete local package with uniqueID:\(metaToBeClean.uniqueID)")
            do {
                try BDPPackageLocalManager.deleteLocalPackage(with: packageContext)
            } catch {
                logger.error("BDPPackageLocalManager clean package with error:\(error)")
            }
            logger.info("cleanComponentsWithPolicy->end delete local package with uniqueID:\(metaToBeClean.uniqueID)")
        }
    }
}
