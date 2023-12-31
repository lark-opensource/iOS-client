//
//  SecurityPolicyDebugService.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/5/30.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkContainer
import RustSDK
import UniverseDesignColor
import UniverseDesignToast

public protocol SecurityPolicyDebugService {
    var userResolver: UserResolver { get }

    func clearStrategyAuthCache()

    func getSceneCache() -> String

    func getStaticCache(with: SecurityPolicyDebugDataRetrievalProtocol) -> String

    func getRetryList() -> String

    func getIPList() -> String

    func getSceneCacheSize() -> Int

    func getSceneContexts() -> [SecurityPolicy.SceneContext]

    var text: String { get set }

    func addToDebugText(msg: String)
}

extension SecurityPolicyDebugService {
    public func getStaticCache(with retriever: SecurityPolicyDebugDataRetrievalProtocol) -> String {
        let staticModels: [PolicyModel]
        if let modelFactory = try? userResolver.resolve(PolicyModelFactory.self) {
            staticModels = modelFactory.staticModels
        } else {
            staticModels = SecurityPolicyConstKey.staticPolicyModel
        }
        let arr: [SecurityPolicyValidateResultCache] = staticModels.compactMap {
            return retriever.read(key: $0.taskID)
        }
        let str = arr.reduce("", { previous, current in
            guard let data = try? JSONEncoder().encode(current),
                  let resultStr = String(data: data, encoding: .utf8) else { return "" }
            return previous + "\n\n" + resultStr
        })
        return str
    }
}

public final class SecurityPolicyDebugServiceImp: SecurityPolicyDebugService, UserResolverWrapper {

    public let userResolver: UserResolver

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        SPLogger.info("init SP Debug V1")
    }

    var manager: SecurityPolicyManager? {
        let imp = try? userResolver.resolve(assert: SecurityPolicyService.self) as? SecurityPolicyIMP
        return imp?.manager
    }
    public func clearStrategyAuthCache() {
        manager?.clearFileStrategyCache()
    }

    public func getSceneCache() -> String {
        let arr = manager?.getSceneCache() ?? []
        let str = arr.reduce("", { previous, current in
            guard let data = try? JSONEncoder().encode(current),
                  let resultStr = String(data: data, encoding: .utf8) else { return "" }
            return previous + "\n\n" + resultStr
        })
        return str
    }

    public func getRetryList() -> String {
        manager?.getRetryList() ?? ""
    }

    public func getIPList() -> String {
        manager?.getIPList() ?? ""
    }

    public func getSceneCacheSize() -> Int {
        manager?.getSceneCacheSize() ?? 0
    }

    public func getSceneContexts() -> [SecurityPolicy.SceneContext] {
        guard let eventManager = try? userResolver.resolve(type: SceneEventService.self) as? SecurityPolicy.EventManager else {
            return []
        }
        return eventManager.sceneContexts
    }

    public var text: String = ""

    public func addToDebugText(msg: String) {
        /// 目前有些业务仓没有注入SCDebugService，所以使用InjectedOptional
        /// V1 版本的日志未兼容，暂不做支持
    }

    private var ntpTime: TimeInterval {
        let ntpTime = TimeInterval(get_ntp_time() / 1000)
        // ntp_time有获取失败的情况，获取失败的时候返回的值是时间的偏移量，和sdk同学沟可以认为通当ntp_time的值大于2010年的时间戳认为获取成功
        let ntpBaseTimestamp: TimeInterval = 1_262_275_200 // 2010-01-01 00:00
        if ntpTime > ntpBaseTimestamp {
            return ntpTime
        } else {
            SCLogger.error("security policy: failed to get ntp time")
            return Date().timeIntervalSince1970
        }
    }

    private func getCurrentTime() -> String {
        let now = Date(timeIntervalSince1970: ntpTime)
        // 创建一个日期格式器
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(dformatter.string(from: now))"
    }
}
