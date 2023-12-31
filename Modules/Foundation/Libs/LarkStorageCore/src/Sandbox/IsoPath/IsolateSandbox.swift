//
//  IsolateSandbox.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import LKCommonsLogging

struct IsolatePathConfig {
    var space: Space
    var domain: DomainType
    var rootType: RootPathType
}

public struct IsolateSandboxPath: PathType {
    enum InnerType: String {
        case standard   // 标准路径（规范路径）
        case custom     // 定制的非标准路径
        case temporary  // 临时（解密场景）
    }

    var rootPart: AbsPath
    var relativePart: String
    var type: InnerType
    var config: IsolatePathConfig

    public var absoluteString: String {
        return (rootPart + relativePart).absoluteString
    }

    public var deletingLastPathComponent: Self {
        let newRelative = (relativePart as NSString).deletingLastPathComponent
        return clone(with: newRelative)
    }

    init(rootPart: AbsPath, relativePart: String = "", type: InnerType, config: IsolatePathConfig) {
        self.rootPart = rootPart
        self.relativePart = relativePart
        self.type = type
        self.config = config
    }

    func clone(with relative: String) -> Self {
        return Self(rootPart: rootPart, relativePart: relative, type: type, config: config)
    }

    public func appendingRelativePath(_ relativePath: String) -> Self {
        let newRelative = (relativePart as NSString).appendingPathComponent(relativePath)
        return clone(with: newRelative)
    }
}

/// Isolate Sandbox
public final class IsolateSandbox: SandboxProxy<IsolateSandboxPath> {
    let space: Space
    let domain: DomainType
    var cipherSuite: SBCipherSuite?

    override var wrapped: Sandbox<RawPath> { self.proxyHead }

    private let base = SandboxBase<RawPath>()
    private var proxyHead: Sandbox<RawPath>

    private static let wrongDomainCharacterSet = CharacterSet(charactersIn: "-").union(.domainForbiddens)

    public init(space: Space, domain: DomainType) {
        self.space = space.invalidFixed()
        self.domain = domain
        self.proxyHead = SandboxProxy(wrapped: base)
        super.init(wrapped: proxyHead)

        // domain 检查，Swift.assert 暂时关闭，后续推进治理完成存量治理再打开
        SBUtils.disableSwiftAssert()
        SBUtil.assert(
            !domain.contains(characterSet: Self.wrongDomainCharacterSet, includesAncestor: true),
            "Do not use '.' or '-' in domain identifier",
            event: .wrongDomain
        )
        SBUtils.enableSwiftAssert()
        SBUtil.assert(self.space == space, event: .wrongSpace)
    }
}

// MARK: - Resolve Root Path

extension IsolateSandbox {

    // MARK: Resolve Normal Root Path

    static func standardRootPath(
        withSpace space: Space,
        domain: DomainType,
        type: RootPathType.Normal
    ) -> AbsPath {
        return AbsPath.rootPath(for: type)
            .appendingComponent(with: space)
            .appendingComponent(with: domain)
    }

    static func rootPath(
        withSpace space: Space,
        domain: DomainType,
        type: RootPathType.Normal
    ) -> IsolateSandboxPath {
        let seed = SBMigrationSeed(space: space, domain: domain, rootType: .normal(type))
        if let task = SBMigrationTaskManager.shared.task(forSeed: seed),
           let path = task.resolveRootPath()
        {
            return path
        }

        let root = standardRootPath(withSpace: space, domain: domain, type: type)
        return .init(rootPart: root, type: .standard, config: seed)
    }

    // MARK: Resolve Shared Root Path

    static func standardRootPath(
        withSpace space: Space,
        domain: DomainType,
        type: RootPathType.Shared
    ) -> AbsPath? {
        guard let root = AbsPath.rootPath(for: type, appGroupId: Dependencies.appGroupId) else {
            return nil
        }
        return root.appendingComponent(with: space).appendingComponent(with: domain)
    }

    static func rootPath(
        withSpace space: Space,
        domain: DomainType,
        type: RootPathType.Shared
    ) -> IsolateSandboxPath? {
        let seed = SBMigrationSeed(space: space, domain: domain, rootType: .shared(type))
        if let task = SBMigrationTaskManager.shared.task(forSeed: seed),
           let path = task.resolveRootPath()
        {
            return path
        }

        guard let root = standardRootPath(withSpace: space, domain: domain, type: type) else {
            return nil
        }
        return .init(rootPart: root, type: .standard, config: seed)
    }

}
