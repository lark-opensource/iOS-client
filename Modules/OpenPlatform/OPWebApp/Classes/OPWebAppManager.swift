//
//  OPWebAppManager.swift
//  OPGadget
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

/// loader阶段
@objc
public enum OPWebAppLoaderState: Int {
    // meta请求阶段
    case meta
    // pkg拉包阶段
    case pkg

}

@objc
public enum OPWebAppErrorType: Int {
    // larkVersion不匹配
    case verisonCompatible
    // 离线能力未开启
    case offlineDisable
    // 未知错误
    case unknow
}

public typealias completeCallback = (Error?,  OPWebAppLoaderState, OPWebAppExtConfig?) -> Void
public typealias innerCompleteCallback = (OPBizMetaProtocol?,  Error?,  OPWebAppLoaderState, OPAppLoaderStrategy) -> Void

//  有响应走responseAndData，否则降级到fallbackRequest（一期不做），降级不到只能走error
public enum OfflineInterceptModel {
    case responseAndData(URLResponse, Data)
    case fallbackRequest(URLRequest)
    case error(Error)
}

public protocol OPWebAppManagerProtocol: AnyObject {
    /// 是否允许拦截
    /// - Returns: 是否需要进行拦截
    func canInterceptWith(_ request: URLRequest) -> Bool
    /// 获取资源回掉
    func fetchResourceWith(_ request: URLRequest, compeletionHandler: @escaping (OfflineInterceptModel) -> Void)
    /// 是否是合法的vhost，允许跳过 SecLink 检查
    func isValidVhostInUrl(_ url: URL?) -> Bool
    /// 通过uniqueID 获取离线用中的 vhost 和 mainUrl
    func webAppURLWithUniqueId(_ uniqueID: OPAppUniqueID) -> (String, String)?
    /// 准备包管理能力，完成时进行回调
    /// supportOnline 是否支持仅在线的网页应用形态
    func prepareWebApp(uniqueId: OPAppUniqueID,
                       previewToken: String?,
                       supportOnline: Bool,
                       completeBlock: completeCallback?)
    /// 预加载的方法，收到预推后执行该方法predownload离线包
    func preloadWebAppWith(uniqueId: OPAppUniqueID,
                           completeBlock: completeCallback?)
    //H5容器关闭时清理对应的缓存，避免多场景实例缓存发生冲突
    func cleanWebAppInMemory(uniqueID: OPAppUniqueID)
    
    ///用于清理所有历史Meta信息，其他场景请勿调用
    ///https://meego.feishu.cn/larksuite/story/detail/4663900?parentUrl=%2Fworkbench&tab=todo
    func cleanAllWebAppMetas()
}

private extension URLRequest {
    // 从虚拟与命中获取 appId
    func appId() -> String? {
        if let url = urlRequest?.url {
            return url.appId()
        }
        return nil
    }
}

private extension URL {
    // 从虚拟与命中获取 appId
    func appId() -> String? {
        if let components = self.host?.split(separator: ".") {
            if components.count > 0 {
                return String(components[0])
            }
        }
        return nil
    }
}

private class OPWebAppLoaderListener: OPAppLoaderMetaAndPackageEvent {
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
        let metaProvider = OPWebAppMetaProvider(builder: OPWebAppMetaBuilder())
        var meta: OPBizMetaProtocol? = nil
        do {
            meta = try metaProvider.getLocalMeta(with: uniqueID)
        } catch {
            logger.error("meta fetch error with\(uniqueID), error:\(error)")
        }
        completeBlock?(meta, error, .pkg, strategy)
    }
//    capture reader here if fallback suuport later
//    func onPackageReaderReady(strategy: OPAppLoaderStrategy, reader: OPPackageReaderProtocol) {
//
//    }
    
}

private var AssociatedObjectHandle: UInt8 = 0
//离线吧业务逻辑内使用
internal extension OPAppUniqueID {
    var supportOnline: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private let logger = Logger.oplog(OPWebAppManager.self)

extension String {
    //返回 UA 中 InstanceID 的内容
    public func instanceIDFromUserAgent() -> String {
        var instanceID: String = ""
        self.split(separator: " ").forEach {
            if $0.contains("LKBrowserIdentifier") {
                let result = $0.split(separator: "/")
                if (result.count == 2) {
                    instanceID = String(result[1])
                }
            }
        }
        return instanceID
    }
}

internal extension URLRequest {
    func instanceIDFromUserAgent() -> String {
        let userAgent = self.allHTTPHeaderFields?["User-Agent"] ?? ""
        return userAgent.instanceIDFromUserAgent()
    }
}

public final class OPWebAppManager: OPWebAppManagerProtocol {
    private var loaderMap: [String: (OPWebAppMeta?, OPWebAppLoader?)] = [:]
    private var fileHandleMap: [String: BDPPackageStreamingFileHandle] = [:]
    
