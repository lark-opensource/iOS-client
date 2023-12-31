//
//  CCMClean.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/7/18.
//  


import Foundation
import LarkStorage
import LarkClean
import SKInfra
import SKFoundation

extension CleanRegistry {
    @_silgen_name("Lark.LarkClean_CleanRegistry.CCM")
    public static func registerCCM() {
        registerPaths(forGroup: "ccm") { ctx in
            let users = ctx.userList
            var path = [
                CleanIndex.Path.abs(LynxIOHelper.Path.getRootFolder_().pathString),
                CleanIndex.Path.abs(SKFilePath.globalSandboxWithLibrary.appendingRelativePath("CustomResourceService").pathString),
                CleanIndex.Path.abs(SKFilePath.globalSandboxWithLibrary.appendingRelativePath("docs/clipping/html").pathString),
                CleanIndex.Path.abs(userPersistentLibraryPath().absoluteString),
                CleanIndex.Path.abs(userTransientLibraryPath().absoluteString),
                CleanIndex.Path.abs(userSKNormalLibraryPath().absoluteString),
                CleanIndex.Path.abs(userDocsImageStoreLibraryPath().absoluteString),
                CleanIndex.Path.abs(userDocsImageCacheLibraryPath().absoluteString),
                CleanIndex.Path.abs(userDocsDLPLibraryPath().absoluteString),
                CleanIndex.Path.abs(SKFilePath.globalSandboxWithLibrary.appendingRelativePath("WaterMark").pathString),
            ]
            for user in users {
                path.append(contentsOf: [
                    CleanIndex.Path.abs(userSKConfigLibraryPath(userid: user.userId).absoluteString),
                    CleanIndex.Path.abs(SKFilePath.userSandboxWithLibrary(user.userId).appendingRelativePath("docsDB").pathString),
                    CleanIndex.Path.abs(SKFilePath.userSandboxWithLibrary(user.userId).appendingRelativePath("NewCache/ClientVars").pathString),
                    CleanIndex.Path.abs(userdocsIconCachePath(userid: user.userId).absoluteString)
                ])
            }
            return path
        }
    }
    
    // 指定用户的存储路径
    static func userPersistentLibraryPath() -> IsoPath {
        let space: Space = .global
        let domain = Domain.biz.ccm.child("drive").child("persistent_cache")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.library)
        return cachePath
    }
    
    static func userTransientLibraryPath() -> IsoPath {
        let space: Space = .global
        let domain = Domain.biz.ccm.child("drive").child("transient_cache")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.cache)
        return cachePath
    }
    
    static func userSKNormalLibraryPath() -> IsoPath {
        let domain = Domain.biz.ccm.child("skNormalCache")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.cache)
        return cachePath
    }
    
    static func userSKConfigLibraryPath(userid: String) -> IsoPath {
        let space: Space = .user(id: userid)
        let domain = Domain.biz.ccm.child("skConfigCache")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.library)
        return cachePath
    }
    
    static func userdocsIconCachePath(userid: String) -> IsoPath {
        let space: Space = .user(id: userid)
        let domain = Domain.biz.ccm.child("DocsIconCache")
        let cachePath: IsoPath = .in(space: space, domain: domain).build(.document)
        return cachePath
    }
    
    static func userDocsImageStoreLibraryPath() -> IsoPath {
        let domain = Domain.biz.ccm.child("docsImageStore")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.library)
        return cachePath
    }
    
    static func userDocsImageCacheLibraryPath() -> IsoPath {
        let domain = Domain.biz.ccm.child("docsImageCache")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.cache)
        return cachePath
    }
    
    static func userDocsDLPLibraryPath() -> IsoPath {
        let domain = Domain.biz.ccm.child("docsDlp")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.document)
        return cachePath
    }
    
    
}
