//
//  TokenConfigManager.swift
//  EEAtomic
//
//  Created by huanzhengjie on 2022/8/3.
//

import LarkSnCService
import UIKit
import ThreadSafeDataStructure

let TCM = TokenConfigManager.shared

/// 请求path
private let kTokenRequestPath = "/api/module/compliance/api_control/token/config_list_v2"
/// 缓存key
private let kTokenConfigStorageKey = "token_config_storage_key"
/// 缓存拉取数据时间的key
private let kTokenConfigRequestTimeStorageKey = "token_config_request_time_storage_key"
/// 自动更新的时间阈值
private let kTokenConfigRefreshTimeSpan = 6 * 3600
/// 自动更新的时间阈值key值，setting可以配置
private let kTokenConfigRefreshTimeSpanKey = "token_config_refresh_time_span"
/// 资源内置的文件名
private let kTokenConfigLostBuildInKey = "token_config_list"

/// 数据读写/解析失败失败上报结构
struct ParseResult {
    let scene: Scene
    let errorMsg: String

    /// 构造整体参数
    func build() -> [String: Any] {
        var dict = [String: Any]()
        dict["scene"] = scene.rawValue
        dict["error_msg"] = errorMsg
        return dict
    }

    /// 构造整体参数 & 所有tokenConfig数据
    func buildWithData(_ all: Data) -> [String: Any] {
        var dict = [String: Any]()
        dict["scene"] = scene.rawValue
        dict["error_msg"] = errorMsg
        dict["token_list"] = all
        return dict
    }

    /// 构造整体参数 & 单个tokenConfig数据
    func buildWithData(_ single: [String: Any]) -> [String: Any] {
        var dict = [String: Any]()
        dict["scene"] = scene.rawValue
        dict["error_msg"] = errorMsg
        dict["token_list"] = single
        return dict
    }
}

/// Token相关的判断逻辑：是否有效、是否禁用等
final class TokenConfigManager {
    /// 字典，保存 identifier->TokenConfig的映射关系
    private var configDict = SafeDictionary<String, TokenConfig>()
    private var interceptors = [Interceptor]()
    private let queue = DispatchQueue(label: "LarkSensitivityControl.TokenConfigManager")
    /// 保存tokenconfig字典数据来源
    var tokenSource: TokenSource = .empty

    /// 单例
    static let shared = TokenConfigManager()

    private init() {
        registerInterceptors()
        addObservers()
    }
}

// MARK: - 事件处理

extension TokenConfigManager {
    /// 注册事件
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    @objc
    func applicationWillEnterForeground(notification: NSNotification) {
        if Assistant.isDownGraded() {
            return
        }

        queue.async {
            let cacheDate: Date?
            do {
                cacheDate = try LSC.storage?.get(key: kTokenConfigRequestTimeStorageKey)
            } catch {
                LSC.logger?.error("request cache time error:\(error.localizedDescription)")
                return
            }

            guard let cacheDate = cacheDate else {
                return
            }
            let components = Calendar.current.dateComponents([.second], from: cacheDate, to: Date())
            guard let second = components.second else {
                return
            }

            if second >= self.timeSpanForRefreshData() {
                // 超过时间阈值更新一次配置数据
                self.loadRemoteData()
                LSC.logger?.info("update token config list.")
            }
        }
    }

    func timeSpanForRefreshData() -> Int {
        let timeSpan = try? LSC.settings?.int(key: kTokenConfigRefreshTimeSpanKey, default: kTokenConfigRefreshTimeSpan)
        return timeSpan.or(kTokenConfigRefreshTimeSpan)
    }
}

// MARK: - 注册拦截器

extension TokenConfigManager {
    /// 注册拦截器
    ///
    /// 拦截器有顺序要求，按照注册顺序先后判断，遇到第一个被拦截则终止判断
    private func registerInterceptors() {
        registerInterceptor(IgnoreInterceptor())
        registerInterceptor(NotExistInterceptor())
        registerInterceptor(DisableInterceptor())
        registerInterceptor(AtomicInfoNotMatchInterceptor())
    }

    /// 供外部注册拦截器，如策略引擎等
    ///
    /// 优先判断前面默认添加的拦截器
    func registerInterceptor(_ interceptor: Interceptor) {
        interceptors.append(interceptor)
    }

    /// 供外部注册拦截器，插入数组头部
    func registerInterceptorInsertFront(_ interceptor: Interceptor) {
        interceptors.insert(interceptor, at: 0)
    }
}

// MARK: - 数据请求、缓存和解析逻辑

extension TokenConfigManager {

