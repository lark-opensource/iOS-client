//
//  KVMigrationTaskManager.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic

extension Const.KV {
    // 每个 domain 只能注册一次
    static let migrationRegistryLimit = 1
}

final class KVMigrationTaskManager {

    static let shared = KVMigrationTaskManager()

    private struct TaskWrapper {
        var task: KVMigrationTask?
    }

    var enableCache = true

    // protect `tasks`
    private let lock = UnfairLock()
    private var tasks = [String: TaskWrapper]()

    private let serialQueue = DispatchQueue(label: "lark_storage.key_value.migrate.queue", qos: .utility)

    func task(forSeed seed: KVMigrationSeed) -> KVMigrationTask? {
        return safeTask(forSeed: seed)
    }

    func allTasks(forSpaces spaces: [Space]) -> [KVMigrationTask] {
        // 只有加入了白名单的 domain 才能执行 allTasks 迁移
        let items = KVMigrationRegistry.allItems.filter { item in
            Dependencies.backgroundTaskWhiteList?.contains {
                $0.isSame(as: item.domain) || $0.isAncestor(of: item.domain)
            } ?? false
        }
        return spaces
            .flatMap { space -> [(Space, DomainType, KVStoreType)] in
                items.map { (space, $0.domain, .udkv) } +
                items.map { (space, $0.domain, .mmkv) }
            }
            .flatMap { (space, domain, type) -> [KVMigrationTask] in
                var tasks = [KVMigrationTask]()

                if let task = safeTask(forSeed: KVMigrationSeed(
                    space: space,
                    domain: domain,
                    mode: .normal,
                    type: type
                )) {
                    tasks.append(task)
                }
                if !Dependencies.appGroupId.isEmpty,
                   let task = safeTask(forSeed: KVMigrationSeed(
                        space: space,
                        domain: domain,
                        mode: .shared,
                        type: type
                   ))
                {
                    tasks.append(task)
                }
                return tasks
            }
    }

    func runTask(forSpaces spaces: [Space]) {
        let tasks = allTasks(forSpaces: spaces)
        let runCountLimit = 10 // 每次最多迁移 10 个
        for task in tasks {
            var runCount = 0
            serialQueue.async {
                guard task.runable else { return }
                guard runCount < runCountLimit else { return }

                task.run()
                runCount += 1
            }
        }
    }

    // MARK: Privates

    private func safeTask(forSeed seed: KVMigrationSeed) -> KVMigrationTask? {
        let taskId = KVMigrationTask.taskId(forSeed: seed)
        guard enableCache else {
            return makeTask(forSeed: seed).task
        }
        lock.lock()
        if let wrapper = tasks[taskId] {
            lock.unlock()
            return wrapper.task
        } else {
            lock.unlock()
            let new = makeTask(forSeed: seed)
            lock.lock()
            tasks[taskId] = new
            lock.unlock()
            return new.task
        }
    }

    private func makeTask(forSeed seed: KVMigrationSeed) -> TaskWrapper {
        let items = KVMigrationRegistry.allItems.filter { seed.domain.isSame(as: $0.domain) }
        KVStores.assert(
            items.count <= Const.KV.migrationRegistryLimit,
            "items.count = \(items.count)",
            event: .migration
        )
        var wrapper = TaskWrapper()
        guard let item = items.first else { return wrapper }

        let configs = item.provider(seed.space).filter { $0.to == seed.type && $0.mode == seed.mode }
        if !configs.isEmpty {
            wrapper.task = KVMigrationTask(seed: seed, strategy: item.strategy, configs: configs)
        }
        return wrapper
    }

}

extension KVUtils {
    public static func runMigrationTasks(forSpaces spaces: [Space]) {
        KVMigrationTaskManager.shared.runTask(forSpaces: spaces)
    }
}
