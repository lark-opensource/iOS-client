//
//  OpenPluginManager.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import ECOProbe
import ECOProbeMeta
import LarkFeatureGating
import LarkSetting
import ECOInfra

public final class OpenPluginManager: OpenPluginManagerProtocol {

    static private let logger = Logger.log(OpenPluginManager.self, category: "OpenAPI")
    static private var cache = [String: [OpenAPIConfig]]() // config的cache
    static private let cacheLock = DispatchSemaphore(value: 1)
    
    public typealias APIRegistrationFilter = ((_ apiName: String, _ conditions: [OpenAPIAccessConfig]) -> Bool)
    public typealias AuthenticationChecker = ((_ apiName: String) -> OpenAPISimpleResponse)
    public typealias AsyncAuthorizationChecker = ((_ apiName: String, _ checkResult: @escaping OpenAPISimpleCallback) -> Void)
    
    private let apiRegistrationFilter: APIRegistrationFilter?
    
    // 鉴权器：用于某些需要身份验证的api校验
    private let authenticationChecker: AuthenticationChecker?

    // 授权器：用于某些需要用户/系统授权的api校验, 只用于异步接口
    private let asyncAuthorizationChecker: AsyncAuthorizationChecker?

    public private(set) var defaultPluginConfig: [String: OpenAPIInfo] = [:]

    private let pluginsLock = DispatchSemaphore(value: 1)
    private(set) var plugins: [String: OpenBasePlugin] = [:]
    
    let extensionResolver: OPExtensionResolver

    /// 初始化默认apis
    /// - Parameters:
    ///   - plistPath: api配置列表
    ///   - bizScene: 当前PM所属的业务域，可以使用plist配置中包含该scene的私有API
    ///   - authenticationChecker: 鉴权校验器
    ///   - asyncAuthorizationChecker: 授权鉴权校验器
    public init(
        defaultPluginConfig plistPath: String? = nil,
        bizDomain: OpenAPIBizDomain,
        bizType: OpenAPIBizType,
        bizScene: String,
        apiRegistrationFilter: APIRegistrationFilter? = nil,
        authenticationChecker: AuthenticationChecker? = nil,
        asyncAuthorizationChecker: AsyncAuthorizationChecker? = nil
    ) {
        let defaultPath = BundleConfig.LarkOpenPluginManagerBundle.path(forResource: "LarkOpenAPIConfigs", ofType: "plist")
        self.apiRegistrationFilter = apiRegistrationFilter
        self.asyncAuthorizationChecker = asyncAuthorizationChecker
        self.authenticationChecker = authenticationChecker
        self.extensionResolver = OPExtensionResolver()
        if let path = plistPath ?? defaultPath {
            do {
                var config: [OpenAPIConfig]
                if let storageConfigs = self.configsCache(path: path) {
                    config = storageConfigs
                } else {
                    // lint:disable:next lark_storage_check
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    config = try PropertyListDecoder().decode([OpenAPIConfig].self, from: data)
                    self.storageConfigs(path: path, value: config)
                }
                
                if let apiFilter = apiRegistrationFilter {
                    config.compactMap({ item -> (OpenAPIInfo, [OpenAPIAccessConfig])? in
                        guard let apiInfo = item.matchedAPIInfo(for: bizDomain, type: bizType, scene: bizScene) else { return nil
                        }
                        return (apiInfo, item.conditions)
                    })
                    .filter({ apiFilter($0.0.apiName, $0.1) })
                    .forEach({ defaultPluginConfig[$0.0.apiName] = $0.0 })
                } else {
                    config.compactMap({ $0.matchedAPIInfo(for: bizDomain, type: bizType, scene: bizScene) })
                        .forEach({ defaultPluginConfig[$0.apiName] = $0 })
                }
            } catch {
                assertionFailure("apiConfig plistPath has wrong format: \(error)")
                OpenPluginManager.logger.warn("apiConfig plistPath has wrong format: \(error)")
            }
        }
    }

    public func onBackground() {
        plugins.values.forEach {
            $0.onBackground()
        }
    }
    
