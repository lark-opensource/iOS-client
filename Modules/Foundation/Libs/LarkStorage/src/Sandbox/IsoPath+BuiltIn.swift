//
//  IsoPath+BuiltIn.swift
//  LarkStorage
//
//  Created by 7Up on 2023/9/4.
//

import Foundation

extension AbsPath {
    public static var rustSdk: AbsPath { AbsPath.document + "sdk_storage" }
}

private func _sb_temporary_domain() -> Domain {
    return Domain.sandbox.child("Temporary")
}

private func _sb_cache_domain() -> Domain {
    return Domain.sandbox.child("Cache")
}

extension IsoPath {
    /// 解析 Rust SDK 维护的 path，转 `IsoPath`
    /// 要求 `rustPathString` 必须是 `Documents/sdk_storage` 下的路径
    public static func parse(fromRust rustPath: AbsPathConvertiable) throws -> IsoPath {
        return try IsoPath.parse(from: rustPath, space: .global, domain: Domain.biz.rust)
    }

    /// 构建 Rust SDK 维护的 IsoPath
    public static func rustSdk(relativePart: String? = nil) throws -> IsoPath {
        do {
            let basePath = try IsoPath.parse(fromRust: AbsPath.rustSdk)
            if let relativePart, !relativePart.isEmpty {
                return basePath + relativePart
            } else {
                return basePath
            }
        } catch {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            throw error
            #endif
        }
    }
}

// public checked. NOTE: 这个 `public` 不能删
final public class _IsoPathParserRegistry {
    /// 注册 Path Parser
    @_silgen_name("Lark.LarkStorage_SandboxIsoPathParserRegistry.LarkStorage")
    public static func registerBuiltInPathParser() {
        IsoPath.Parser.register(forDomain: Domain.biz.rust) { space, absPath in
            let sdkRootPath = AbsPath.rustSdk
            guard case .global = space, absPath.starts(with: sdkRootPath) else {
                return nil
            }
            return .init(rootPart: sdkRootPath)
        }

        IsoPath.Parser.register(forDomain: _sb_cache_domain()) { space, absPath in
            let cacheRootPath = AbsPath.cache
            guard case .global = space, absPath.starts(with: cacheRootPath) else {
                return nil
            }
            return .init(rootPart: cacheRootPath)
        }

        IsoPath.Parser.register(forDomain: _sb_temporary_domain()) { space, absPath in
            let tmpRootPath = AbsPath.temporary
            guard case .global = space, absPath.starts(with: tmpRootPath) else {
                return nil
            }
            return .init(rootPart: tmpRootPath)
        }
    }
}

/// 非必须，不使用
extension NotStrictlyExtension where BaseType == IsoPath {
    /// cachePath 转 IsoPath
    /// 要求 `cachePath` 必须是 Library/Caches 的路径
    public static func parse(fromCache cachePath: AbsPath) throws -> IsoPath {
        return try IsoPath.parse(from: cachePath, space: .global, domain: _sb_cache_domain())
    }

    /// tmpPath 转 IsoPath
    /// 要求 `tmpPath` 必须是 tmp/ 的路径
    public static func parse(fromTemporary tmpPath: AbsPath) throws -> IsoPath {
        return try IsoPath.parse(from: tmpPath, space: .global, domain: _sb_temporary_domain())
    }

    /// 构建 Library/Caches 下的 `IsoPath`
    public static func cache() -> IsoPath {
        let domain = _sb_cache_domain()
        if let ret = try? IsoPath.notStrictly.parse(fromCache: .cache) {
            return ret
        } else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            SBUtils.assert(false, event: .unexpectedParseFailure)
            return .in(space: .global, domain: domain).build(.cache)
            #endif
        }
    }

    /// 构建 tmp/ 下的 `IsoPath`
    public static func temporary() -> IsoPath {
        let domain = _sb_temporary_domain()
        if let ret = try? IsoPath.notStrictly.parse(fromTemporary: .temporary) {
            return ret
        } else {
            #if DEBUG || ALPHA
            fatalError("unexpected")
            #else
            SBUtils.assert(false, event: .unexpectedParseFailure)
            return .in(space: .global, domain: domain).build(.temporary)
            #endif
        }
    }
}

extension IsoPath {
    /// 构建 tmp/ 下的 `IsoPath`
    public static func temporary() -> IsoPath {
        return .notStrictly.temporary()
    }
}
