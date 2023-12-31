//
//  OfflineResourceManager.swift
//  OfflineResourceManager
//
//  Created by Miaoqi Wang on 2019/11/26.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker
import IESGeckoKit
import EEAtomic
import TTNetworkManager
import LarkBoxSetting
import LarkAccountInterface

typealias UnderlyingManager = IESGurdKit

/// fetch result handler
public typealias FetchResult = (_ isSuccess: Bool, _ status: OfflineResourceStatus) -> Void

/// offline resource status
public enum OfflineResourceStatus {
    /// unregistered
    case unRegistered
    /// registered but not ready for using
    case notReady
    /// ready for using
    case ready
}

/// Offline resource manager, based on Gecko, currently
public final class OfflineResourceManager: NSObject {
    static let shared = OfflineResourceManager()

    static let logger = Logger.log(OfflineResourceManager.self)
    static let taskQueue = DispatchQueue(label: "com.lark.offlineResourceManager")

    @AtomicObject var config: OfflineResourceConfig = .empty()
    @AtomicObject var bizConfigs: [BizID: OfflineResourceBizConfig] = [:]

    var debugBizConfigsBackUp: [BizID: OfflineResourceBizConfig]?
    var refetchTasks: [BizID: ReFetchTask] = [:]

    var readyToFetch: Bool = false {
        didSet {
            if readyToFetch {
                reFetch()
            }
        }
    }

    func updateReadyToFetch() {
        // ready: after setConfig & after register & deviceId is not empty
        self.readyToFetch = !self.config.deviceId.isEmpty &&
            !self.config.appId.isEmpty &&
            !bizConfigs.isEmpty
    }

    func reFetch() {
        OfflineResourceManager.taskQueue.async {
            if !self.refetchTasks.isEmpty {
                self.refetchTasks.values.forEach { (task) in
                    OfflineResourceManager.logger.info("refetch id \(task.bizId)")
                    OfflineResourceManager.fetchResource(byId: task.bizId,
                                                         resourceVersion: task.resourceVersion,
                                                         customParams: task.customParams,
                                                         complete: task.result)
                }
                self.refetchTasks.removeAll()
            }
        }
    }

    @discardableResult
    class func innerSetDID(_ did: String) -> Bool {
        guard !did.isEmpty else {
            logger.warn("device id is empty")
            return false
        }
        UnderlyingManager.deviceID = did
        return true
    }

    @discardableResult
    class func innerSetDomain(_ domain: String) -> Bool {
        guard !config.domain.isEmpty else {
            logger.warn("domain is empty")
            return false
        }

        UnderlyingManager.platformDomain = domain
        return true
    }

    struct ReFetchTask {
        let bizId: BizID
        let resourceVersion: String?
        let customParams: [String: Any]?
        let result: FetchResult?
    }
}

// MARK: - public functions
extension OfflineResourceManager {
    /// config
    public static var config: OfflineResourceConfig {
        return shared.config
    }

    /// biz configs
    public static var bizConfigs: [BizID: OfflineResourceBizConfig] {
        return shared.bizConfigs
    }

    public class func setGurdEnable() {
        taskQueue.async {
            if BoxSetting.isBoxOff() {
                UnderlyingManager.enable = false
            } else {
                UnderlyingManager.enable = true
            }
        }
    }

    /// set config, call this function first
    public class func setConfig(_ config: OfflineResourceConfig) {
        taskQueue.async {
            shared.config = config
            innerSetDID(config.deviceId)
            innerSetDomain(config.domain)
            UnderlyingManager.setup(withAppId: config.appId,
                                    appVersion: config.appVersion,
                                    cacheRootDirectory: config.cacheRootDirectory)
            UnderlyingManager.appLogDelegate = shared
            if config.isBoe {
                UnderlyingManager.networkDelegate = shared
            }
            logger.info("set config \(config)")
            shared.updateReadyToFetch()
        }
    }

    /// reset device id
    public class func setDeviceId(_ did: String) {
        taskQueue.async {
            guard innerSetDID(did) else { return }
            logger.info("update did \(did)")
            shared.config.deviceId = did
            shared.updateReadyToFetch()
        }
    }

    /// reset device id
    public class func setDomain(_ domain: String) {
        taskQueue.async {
            guard innerSetDomain(domain) else { return }
            logger.info("update domain \(domain)")
            shared.config.domain = domain
            shared.updateReadyToFetch()
        }
    }

