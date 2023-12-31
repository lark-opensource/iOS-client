//
//  OPBlockGuideInfoLoadTask.swift
//  OPBlock
//
//  Created by yinyuan on 2021/3/11.
//

import Foundation
import OPSDK
import OPBlockInterface
import LarkOPInterface
import TTMicroApp
import ECOProbe
import LKCommonsLogging
import LarkSetting
import LarkFeatureGating
import LarkStorage
import LarkAccountInterface
import LarkContainer

private let logger = Logger.oplog(OPBlockGuideInfoLoadTask.self, category: "OPBlockGuideInfoLoadTask")

/// 引导信息加载任务
class OPBlockGuideInfoLoadTask: OPTask<OPBlockGuideInfoLoadTaskInput, OPBlockGuideInfoLoadTaskOutput> {
    private let userResolver: UserResolver

    private var netStatusService: OPNetStatusHelper? {
        return try? userResolver.resolve(assert: OPNetStatusHelper.self)
    }

    private struct BlockGuideInfoCacheConfig: SettingDefaultDecodable{
        static let settingKey = UserSettingKey.make(userKeyLiteral: "block_cache_GetBlockGuideInfo")

        static let defaultValue = BlockGuideInfoCacheConfig(
            cacheTimeout: 86400,
            enableTimeout: true,
            useVersionCache: false
        )

        // 缓存过期时间
        let cacheTimeout: Int
        // 是否支持缓存失效
        let enableTimeout: Bool
        // 是否将version作为隔离key
        let useVersionCache: Bool
        
        enum CodingKeys: String, CodingKey {
            case enableTimeout = "enableTimeoutIos"
            case cacheTimeout
            case useVersionCache
        }
    }

    private var blockGuideInfoCacheConfig: BlockGuideInfoCacheConfig {
        return userResolver.settings.staticSetting()
    }

    private weak var task: URLSessionDataTask?

    /// 同LoadTask
    private let containerContext: OPContainerContext

    private static var useGuideInfoNewKey = false
    
    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    /// kv store
    /// space: user
    /// domain: biz.block.{blockId}.{host}
    private let store: KVStore
    
    required init(userResolver: UserResolver, containerContext: OPContainerContext) {
        self.userResolver = userResolver
        self.containerContext = containerContext

        // store domain: biz.block.{blockTypeId}.{host}
        let storeDomain = Domain.biz.block
            .child(containerContext.uniqueID.identifier)
            .child(containerContext.uniqueID.host)
        self.store = KVStores
            .in(space: .user(id: userResolver.userID))
            .in(domain: storeDomain)
            .mmkv()
        super.init(dependencyTasks: [])
        name = "OPBlockGuideInfoTask uniqueID: \(containerContext.uniqueID)"
    }
    