    private let loaderLock: NSLock = NSLock()
    private let fileHandleLock: NSLock = NSLock()
    
    public static let sharedInstance = OPWebAppManager()

    public func prepareWebApp(uniqueId: OPAppUniqueID,
                              previewToken: String?,
                              supportOnline: Bool,
                              completeBlock: completeCallback?)  {
        WebAppMetaMigration.migrateWebAppMeta()
        self.loaderLock.lock()
        uniqueId.supportOnline = supportOnline
        let loader =  OPWebAppLoader(uniqueID: uniqueId,
                                     previewToken: previewToken ?? "")
        //先存一下，防止 loader 提前释放
        self.loaderMap[uniqueId.fullString] = (nil, loader)
        self.loaderLock.unlock()
        let listener = OPWebAppLoaderListener(uniqueId) { [weak self](meta, error, state, strategy) in
            //外部业务只需要关注普通加载流程
            if strategy == .normal {
                //回调可以安全触发 UI 操作
                let webAppMeta = meta as? OPWebAppMeta
                //只有在meta阶段且离线包场景，需要在内存缓存
                if let self = self,
                    let webAppMeta = webAppMeta,
                   state == .meta,
                   webAppMeta.extConfig.offlineEnable == true {
                    self.loaderLock.lock()
                    //覆盖一下之前 dictionary 里的数据
                    self.loaderMap[uniqueId.fullString] = (webAppMeta, loader)
                    self.loaderLock.unlock()
                }
                DispatchQueue.main.async {
                    //loaderMap 里存的 .meta 阶段是首次启动展示的meta，
                    let (cachedMeta, _) = self?.loaderMap[uniqueId.fullString] ?? (nil, nil)
                    //离线包主入口FG，取 H5 meta 逻辑包涵非离线包业务
                    //需要结合 meta 的 extConfig 结果判断
                    if let extConfig = cachedMeta?.extConfig ?? webAppMeta?.extConfig,
                       OPSDKFeatureGating.isWebappOfflineEnable() == false,
                       extConfig.offlineEnable {
                        let error = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "webapp offline disable, FG turn off with \(uniqueId)")
                        completeBlock?(error, state, nil)
                        logger.error("web offline prepareWebApp feature disable for")
                    } else {
                        completeBlock?(error, state, cachedMeta?.extConfig ?? webAppMeta?.extConfig)
                    }
                }
            }
        }
        loader?.loadMetaAndPackage(listener: listener)
    }
    