    /// register biz config
    public class func registerBiz(configs: [OfflineResourceBizConfig]) {
        taskQueue.async {
            guard !configs.isEmpty else {
                logger.info("empty configs")
                return
            }

            var registerDic: [String: [String]] = [:]

            configs.forEach { (cfg) in
                // 保存cfg
                if shared.bizConfigs[cfg.bizID] != nil {
                    logger.info("update config for bizId: \(cfg.bizID)")
                }
                shared.bizConfigs[cfg.bizID] = cfg

                // 合并相同 Key 下面的 channels
                if registerDic[cfg.bizKey] == nil {
                    registerDic[cfg.bizKey] = [cfg.subBizKey]
                } else {
                    registerDic[cfg.bizKey]?.append(cfg.subBizKey)
                }
            }

            registerDic.forEach { (key, chls) in
                logger.info("register resource key \(key) channels \(chls)")
                UnderlyingManager.registerAccessKey(key, channels: chls)
            }
            shared.updateReadyToFetch()
        }
    }

    /// fetch resource using biz id
    /// - Parameters:
    ///     - id: business id
    ///     - resouceVersion: local version used for version compare. set nil will use app version
    ///     - customParams: custom fetch resource params
    ///     - complete: fetch result, which will be dispatch on `Main Thread`
    public class func fetchResource(byId id: String,
                                    resourceVersion: String? = nil,
                                    customParams: [String: Any]? = nil,
                                    complete: FetchResult? = nil) {
        taskQueue.async {
            guard let config = bizConfigs[id] else {
                logger.warn("biz id: \(id) not registered")
                complete?(false, .unRegistered)
                return
            }
            logger.info("fetch resource \(config) resourceVersion \(resourceVersion ?? "0")")
            if shared.readyToFetch {
                UnderlyingManager.syncResources { params in
                    params.accessKey = config.bizKey
                    params.channels = [config.subBizKey]
                    params.forceRequest = false
                    if let customParams = customParams {
                        params.customParams = customParams
                    }
                    if let resourceVersion = resourceVersion {
                        params.resourceVersion = resourceVersion
                    }
                } completion: { isSuccess, statusInfo in
                    self.logger.info("sync resource success:\(isSuccess) statusInfo: \(statusInfo)")
                    if isSuccess {
                        complete?(true, .ready)
                    } else {
                        complete?(false, .notReady)
                    }
                }
            } else {
                logger.info("not ready to fetch \(id) config:\(self.config) bizCount: \(bizConfigs.count)")
                shared.refetchTasks[id] = ReFetchTask(bizId: id, resourceVersion: resourceVersion, customParams: customParams, result: complete)
            }
        }
    }

    /// root dir of resource for specified biz idd
    public class func rootDir(forId id: String) -> String? {
        guard let config = bizConfigs[id] else {
            logger.warn("biz id: \(id) not registered")
            return nil
        }
        return UnderlyingManager.rootDir(forAccessKey: config.bizKey, channel: config.subBizKey)
    }

    /// get resource status
    public class func getResourceStatus(byId id: String) -> OfflineResourceStatus {
        if let config = bizConfigs[id] {
            let status = UnderlyingManager.cacheStatus(forAccessKey: config.bizKey, channel: config.subBizKey)
            return status == .active ? .ready : .notReady
        } else {
            return .unRegistered
        }
    }

    /// check file exists
    public class func fileExists(id: String, path: String) -> Bool {
        guard let config = bizConfigs[id] else {
            logger.warn("biz id: \(id) not registered")
            return false
        }
        return UnderlyingManager.hasCache(forPath: path, accessKey: config.bizKey, channel: config.subBizKey)
    }

    /// get data for path
    public class func data(forId id: String, path: String) -> Data? {
        guard let config = bizConfigs[id] else {
            logger.warn("biz id: \(id) not registered")
            return nil
        }
        logger.info("get data for id \(id)")
        return UnderlyingManager.data(forPath: path, accessKey: config.bizKey, channel: config.subBizKey)
    }

    /// clear cache for specified biz id
    public class func clear(id: String, completion: ((Bool) -> Void)? = nil) {
        taskQueue.async { 
            guard let config = bizConfigs[id] else {
                logger.warn("biz id: \(id) not registered")
                completion?(false)
                return
            }
            logger.info("clear cache for id \(id)")
            UnderlyingManager.clearCache(forAccessKey: config.bizKey, channel: config.subBizKey)
            completion?(true)
        }
    }

    /// remove biz configs of specific types
    public class func removeBizConfigs(of types: [BizType]) {
        taskQueue.async {
            guard !bizConfigs.isEmpty else {
                logger.info("remove biz config types: no configs")
                return
            }
            let configsToRemove = bizConfigs.values.filter { (config) -> Bool in
                types.contains(config.bizType)
            }
            configsToRemove.forEach { (config) in
                shared.bizConfigs.removeValue(forKey: config.bizID)
            }
            logger.info("remove biz config types: \(types)")
        }
    }
}