    override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchGuideInfo.start_guide_info)
            .tracing(containerContext.blockContext.trace)
            .setUniqueID(containerContext.uniqueID)
            .flush()
        let startTime = Date()

        super.taskDidStarted(dependencyTasks: dependencyTasks)
        // 校验入参合法
        guard let input = self.input else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            // 此时input为空为异常情况，没有uniqueID，所以先用logger以免缺少日志
            trace.error("OPBlockGuideInfoLoadTask.taskDidStarted error: input == nil")
            let monitorCode = OPBlockitMonitorCodeMountLaunch.internal_error
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .tracing(containerContext.blockContext.trace)
                .setErrorMessage("OPBlockGuideInfoLoadTask invalid input, input is nil")
                .addCategoryValue("biz_error_code", "\(OPBlockitLaunchInternalErrorCode.invalidGuideInfoTaskInout.rawValue)")
                .flush()
            taskDidFailed(error: monitorCode.error(message: "OPBlockGuideInfoLoadTask invalid input, input is nil"))
            return
        }

        let uniqueID = input.containerContext.uniqueID

        trace.info("OPBlockGuideInfoLoadTask.taskDidStarted")

        if input.containerContext.uniqueID.versionType == .preview {
            trace.info("OPBlockGuideInfoLoadTask.taskDidStarted preview mode")
            // preview 模式不用检查 guide info
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: OPBlockitMonitorCodeMountLaunchGuideInfo.guide_info_success)
                .setResultTypeSuccess()
                .addMetricValue("duration", Int(Date().timeIntervalSince(startTime) * 1000))
                .addMap(["use_cache": false])
                .tracing(containerContext.blockContext.trace)
                .flush()
            taskDidSucceeded()
            return
        }

        guard let blockContainerConfig = input.containerContext.containerConfig as? OPBlockContainerConfigProtocol else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            trace.error("OPBlockGuideInfoLoadTask.taskDidStarted error: invalid containerConfig")
            let monitorCode = OPBlockitMonitorCodeMountLaunch.internal_error
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .setErrorMessage("OPBlockGuideInfoLoadTask invalid containerConfig")
                .addCategoryValue("biz_error_code", "\(OPBlockitLaunchInternalErrorCode.invalidContainerConfig.rawValue)")
                .tracing(containerContext.blockContext.trace)
                .flush()
            taskDidFailed(error: monitorCode.error(message: "OPBlockGuideInfoLoadTask invalid containerConfig"))
            return
        }
        
        var shouldUseHostData = false
        // 判断是否可以使用注入数据 && 是否有注入数据
        if OPBlockDataInjectSetting.isEnableInjectData(host: blockContainerConfig.host, blockTypeId: uniqueID.identifier, dataType: .guideInfo),
           let guideInfoDataService = input.serviceContainer.resolve(BlockDataSourceService<OPBlockGuideInfo>.self) {
            shouldUseHostData = true
            if let guideInfo = guideInfoDataService.fetchData(dataType: .guideInfo) {
                dealInjectGuideInfo(guideInfo: guideInfo, uniqueID: uniqueID, startTime: startTime)
                // 继续走网络 去刷新缓存
            }
        }

        // 有缓存 缓存没有过期 且 缓存可用的情况下 使用缓存
        let usedCache = hasCache() && isCacheValid() && isUsableCache()
        // 如果来自于缓存，则立即回调成功。
        // 同时继续发起请求，保证 c/s 数据同步
        if usedCache {
            trace.info("OPBlockGuideInfoLoadTask.taskDidStarted use cache")
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: OPBlockitMonitorCodeMountLaunchGuideInfo.guide_info_success)
                .setResultTypeSuccess()
                .addMetricValue("duration", Int(Date().timeIntervalSince(startTime) * 1000))
                .addMap(["use_cache": true])
                .tracing(containerContext.blockContext.trace)
                .flush()
            taskDidSucceeded()
        }

        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchGuideInfo.start_fetch_guide_info)
        .setUniqueID(containerContext.uniqueID)
        .tracing(containerContext.blockContext.trace)
        .flush()

        let start = Date()
        let request: URLRequest
        let monitor = OPMonitor(name: String.OPBlockitMonitorKey.eventName, code: nil)
            .addCategoryValue("enable_timeout_ios", blockGuideInfoCacheConfig.enableTimeout)
            .addCategoryValue("use_version_cache", blockGuideInfoCacheConfig.useVersionCache)
            .addCategoryValue("cache_timeout", blockGuideInfoCacheConfig.cacheTimeout)
            .addCategoryValue("use_cache", usedCache)
            .addCategoryValue("has_cache", hasCache())
            .addCategoryValue("cache_valid", isCacheValid())
            .addCategoryValue("cache_timestamp", getCacheTimestamp())
            .addCategoryValue("should_use_host_data", shouldUseHostData)
            .addCategoryValue("use_host_data", false)
            .tracing(containerContext.blockContext.trace)
            .setResultTypeFail()
            .tracing(containerContext.blockContext.trace)
        do {
            request = try generateGuideInfoRequest(uniqueID: uniqueID, containerConfig: blockContainerConfig)
        } catch {
            let err = error as? OPError ?? OPBlockitMonitorCodeMountLaunch.internal_error.error(message: "generate guideInfo request error")
            let duration = Date().timeIntervalSince(startTime) * 1000
            monitor.setMonitorCode(err.monitorCode)
                .setDuration(duration)
                .setErrorMessage("generate guideInfo request error")
                .setError(err)
                .addCategoryValue("biz_error_code", "\(OPBlockitLaunchInternalErrorCode.createGuideInfoRequestFail.rawValue)")
                .flush()
            trace.error("OPBlockGuideInfoLoadTask.taskDidStarted error: \(err.localizedDescription)")
            taskDidFailed(error: err)
            return
        }

        let tempTrace = trace
        let blockContext = containerContext.blockContext
        task = BDPNetworking.sharedSession().dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else {
                tempTrace.error("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: self is released")
                return
            }
            let requestID = response?.allHeaderFields["x-request-id"] as? String ?? ""
            let logId = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
            monitor
                .addCategoryValue("http_code", response?.statusCode)
                .addCategoryValue("request_id", requestID)
                .addCategoryValue("log_id", logId)
                .setUniqueID(uniqueID)
            guard let data = data, error == nil else {
                let data = GuideInfoStatusViewItem(imageType: .no_wifi, displayMsg: BundleI18n.OPBlock.OpenPlatform_BlockGuide_LoadFailRetry, button: nil)
                let monitorCode = OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_network_error
                let duration = Date().timeIntervalSince(startTime) * 1000
                monitor.setMonitorCode(monitorCode)
                    .setDuration(duration)
                    .setError(error)
                    .addCategoryValue("net_status", self.netStatusService?.status.rawValue)
                    .flush()
                let error = error?.newOPError(monitorCode: monitorCode) ?? monitorCode.error()
                GuideInfoStatusViewItems.dataMap[error] = data
                self.trace.error("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: guide info request error")
                self.taskDidFailed(error: error)
                return
            }
            let monitorCode = OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_biz_error
            do {
                let duration = Date().timeIntervalSince(startTime) * 1000
                let json = try JSONSerialization.jsonObject(with: data)
                guard let jsonDic = json as? [String: Any] else {
                    self.trace.error("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: jsonObject type invalid")
                    monitor.setMonitorCode(monitorCode)
                        .setDuration(duration)
                        .setErrorMessage("jsonObject type invalid")
                        .addCategoryValue("biz_error_code", "\(OPBlockitGuideInfoBizErrorCode.invalidType.rawValue)")
                        .flush()
                    self.taskDidFailed(error: monitorCode.error(message: "jsonObject type invalid"))
                    return
                }
                guard let code = jsonDic["code"] as? Int, code == 0 else {
                    let duration = Date().timeIntervalSince(startTime) * 1000
                    self.trace.error("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: guide info request failed. code:\(jsonDic["code"] ?? "")")
                    monitor.setMonitorCode(monitorCode)
                        .setDuration(duration)
                        .setErrorMessage("guide info request invalid code")
                        .addMap([
                            "biz_code": jsonDic["code"] as? Int,
                            "data_keys": jsonDic.map({ $0.key }),
                            "biz_error_code": "\(OPBlockitGuideInfoBizErrorCode.invalidCode.rawValue)"
                        ])
                        .flush()
                    self.taskDidFailed(error: monitorCode.error(message: "guide info request invalid code:\(jsonDic["code"] ?? "")"))
                    return
                }
                guard let data = jsonDic["data"] as? [String: Any],
                      let block_extensions = data["block_extensions"] as? [String: Any],
                      let block_info = block_extensions[uniqueID.identifier] as? [String: Any],
                      let block_extension = block_info["block_extension"] as? [String: Any],
                      let statusRawValue = block_extension["status"] as? Int,
                      let status = OPBlockGuideInfoStatus(rawValue: statusRawValue)
                else {
                    self.trace.error("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: guide info parse status failed")
                    let duration = Date().timeIntervalSince(startTime) * 1000
                    monitor.setMonitorCode(monitorCode)
                        .setDuration(duration)
                        .setErrorMessage("guide info parse data failed")
                        .addMap([
                            "biz_code": jsonDic["code"] as? Int,
                            "data_keys": jsonDic.map({ $0.key }),
                            "biz_error_code": "\(OPBlockitGuideInfoBizErrorCode.parseDataFail.rawValue)"
                        ])
                        .flush()
                    self.taskDidFailed(error: monitorCode.error(message: "guide info parse data failed."))
                    return
                }

                self.trace.info("OPBlockGuideInfoLoadTask.taskDidStarted dataTask did complete, status: \(status)")

                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_success)
                    .setResultTypeSuccess()
                    .addMap([
                        "status": status.rawValue,
                        "use_cache": usedCache,
                        "request_id": requestID,
                        "log_id": logId
                    ])
                    .tracing(blockContext.trace)
                    .flush()

                let info = OPBlockGuideInfoStatusHandler.handle(status: status, block_info: block_info)

                // 如果 isUsableFromCache 为 true，则说明已经回调成功了
                // 不再回调避免多次回调
                if info.isUsable && !usedCache {
                    self.trace.info("OPBlockGuideInfoLoadTask.taskDidStarted dataTask usable & not from cache")
                    monitor.setMonitorCode(OPBlockitMonitorCodeMountLaunchGuideInfo.guide_info_success)
                        .addMetricValue("duration", Int(Date().timeIntervalSince(start) * 1000))
                        .addCategoryValue("request_id", requestID)
                        .addCategoryValue("log_id", logId)
                        .setResultTypeSuccess()
                        .flush()
                    self.taskDidSucceeded()
                }

                if let err = info.error {
                    // 不再回调避免多次回调
                    if !usedCache {
                        self.trace.error("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: \(err.localizedDescription)")
                        monitor.setMonitorCode(err.monitorCode)
                            .addCategoryValue("duration", Int(Date().timeIntervalSince(start) * 1000))
                            .addMap(["status": status.rawValue])
                            .setErrorMessage("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error")
                            .setError(err)
                            .flush()
                        self.taskDidFailed(error: err)
                    }
                }

                // 将请求结果缓存起来
                self.setUsableByCache(usable: info.isUsable)

            } catch {
                self.trace.error("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: json decode failed")
                monitor.setMonitorCode(monitorCode)
                    .addCategoryValue("duration", Int(Date().timeIntervalSince(start) * 1000))
                    .setErrorMessage("OPBlockGuideInfoLoadTask.taskDidStarted dataTask error: json decode failed")
                    .setError(error)
                    .flush()
                self.taskDidFailed(error: error.newOPError(monitorCode: monitorCode))
            }
        })

        task?.resume()
        trace.info("OPBlockGuideInfoLoadTask.taskDidStarted task did resume")
    }
    
    override func taskDidCancelled(error: OPError) {
        super.taskDidCancelled(error: error)

        trace.error("OPBlockGuideInfoLoadTask.taskDidCancelled error: \(error.localizedDescription)")
        // 如果网络请求正在进行则取消
        task?.cancel()
        task = nil
    }
    
}