    /// 首先拉取本地缓存数据，没有则拉取本地内置数据
    func loadCacheData() {
        if Assistant.isDownGraded() {
            return
        }
        // 取缓存数据
        do {
            let data: Data? = try LSC.storage?.get(key: kTokenConfigStorageKey)
            if let data = data {
                tokenSource = .local
                update(withData: data, isCache: true)
                LSC.logger?.info("load token config cached data.")
                return
            }
            loadBuiltInData()
        } catch {
            let category = ParseResult(scene: .readLocal, errorMsg: error.localizedDescription).build()
            LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: category, metric: nil)
            LSC.logger?.error("get token config cached data failure: \(error.localizedDescription)")
        }
    }

    /// 拉取内置数据
    private func loadBuiltInData() {
        var localData: Data?
        do {
            localData = try Bundle.LSCBundle?.readFileToData(forResource: kTokenConfigLostBuildInKey, ofType: .zip)
            LSC.logger?.info("SensitivityController reads config file successfully.")
        } catch {
            LSC.logger?.error("Error when SensitivityController reading config files: \(error.localizedDescription)")
            let category = ParseResult(scene: .readBuiltIn, errorMsg: error.localizedDescription).build() // 错误上报slardar
            LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: category, metric: nil)
            return
        }

        guard let localData = localData else {
            return
        }
        tokenSource = .builtIn
        update(withData: localData, isCache: true)
        LSC.logger?.info("load token config build-in data.")
    }

    /// 拉取网络数据，数据有效则更新到本地缓存数据
    func loadRemoteData() {
        if Assistant.isDownGraded() {
            return
        }
        let domain: String? = LSC.environment?.get(key: "domain")
        guard let domain = domain else {
            LSC.logger?.warn("domain is nil")
            return
        }
        var request = HTTPRequest(domain, path: kTokenRequestPath, method: .post)
        request.headers = ["Content-Type": "application/json"]
        request.data = ["terminal_type": 4]
        LSC.client?.request(request) { [weak self] result in
            switch result {
            case let .success(data):
                self?.tokenSource = .remote
                self?.update(withData: data, isCache: false)
            case let .failure(error):
                LSC.logger?.error("network request failure: \(error.localizedDescription)")
            }
        }
    }

    func update(withData data: Data, isCache: Bool) {
        guard let tokenConfigList = TokenConfig.createConfigs(with: data) else {
            return
        }
        if tokenConfigList.isEmpty {
            return
        }
        LSC.logger?.info("get first token config: \(String(describing: tokenConfigList.first))")
        for tokenConfig in tokenConfigList {
            configDict[tokenConfig.identifier] = tokenConfig
        }
        // 数据有效，缓存数据并更新加载时间
        if !isCache {
            do {
                try LSC.storage?.set(data, forKey: kTokenConfigStorageKey)
                try LSC.storage?.set(Date(), forKey: kTokenConfigRequestTimeStorageKey)
            } catch {
                let category = ParseResult(scene: .update, errorMsg: error.localizedDescription).build()
                LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: category, metric: nil)
                LSC.logger?.error("update token config data from remote failure: \(error.localizedDescription)")
            }
            LSC.logger?.info("update token config data from remote success.")
        }
    }
}

// MARK: - token 的检测逻辑

extension TokenConfigManager {
    /// 根据identifier获取对应的tokenConfig
    ///
    /// - Parameters:
    ///     - identifier: 唯一标识
    /// - Returns: tokenConfig
    func tokenConfig(of identifier: String) -> TokenConfig? {
        return configDict[identifier]
    }

    /// 是否存在对应的token
    func contains(token: Token) -> Bool {
        return configDict.keys.contains(token.identifier)
    }

    /// 是否禁用
    func isForbidden(token: Token) -> Bool {
        return tokenConfig(of: token.identifier)?.status == .DISABLE
    }

    func checkResult(ofToken token: Token, context: Context) -> ResultInfo {
        // 遍历拦截器，遇到第一个拦截则直接返回
        for interceptor in interceptors {
            switch interceptor.intercept(token: token, context: context) {
            case .continue:
                continue
            case .break(let result):
                return result
            }
        }
        // 都没有被拦截则成功通过检测
        return CheckResult(token: token, code: Code.success, context: context)
    }
}

// MARK: - 获取 token 关联的 psda_atomicinfo

extension TokenConfigManager {

    func getAtomicInfo(of identifier: String) -> [String]? {
        return configDict[identifier]?.atomicInfoList
    }
}

// MARK: - Convenience for test

extension TokenConfigManager {

    func reset() {
        configDict.removeAll()
        interceptors.removeAll()
        registerInterceptors()
    }
}

// MARK: - Convenience for debug

extension TokenConfigManager {

    func getConfigDict() -> SafeDictionary<String, TokenConfig> {
        return configDict
    }

    func setConfigDict(identifier: String, tokenConfig: TokenConfig) {
        configDict[identifier] = tokenConfig
    }
}
