//
//  SKFilePath+BitableBase.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/1/3.
//

import Foundation
import LarkStorage

public extension SKFilePath {
    // 全局 Bitable document 目录 : 相当于 document/Bitable
    static var bitableGlobalSandboxWithDocument: SKFilePath {
        bitableGlobalSandbox(forType: .document)
    }
    
    // 全局 Bitable library 目录 : 相当于 library/Bitable
    static var bitableGlobalSandboxWithLibrary: SKFilePath {
        bitableGlobalSandbox(forType: .library)
    }
    
    // 全局 Bitable cache 目录 : 相当于 library/cache/Bitable
    static var bitableGlobalSandboxWithCache: SKFilePath {
        bitableGlobalSandbox(forType: .cache)
    }
    
    // 全局 Bitable temporary 目录 : 相当于 tmp/Bitable
    static var bitableGlobalSandboxWithTemporary: SKFilePath {
        bitableGlobalSandbox(forType: .temporary)
    }
    
    private static func bitableGlobalSandbox(forType type: RootPathType.Normal) -> SKFilePath {
        return .isoPath(.in(space: .global, domain: Domains.Business.bitable).build(type))
    }
     
    // 单个用户 ccm document 目录
    static func bitableUserSandboxWithDocument(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .document)
    }
    
    // 单个用户 ccm library 目录
    static func bitableUserSandboxWithLibrary(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .library)
    }
    
    // 单个用户 ccm cache 目录
    static func bitableUserSandboxWithCache(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .cache)
    }
    
    // 单个用户 ccm temporary 目录
    static func bitableUserSandboxWithTemporary(_ userId: String) -> SKFilePath {
        userSandbox(userId, forType: .temporary)
    }
    
    static func bitableUserSandbox(_ userId: String, forType type: RootPathType.Normal) -> SKFilePath {
        return .isoPath(.in(space: .user(id: userId), domain: Domains.Business.bitable).build(type))
    }
}