    public func onForeground() {
        plugins.values.forEach {
            $0.onForeground()
        }
    }
    
    
    // 获取cache config
    private func configsCache(path: String) -> [OpenAPIConfig]? {
        Self.cacheLock.wait()
        defer {
            Self.cacheLock.signal()
        }
        let configs = Self.cache[path]
        return configs
    }

    // storage config
    private func storageConfigs(path: String, value: [OpenAPIConfig]) {
        Self.cacheLock.wait()
        defer {
            Self.cacheLock.signal()
        }
        if Self.cache.count > 3  {
            // 控制内存，简单的移除第一个会出现总是移除某一个，缓存方案失效的问题，需要考虑实现个LRU，现在只有一份plist，所以暂不实现
            assertionFailure("OpenPluginManger not support multiple cache count, need consider memory manage")
            return
        }
        Self.cache[path] = value
    }

    // 支持弱类型调用异步接口
    public func asyncCall(
        apiName: String,
        params: [AnyHashable: Any],
        canUseInternalAPI: Bool,
        context: OpenAPIContext,
        callback: @escaping OpenAPISimpleCallback
    ) {
        let checkResult = checkBeforeCall(apiName: apiName, canUseInternalAPI: canUseInternalAPI, context: context)
        guard let paramsType = checkResult.paramType,
              let plugin = checkResult.plugin else {
            callback(.failure(error: checkResult.error ?? OpenAPIError(code: OpenAPICommonErrorCode.unknown).setErrno(OpenAPICommonErrno.unknown)))
            return
        }
        let handleCall = { [weak self] in
            guard let self = self else {
                context.apiTrace.error("handleCall failed, pluginManager is nil")
                return
            }
            do {
                let paramModel = try paramsType.init(with: params)
                if !paramModel.checkResults.isEmpty {
                    OPMonitor(name: "op_api_invoke", code: EPMClientOpenPlatformApiCommonCode.plugin_input_checker)
                        .addCategoryValue("api_name", apiName)
                        .addCategoryValue("check_results", paramModel.checkResults)
                        .flushTo(context.apiTrace)
                }
                self.asyncExecuteOnMainIfNeeded(forceOnMain: checkResult.onMainThread) {
                    do {
                        try plugin.asyncHandle(
                            apiName: apiName,
                            params: paramModel,
                            context: context,
                            callback: callback
                        )
                    } catch let err as OpenAPIError {
                        callback(.failure(error: err))
                    } catch {
                        /// 先收敛在 OpenPluginManager 层，下一阶段再做整体的整合
                        let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknownException)
                            .setErrno(OpenAPICommonErrno.unhandledException)
                            .setError(error)
                        callback(.failure(error: apiError))
                    }
                }
            } catch let err as OpenAPIError {
                context.apiTrace.error("params invalid for \(apiName), error: \(err)")
                callback(.failure(error: err))
            } catch {
                context.apiTrace.error("params invalid for \(apiName), error: \(error)")
                let err = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.unknown) // 参数初始化失败抛出的非OpenAPIError，为未知的errno
                    .setOuterMessage(error.localizedDescription)
                    .setError(error)
                callback(.failure(error: err))
            }
        }
        if let authorChecker = asyncAuthorizationChecker {
            authorChecker(apiName, { response in
                switch response {
                case .success(data: _):
                    handleCall()
                case let .failure(error: err):
                    context.apiTrace.error("authorizationChecker failed", additionalData: [
                        "apiName": apiName,
                        "innerCode": "\(String(describing: err.innerCode))",
                        "errorCode": "\(err.code.rawValue)"
                    ])
                    callback(.failure(error: err))
                case .continue(event: _, data: _):
                    let errMsg = "authorizationChecker for \(apiName) should not enter continue"
                    assertionFailure(errMsg)
                    context.apiTrace.error(errMsg)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                        .setMonitorMessage(errMsg)
                    callback(.failure(error: error))
                }
            })
        } else {
            handleCall()
        }
    }

    // 支持强类型调用异步接口
    public func asyncCall<Param>(
        apiName: String,
        params: Param,
        canUseInternalAPI: Bool,
        context: OpenAPIContext,
        callback: @escaping OpenAPISimpleCallback
    ) where Param: OpenAPIBaseParams {
        let checkResult = checkBeforeCall(apiName: apiName, canUseInternalAPI: canUseInternalAPI, context: context, params: params)
        guard let plugin = checkResult.plugin else {
            callback(.failure(error: checkResult.error ?? OpenAPIError(code: OpenAPICommonErrorCode.unknown).setErrno(OpenAPICommonErrno.unknown)))
            return
        }
        func handleCall() {
            asyncExecuteOnMainIfNeeded(forceOnMain: checkResult.onMainThread) {
                do {
                    try plugin.asyncHandle(
                        apiName: apiName,
                        params: params,
                        context: context,
                        callback: callback
                    )
                } catch let err as OpenAPIError {
                    callback(.failure(error: err))
                } catch {
                    /// 先收敛在 OpenPluginManager 层，下一阶段再做整体的整合
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknownException)
                        .setErrno(OpenAPICommonErrno.unhandledException)
                        .setError(error)
                    callback(.failure(error: apiError))
                }
            }
        }
        if let authorChecker = asyncAuthorizationChecker {
            authorChecker(apiName, { response in
                switch response {
                case .success(data: _):
                    handleCall()
                case let .failure(error: err):
                    context.apiTrace.error("authorizationChecker failed", additionalData: [
                        "apiName": apiName,
                        "innerCode": "\(String(describing: err.innerCode))",
                        "errCode": "\(err.code.rawValue)"
                    ])
                    callback(.failure(error: err))
                case .continue(event: _, data: _):
                    let errMsg = "authorizationChecker for \(apiName) should not enter continue"
                    assertionFailure(errMsg)
                    context.apiTrace.error(errMsg)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                        .setMonitorMessage(errMsg)
                    callback(.failure(error: error))
                }
            })
        } else {
            handleCall()
        }
    }

    // 支持弱类型调用同步接口
    public func syncCall(
        apiName: String,
        params: [AnyHashable: Any],
        canUseInternalAPI: Bool,
        context: OpenAPIContext
    ) -> OpenAPISimpleResponse {
        let checkResult = checkBeforeCall(apiName: apiName, canUseInternalAPI: canUseInternalAPI, context: context)
        guard let paramsType = checkResult.paramType,
              let plugin = checkResult.plugin else {
            return .failure(error: checkResult.error ?? OpenAPIError(code: OpenAPICommonErrorCode.unknown).setErrno(OpenAPICommonErrno.unknown))
        }
        do {
            let paramModel = try paramsType.init(with: params)
            if !paramModel.checkResults.isEmpty {
                OPMonitor(name: "op_api_invoke", code: EPMClientOpenPlatformApiCommonCode.plugin_input_checker)
                    .addCategoryValue("api_name", apiName)
                    .addCategoryValue("check_results", paramModel.checkResults)
                    .flushTo(context.apiTrace)
            }
            return syncExecuteOnMainIfNeeded(forceOnMain: checkResult.onMainThread) {
                do {
                    return try plugin.syncHandle(
                        apiName: apiName,
                        params: paramModel,
                        context: context
                    )
                } catch let err as OpenAPIError {
                    return .failure(error: err)
                } catch {
                    /// 先收敛在 OpenPluginManager 层，下一阶段再做整体的整合
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknownException)
                        .setErrno(OpenAPICommonErrno.unhandledException)
                        .setError(error)
                    return .failure(error: apiError)
                }
            }
        } catch let err as OpenAPIError {
            context.apiTrace.error("params invalid for \(apiName), error: \(err)")
            return .failure(error: err)
        } catch {
            assertionFailure("should not enter here")
            context.apiTrace.error("generate params fail for \(apiName), error: \(error)")
            let err = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setErrno(OpenAPICommonErrno.unknown) // 参数初始化失败抛出的非OpenAPIError，为未知的errno
                .setOuterMessage(error.localizedDescription)
                .setError(error)
            return .failure(error: err)
        }
    }

    // 支持强类型调用同步接口
    public func syncCall<Param>(
        apiName: String,
        params: Param,
        canUseInternalAPI: Bool,
        context: OpenAPIContext
    ) -> OpenAPISimpleResponse where Param: OpenAPIBaseParams {
        let checkResult = checkBeforeCall(apiName: apiName, canUseInternalAPI: canUseInternalAPI, context: context, params: params)
        guard let plugin = checkResult.plugin else {
            return .failure(error: checkResult.error ?? OpenAPIError(code: OpenAPICommonErrorCode.unknown).setErrno(OpenAPICommonErrno.unknown))
        }
        return syncExecuteOnMainIfNeeded(forceOnMain: checkResult.onMainThread) {
            do {
                return try plugin.syncHandle(
                    apiName: apiName,
                    params: params,
                    context: context
                )
            } catch let err as OpenAPIError {
                return .failure(error: err)
            } catch {
                /// 先收敛在 OpenPluginManager 层，下一阶段再做整体的整合
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknownException)
                    .setErrno(OpenAPICommonErrno.unhandledException)
                    .setError(error)
                return .failure(error: apiError)
            }
        }
    }

    // 多播事件
    public func postEvent<Param, Result>(
        eventName: String,
        params: Param,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        var pluginNames: [String: String] = [:]
        for item: OpenAPIInfo in defaultPluginConfig.values {
            pluginNames[item.pluginClass] = item.pluginClass
        }
        var findPlugin = false
        for pluginClass: String in pluginNames.keys {
            let pluginType = NSClassFromString("\(pluginClass)") as? OpenBasePlugin.Type
            if let pluginType = pluginType {
                if let events = pluginType.supportEvents() as? [String], events.contains(eventName) {
                    let plugin = getPluginAndCreateIfNeeded(with: pluginClass, pluginClass: pluginType)
                    /// 多播需要保证部分失败，其他 event 还要发出去，因此在此处统一 catch，非框架预期的 error 使用 callback 跑抛出。
                    /// 后续需要考虑的事情:
                    /// 1. 多播的 callback 方式，是每个单独 callback, 还是聚合后 callback
                    /// 2. 单独 callback 是否有生命周期冲突的问题
                    do {
                        try plugin.postEvent(apiName: eventName, params: params, context: context, callback: callback)
                    } catch let err as OpenAPIError {
                        callback(.failure(error: err))
                    } catch {
                        /// 先收敛在 OpenPluginManager 层，下一阶段再做整体的整合
                        let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknownException)
                            .setErrno(OpenAPICommonErrno.unhandledException)
                            .setError(error)
                        callback(.failure(error: apiError))
                    }
                    findPlugin = true
                }
            }
        }
        if !findPlugin {
            context.apiTrace.info("can not find plugin, eventName \(eventName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("can not find plugin, eventName \(eventName)")
            callback(.failure(error: error))
        }
    }
    
    // 暂时绕过Bazel编译问题，本方法不应该被调用，具体背景可以联系supeng.charlie
    public func fixBazelBuildError() {
        OPMonitor("")
    }
}

