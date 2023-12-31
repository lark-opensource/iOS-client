//
//  SKFilePathMigration.swift
//  SKFoundation
//
//  Created by huangzhikai on 2022/11/29.
//

import Foundation
import LarkStorage

public class SKFilePathMigration {
    // 注册迁移
    @_silgen_name("Lark.LarkStorage_SandboxMigrationRegistry.CCM")
    public static func registerSandboxMigration() {
        let domain = Domains.Business.ccm
        SBMigrationRegistry.registerMigration(forDomain: domain) { space in
            //https://bytedance.feishu.cn/docx/Qx6SddHqYor6VTx3lu6cmCG4nzb
            switch space {
            case .user(let uid):
                return [
                    .library: .partial(
                        fromRoot: AbsPath.library + "DocsSDK/\(uid)",
                        strategy: .redirect,
                        items: ["docsDB",
                                "NewCache",
                                "BitableCache",
                                "wiki",
                                "translationHistrory"]
                    ),
                    .temporary: .partial(
                        fromRoot: AbsPath.temporary + "DocsSDK/\(uid)",
                        strategy: .redirect,
                        items: ["microInsertPicture"]
                    )
                ]
            case .global:
                return [
                    .document: .partial(
                        fromRoot: AbsPath.document + "DocsSDK",
                        strategy: .redirect,
                        items: ["sdk_storage"]
                    ),
                    .library: .partial(
                        fromRoot: AbsPath.library + "DocsSDK",
                        strategy: .redirect,
                        items: ["workspace",
                                "drive",
                                "space",
                                "NewCache",
                                "docs",
                                "SKResource",
                                "document-activity",
                                "CacheService",
                                "ResourceService",
                                "HotFixBackup",
                                "BundleBackup",
                                "simpleBundleBackup",
                                "fullPkgBackup",
                                "fullPkgDownload",
                                "grayscalePkgDownload",
                                "grayscalePkgBackup",
                                "grayscalePkgDownload",
                                "SaviorBackup",
                                "CustomResourceService",
                                "WaterMark",
                                "lynx",
                                "docsDB"]
                    ),
                    .cache: .partial(
                        fromRoot: AbsPath.cache,
                        strategy: .redirect,
                        items: ["DocsSDK/space",
                                "DocsSDK/drive",
                                "DocsSDK/docs",
                                "DocsSDK/OCRCacheImage",
                                "DocsSDK/preview_file_cache",
                                "DocsSDK/CustomResource",
                                "DocsSDK/CustomResourceTemp",
                                "drive"]
                    )
                ]
            @unknown default:
                return [:]
            }
        }
    }
    
    
    //Bitable注册迁移
    @_silgen_name("Lark.LarkStorage_SandboxMigrationRegistry.Bitable")
    public static func registerBitableSandboxMigration() {
        let domain = Domains.Business.bitable
        SBMigrationRegistry.registerMigration(forDomain: domain) { space in
            //https://bytedance.feishu.cn/docx/Qx6SddHqYor6VTx3lu6cmCG4nzb
            switch space {
            case .user(let uid):
                return [
                    .library: .partial(
                        fromRoot: AbsPath.library + "Bitable/\(uid)",
                        strategy: .redirect,
                        items: ["docsDB"]
                    )
                ]
            case .global:
                return [
                    .document: .partial(
                        fromRoot: AbsPath.document + "Bitable",
                        strategy: .redirect,
                        items: []
                    ),
                    .library: .partial(
                        fromRoot: AbsPath.library + "Bitable",
                        strategy: .redirect,
                        items: ["form"]
                    ),
                    .temporary: .partial(
                        fromRoot: AbsPath.temporary + "Bitable",
                        strategy: .redirect,
                        items: []
                    ),
                    .cache: .partial(
                        fromRoot: AbsPath.cache + "Bitable",
                        strategy: .redirect,
                        items: []
                    )
                ]
            @unknown default:
                return [:]
            }
        }
    }
    
    //LarkCache注册迁移
    @_silgen_name("Lark.LarkStorage_SandboxMigrationRegistry.ccmCache")
    public static func registerCCMCacheMigration() {
        //https://bytedance.feishu.cn/docx/XjpBdngjgo4Z7BxU1s9cxbP4ndh
        let docsDlpDomain = Domain.biz.ccm.child("docsDlp")
        SBMigrationRegistry.registerMigration(forDomain: docsDlpDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .document: .whole(
                    fromRoot: AbsPath.document + "DocsSDK/docsDlp",
                    strategy: .redirect
                )
            ]
        }
        
        let skNormalCacheDomain = Domain.biz.ccm.child("skNormalCache")
        SBMigrationRegistry.registerMigration(forDomain: skNormalCacheDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .cache: .whole(
                    fromRoot: AbsPath.cache + "DocsSDK/skNormalCache",
                    strategy: .redirect
                )
            ]
        }
        
        let skConfigCacheDomain = Domain.biz.ccm.child("skConfigCache")
        SBMigrationRegistry.registerMigration(forDomain: skConfigCacheDomain) { space in
            guard case .user(let userId) = space else { return [:] }
            return [
                .library: .whole(
                    fromRoot: AbsPath.library + "DocsSDK/\(userId)/skNormalCache",
                    strategy: .redirect
                )
            ]
        }

        let docsImageStoreDomain = Domain.biz.ccm.child("docsImageStore")
        SBMigrationRegistry.registerMigration(forDomain: docsImageStoreDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .library: .whole(
                    fromRoot: AbsPath.library + "DocsSDK/docsImageStore",
                    strategy: .redirect
                )
            ]
        }
        
        let docsImageCacheDomain = Domain.biz.ccm.child("docsImageCache")
        SBMigrationRegistry.registerMigration(forDomain: docsImageCacheDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .cache: .whole(
                    fromRoot: AbsPath.cache + "DocsSDK/docsImageCache",
                    strategy: .redirect
                )
            ]
        }
        
        let persistentCacheDomain = Domain.biz.ccm.child("drive").child("persistent_cache")
        SBMigrationRegistry.registerMigration(forDomain: persistentCacheDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .library: .whole(
                    fromRoot: AbsPath.library + "DocsSDK/drive/persistent_cache",
                    strategy: .redirect
                )
            ]
        }
        
        let transientCacheDomain = Domain.biz.ccm.child("drive").child("transient_cache")
        SBMigrationRegistry.registerMigration(forDomain: transientCacheDomain) { space in
            guard case .global = space else { return [:] }
            return [
                .cache: .whole(
                    fromRoot: AbsPath.cache + "DocsSDK/drive/transient_cache",
                    strategy: .redirect
                )
            ]
        }
        
        
    }
    
    
}
