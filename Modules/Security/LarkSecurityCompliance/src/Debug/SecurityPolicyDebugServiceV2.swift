//
//  SecurityPolicyDebugServiceV2.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/5/30.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkAccountInterface
import LarkContainer
import RustSDK
import UniverseDesignColor
import UniverseDesignToast

extension SecurityPolicyV2 {
    public final class SecurityPolicyDebugServiceImp: SecurityPolicyDebugService, UserResolverWrapper {
        public let userResolver: UserResolver

        public init(userResolver: UserResolver) {
            self.userResolver = userResolver
            SecurityPolicy.logger.didLogCallback = { [weak self] text in
                guard let self else { return }
                self.addToDebugText(msg: text)
            }
            SecurityPolicy.logger.info("init SP Debug V2")
        }

        var manager: PolicyAuthManager? {
            let imp = try? userResolver.resolve(assert: SecurityPolicyService.self) as? SecurityPolicyIMP
            return imp?.manager.policyAuth
        }

        public func clearStrategyAuthCache() {
            guard let cacheManager = try? userResolver.resolve(assert: SecurityPolicyCacheService.self) else { return }
            cacheManager.removeAll()
        }

        public func getSceneCache() -> String {
            guard let passportService = try? userResolver.resolve(assert: PassportUserService.self) else { return "" }
            let cacheManager = FIFOCache(userID: passportService.user.userID,
                                         maxSize: 10_000,
                                         cacheKey: PointKey.imFileRead.rawValue)
            let arr: [SecurityPolicyValidateResultCache] = cacheManager.getAllRealCache()
            let str = arr.reduce("", { previous, current in
                guard let data = try? JSONEncoder().encode(current),
                      let resultStr = String(data: data, encoding: .utf8) else { return "" }
                return previous + "\n\n" + resultStr
            })
            return str
        }

        public func getRetryList() -> String {
            let strList: [String] = manager?.retryManager.retryList.map { retryPair in
                let entity = retryPair.key.entity
                var prefix = entity.entityOperate.rawValue + "+"
                prefix += (entity.entityType.rawValue)

                let surfix = retryPair.value
                return prefix + "\n" + "\(surfix)"
            } ?? []
            return strList.reduce("", { $0 + "\n\n" + $1 })
        }

        public func getIPList() -> String {
            let strList = manager?.delayClearCacheManager?.ipPolicyModelMap.map { return $0.key + "\n" + "\($0.value ?? 0)" } ?? []
            return strList.reduce("", { $0 + "\n\n" + $1 })
        }

        public func getSceneCacheSize() -> Int {
            guard let passportService = try? userResolver.resolve(assert: PassportUserService.self) else { return 0 }
            let cacheManager = FIFOCache(userID: passportService.user.userID, maxSize: 10_000, cacheKey: PointKey.imFileRead.rawValue)
            return cacheManager.count
        }

        public func getSceneContexts() -> [SecurityPolicy.SceneContext] {
            guard let eventManager = try? userResolver.resolve(type: SceneEventService.self) as? EventManager else {
                return []
            }
            return eventManager.sceneContexts
        }

        public var text: String = ""

        public func addToDebugText(msg: String) {
            /// 目前有些业务仓没有注入SCDebugService，所以使用InjectedOptional
            @InjectedOptional var debugService: SCDebugService? // Global
            if debugService?.enableFileOperateLog?() ?? false {
                DispatchQueue.runOnMainQueue {
                    self.text = (self.getCurrentTime() + msg + "\n\n") + self.text
                }
            }
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
}

public protocol SecurityPolicyDebugDataRetrievalProtocol {
    static var identifier: String { get }

    init(userResolver: UserResolver)

    func read(key: String) -> SecurityPolicyValidateResultCache?
}

extension SecurityPolicyV2 {
    public struct SecurityPolicyV3DebugDataRetriever: SecurityPolicyDebugDataRetrievalProtocol {
        public static let identifier = "V3"
        private let localCache: UnorderedCache
        
        public init(userResolver: UserResolver) {
            self.localCache = UnorderedCache(userID: userResolver.userID,
                                             maxSize: SecurityPolicyV2.SecurityPolicyConstKey.staticCacheMaxCapacity,
                                             cacheKey: SecurityPolicyV2.SecurityPolicyConstKey.staticCacheKey)
        }
        
        public func read(key: String) -> SecurityPolicyValidateResultCache? {
            localCache.read(forKey: key)
        }
    }
}

extension SecurityPolicyV2.SecurityPolicyV1DataRetriever: SecurityPolicyDebugDataRetrievalProtocol {}
extension SecurityPolicyV2.SecurityPolicyV2DataRetriever: SecurityPolicyDebugDataRetrievalProtocol {}
