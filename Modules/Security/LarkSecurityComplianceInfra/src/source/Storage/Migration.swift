//
//  Migration.swift
//  LarkSecurityComplianceInfra
//
//  Created by AlbertSun on 2023/8/30.
//

import Foundation
import LarkStorage

public final class SCKeyValueMigration {
    @_silgen_name("Lark.LarkStorage_KeyValueMigrationRegistry.Security")
    public static func registerSCKeyValueMigration() {
        // PasteProtect
        KVMigrationRegistry.registerMigration(forDomain: Domain.biz.snc.child("PasteProtect"), strategy: .sync) { space in
            guard case .user = space else { return [] }
            return [
                .from(userDefaults: .standard, prefixPattern: "lark.securityCompliance."),
                .from(userDefaults: .standard, prefixPattern: "PasteboardServiceImp.")
            ]
        }
        
        // AppLock
        KVMigrationRegistry.registerMigration(forDomain: Domain.biz.snc.child("AppLock"), strategy: .sync) { space in
            guard case .user(let userId) = space, !userId.isEmpty, let tenantId = Dependencies.passport?.tenantId(forUser: userId) else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "\(userId)_\(tenantId)_AppLockSettingFirstBiometricKey" ~> "AppLockSettingFirstBiometricKey",
                    "\(userId)_\(tenantId)_AppLockSettingConfigInfoKey" ~> "AppLockSettingConfigInfoKey"
                ])
            ]
        }
        
        // SecurityAudit
        KVMigrationRegistry.registerMigration(forDomain: Domain.biz.snc.child("SecurityAudit"), strategy: .sync) { space in
            if case .user(let userId) = space, !userId.isEmpty {
                return [
                    .from(userDefaults: .standard, items: [
                        String("1_\(userId)_strictAuthMode".sha256()) ~> "SecurityAuditStrictAuthMode"
                    ])
                ]
            } else {
                return [
                    .from(userDefaults: .standard, items: [
                        String("1__strictAuthMode".sha256()) ~> "SecurityAuditStrictAuthMode"
                    ])
                ]
                
            }
        }
    }
}

public final class SCSandboxMigration {
    @_silgen_name("Lark.LarkStorage_SandboxMigrationRegistry.Security")
    public static func registerSCSandboxMigration() {
        // SecurityAudit Database
        SBMigrationRegistry.registerMigration(
            forDomain: Domain.biz.snc.child("SecurityAudit")
        ) { _ in
            return [
                .library: .whole(fromRoot: AbsPath.library + "SecurityAudit", strategy: .moveOrDrop(allows: [.background, .intialization]))
            ]
        }
    }
}