extension OPBlockGuideInfoLoadTask {
    
    /// 获取拉GuideInfo的request
    /// - Parameter uniqueID: 需要拉取GuideInfo的ID
    /// - Throws: 无法组装url时会抛出异常
    /// - Returns: 组装好的拉取GuideInfo的request
    private func generateGuideInfoRequest(uniqueID: OPAppUniqueID, containerConfig: OPBlockContainerConfigProtocol) throws -> URLRequest {

        // 目前缺少相关可用网络基建，暂时内聚在这里，等待 infra 基建完善后接入
        guard let metaURL = URL.opURL(domain: OPApplicationService.current.domainConfig.openAppInterface,
                                path: "lark/app_interface/api",
                                resource: "GetBlockGuideInfo") else {
            let err = OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunch.internal_error, message: "can not get metaURL")
            trace.error("OPBlockGuideInfoLoadTask.generateGuideInfoRequest error: \(err.localizedDescription)")
            throw err
        }
        var headers: [String: String] = [:]
        headers["Cookie"] = "session=\(OPApplicationService.current.accountConfig.userSession)"
        headers["Content-Type"] = "application/json"

        var params: [String: Any] = [:]
        params["lark_version"] = "\(OPApplicationService.current.envConfig.larkVersion)"
        params["host"] = containerConfig.host
        params["block_ids"] = ["\(uniqueID.identifier)"]
        var request = OPURLSessionTaskConfigration(identifier: uniqueID.description,
                                            url: metaURL,
                                            method: .post,
                                            headers: NSDictionary(dictionary: headers),
                                            params: NSDictionary(dictionary: params)).urlRequest
        request.cachePolicy = .reloadIgnoringCacheData
        request.timeoutInterval = 15.0
        return request
    }

    private func isCacheValid() -> Bool {
        let timestamp = store.integer(forKey: BlockCacheKey.BlockType.Host.guideInfoTimestamp)
        if blockGuideInfoCacheConfig.enableTimeout {
            return (timestamp + blockGuideInfoCacheConfig.cacheTimeout) >= Int(Date().timeIntervalSince1970)
        } else {
            return false
        }
    }

    private func hasCache() -> Bool {
        return store.contains(key: BlockCacheKey.BlockType.Host.guideInfoData)
    }

    private func isUsableCache() -> Bool {
        return store.bool(forKey: BlockCacheKey.BlockType.Host.guideInfoData)
    }

    private func setUsableByCache(usable: Bool) {
        store.set(usable, forKey: BlockCacheKey.BlockType.Host.guideInfoData)
        store.set(Int(Date().timeIntervalSince1970), forKey: BlockCacheKey.BlockType.Host.guideInfoTimestamp)
    }

    private func getCacheTimestamp() -> Int {
        return store.integer(forKey: BlockCacheKey.BlockType.Host.guideInfoTimestamp)
    }
}

