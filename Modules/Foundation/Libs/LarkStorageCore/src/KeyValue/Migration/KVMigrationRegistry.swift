//
//  KVMigrationRegistry.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic
import LKCommonsLogging

/// 注册 KeyValue 迁移任务
public final class KVMigrationRegistry {
    static let loadableKey = "LarkStorage_KeyValueMigrationRegistry"
    public static let logger = Logger.log(KVMigrationRegistry.self, category: "LarkStorage.KeyValue.Migration")
}

/// 迁移策略
public enum KVMigrationStrategy: UInt {
    /// 同步
    case sync
    /// 移动
    case move
}

/// 注册迁移
extension KVMigrationRegistry {

    private static let lock = UnfairLock()
    public typealias ConfigProvider = (Space) -> [KVMigrationConfig]

    /// 注册 Domain 粒度的迁移配置（全量后一段时间会删掉）
    /// - Parameters:
    ///   - domain: some domain
    ///   - strategy: 迁移策略
    ///   - provider: 产生 configs
    public static func registerMigration(
        forDomain domain: DomainType,
        strategy: KVMigrationStrategy = .sync,
        provider: @escaping ConfigProvider
    ) {
        lock.lock(); defer { lock.unlock() }
        _allItems.append(.init(domain: domain, strategy: strategy, provider: provider))
    }

    struct Item {
        var domain: DomainType
        var strategy: KVMigrationStrategy
        var provider: ConfigProvider
    }

    private static var _allItems = [Item]()

    static var allItems: [Item] {
        Dependencies.loadOnce(loadableKey)
        lock.lock(); defer { lock.unlock() }
        return _allItems
    }

    /// 清除所有配置，仅用于单测
    static func clearAllItems() {
        lock.lock(); defer { lock.unlock() }
        _allItems.removeAll()
    }

    // 合并两个迁移配置，返回新的配置，`usingMigration` 时使用
    static func mergeConfigs(
        _ oldConfigs: [KVMigrationConfig], _ newConfigs: [KVMigrationConfig]
    ) -> [KVMigrationConfig] {
        // NOTE: 考虑到 configs 量级很小，这里的代码没有进行优化
        var ret = [KVMigrationConfig]()

        // 1. 首先进行去重
        let oldWrappers = oldConfigs.map(KVMigrationConfigWrapper.init)
        let newWrappers = newConfigs.map(KVMigrationConfigWrapper.init)
        let configSet = Set(oldWrappers).union(newWrappers)
        // 2. 再合并 simpleItem
        // 2.1 筛出 simpleItem 的配置
        let grouped1 = Dictionary(grouping: configSet) { $0.matcherWrapper.itemSet.isNil }

        // 这部分是非 simpleItem 的配置，不用合并
        if let configSet = grouped1[true] {
            ret.append(contentsOf: configSet.map(\.wrapped))
        }

        // 这部分是 simpleItem 的配置，需要合并
        if let configSet = grouped1[false] {
            let simpleConfigSet = configSet.filter { $0.matcherWrapper.itemSet != nil }
            // 2.2 对 simpleConfigSet 分组
            let grouped2 = Dictionary(grouping: simpleConfigSet, by: ConfigGrouper.init)
            // 2.3 同组的合并 simpleItem
            let results = grouped2.map { grouper, wrappers in
                let itemSet = wrappers
                    .compactMap { $0.matcherWrapper.itemSet }
                    .reduce(Set()) { $0.union($1) }
                    .map { $0.wrapped }
                return KVMigrationConfig(from: grouper.from, to: grouper.to, keyMatcher: .simple(Array(itemSet)))
            }
            ret.append(contentsOf: results)
        }
        return ret
    }

}

// MARK: - 以下代码是为了方便合并操作中的比较及去重

private struct ConfigGrouper: Hashable {
    let from: KVMigrationConfig.From
    let to: KVMigrationConfig.To

    init(wrapper: KVMigrationConfigWrapper) {
        self.from = wrapper.wrapped.from
        self.to = wrapper.wrapped.to
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.from == rhs.from && lhs.to == rhs.to
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.from)
        hasher.combine(self.to)
    }
}

struct KVMigrationConfigWrapper: Hashable {
    let wrapped: KVMigrationConfig
    fileprivate let matcherWrapper: KeyMatcherWrapper

    init(wrapped: KVMigrationConfig) {
        self.wrapped = wrapped
        self.matcherWrapper = KeyMatcherWrapper(wrapped: wrapped.keyMatcher)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrapped.from == rhs.wrapped.from &&
        lhs.wrapped.to == rhs.wrapped.to &&
        lhs.matcherWrapper == rhs.matcherWrapper
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wrapped.from)
        hasher.combine(wrapped.to)
        hasher.combine(matcherWrapper)
    }
}

private struct KeyMatcherWrapper: Hashable {
    let wrapped: KVMigrationConfig.KeyMatcher
    let itemSet: Set<ItemWrapper>?

    init(wrapped: KVMigrationConfig.KeyMatcher) {
        self.wrapped = wrapped
        if case .simple(let items) = wrapped {
            self.itemSet = Set(items.map(ItemWrapper.init))
        } else {
            self.itemSet = nil
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.wrapped, rhs.wrapped) {
        case (.simple, .simple):
            return lhs.itemSet == rhs.itemSet
        case (.prefix(let oldPattern, _), .prefix(let newPattern, _)),
            (.suffix(let oldPattern, _), .suffix(let newPattern, _)),
            (.dropPrefix(let oldPattern, _), .dropPrefix(let newPattern, _)):
            return oldPattern == newPattern
        case (.allValues, .allValues):
            return true
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch wrapped {
        case .simple:
            hasher.combine("simple")
            hasher.combine(itemSet)
        case .prefix(let pattern, _):
            hasher.combine("prefix")
            hasher.combine(pattern)
        case .suffix(let pattern, _):
            hasher.combine("suffix")
            hasher.combine(pattern)
        case .dropPrefix(let pattern, _):
            hasher.combine("dropPrefix")
            hasher.combine(pattern)
        case .allValues:
            hasher.combine("allValues")
        }
    }
}

private struct ItemWrapper: Hashable {
    let wrapped: KVMigrationConfig.KeyMatcher.SimpleItem

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrapped.newKey == rhs.wrapped.newKey
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wrapped.newKey)
    }
}

extension KVMigrationConfig.From: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .userDefaults(let ud):
            hasher.combine("userDefaults")
            switch ud {
            case .standard:
                hasher.combine("standard")
            case .suiteName(let text):
                hasher.combine("suiteName")
                hasher.combine(text)
            case .appGroup:
                hasher.combine("appGroup")
            }
        case .mmkv(let mm):
            hasher.combine("mmkv")
            switch mm {
            case .custom(let mmapId, let rootPath):
                hasher.combine(mmapId)
                hasher.combine(rootPath)
            }
        }
    }
}
