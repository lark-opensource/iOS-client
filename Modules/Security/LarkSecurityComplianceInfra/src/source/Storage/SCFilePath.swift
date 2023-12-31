//
//  SCFilePath.swift
//  LarkSecurityComplianceInfra
//
//  Created by AlbertSun on 2023/8/29.
//

import Foundation
import LarkStorage

public protocol SCFilePath {
    var pathString: String { get }
    
    var exists: Bool { get }
    
    var isDirectory: Bool { get }
    
    var fileAttributes: FileAttributes { get }
    
    // 拼接路径
    func appendingRelativePath(_ relativePath: String) -> Self
    
    // 创建路径
    func createDirectoryIfNeeded(withIntermediateDirectories createIntermediates: Bool) throws
}

// global
public struct SCSandBox {
    public static func globalSandboxWithDocument(business: SncBiz = .common) -> SCFilePath {
        globalDirectory(forBiz: business, forType: .document)
    }
    
    public static func globalSandboxWithLibrary(business: SncBiz = .common) -> SCFilePath {
        globalDirectory(forBiz: business, forType: .library)
    }
    
    public static func globalSandboxWithCache(business: SncBiz = .common) -> SCFilePath {
        globalDirectory(forBiz: business, forType: .cache)
    }
    
    public static func globalSandboxWithTemporary(business: SncBiz = .common) -> SCFilePath {
        globalDirectory(forBiz: business, forType: .temporary)
    }
}

// user
public extension SCSandBox {
    static func userSandboxWithDocument(userId: String, business: SncBiz = .common) -> SCFilePath {
        userDirectory(userId: userId, forBiz: business, forType: .document)
    }
    
    static func userSandboxWithLibrary(userId: String, business: SncBiz = .common) -> SCFilePath {
        userDirectory(userId: userId, forBiz: business, forType: .library)
    }
    
    static func userSandboxWithCache(userId: String, business: SncBiz = .common) -> SCFilePath {
        userDirectory(userId: userId, forBiz: business, forType: .cache)
    }
    
    static func userSandboxWithTemporary(userId: String, business: SncBiz = .common) -> SCFilePath {
        userDirectory(userId: userId, forBiz: business, forType: .temporary)
    }
}

private extension SCSandBox {
    static func globalDirectory(forBiz biz: SncBiz, forType type: RootPathType.Normal) -> SCIsoPath {
        SCIsoPath(path: IsoPath.global.in(domain: biz).build(type))
    }
    
    static func userDirectory(userId: String, forBiz biz: SncBiz, forType type: RootPathType.Normal) -> SCIsoPath {
        SCIsoPath(path: IsoPath.user(id: userId).in(domain: biz).build(type))
    }
}

private struct SCIsoPath: SCFilePath {
    let path: IsoPath
    
    var pathString: String {
        path.absoluteString
    }
    
    var exists: Bool {
        path.exists
    }
    
    var isDirectory: Bool {
        path.isDirectory
    }
    
    var fileAttributes: FileAttributes {
        path.attributes
    }
    
    // 拼接路径
    func appendingRelativePath(_ relativePath: String) -> Self {
        SCIsoPath(path: path.appendingRelativePath(relativePath))
    }
    
    // 创建路径
    func createDirectoryIfNeeded(withIntermediateDirectories createIntermediates: Bool) throws {
        try path.createDirectoryIfNeeded(withIntermediateDirectories: createIntermediates)
    }
}