extension OPBlockGuideInfoLoadTask {
    private func dealInjectGuideInfo(guideInfo: OPBlockGuideInfo, uniqueID: OPAppUniqueID, startTime: Date) {
        let monitor = OPMonitor(name: String.OPBlockitMonitorKey.eventName, code: nil)
            .addCategoryValue("should_use_host_data", true)
            .addCategoryValue("use_host_data", true)
            .tracing(containerContext.blockContext.trace)
        let monitorCode = OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_biz_error
                    
        guard let status = OPBlockGuideInfoStatus(rawValue: guideInfo.blockExtension.status) else {
            self.trace.error("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask error: inject guide info parse status failed")
            let duration = Date().timeIntervalSince(startTime) * 1000
            monitor.setMonitorCode(monitorCode)
                .setDuration(duration)
                .setErrorMessage("guide info parse data failed")
                .addCategoryValue("biz_error_code", "\(OPBlockitGuideInfoBizErrorCode.parseInjectedDataFail.rawValue)")
                .flush()
            self.taskDidFailed(error: monitorCode.error(message: "inject guide info parse data failed."))
            return
        }

        self.trace.info("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask did complete, status: \(status)")

        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchGuideInfo.fetch_guide_info_success)
        .setResultTypeSuccess()
        .addMap(["status": status.rawValue,
                 "use_cache": false,
                 "should_use_host_data": true,
                 "use_host_data": true])
        .tracing(containerContext.blockContext.trace)
        .flush()
        do {
            let jsonData = try JSONEncoder().encode(guideInfo)
            let block_Info = try JSONSerialization.jsonObject(with: jsonData)
            guard let block_Info = block_Info as? [String: Any] else {
                self.trace.error("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask error: blockInfo jsonObject type invalid")
                monitor.setMonitorCode(monitorCode)
                    .setDuration(Date().timeIntervalSince(startTime) * 1000)
                    .setErrorMessage("jsonObject type invalid")
                    .addCategoryValue("biz_error_code", "\(OPBlockitGuideInfoBizErrorCode.injectedDataInvalidType.rawValue)")
                    .flush()
                self.taskDidFailed(error: monitorCode.error(message: "jsonObject type invalid"))
                return
            }

            // 之后统一转成struct传入 现在先转成map。。
            let info = OPBlockGuideInfoStatusHandler.handle(status: status, block_info: block_Info)
            if info.isUsable {
                self.trace.info("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask usable")
                monitor.setMonitorCode(OPBlockitMonitorCodeMountLaunchGuideInfo.guide_info_success)
                    .addMetricValue("duration", Int(Date().timeIntervalSince(startTime) * 1000))
                    .setResultTypeSuccess()
                    .flush()
                self.taskDidSucceeded()
                return
            }

            if let err = info.error {
                self.trace.error("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask error: \(err.localizedDescription)")
                monitor.setMonitorCode(err.monitorCode)
                    .setDuration(Date().timeIntervalSince(startTime) * 1000)
                    .addMap(["status": status.rawValue])
                    .setErrorMessage("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask error")
                    .setError(err)
                    .flush()
                self.taskDidFailed(error: err)
            }
        } catch {
            self.trace.error("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask error: json encode failed")
            monitor.setMonitorCode(monitorCode)
                .setDuration(Date().timeIntervalSince(startTime) * 1000)
                .setErrorMessage("OPBlockGuideInfoLoadTask.dealInjectGuideInfo dataTask error: json encode failed")
                .setError(error)
                .flush()
            self.taskDidFailed(error: error.newOPError(monitorCode: monitorCode))
        }
    }
}
