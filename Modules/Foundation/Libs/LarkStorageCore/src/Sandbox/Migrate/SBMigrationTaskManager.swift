//
//  SBMigrationManager.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic
import LKCommonsLogging

private let allRootTypes: [RootPathType] = [
    .normal(.document),
    .normal(.library),
    .normal(.cache),
    .normal(.temporary),
    .shared(.root),
    .shared(.cache),
    .shared(.library)
]

extension Const.SB {
    // 每个 domain 只能注册一次
    static let migrationRegistryLimit = 1
}

/// 管理 Sandbox 的迁移任务
final class SBMigrationTaskManager {
    static let shared = SBMigrationTaskManager()

    private struct TaskWrapper {
        var task: SBMigrationTask?
    }

    var enableCache = true

    // protect `tasks`
    private let lock = UnfairLock()
    private var tasks = [SBMigrationSeed: TaskWrapper]()

    private let serialQueue = DispatchQueue(label: "lark_storage.sandbox.migrate.queue", qos: .utility)

    func task(forSeed seed: SBMigrationSeed) -> SBMigrationTask? {
        return safeTask(forSeed: seed)
    }

    func allTasks(forSpaces spaces: [Space]) -> [SBMigrationTask] {
        let domains = SBMigrationRegistry.allItems.map(\.domain)
        return spaces
            .flatMap { space -> [(Space, DomainType)] in
                domains.map { (space, $0) }
            }
            .flatMap { (space, domain) -> [SBMigrationSeed] in
                return allRootTypes.map { type in
                    SBMigrationSeed(space: space, domain: domain, rootType: type)
                }
            }
            .compactMap(safeTask(forSeed:))
    }

    func runTask(forSpaces spaces: [Space]) {
        let tasks = allTasks(forSpaces: spaces)
        let runCountLimit = 4 // 每次最多迁移 4 个
        for task in tasks {
            var runCount = 0
            serialQueue.async {
                guard runCount < runCountLimit else { return }
                let ret = task.respondsToBackgroundNotification()
                if ret {
                    runCount += 1
                }
            }
        }
    }

    private func safeTask(forSeed seed: SBMigrationSeed) -> SBMigrationTask? {
        guard enableCache else {
            return makeTask(forSeed: seed).task
        }
        lock.lock()
        defer { lock.unlock() }
        if let wrapper = tasks[seed] {
            return wrapper.task
        } else {
            let new = makeTask(forSeed: seed)
            tasks[seed] = new
            return new.task
        }
    }

    private func makeTask(forSeed seed: SBMigrationSeed) -> TaskWrapper {
        let items = SBMigrationRegistry.allItems.filter { $0.domain.isSame(as: seed.domain) }
        // 每个 domain 只能注册一次
        SBUtils.assert(
            items.count <= Const.SB.migrationRegistryLimit,
            "items.count = \(items.count), domain: \(seed.domain)",
            event: .migration
        )
        var wrapper = TaskWrapper()
        guard let item = items.first else { return wrapper }

        if let config = item.provider(seed.space, seed.rootType) {
            wrapper.task = SBMigrationTask(seed: seed, config: config)
        }
        return wrapper
    }

}

extension SBUtils {
    public static func runMigrationTasks(forSpaces spaces: [Space]) {
        SBMigrationTaskManager.shared.runTask(forSpaces: spaces)
    }
}
