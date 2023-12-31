//
//  NativeAppPluginManager.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/6/7.
//

import Foundation
import NativeAppPublicKit
import LarkOpenAPIModel
import LKCommonsLogging
import LarkOpenPluginManager

public protocol NativeAppPluginManagerProtocol: AnyObject {

    /// 异步调度具体api，派发给apiHandler实现逻辑
    /// - Parameters:
    ///   - apiName: 事件名称
    ///   - params: 外部透传参数
    func asyncCall(
        apiName: String,
        params: [AnyHashable: Any],
        context: OpenAPIContext,
        callback: @escaping (NativeAppAPIBaseResult) -> Void
    )

    /// 同步调度具体api，派发给apiHandler实现逻辑
    /// - Parameters:
    ///   - apiName: 事件名称
    ///   - params: 外部透传参数
    func syncCall(
        apiName: String,
        params: [AnyHashable: Any],
        context: OpenAPIContext
    ) -> NativeAppAPIBaseResult
}


public final class NativeAppPluginManager: NativeAppPluginManagerProtocol {

    static private let logger = Logger.log(NativeAppPluginManager.self, category: "NativeAPI")
    var configs: [NativeAppApiConfig]?
    public var pluginConfigs: [String: NativeAppApiInfo] = [:]  //key:apiName
    private var plugins: [String: NativeAppBasePlugin] = [:]     //key:pluginClass
    private let pluginsLock = DispatchSemaphore(value: 1)


    public init() {
        let data = NativeAppConnectManager.shared.getAPIManager()?.getNativeAppAPIConfigs()
        guard let data = data else {
            return
        }
        do {
            self.configs = try PropertyListDecoder().decode([NativeAppApiConfig].self, from: data)
            self.configs?.compactMap({$0.matchedAPIInfo()}).forEach({ pluginConfigs[$0.apiName] = $0 })
        } catch let e {
            NativeAppPluginManager.logger.error("load plist error: \(e.localizedDescription)")
        }
    }

    public func asyncCall(apiName: String, params: [AnyHashable : Any], context: OpenAPIContext, callback: @escaping (NativeAppAPIBaseResult) -> Void) {
        NativeAppPluginManager.logger.info("NativeAppPluginManager: will async call:\(apiName)")
        let checkResult = checkBeforeCall(apiName: apiName, context: context)
        guard let plugin = checkResult.plugin else {
            let result = NativeAppAPIBaseResult(resultType: .fail, data: ["error": "have not api plugin"])
            callback(result)
            return
        }
        do {
            asyncExecuteOnMainIfNeeded(forceOnMain: checkResult.onMainThread) {
                do {
                    let params = NativeAppConnectManager.shared.getAPIManager()?.getParams(paramsClassString: self.pluginConfigs[apiName]!.paramsClass, params: params)
                    guard let params = params else {
                        let result = NativeAppAPIBaseResult(resultType: .fail, data: ["error": "have not api params class"])
                        callback(result)
                        return
                    }
                    NativeAppPluginManager.logger.info("NativeAppPluginManager: async call:\(apiName)")
                    try plugin.asyncHandle(apiName: apiName, params: params, callback: callback)
                } catch {
                    let result = NativeAppAPIBaseResult(resultType: .fail, data: ["error": "unknownException"])
                    callback(result)
                }
            }
        } catch let err as InvokeNativeAppAPIError {
            let result = NativeAppAPIBaseResult(resultType: .fail, data: ["error": err.errorMes])
            callback(result)
        } catch {
            let result = NativeAppAPIBaseResult(resultType: .fail, data: ["error": error.localizedDescription])

            callback(result)
        }
    }

