//
//  ECOCookie+KAMigration.swift
//  ECOInfra
//
//  Created by Meng on 2021/5/21.
//

import Foundation
import LKCommonsLogging
import CryptoSwift
import LarkContainer

@objc(KACookieMigration)
public final class KAMigrationForObjc: NSObject {
    private static let logger = Logger.oplog(ECOCookiePlugin.self, category: "ECOCookie.KAMigration")

    private static let migrationKey = "gadget.cookie.migration.from.AppIsolate.to.UserAndAppIsolate"

    @objc public class func migrate(userId: String) {
        let migrated = LSUserDefault.standard.getBool(forKey: Self.migrationKey)
        Self.logger.info("start ka gadget cookie migration", additionalData: [
            "migrated": "\(migrated)",
            "userId": userId
        ])

        guard !userId.isEmpty else {
            logger.error("ka gadget cookie migration userId empty")
            return
        }

        guard !migrated else { return }
        KAMigration.migrationFromAppIsolateToUserAndAppIsolate(userId: userId)
        LSUserDefault.standard.set(true, forKey: Self.migrationKey)
    }
}

class KAMigration {
    static let logger = Logger.oplog(ECOCookiePlugin.self, category: "ECOCookie.KAMigration")

    private static let md5Count: Int = 32
    private static let staticDomainSuffix = ".gadget.lark"

    /// Cookie 的 App 维度隔离升级到 User + App 维度隔离
    static func migrationFromAppIsolateToUserAndAppIsolate(userId: String) {
        let start = Date().timeIntervalSince1970
        var migratedDomains: [String] = []
        let suffixCount =  1 /* dot */ + md5Count /* appId.md5 */ + staticDomainSuffix.count

        let cookies = HTTPCookieStorage.shared.cookies ?? []
        for cookie in cookies where cookie.domain.hasSuffix(staticDomainSuffix) && cookie.domain.count > suffixCount {
            let newCookie = cookie.convertDomain(handler: {

                let suffix = String($0.suffix(suffixCount)) // .{appId-md5}.gadget.lark
                if !suffix.hasPrefix(".") {
                    assertionFailure()
                    return $0
                }

                let isolateIdentifier = String(suffix.dropFirst()) // remove "." => {appId-md5}.gadget.lark
                let appIdMD5 = String(isolateIdentifier.prefix(md5Count)) // {appId-md5}
                if appIdMD5.contains(".") {
                    assertionFailure()
                    return $0
                }

                let originDomain = String($0.dropLast(suffixCount)) // origin domain
                let appIdHash = String(appIdMD5.prefix(8))
                let userIdHash = String(userId.md5().suffix(8))

                // {origin-domain}.{appId-md5-prefix8}.{userId-md5-suffix8}.gadget.lark
                return originDomain + "." + appIdHash + "." + userIdHash + staticDomainSuffix
            })

            if let newCookie = newCookie {
                if newCookie.domain == cookie.domain { // convertDomain failed, continue
                    continue
                }
                HTTPCookieStorage.shared.setCookie(newCookie)
                migratedDomains.append(newCookie.domain)
            }
        }

        let migratedDomainsUnique = Set(migratedDomains)
        let end = Date().timeIntervalSince1970
        let duration = (end - start) * 1000
        logger.info("ECOCookie KA cookie did migration", additionalData: [
            "duration": "\(duration)",
            "migrated_domains": "\(migratedDomainsUnique)"
        ])
    }
}
