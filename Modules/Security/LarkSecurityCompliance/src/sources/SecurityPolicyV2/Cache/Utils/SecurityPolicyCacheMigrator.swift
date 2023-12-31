//
//  SecurityPolicyCacheMigrator.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/12/21.
//

import Foundation
import LarkContainer
import ThreadSafeDataStructure
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import LarkPolicyEngine

extension SecurityPolicyV2 {
    class SecurityPolicyCacheMigrator {
        // swiftlint:disable nesting
        enum SourceType: CaseIterable {
            case sourceV1
            case sourceV2
            
            var cacheSource: SecurityPolicyDataRetrievalProtocol.Type {
                switch self {
                case .sourceV1:
                    return SecurityPolicyV1DataRetriever.self
                case .sourceV2:
                    return SecurityPolicyV2DataRetriever.self
                }
            }
        }
        // swiftlint:enable nesting
        static let queue = DispatchQueue(label: "security_policy_static_migrate")
        let userResolver: UserResolver
        let migrateFlagStore: SCKeyValueStorage
        let migrateFlagKey = SecurityPolicyV2.SecurityPolicyConstKey.staticCacheMigrateKeyV3
        private var retrievers: [SecurityPolicyDataRetrievalProtocol] = []
        private var isMigrated: Bool {
            didSet {
                migrateFlagStore.set(true, forKey: migrateFlagKey)
            }
        }
        
        init(userResolver: UserResolver) {
            self.userResolver = userResolver
            self.migrateFlagStore = SCKeyValue.MMKV(userId: userResolver.userID, business: .securityPolicy())
            self.isMigrated = migrateFlagStore.bool(forKey: migrateFlagKey)
        }
        
        func migrateData(to cache: SecurityPolicyCache) {
            guard !isMigrated else { return }
            isMigrated = true
            retrievers = SourceType.allCases.map { $0.cacheSource.init(userResolver: userResolver) }
            for retriever in retrievers where !retriever.isEmpty {
                migrate(with: retriever, to: cache)
                retrievers.forEach { $0.cleanAll() }
                return
            }
            SecurityPolicyV2.SecurityPolicyEventTrack.larkStaticCacheMigrate(source: "null")
        }
        
        private func migrate(with retriever: SecurityPolicyDataRetrievalProtocol, to cache: SecurityPolicyCache) {
            guard let modelFactory = try? userResolver.resolve(assert: PolicyModelFactory.self) else { return }
            modelFactory.staticModels.forEach {
                let taskID = $0.taskID
                guard !cache.contains(forKey: taskID),
                      let result: SecurityPolicyValidateResultCache = retriever.read(key: taskID) else { return }
                cache.write(value: result, forKey: taskID)
            }
            SecurityPolicyV2.SecurityPolicyEventTrack.larkStaticCacheMigrate(source: type(of: retriever).identifier)
        }
    }
}
