//
//  SBMigrationRegistry+Lark.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import UIKit
import Foundation
import LarkStorage

/// Sandbox 的注册迁移
extension SBMigrationRegistry {

    @_silgen_name("Lark.LarkStorage_SandboxMigrationRegistry.LarkStorage")
    public static func registerLarkMigration() {
        SBMigrationRegistry.logger.info("registerLarkMigration invoked")

        SBMigrationRegistry.registerMessenger()
        SBMigrationRegistry.registerCalendar()
        SBMigrationRegistry.registerMinutes()
        SBMigrationRegistry.registerCore()
        SBMigrationRegistry.registerInfra()
    }

    private static func registerMessenger() {
        let strategy: SBMigrationStrategy = .redirect
        let downloadDomain = Domain.biz.messenger.child("Downloads")
        registerMigration(forDomain: downloadDomain) { space in
            guard case .user(let userId) = space else { return [:] }
            return [
                .cache: .whole(
                    fromRoot: AbsPath.cache + "messenger/LarkUser_\(userId)/downloads",
                    strategy: strategy
                )
            ]
        }

        let sendVideoDomain = Domain.biz.messenger.child("SendVideo")
        registerMigration(forDomain: sendVideoDomain) { space in
            guard case .user(let userId) = space else { return [:] }
            return [
                .cache: .whole(
                    fromRoot: AbsPath.cache + "messenger/LarkUser_\(userId)/videoCache",
                    strategy: strategy
                )
            ]
        }

        let draftDomain = Domain.biz.messenger.child("Draft")
        registerMigration(forDomain: draftDomain) { space in
            guard case .user(let userId) = space else { return [:] }
            return [
                .document: .whole(fromRoot: AbsPath.document + "LarkUser_\(userId)/Draft", strategy: strategy)
            ]
        }

        let ttVideoDomain = Domain.biz.messenger.child("TTVideoCache")
        registerMigration(forDomain: ttVideoDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .cache: .whole(fromRoot: AbsPath.cache + "ttVideoCache", strategy: strategy)
            ]
        }

        let primaryColorDomain = Domain.biz.messenger.child("PrimaryColor")
        registerMigration(forDomain: primaryColorDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .cache: .partial(fromRoot: AbsPath.cache, strategy: strategy, items: [
                    .init("LarkChatSetting/primryCacheColor.plist"),
                    .init("Thread/primryCacheColor.plist"),
                    .init("Moments/primryCacheColor.plist")
                ])
            ]
        }

        let foldApproveDomain = Domain.biz.messenger.child("FoldApprove")
        registerMigration(forDomain: foldApproveDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .document: .whole(fromRoot: AbsPath.document + "FoldApprove", strategy: strategy)
            ]
        }
    }

    private static func registerCore() {
        registerMigration(forDomain: Domain.biz.core.child("MobileCode")) { space in
            guard case .global = space else { return [:] }
            return [
                .document: .partial(
                    fromRoot: AbsPath.document,
                    strategy: .moveOrDrop(allows: [.background, .intialization]),
                    items: ["MobileCode"]
                )
            ]
        }
    }

    private static func registerInfra() {
        registerMigration(forDomain: Domain.biz.infra.child("DynamicBrand")) { space in
            guard case .global = space else { return [:] }
            return [
                .library: .partial(
                    fromRoot: AbsPath.library,
                    strategy: .redirect,
                    items: ["DynamicBrand"]
                )
            ]
        }
    }

    private static func registerCalendar() {
        registerMigration(forDomain: Domain.biz.calendar) { space in
            guard case .user = space else { return [:] }
            return [
                .library: .whole(
                    fromRoot: AbsPath.library + "calendar",
                    strategy: .moveOrDrop(allows: [.background, .intialization])
                )
            ]
        }
    }

    private static func registerMinutes() {
        registerMigration(forDomain: Domain.biz.minutes.child("Cache")) { space in
            guard case .global = space else { return [:] }
            return [
                .library: .whole(
                    fromRoot: AbsPath.library + "Minutes",
                    strategy: .moveOrDrop(allows: [.background, .intialization])
                )
            ]
        }
    }
}
