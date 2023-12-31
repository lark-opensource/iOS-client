//
//  KVMigrationTask.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic

typealias KVMigrationSeed = KVStoreConfig

/// 表示一个迁移任务
final class KVMigrationTask {
    var seed: KVMigrationSeed
    var strategy: KVMigrationStrategy
    var configs: [KVMigrationConfig]
    var status: KVConfig<Status>

    /// 该 store 用于记录 task 的迁移状态
    private static let statusStore = KVStores.udkv(
        config: .init(space: .global, domain: Domain.keyValue.child("Migration")),
        proxies: [.track, .rekey, .log]
    )

    init(seed: KVMigrationSeed, strategy: KVMigrationStrategy, configs: [KVMigrationConfig]) {
        self.seed = seed
        self.strategy = strategy
        self.configs = configs

        let identifier = Self.taskId(forSeed: seed)
        self.status = KVConfig<Status>(key: identifier, default: .idle, store: Self.statusStore)

        switch self.status.value {
        case .rollback:
            // 用于`clearMigrationMarks`优化，详见文档：
            // https://bytedance.feishu.cn/docx/TtNEd1iRyoT9V2xwayqcxogSnuR
            self.status.value = .idle
        case .copying:
            self.status.value = .idle   // 异常情况，进行修复
        case .deleting:
            self.status.value = .copied // 异常情况，进行修复
        default: break
        }
    }

    /// 是否可运行
    var runable: Bool {
        switch strategy {
        case .sync: return status.value == .idle
        case .move: return status.value == .idle || status.value == .copied
        }
    }

    func run() {
        guard runable else { return }

        switch status.value {
        case .idle:     // copy data
            self.status.value = .copying
            track(action: "migrateCopy") {
                if let toStore = makeToStore(forSeed: seed) {
                    configs.forEach { $0.copyAll(to: toStore) }
                }
            }
            self.status.value = .copied
        case .copied:   // delete data
            self.status.value = .deleting
            track(action: "migrateClean") {
                configs.forEach { $0.cleanAll() }
            }
            self.status.value = .deleted
        default:
            KVStores.assertionFailure("unexpected status: \(status.value.rawValue)")
        }
    }

    private func makeToStore(forSeed seed: KVMigrationSeed) -> KVStore? {
        let store: KVStore?
        var config = KVStoreConfig(space: seed.space, domain: seed.domain, mode: seed.mode, type: seed.type)
        switch seed.type {
        case .udkv:
            store = KVStores.udkv(config: config, proxies: [.track, .rekey, .log])
        case .mmkv:
            store = KVStores.mmkv(config: config, proxies: [.track, .rekey, .log])
        }
        return store
    }

    private func track(action: String, block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()

        block()

        let end = CFAbsoluteTimeGetCurrent()
        let event = TrackerEvent(
            name: "lark_storage_key_value_action",
            metric: [
                "latency": (end - start) * Double(Const.thousand)
            ],
            category: [
                "is_main_thread": Thread.isMainThread,
                "base_type": seed.type.rawValue,
                "action": action,
                "biz": seed.domain.root.isolationId,
                "scene": "migration"
            ],
            extra: [:]
        )
        DispatchQueue.global(qos: .utility).async {
            Dependencies.post(event)
        }
    }

    static func taskId(forSeed seed: KVMigrationSeed) -> String {
        let spacePart = "space_" + seed.space.isolationId
        let domainPart = "domain_" + seed.domain.asComponents()
            .map(\.isolationId)
            .joined(separator: "_")
        let modePart: String
        switch seed.mode {
        case .normal: modePart = "mode_normal"
        case .shared: modePart = "mode_shared_" + Dependencies.appGroupId
        }
        let typePart = "type_" + seed.type.rawValue
        let versPart = "version_v1"
        return "\(spacePart).\(domainPart).\(modePart).\(typePart).\(versPart)"
    }

}

// MARK: - Task Status

extension KVMigrationTask {
    /// ** 描述迁移状态 **
    /// - 迁移流程：idle -> coping -> copied -> deleting -> deleted/finished
    /// - case 说明
    ///   - idle: 待续
    ///   - coping: 正在复制数据到目标 Store
    ///   - copied: 复制完毕；此后读数据行为无需再兼容旧库的数据；但写数据时仍然双写
    ///   - deleting: 正在删除源数据
    ///   - deleted: 删除源数据完毕
    ///
    /// NOTE: Status 落库，rawValue 不要轻易变更
    enum Status: Int, Codable, Comparable {

        case rollback   = -100
        case idle       = 0
        case copying    = 100
        case copied     = 200
        case deleting   = 300
        case deleted    = 400

        static var finished: Status = .deleted

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

extension KVMigrationTask.Status: KVNonOptionalValue {

    typealias StoreType = RawValue

    var storeWrapped: Int? { rawValue }

    static func fromStore(_ val: Int) -> Self {
        Self(rawValue: val) ?? .idle
    }

}