extension OpenPluginManager {

    struct PluginPreCheckResult {

        let onMainThread: Bool
        let paramType: OpenAPIBaseParams.Type?
        let plugin: OpenBasePlugin?
        let error: OpenAPIError?

        init(onMainThread: Bool = false,
             paramType: OpenAPIBaseParams.Type? = nil,
             plugin: OpenBasePlugin? = nil,
             error: OpenAPIError? = nil) {
            self.onMainThread = onMainThread
            self.paramType = paramType
            self.plugin = plugin
            self.error = error
        }
    }

    /// 获取并缓存plugin
    /// - Parameters:
    ///   - pluginName: plugin类型名称
    ///   - pluginClass: plugin对应的类型
    /// - Returns: 生成的plugin实例
    private func getPluginAndCreateIfNeeded(
        with pluginName: String,
        pluginClass: OpenBasePlugin.Type
    ) -> OpenBasePlugin {
        pluginsLock.wait()
        defer {
            pluginsLock.signal()
        }
        if let plugin = plugins[pluginName] {
            return plugin
        }
        // TODOZJX
        let plugin = pluginClass.init(resolver: OPUserScope.userResolver())
        plugin.extensionResolver = extensionResolver
        plugins[pluginName] = plugin
        return plugin
    }

    /// 在真正调用plugin前，进行一些通用检查，包括api是否配置、是否有对应实现、是否经过鉴权等
    /// - Parameters:
    ///   - apiName: 接口名
    ///   - canUseInternalAPI: 是否能使用内部API
    ///   - context: api调用上下文
    ///   - params: 传入的具体的参数实例
    /// - Returns: 对应接口是否在主线程运行、参数类型、插件类型、检查失败具体错误
    private func checkBeforeCall<Param>(
        apiName: String,
        canUseInternalAPI: Bool,
        context: OpenAPIContext,
        params: Param? = nil
    ) -> PluginPreCheckResult where Param: OpenAPIBaseParams {
        // check 该API是否注册
        guard let pluginConfig = defaultPluginConfig[apiName] else {
            context.apiTrace.error("can not find plugin config for \(apiName), default:\(defaultPluginConfig.count)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage("can not find plugin config for \(apiName), default:\(defaultPluginConfig.count)")
            return PluginPreCheckResult(error: error)
        }
        // check 该API是否开放
        guard canUseInternalAPI || pluginConfig.publicToJS else {
            context.apiTrace.error("can not use internal handler for \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage("can not use internal handler for \(apiName)")
            return PluginPreCheckResult(error: error)
        }
        // check 对应handler是否有实现
        let pluginClass = NSClassFromString("\(pluginConfig.pluginClass)") as? OpenBasePlugin.Type
        guard let pluginType = pluginClass else {
            context.apiTrace.error("can not generator plugin \(pluginConfig.pluginClass) for \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage("can not generator plugin \(pluginConfig.pluginClass) for \(apiName)")
            return PluginPreCheckResult(onMainThread:pluginConfig.excuteOnMainThread,
                                        error: error)
        }
        // check 对应参数是否有实现
        guard let paramsClass = NSClassFromString("\(pluginConfig.paramsClass)") as? OpenAPIBaseParams.Type else {
            context.apiTrace.error("can not generator params \(pluginConfig.paramsClass) for \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage("can not generator params \(pluginConfig.paramsClass) for \(apiName)")
            return PluginPreCheckResult(onMainThread:pluginConfig.excuteOnMainThread,
                                        error: error)
        }
        // check 传入的参数类型是否是对应参数类型
        if let detailParams = params {
            let paramsClass = NSStringFromClass(type(of: detailParams))
            guard pluginConfig.paramsClass == paramsClass else {
                context.apiTrace.error("\(apiName) required params \(pluginConfig.paramsClass), not \(paramsClass)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: "params class")))
                    .setMonitorMessage("\(apiName) required params \(pluginConfig.paramsClass), not \(paramsClass)")
                return PluginPreCheckResult(onMainThread:pluginConfig.excuteOnMainThread,
                                            error: error)
            }
        }
        // check 是否通过鉴权
        let authenResult = authenticationChecker?(apiName) ?? .success(data: nil)
        switch authenResult {
        case .failure(error: let error):
            context.apiTrace.error("authenticationChecker failed for \(apiName) errorCode \(error.code.rawValue)")
            return PluginPreCheckResult(onMainThread:pluginConfig.excuteOnMainThread,
                                        error: error)
        default:
            break
        }
        let plugin = getPluginAndCreateIfNeeded(with: pluginConfig.pluginClass, pluginClass: pluginType)
        return PluginPreCheckResult(onMainThread:pluginConfig.excuteOnMainThread,
                                    paramType: paramsClass,
                                    plugin: plugin)
    }

    /// 按需切换到主线程异步执行逻辑
    /// - Parameters:
    ///   - forceOnMain: 是否强制在主线程执行
    ///   - block: 需要执行的逻辑
    private func asyncExecuteOnMainIfNeeded(forceOnMain: Bool, block: @escaping os_block_t) {
        // TODO:(Meng) 异步 block 的 error 抛出方式
        if forceOnMain && !Thread.isMainThread {
            DispatchQueue.main.async {
                block()
            }
        } else {
            block()
        }
    }

    /// 按需同步派发到主线程执行任务
    /// - Parameters:
    ///   - forceOnMain: 是否强制在主线程执行
    ///   - block: 需要执行的逻辑
    private func syncExecuteOnMainIfNeeded(
        forceOnMain: Bool,
        block: @escaping () -> OpenAPISimpleResponse
    ) -> OpenAPISimpleResponse {
        if forceOnMain && !Thread.isMainThread {
            return DispatchQueue.main.sync {
                return block()
            }
        } else {
            return block()
        }
    }
}
