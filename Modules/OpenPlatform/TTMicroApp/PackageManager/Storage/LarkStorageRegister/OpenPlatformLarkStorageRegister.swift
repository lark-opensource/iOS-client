//
//  OpenPlatformLarkStorageRegister.swift
//  TTMicroApp
//
//  Created by ByteDance on 2023/1/13.
//

import Foundation
import LarkStorage
import OPFoundation
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer
import ECOInfra

public final class OpenPlatformModAssembly {
    static let logger = Logger.oplog(OpenPlatformModAssembly.self, category: "OpenPlatformModAssembly")

    @_silgen_name("Lark.LarkStorage_SandboxMigrationRegistry.LarkOpenPlatform")
    public static func registerSandboxMigration() {
        SBMigrationRegistry.registerMigration(forDomain: Domain.biz.microApp) { space in
            switch space {
            case .global:
                return [:]
            case .user(let uid):
                guard let fileSystemPlugin = BDPTimorClient.shared().fileSystemPlugin.sharedPlugin() as? BDPFileSystemPluginDelegate,
                      let accountTokenDirecrotyName = OPUnsafeObject(fileSystemPlugin.accountTokenDirecrotyName()) else {
                    assertionFailure("accountToken空")
                    Self.logger.error("OpenPlatformModAssembly get accountToken nil")
                    @Provider var passport: PassportService
                    guard let tenantID = passport.userList.first(where: { $0.userID == uid })?.tenant.tenantID else {
                        Self.logger.error("OpenPlatformModAssembly get tenantID nil")
                        return [:]
                    }
                    let accountToken = OPAccountTokenHelper.accountToken(userID: uid, tenantID: tenantID)
                    Self.logger.info("OpenPlatformModAssembly atm:\(accountToken.mask())")
                    return [
                        .library: .whole(
                            fromRoot: AbsPath.library + "Timor" + "/\(accountToken)",
                            strategy: .redirect
                        ),
                    ]
                }
                Self.logger.info("OpenPlatformModAssembly atm:\(accountTokenDirecrotyName.mask())")
                return [
                    .library: .whole(
                        fromRoot: AbsPath.library + "Timor" + "/\(accountTokenDirecrotyName)",
                        strategy: .redirect
                    ),
                ]
            @unknown default:
                return [:]
            }
            
        }
        
        //开放业务
        SBMigrationRegistry.registerMigration(forDomain: Domain.biz.microApp.child("openBusiness")) { space in
            switch space {
            case .global:
                return [:]
            case .user(let userId):
                return [
                    .cache: .whole(
                        fromRoot: AbsPath.cache + "/LarkOpenPlatform/LarkOpenPlatform_\(userId)",
                        strategy: .redirect
                    ),
                ]
            @unknown default:
                return [:]
            }
        }
        
        //文件api fileLog
        SBMigrationRegistry.registerMigration(forDomain: Domain.biz.microApp.child("fileLog")) { space in
            switch space {
            case .global:
                return [:]
            case .user(let userId):
                return [
                    .cache: .partial(fromRoot: AbsPath.cache + "/com.filesystem.openplatform",
                                     strategy: .redirect,
                                     items: [.init("LarkUser_\(userId).filelog")]
                                    )
                ]
            @unknown default:
                return [:]
            }
        }
    }
}
