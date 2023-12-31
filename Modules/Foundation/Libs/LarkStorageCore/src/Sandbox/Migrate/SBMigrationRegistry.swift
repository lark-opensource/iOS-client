//
//  SBMigrationRegistry.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import LKCommonsLogging

// MARK: Migration Strategy

/// 迁移策略
public enum SBMigrationStrategy {
    /// 重定向，不移动；
    case redirect

    public struct MoveAllows: OptionSet {
        public var rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// 进入后台触发
        public static let background = Self(rawValue: 1<<0)
        /// 初始化时触发
        public static let intialization = Self(rawValue: 1<<1)
    }

    /// 尝试在合适的时机移动；原数据不丢，移动前，仍然定位到原位置
    /// `allows` 描述允许迁移的时机
    case moveOrDrop(allows: MoveAllows = .background)
}

// MARK: Migration Config

/// 迁移配置
public struct SBMigrationConfig {
    // swiftlint:disable nesting
    public enum PathMatcher {
        public struct PartialItem {
            var relativePart: String
            public init(_ relativePart: String) {
                self.relativePart = relativePart
            }
        }

        /// 整体迁移
        case whole

        /// 部分迁移
        case partial([PartialItem])
    }
    // swiftlint:enable nesting

    public var fromRoot: AbsPath
    public var strategy: SBMigrationStrategy
    public var pathMatcher: PathMatcher

    internal init(fromRoot: AbsPath, strategy: SBMigrationStrategy, pathMatcher: PathMatcher) {
        self.fromRoot = fromRoot
        self.strategy = strategy
        self.pathMatcher = pathMatcher
    }

    /// 生成整体迁移的配置
    public static func whole(fromRoot: AbsPath, strategy: SBMigrationStrategy) -> Self {
        Self(fromRoot: fromRoot, strategy: strategy, pathMatcher: .whole)
    }

    /// 生成局部迁移的配置
    public static func partial(
        fromRoot: AbsPath,
        strategy: SBMigrationStrategy,
        items: [PathMatcher.PartialItem]
    ) -> Self {
        Self(fromRoot: fromRoot, strategy: strategy, pathMatcher: .partial(items))
    }
}

/// 支持字符串生成 `PartialItem`
extension SBMigrationConfig.PathMatcher.PartialItem: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

// MARK: Migration Registry

/// 注册 Sandbox 迁移任务
public final class SBMigrationRegistry {
    static let loadableKey = "LarkStorage_SandboxMigrationRegistry"
    public static let logger = Logger.log(SBMigrationRegistry.self, category: "LarkStorage.Sandbox.Migration")

    struct Item {
        var domain: DomainType
        var provider: (Space, RootPathType) -> SBMigrationConfig?
    }

    private static var _allItems = [Item]()
    static var allItems: [Item] {
        Dependencies.loadOnce(loadableKey)
        return _allItems
    }

    public typealias ConfigProvider = (Space) -> [RootPathType.Normal: SBMigrationConfig]

    /// 注册 Domain 粒度的迁移配置
    ///
    /// - Parameters:
    ///   - domain: some domain
    ///   - provider: 提供迁移配置
    public static func registerMigration(forDomain domain: DomainType, provider: @escaping ConfigProvider) {
        let item = Item(domain: domain) { (space, type) in
            guard case .normal(let normalType) = type else { return nil }
            return provider(space)[normalType]
        }
        _allItems.append(item)
    }

}

// MARK: Migration Registry - Redirect

// 针对重定向场景做一些接口优化，使之更容易被理解；本质上仍然是 `SBMigrationRegistry` 的逻辑

public struct SBRedirectRegistry {
    public typealias ConfigProvider = (Space) -> [RootPathType.Normal: AbsPath]

    /// 注册重定向
    public static func registerRedirect(forDomain domain: DomainType, provider: @escaping ConfigProvider) {
        SBMigrationRegistry.registerMigration(forDomain: domain) { space in
            return provider(space).mapValues { absPath in
                return SBMigrationConfig.whole(fromRoot: absPath, strategy: .redirect)
            }
        }
    }
}
