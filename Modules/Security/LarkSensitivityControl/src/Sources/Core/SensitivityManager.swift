//
//  SensitivityManager.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/18.
//

import UIKit
import LarkSnCService

/// 供外部使用的统一入口
@objc
final public class SensitivityManager: NSObject {

    /// 能力配置
    public final class Service: SnCService {
        public var client: HTTPClient?
        public var storage: Storage?
        public var logger: Logger?
        public var tracker: Tracker?
        public var monitor: Monitor?
        public var settings: Settings?
        public var environment: Environment?

        /// 构造方法
        init(build: (Service) -> Void) {
            build(self)
        }
    }
    private var service: Service?

    private var serviceDict = [String: SensitiveApi.Type]()
    /// 单例
    public static let shared = SensitivityManager()
    private override init() {
        super.init()
    }

    /// 注入能力配置
    public func register(_ serviceBuild: (Service) -> Void) {
        self.service = Service(build: serviceBuild)

        // 适当延迟
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            TCM.loadCacheData()
        }
    }

    /// 供外部注册拦截器，如策略引擎等
    public func registerInterceptor(_ interceptor: Interceptor) {
        TCM.registerInterceptor(interceptor)
    }

    /// 供外部注册拦截器，拦截器插入头部
    public func registerInterceptorInsertFront(_ interceptor: Interceptor) {
        TCM.registerInterceptorInsertFront(interceptor)
    }

    /// 拉取网络数据
    public func loadRemoteData() {
        TCM.loadRemoteData()
    }
}

// MARK: - EMM: Api service

extension SensitivityManager {

    /// 注册对api的自定义能力
    public func registerApiService(_ service: SensitiveApi.Type) {
        serviceDict[service.tag] = service
    }

    /// 取消注册对api的自定义能力
    public func unRegisterApiService(_ service: SensitiveApi.Type) {
        serviceDict.removeValue(forKey: service.tag)
    }

    func getService(forTag tag: String) -> SensitiveApi.Type? {
        return serviceDict[tag]
    }
}

// MARK: - Token check，特殊场景只需要判断token的有效性时使用

extension SensitivityManager {
    /// token有效性判断
    /// - Parameters:
    ///   - token: 业务侧token
    ///   - type: 场景类型
    ///   - context: 上下文信息
    @available(*, deprecated,
                message: "We will deprecate this method, please use the checkToken(_ token: Token, context: Context)")
    public func checkToken(_ token: Token, type: TokenType, context: Context) throws {
        let context = Context([AtomicInfo.Default.defaultAtomicInfo.rawValue])
        try Assistant.checkToken(token, context: context)
    }

    /// token有效性判断
    /// - Parameters:
    ///   - token: 业务侧token
    ///   - context: 上下文信息
    public func checkToken(_ token: Token, context: Context) throws {
        try Assistant.checkToken(token, context: context)
    }

    /// token有效性判断
    /// - Parameters:
    ///   - token: 业务侧token
    ///   - context: 上下文信息
    @objc
    public static func checkToken(_ token: Token, context: Context) throws {
        try Assistant.checkToken(token, context: context)
    }
}

// MARK: - Get service

extension SensitivityManager {

    /// 网络请求
    var client: HTTPClient? {
        return service?.client
    }

    /// 存储
    var storage: Storage? {
        return service?.storage
    }

    /// 日志
    var logger: LarkSnCService.Logger? {
        return service?.logger
    }

    /// 数据上报
    var tracker: Tracker? {
        return service?.tracker
    }

    /// 监控
    var monitor: Monitor? {
        return service?.monitor
    }

    /// Settings
    var settings: Settings? {
        return service?.settings
    }

    var environment: Environment? {
        return service?.environment
    }
}

// MARK: - Convenience for test

extension SensitivityManager {

    func reset() {
        self.service = nil
        serviceDict.removeAll()
    }
}

/// 简写，方便使用
let LSC = SensitivityManager.shared
