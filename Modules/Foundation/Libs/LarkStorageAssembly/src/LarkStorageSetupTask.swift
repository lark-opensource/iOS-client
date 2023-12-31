//
//  LarkStorageSetupTask.swift
//  LarkStorageAssembly
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import BootManager
import LarkContainer
import LarkStorage
import LarkSetting
import EEAtomic
import SSZipArchive
import LarkAccountInterface
import LarkReleaseConfig
import LKCommonsTracker

final class SetupStorageTask: FlowBootTask, Identifiable {
    static var identify = "SetupStorageTask"

    override var runOnlyOnce: Bool { true }

    override func execute(_ context: BootContext) {
        let allDomainIds = Set(Domain.biz.allCases.map(\.isolationId))          // business domains
            .union(Domain.fun.allCases.map(\.isolationId))                      // function domains
            .union([Domain.keyValue.isolationId, Domain.sandbox.isolationId])   // builtIn domains
        LarkStorage.Dependencies.domainChecker = { domain in
#if DEBUG
            return true
#else
            return allDomainIds.contains(domain.root.isolationId)
#endif
        }
        LarkStorage.Dependencies.customTracker = { event in
            Tracker.post(SlardarEvent(
                name: event.name,
                metric: event.metric,
                category: event.category,
                extra: event.extra
            ))
        }
        LarkStorage.Dependencies.zipArchiver = LarkStorageDependencyImpl.self
        LarkStorage.Dependencies.passport = LarkStorageDependencyImpl.shared
        LarkStorage.Dependencies.injectedAppGroupId = ReleaseConfig.groupId
        LarkStorage.Dependencies.backgroundTaskWhiteList = [
            Domain.biz.ai,
            Domain.biz.byteView,
            Domain.biz.calendar,
            // Domain.biz.core,
            Domain.biz.feed,
            Domain.biz.messenger,
            Domain.biz.meego,
            Domain.biz.minutes,
            Domain.biz.setting,
            Domain.biz.todo,
        ]

        KVStores.getCurrentUserId = { AccountServiceAdapter.shared.currentChatterId }
        KVMigrationRegistry.observeBackgroundNotification()
        SBMigrationRegistry.observeBackgroundNotification()
        SetupStorageTask.observeFGNotification()
    }

    /// 监听 FG 更新，并更新 LarkStorageFGCached
    private static func observeFGNotification() {
        // 需在整个 App 生命周期内监听，所以不调用 disposed(by:)
        _ = FeatureGatingManager.realTimeManager.fgObservable
                .subscribe(onNext: {
                    for key in LarkStorageFGCached.Key.allCases {
                        let fgKey = FeatureGatingManager.Key.init(stringLiteral: key.rawValue)
                        let value = FeatureGatingManager.realTimeManager.featureGatingValue(with: fgKey)
                        LarkStorageFGCached.update(value, forKey: key)
                    }
                })
    }
}

private final class LarkStorageDependencyImpl: PassportDependency, ZipArchiver {
    static let shared = LarkStorageDependencyImpl()

    // MARK: PassportDependency
    @Provider var passport: PassportService

    var foregroundUserId: String? {
        passport.foregroundUser?.userID
    }
    var userIdList: [String] {
        passport.userList.map(\.userID)
    }
    var deviceId: String {
        passport.deviceID
    }

    func tenantId(forUser userId: String) -> String? {
        return passport.userList.first(where: { $0.userID == userId })?.tenant.tenantID
    }

    // MARK: ZipArchiver

    static func createZipFile(atPath: String, withFilesAtPaths paths: [String], password: String?) throws {
        SSZipArchive.createZipFile(atPath: atPath, withFilesAtPaths: paths, withPassword: password)
    }

    static func createZipFile(atPath: String, withContentsOfDirectory directoryPath: String, password: String?) throws {
        SSZipArchive.createZipFile(atPath: atPath, withContentsOfDirectory: directoryPath, withPassword: password)
    }

    static func unzipFile(atPath: String, toPath: String, overwrite: Bool, password: String?) throws {
        try SSZipArchive.unzipFile(atPath: atPath, toDestination: toPath, overwrite: overwrite, password: password)
    }
}