    public func preloadWebAppWith(uniqueId: OPAppUniqueID,
                                  completeBlock: completeCallback?) {
        if !OPSDKFeatureGating.isWebappOfflineEnable() && !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.update.pushcommand.enable")) {
            // 离线化开关和在线应用更新开关都没有打开，不需要走后续流程
            if let completeBlock = completeBlock {
                let error = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "webapp offline disable, FG turn off with \(uniqueId)")
                completeBlock(error, .meta, nil)
            }
            logger.error("preloadWebAppWith: webapp offline feature disable")
            return
        }
        self.loaderLock.lock()
        let (existeMeta, loader) = loaderMap[uniqueId.fullString] ?? (nil, OPWebAppLoader(uniqueID: uniqueId, previewToken: ""))
        //先存一下，防止 loader 提前释放
        self.loaderMap[uniqueId.fullString] = (existeMeta, loader)
        self.loaderLock.unlock()
        let listener = OPWebAppLoaderListener(uniqueId) { [weak self](meta, error, state, strategy) in
            if (strategy == .preload && state == .pkg)
                || error != nil {
                //回调可以安全触发 UI 操作
                let webAppMeta = meta as? OPWebAppMeta
                if error != nil {
                    self?.loaderLock.lock()
                    self?.loaderMap.removeValue(forKey: uniqueId.fullString)
                    self?.loaderLock.unlock()
                }
                DispatchQueue.main.async {
                     completeBlock?(error, state, webAppMeta?.extConfig)
                }
            }
        }
        loader?.preloadMetaAndPackage(listener: listener)
    }
    
    public func cleanWebAppInMemory(uniqueID: OPAppUniqueID) {
        self.loaderLock.lock()
        defer{
            self.loaderLock.unlock()
        }
        if let (existedMeta, _) = self.loaderMap[uniqueID.fullString] {
            guard let _ = existedMeta else {
                logger.error("cleanWebAppInMemory existedMeta is nil")
                return
            }
            self.loaderMap.removeValue(forKey: uniqueID.fullString)
            logger.info("cleanWebAppInMemory loaderMap clean memory with uniqueID:\(uniqueID)")
        } else {
            logger.warn("cleanWebAppInMemory loaderMap doesn't have related cache with uniqueID:\(uniqueID)")
        }
    }
    
    public func cleanAllWebAppMetas() {
        logger.info("cleanAllWebAppMetas: try to remove all webapp metas")
        guard let metaInfoModule  = BDPModuleManager(of: .webApp).resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
            logger.error("metaInfo is nil, remove all metas failed because module initialized error")
            return
        }
        metaInfoModule.removeAllMetas();
    }
    
    public func webAppURLWithUniqueId(_ uniqueID: OPAppUniqueID) -> (String, String)? {
        //如果本地存在数据且包已经下载完成，可以进行拦截
        let localMeta = cachedMetaWithUniqueID(uniqueID: uniqueID)
        guard let localMeta = localMeta else { return nil }
        let vhost = localMeta.extConfig.vhost
        let mainUrl = localMeta.extConfig.mainUrl ?? ""
        return (vhost, mainUrl)
    }
    
    public func basicInfoWithUniqueId(_ uniqueID: OPAppUniqueID) -> (String, String)? {
        //如果本地存在数据且包已经下载完成，可以进行拦截
        let localMeta = cachedMetaWithUniqueID(uniqueID: uniqueID)
        guard let localMeta = localMeta else { return nil }
        let pkgName = localMeta.appMetaAdapter.packageData.urls.first?.path.bdp_fileName()
        guard let pkgName = pkgName else { return nil }
        return (localMeta.extConfig.version, pkgName)
    }
    
    /// 是否是合法的vhost，允许跳过 SecLink 检查
    public func isValidVhostInUrl(_ url: URL?) -> Bool {
        if let url = url,
           let host = url.host,
           let appId = url.appId() {
            let uniqueID = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: .webApp)
            let localMeta = cachedMetaWithUniqueID(uniqueID: uniqueID)
            guard let localMeta = localMeta else { return false }
            return localMeta.extConfig.vhost.hasPrefix(host)
        }
        return false
    }
    
    public func canInterceptWith(_ request: URLRequest) -> Bool {
        guard let appId = request.appId()  else {
            logger.error("appId is invalid")
            return false
        }
        guard OPSDKFeatureGating.isWebappOfflineEnable() else {
            logger.warn("isWebappOfflineEnable is false")
            return false
        }
        //暂时只考虑线上版本
        let uniqueID = OPAppUniqueID(appID: appId,
                                     identifier: nil,
                                     versionType: .current,
                                     appType: .webApp,
                                     instanceID: request.instanceIDFromUserAgent())
        //如果本地 pkg 存在，则允许拦截
        if let packageContext = packageContextWithUniqueId(uniqueID) {
            return BDPPackageLocalManager.isLocalPackageExsit(packageContext)
        }
        return false
    }
    
    //从loaderMap 中 加载AppMeta，如果不存在，尝试从本地数据库加载
    private func cachedMetaWithUniqueID(uniqueID: OPAppUniqueID, fallbackEnable: Bool = true) -> OPWebAppMeta? {
        self.loaderLock.lock()
        let (existedMeta, _): (OPWebAppMeta?,OPWebAppLoader?) = self.loaderMap[uniqueID.fullString] ?? (nil, nil)
        self.loaderLock.unlock()
        if let existedMeta = existedMeta {
            return existedMeta
        }
        if !fallbackEnable {
            logger.warn("cachedMetaWithUniqueID can't find meta in map, fallback disable with\(uniqueID)")
            return nil
        }
        logger.warn("cachedMetaWithUniqueID can't find meta in map, fallback with\(uniqueID)")
        let metaProvider = OPWebAppMetaProvider(builder: OPWebAppMetaBuilder())
        do {
            let localMeta = try metaProvider.getLocalMeta(with: uniqueID) as? OPWebAppMeta
            logger.warn("cachedMetaWithUniqueID try to return result from DB with\(uniqueID)")
            return localMeta
        } catch {
            logger.error("meta fetch error with\(uniqueID), error:\(error)")
        }
        logger.warn("cachedMetaWithUniqueID can't find meta, return nil, with\(uniqueID)")
        return nil
    }
    
    private func packageContextWithUniqueId(_ uniqueID: BDPUniqueID) -> BDPPackageContext? {
        let existedMeta = cachedMetaWithUniqueID(uniqueID: uniqueID)
        if let existedMeta = existedMeta {
            return BDPPackageContext(appMeta: existedMeta.appMetaAdapter,
                                     packageType: .pkg,
                                     packageName: nil,
                                     trace: tracing(uniqueID))
        }
        return nil
    }
    
    private func tracing(_ uniqueID: BDPUniqueID) -> BDPTracing {
        let tracingManager = BDPTracingManager.sharedInstance()
        return tracingManager.getTracingBy(uniqueID) ?? tracingManager.generateTracing(by: uniqueID)
    }
    
    public func fetchResourceWith(_ request: URLRequest, compeletionHandler: @escaping (OfflineInterceptModel) -> Void) {
        guard let appId = request.appId(),
              let url = request.url else {
                  logger.error("params invalid")
                  let message = request.appId() == nil ? "appId" : "request.url"
                  let error = OPError.error(monitorCode: GDMonitorCode.invalid_params, message: "\(message) is invalid")
                  compeletionHandler(.error(error))
                  return
        }
        //暂时只考虑线上版本
        let uniqueID = OPAppUniqueID(appID: appId,
                                     identifier: nil,
                                     versionType: .current,
                                     appType: .webApp,
                                     instanceID: request.instanceIDFromUserAgent())
        let packageContext = packageContextWithUniqueId(uniqueID)
        let path = url.path
        if let packageContext = packageContext,
           BDPPackageLocalManager.isLocalPackageExsit(packageContext) {
            self.fileHandleLock.lock()
            let reader = self.fileHandleMap[packageContext.packageName] ?? BDPPackageStreamingFileHandle(afterDownloadedWith: packageContext)
            reader.asyncReadData(withFilePath: path,
                                 dispatchQueue: nil) { error, pkgName, data in
                if let data = data {
                    var allHeaderFields:[String: String] = ["Content-Type": BDPMIMETypeOfFilePath(path),
                                                            "Content-Length": "\(data.count)",
                                                            "Access-Control-Allow-Origin": "*"]
                    //参考竞品 header，且避免KA前后测试包内行为不一致，默认Access-Control-Allow-Origin 为 *
                    //允许通过FG降级到只允许当前host
                    if EMAFeatureGating.boolValue(forKey: "openplatform.webapp.offline.cors"),
                       let host = url.host {
                        allHeaderFields["Access-Control-Allow-Origin"] = host
                    }
                    if let response = HTTPURLResponse(url: url,
                                                      statusCode: 200,
                                                      httpVersion: "HTTP/1.1",
                                                      headerFields: allHeaderFields) {
                        /*
                        let interepModel = OPWebAppInterceptModel(nil, response: response, data: data)
                         */
                        let interepModel = OfflineInterceptModel.responseAndData(response, data)
                        compeletionHandler(interepModel)
                    } else {
                        //construct a interupt model with fallback request here, if it's supported later
                        let error = error ?? OPError.error(monitorCode: GDMonitorCode.unknown_error, message: "response constructed with error")
                        compeletionHandler(.error(error))
                    }
                } else {
                    //construct a interupt model with fallback request here, if it's supported later
                    let error = error ?? OPError.error(monitorCode: GDMonitorCode.unknown_error, message: "fallback not supported yet")
                    compeletionHandler(.error(error))
                }
            }
            self.fileHandleMap[packageContext.packageName] = reader
            self.fileHandleLock.unlock()
        } else {
            let error = OPError.error(monitorCode: GDMonitorCode.unknown_error, message: "package not exist:\(path)")
            compeletionHandler(.error(error))
        }
    }
    
    func executeBuildinResources() {
        let timorBundleUrl = Bundle.main.url(forResource: "TimorAssetBundle", withExtension: "bundle")!
        let mainBundle = Bundle(url: timorBundleUrl)
        if let buildinResourceBundle =  mainBundle?.path(forResource: "BuildinResources.bundle", ofType: ""),
           let buildMetaJsonData = try? Data(contentsOf: URL(fileURLWithPath: buildinResourceBundle.appending("/appMetaList.json"))),
           let metaList = try? JSONSerialization.jsonObject(with: buildMetaJsonData, options: .allowFragments) as? [[String: Any]] {
            let builder = OPWebAppMetaBuilder()
            for json in metaList {
                if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed),
                   let appId = json["appId"] as? String {
                    let uniqueId = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: .webApp)
                    guard let buildInMeta = try? builder.buildFromData(jsonData, uniqueID: uniqueId) as? OPWebAppMeta else {
                        //generate buildIn meta with error
                        logger.error("generate buildIn meta with error: \(uniqueId)")
                        break
                    }
                    let metaContext = MetaContext(uniqueID: uniqueId, token: nil)
                    let provider = GadgetMetaProvider(type: .webApp)
                    let metaLocalAccessor = MetaLocalAccessor(type: .webApp)
                    if let buildinJsonStr = try? buildInMeta.toJson() {
                        if let existedMetaString = metaLocalAccessor.getLocalMeta(with: metaContext),
                           let existedMeta = try? provider.buildMetaModel(with: existedMetaString, context: metaContext) as? OPWebAppMeta {
                            //判断两边的版本，只有内置的版本比已存在的还要高，才进行写入
                            if BDPVersionManager.compareVersion(buildInMeta.appVersion, with: existedMeta.appVersion) > 0 {
                                //预置的版本比本地的要高，保存 meta 信息
                                metaLocalAccessor.saveLocalMeta(with: .current, key: appId, value: buildinJsonStr)
                            } else {
                                //log here
                                logger.error("existed meta found, and buildin version compare fail: \(uniqueId)")
                            }
                        } else {
                            //本地不存在meta信息，直接写入
                            metaLocalAccessor.saveLocalMeta(with: .current, key: appId, value: buildinJsonStr)
                        }
                    } else {
                        logger.error("buildInMeta buildin json invalid: \(uniqueId)")
                    }
                    
                    let tracking = BDPTracing(traceId: "")
                    let packageContext = BDPPackageContext(appMeta: buildInMeta.appMetaAdapter, packageType: .pkg, packageName: nil, trace: tracking)
                    //检查当前gadget的package是否已经存在
                    let packageExisted = BDPPackageLocalManager.isLocalPackageExsit(packageContext)
                    if packageExisted {
                        //如果存在，啥也不干，写点日志
                        logger.info("package existed with uniqueId:\(uniqueId), buildin package has been discard")
                    } else {
                        //写入包信息到本地沙箱目录，同时修改DB状态，将 package state设置为 downloaded
                        let fromResourcePath = buildinResourceBundle.appending("/\(appId).pkg")
                        if let bulidInPackageData =  try? Data(contentsOf: URL(fileURLWithPath: fromResourcePath)) { // NSData.init(contentsOfFile: buildinResourceBundle.appending("/\(appId).package")) {
                            //目标地址目录
                            let pkgDirPath = BDPPackageLocalManager.localPackageDirectoryPath(for: packageContext)
                            do {
                                let fileHandler = try BDPPackageLocalManager.createFileHandle(for: packageContext)
                                fileHandler.seek(toFileOffset: 0)
                                fileHandler.truncateFile(atOffset: 0)
                                fileHandler.synchronizeFile()
                                
                                fileHandler.write(bulidInPackageData)
                            } catch  {
                                logger.error("write package data into sandbox with error:\(error). from:\(fromResourcePath) to:\(pkgDirPath)")
                            }
                            //修改本地package 数据库状态
                            let packageInfoManager = BDPPackageInfoManager(appType: .webApp)
                            packageInfoManager.replaceInToPkgInfo(with: .downloaded, with: uniqueId, pkgName: packageContext.packageName, readType: .normal)
                        }
                    }
                }
                }
        }
    }
}
@objcMembers
public final class WebAppMetaMigration: NSObject {
    static var hasChecked = false
    private static let webappHasMigrateKey = "openplatform_webapp_has_migrate_key"
    public class func migrateWebAppMeta() {
        guard FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.offline.wkurlschemehandler")) else {
            return
        }
        guard !checkHasMigrate() else {
            return
        }
        migrate()
        setHasMigrate()
    }
    private class func migrate() {
        OPWebAppManager.sharedInstance.cleanAllWebAppMetas()
    }
    private class func checkHasMigrate() -> Bool {
        if hasChecked {
            return true
        }
        hasChecked = true
        guard let manager = BDPModuleManager(of: .webApp).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol else {
            return false
        }
        let storage = manager.sharedLocalFileManager().kvStorage
        guard let value = storage.object(forKey: webappHasMigrateKey) as? Bool else {
            return false
        }
        return value
    }
    private class func setHasMigrate() {
        guard let manager = BDPModuleManager(of: .webApp).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol else {
            return
        }
        let storage = manager.sharedLocalFileManager().kvStorage
        storage.setObject(true, forKey: webappHasMigrateKey)
    }
}