    public func syncCall(apiName: String, params: [AnyHashable : Any], context: OpenAPIContext) -> NativeAppAPIBaseResult {
        NativeAppPluginManager.logger.info("NativeAppPluginManager: will sync call:\(apiName)")
        let checkResult = checkBeforeCall(apiName: apiName,context: context)
        guard let plugin = checkResult.plugin else {
            return checkResult.result ?? NativeAppAPIBaseResult(resultType: .fail, data: ["error": "can not find plugin:\(apiName)"])
        }
        do {
            return syncExecuteOnMainIfNeeded(forceOnMain: checkResult.onMainThread) {
                do {
                    let params = NativeAppConnectManager.shared.getAPIManager()?.getParams(paramsClassString: self.pluginConfigs[apiName]!.paramsClass, params: params)
                    guard let params = params else {
                        return NativeAppAPIBaseResult(resultType: .fail, data: ["error": "have not api params class"])
                    }
                    NativeAppPluginManager.logger.info("NativeAppPluginManager: sync call:\(apiName)")
                    return try plugin.syncHandle(
                        apiName: apiName,
                        params: params
                    )
                } catch {
                    return NativeAppAPIBaseResult(resultType: .fail, data: ["error": "sync error"])
                }
            }
        } catch let err as InvokeNativeAppAPIError {
            return NativeAppAPIBaseResult(resultType: .fail, data: ["error": err.errorMes])
        } catch {
            return NativeAppAPIBaseResult(resultType: .fail, data: ["error": error.localizedDescription])
        }
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
        block: @escaping () -> NativeAppAPIBaseResult
    ) -> NativeAppAPIBaseResult {
        if forceOnMain && !Thread.isMainThread {
            return DispatchQueue.main.sync {
                return block()
            }
        } else {
            return block()
        }
    }

    /// 在真正调用plugin前，进行一些通用检查，包括api是否配置、是否有对应实现、是否经过鉴权等
    /// - Parameters:
    ///   - apiName: 接口名
    ///   - canUseInternalAPI: 是否能使用内部API
    ///   - params: 传入的具体的参数实例
    /// - Returns: 对应接口是否在主线程运行、参数类型、插件类型、检查失败具体错误
    private func checkBeforeCall(
        apiName: String,
        context: OpenAPIContext
    ) -> NativeAppPluginPreCheckResult {
        // check 该API是否注册
        guard let pluginConfig = pluginConfigs[apiName] else {
            let result = NativeAppAPIBaseResult(resultType: .fail, data: ["error": "can not find plugin config for \(apiName), configs: \(pluginConfigs.count)"])
            return NativeAppPluginPreCheckResult(result: result)
        }

        let plugin = getPluginAndCreateIfNeeded(with: pluginConfig.pluginClass, context: context)
        return NativeAppPluginPreCheckResult(onMainThread:pluginConfig.excuteOnMainThread,
                                    plugin: plugin)
    }

    /// 获取并缓存plugin
    /// - Parameters:
    ///   - pluginName: plugin类型名称
    ///   - pluginClass: plugin对应的类型
    /// - Returns: 生成的plugin实例
    private func getPluginAndCreateIfNeeded(
        with pluginClass: String,
        context: OpenAPIContext
    ) -> NativeAppBasePlugin? {
        pluginsLock.wait()
        defer {
            pluginsLock.signal()
        }
        if let plugin = plugins[pluginClass] {
            return plugin
        }
        let plugin = NativeAppConnectManager.shared.getAPIManager()?.getPlugin(pluginClassString: pluginClass)
        plugins[pluginClass] = plugin
        if let plugin = plugin {
            // 绑定native api context
            let nativeAppContext =  NativeAppOpenAPIContext()
            nativeAppContext.openApiContext = context
            plugin.pluginContext = nativeAppContext
        }
        return plugin
    }
}

extension NativeAppPluginManager {
    public struct NativeAppPluginPreCheckResult {

        let onMainThread: Bool
        let plugin: NativeAppBasePlugin?
        let result: NativeAppAPIBaseResult?

        init(onMainThread: Bool = false,
             plugin: NativeAppBasePlugin? = nil,
             result: NativeAppAPIBaseResult? = nil) {
            self.onMainThread = onMainThread
            self.plugin = plugin
            self.result = result
        }
    }
}

extension NativeAppApiConfig {

    func matchedAPIInfo() -> NativeAppApiInfo? {
        return NativeAppApiInfo(apiName: apiName, pluginClass: pluginClass, paramsClass: paramsClass, excuteOnMainThread: excuteOnMainThread, isSync: isSync)
    }

}
