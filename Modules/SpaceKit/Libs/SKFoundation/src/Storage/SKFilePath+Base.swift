//
//  SKFilePath+Base.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/11/17.
//

import LarkStorage

public extension SKFilePath {
    // 全局 ccm document 目录 : 相当于 document/DocsSDK
    static var globalSandboxWithDocument: SKFilePath {
        globalSandbox(forType: .document)
    }
    
    // 全局 ccm library 目录 : 相当于 library/DocsSDK
    static var globalSandboxWithLibrary: SKFilePath {
        globalSandbox(forType: .library)
    }
    
    // 全局 ccm cache 目录 : 相当于 cache/DocsSDK
    static var globalSandboxWithCache: SKFilePath {
        globalSandbox(forType: .cache)
    }
    
    // 全局 ccm temporary 目录 : 相当于 tmp/DocsSDK
    static var globalSandboxWithTemporary: SKFilePath {
        globalSandbox(forType: .temporary)
    }
    
    private static func globalSandbox(forType type: RootPathType.Normal) -> SKFilePath {
        return .isoPath(IsolateSandbox(space: .global, domain: Domains.Business.ccm).rootPath(forType: type))
    }
     
    // 单个用户 ccm document 目录
    static func userSandboxWithDocument(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .document)
    }
    
    // 单个用户 ccm library 目录
    static func userSandboxWithLibrary(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .library)
    }
    
    // 单个用户 ccm cache 目录
    static func userSandboxWithCache(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .cache)
    }
    
    // 单个用户 ccm temporary 目录
    static func userSandboxWithTemporary(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .temporary)
    }
    
    static func userSandbox(_ userId: String, forType type: RootPathType.Normal) -> SKFilePath {
        return .isoPath(IsolateSandbox(space: .user(id: userId), domain: Domains.Business.ccm).rootPath(forType: type))
    }
    
    static func parse(path: String) throws -> SKFilePath {
        let isoPath = try IsoPath.parse(from: path, space: .global, domain: Domains.Business.ccm)
        return .isoPath(isoPath)
    }
}

