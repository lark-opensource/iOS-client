//
//  SnCServiceImpl.swift
//  LarkSecurityCompliance
//
//  Created by Bytedance on 2022/9/7.
//

import Foundation
import LarkSnCService
import MMKV
import LarkSetting
import LKCommonsLogging
import LarkEnv
import RxSwift
#if canImport(LarkDebug)
import LarkDebug
#endif
import LarkSecurityComplianceInfra
import LarkReleaseConfig
import LarkAccountInterface
import LarkContainer
import AppContainer

// MARK: - HTTPClient

extension LarkSnCService.HTTPRequest: LarkSecurityComplianceInfra.Request { }
extension HTTPClientImp: LarkSnCService.HTTPClient {

    public func request(_ request: LarkSnCService.HTTPRequest, completion: ((Result<Data, Error>) -> Void)?) {
        var disposable: Disposable?
        disposable = self.request(request)
            .retryWhen({ errors in
                return errors.enumerated().flatMap { (index, error) in
                    if index < request.retryCount {
                        return Observable<Int64>.timer(request.retryDelay, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                    } else {
                        return Observable.error(error)
                    }
                }
            }).subscribe { data in
                completion?(.success(data))
            } onError: { error in
                completion?(.failure(error))
            } onCompleted: {
                disposable?.dispose()
            }
    }
}

// MARK: - Storage
// LarkStorage
public struct SCStorageImpl: Storage {
    let mmkv: SCKeyValueStorage

    public init(category: SncBiz) {
        mmkv = SCKeyValue.globalMMKVEncrypted(business: category)
    }

    public func set<T>(_ value: T?, forKey: String, space: StorageSpace) throws where T: Decodable, T: Encodable {
        let data = try JSONEncoder().encode(value)
        mmkv.set(data, forKey: forKey)
    }

    public func get<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable, T: Encodable {
        guard let data = mmkv.data(forKey: key) else {
            return nil
        }
        let value = try JSONDecoder().decode(T.self, from: data)
        return value
    }

    public func remove<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable, T: Encodable {
        let value: T? = try get(key: key, space: .user)
        mmkv.removeObject(forKey: key)
        return value
    }

    public func clearAll(space: StorageSpace) {
        mmkv.clearAll()
    }
}

// MARK: - Logger

struct LoggerImpl: LarkSnCService.Logger {
    private let logger: LKCommonsLogging.Log

    init(category: String = "snc_service") {
        logger = LKCommonsLogging.Logger.log(LoggerImpl.self, category: category)
    }

    func log(level: LarkSnCService.LogLevel,
             _ message: String,
             file: String,
             line: Int,
             function: String) {
        logger.log(level: level.rawValue, message, file: file, function: function, line: line)
    }
}

// MARK: - Tracker

final class TrackerImpl: Tracker {
    func send(event name: String, params: [AnyHashable: Any]?) {
        Events.track(name, params: params ?? [:])
    }
}

// MARK: - Monitor

final class MonitorImpl: LarkSnCService.Monitor {
    private let business: SCMonitorBusiness

    init(business: SCMonitorBusiness) {
        self.business = business
    }

    func sendInfo(service name: String, category: [String: Any]?, metric: [String: Any]?) {
        LarkSecurityComplianceInfra.SCMonitor.info(business: business, eventName: name, category: category, metric: metric)
    }

    func sendError(service name: String, error: Error?) {
        LarkSecurityComplianceInfra.SCMonitor.error(business: business, eventName: name, error: error)
    }
}

// MARK: - Settings

final class SettingsImpl: LarkSnCService.Settings {

    private let settingKey = UserSettingKey.make(userKeyLiteral: "lark_security_compliance_config")

    func setting<T>(key: String) throws -> T? where T: Decodable {
        let settings = try SettingManager.shared.setting(with: settingKey) // Global
        return settings[key] as? T
    }
}

// MARK: - Environment

final class EnvironmentImpl: Environment {

    var debug: Bool {
        #if canImport(LarkDebug)
        return appCanDebug()
        #else
        return false
        #endif
    }

    var inhouse: Bool {
        #if ALPHA
        return true
        #else
        return false
        #endif
    }

    var boe: Bool {
        EnvManager.env.isStaging
    }

    var isKA: Bool {
        ReleaseConfig.isKA
    }

    var userId: String {
        @Provider var service: PassportService
        return service.foregroundUser?.userID ?? ""
    }

    var tenantId: String {
        @Provider var service: PassportService
        return service.foregroundUser?.tenant.tenantID ?? ""
    }

    /// 是否登录
    var isLogin: Bool {
        @Provider var service: PassportService
        return service.foregroundUser != nil
    }

    /// 用户账号品牌
    var userBrand: String {
        @Provider var service: PassportService
        return service.tenantBrand.rawValue
    }

    /// 安装包品牌
    var packageId: String {
        if let channel = Bundle.main.infoDictionary?["RELEASE_CHANNEL"] as? String,
           channel.lowercased().hasSuffix("oversea") {
            return "lark"
        } else {
            return "feishu"
        }
    }

    func get<T>(key: String) -> T? {
        if key == "domain" {
            if let psdaDomain = DomainSettingManager.shared.currentSetting[.securityCompliance]?.first {
                return "https://" + psdaDomain as? T
            }
        }
        return nil
    }
}