// MARK: - Debug
extension OfflineResourceManager {

    func appCanDebug() -> Bool {
        #if DEBUG
        return true
        #else
        let suffix = matchingStrings(string: config.appVersion, regex: "[a-zA-Z]+(\\d+)?").first?.first
        return suffix != nil
        #endif
    }

    func matchingStrings(string: String, regex: String, options: NSRegularExpression.Options = []) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: options) else { return [] }
        let nsString = string as NSString
        let results = regex.matches(in: string, options: [], range: NSRange(location: 0, length: nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                ? nsString.substring(with: result.range(at: $0))
                : ""
            }
        }
    }

    /// debug menu config
    public class func debugResourceDisable(_ disable: Bool) {
        if shared.appCanDebug() {
            if disable {
                OfflineResourceManager.logger.debug("debug switch config disable config \(bizConfigs)")
                shared.debugBizConfigsBackUp = bizConfigs
                shared.bizConfigs = [:]
            } else {
                // check empty in case bizConfigs is updated by other place
                if bizConfigs.isEmpty, let configs = shared.debugBizConfigsBackUp {
                    OfflineResourceManager.logger.debug("debug switch enable config \(configs)")
                    shared.bizConfigs = configs
                }
            }
        }
    }
}

extension OfflineResourceManager: IESGurdNetworkDelegate {
    public func downloadPackage(with model: IESGurdDownloadInfoModel,
                                completion: @escaping IESGurdNetworkDelegateDownloadCompletion) {
        let configuration = URLSessionConfiguration.default
        let downloadSesion = URLSession(configuration: configuration)
        guard let url = URL(string: model.currentDownloadURLString) else {
            return
        }
        let request = URLRequest(url: url)
        let downloadtask: URLSessionDownloadTask = downloadSesion.downloadTask(with: request) { location, response, error in
            completion(location, error)
        }
        downloadtask.resume()
    }

    public func cancelDownload(withIdentity identity: String) {
        
    }
    
    public func request(withMethod method: String,
                        urlString URLString: String,
                        params: [AnyHashable : Any],
                        completion: @escaping (IESGurdNetworkResponse) -> Void) {
        let updatedUrlString = exchangeHttp(originalUrl: URLString)
        let useJson: Bool = method.uppercased() == "POST"
        let finishBlock: TTNetworkJSONFinishBlockWithResponse = { error, obj, response in
            let networkResponse = IESGurdNetworkResponse()
            if let response = response, let allHeaderFields = response.allHeaderFields as? [AnyHashable: Any] {
                networkResponse.statusCode = response.statusCode
                networkResponse.allHeaderFields = allHeaderFields
            }
            if let responseObj = obj {
                networkResponse.responseObject = responseObj
            }
            if let error = error {
                networkResponse.error = error
            }
            completion(networkResponse)
        }
        let headerField = useJson ? ["Content-Type": "application/json"] : nil
        let requestSerializer: TTHTTPRequestSerializerProtocol.Type = {
            useJson ? NetworkRequestJsonSerializer.self : TTHTTPRequestSerializerBase.self
        }()
        
        TTNetworkManager.shareInstance().requestForJSON(withResponse: updatedUrlString,
                                                        params: params,
                                                        method: method,
                                                        needCommonParams: false,
                                                        headerField: headerField,
                                                        requestSerializer: requestSerializer,
                                                        responseSerializer: TTHTTPRequestSerializerBase.self as? TTJSONResponseSerializerProtocol.Type,
                                                        autoResume: true,
                                                        callback: finishBlock)
    }

    func exchangeHttp(originalUrl: String?) -> String {
        var url: String
        if let originalUrl = originalUrl {
            url = originalUrl
        } else {
            url = "https://%@\(IESGurdKit.platformDomain)"
        }
        if self.config.isBoe, url.hasPrefix("https://") {
            url = url.replacingOccurrences(of: "https://", with: "http://")
        }
        return url
    }
}

extension OfflineResourceManager: IESGurdAppLogDelegate {
    public func trackEvent(_ event: String, params: [AnyHashable : Any]) {
        var trackParams = params
        trackParams["params_for_special"] = "gecko"
        Tracker.post(TeaEvent(event, params: trackParams))
        OfflineResourceManager.logger.info("[Gecko]-[\(event)]-\(params)")
    }
}

extension OfflineResourceManager {
    public class func activeInternalPackage(with bundle: String, accessKey: String, channel: String) {
        UnderlyingManager.activeInternalPackage(withBundleName: bundle, accessKey: accessKey, channel: channel) { isSucc in
            OfflineResourceManager.logger.info("active internal package channel:\(channel), isSucc:\(isSucc)")
        }
    }
}
