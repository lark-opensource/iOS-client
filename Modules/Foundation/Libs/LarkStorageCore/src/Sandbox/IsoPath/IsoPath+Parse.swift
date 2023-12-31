//
//  IsoPath+Parse.swift
//  LarkStorage
//
//  Created by 7Up on 2022/12/21.
//

import Foundation

extension IsoPath {
    /// Parse Error
    enum ParseError: Error {
        /// 非法 path
        case invalidPath(String)
        /// 找不到 rootType
        case unknownRootType
        /// 隔离区域外的 path
        case outsidePath
    }

    /// 从 AbsPath 解析获取 `IsoPath`
    /// - Parameter absoluteString: 绝对路径，要求是沙盒内的绝对路径
    /// - Parameter space: Space
    /// - Parameter domain: Domain
    public static func parse(from absPath: AbsPathConvertiable, space: Space, domain: DomainType) throws -> IsoPath {
        return try Parser(absoluteString: absPath.asAbsPath().absoluteString, space: space, domain: domain).parse()
    }

    /// 解析 `IsoPath`，`String`(absolutePathString) -> `IsoPath`
    public final class Parser {
        let absoluteString: String
        let space: Space
        let domain: DomainType
        init(absoluteString: String, space: Space, domain: DomainType) {
            self.absoluteString = absoluteString
            self.space = space
            self.domain = domain
        }

        func parse() throws -> IsoPath {
            guard absoluteString.hasPrefix("/") else {
                throw ParseError.invalidPath("not absolute path string")
            }
            let absPath = AbsPath(absoluteString)
            guard absPath.starts(with: AbsPath.home) else {
                throw ParseError.invalidPath("not sandbox path")
            }
            guard let rootType = Self.rootType(for: absoluteString) else {
                throw ParseError.unknownRootType
            }
            let root: IsoPath
            if let tester = Self.testers[domain.hashable] {
                guard let success = tester(space, AbsPath(absoluteString)) else {
                    throw ParseError.outsidePath
                }
                let sandbox = IsolateSandbox(space: space, domain: domain)
                let base = IsolateSandboxPath(
                    rootPart: success.rootPart,
                    type: .custom,
                    config: .init(space: space, domain: domain, rootType: .normal(rootType))
                )
                var wrapped = sandbox.wrapped
                wrapped = SandboxIsoCommonCryptoProxy(wrapped: wrapped)
                root = IsoPath(base: base, sandbox: wrapped)
            } else {
                root = IsoPath.in(space: space, domain: domain).build(rootType)
            }
            guard let relative = absPath.relativePath(to: root) else {
                throw ParseError.outsidePath
            }
            return root + relative
        }

        static func rootType(for absoluteString: String) -> RootPathType.Normal? {
            let testPath = AbsPath(absoluteString)
            if testPath.starts(with: AbsPath.document) {
                return .document
            }
            if testPath.starts(with: AbsPath.temporary) {
                return .temporary
            }
            if testPath.starts(with: AbsPath.cache) {
                return .cache
            }
            if testPath.starts(with: AbsPath.library) {
                return .library
            }
            return nil
        }
    }
}

public extension IsoPath.Parser {
    static let loadableKey = "LarkStorage_SandboxIsoPathParserRegistry"

    struct TestSuccess {
        public var rootPart: AbsPath
        public init(rootPart: AbsPath) {
            self.rootPart = rootPart
        }
    }

    typealias Tester = (Space, AbsPath) -> TestSuccess?

    private static var _testers = [DomainHash: Tester]()

    internal static var testers: [DomainHash: Tester] {
        Dependencies.loadOnce(Self.loadableKey)
        return _testers
    }

    /// 注册 Domain 粒度的迁移配置
    static func register(forDomain domain: DomainType, tester: @escaping Tester) {
        _testers[domain.hashable] = tester
    }
}

extension IsoPath {

    public typealias AbsoluteStrig = String

    /// `map` 操作
    public func map(transform: (AbsoluteStrig) -> AbsoluteStrig) throws -> IsoPath {
        let transformed = transform(absoluteString)
        let newBase = try IsoPath.parse(
            from: transformed,
            space: base.config.space,
            domain: base.config.domain
        ).base
        return .init(base: newBase, sandbox: sandbox)
    }

}
