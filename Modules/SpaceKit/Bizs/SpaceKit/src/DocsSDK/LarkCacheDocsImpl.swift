//
//  LarkCacheDocsImpl.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2020/8/19.
//  接入LarkCache的注册清理，清理的类型一般是数据库，其它类型使用CacheService的统一缓存

import Foundation
import SKFoundation
import SKCommon
import LarkCache
import RxSwift
import SKWikiV2
import SKBitable
import SKComment
import SKInfra
import SKWorkspace
import LarkContainer

public final class LarkCacheDocsImpl: CleanTask {
    private let cleanCacheDisposeBag = DisposeBag()
    private let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)

    public var name: String = "Docs-autoClean-"

    public init() {
    }

    public func clean(config: CleanConfig, completion: @escaping Completion) {
        // 剪存资源清理
        ClippingBridgeFactory.cleanClippingResource()
        
        guard let newCache = DocsContainer.shared.resolve(NewCacheAPI.self) else {
            let result = TaskResult(completed: false,
                                    costTime: 0,
                                    size: .bytes(0))
            completion(result)
            return
        }
        newCache.cacheClean(maxSize: 300 * 1024 * 1024, ageLimit: config.global.cacheTimeLimit, isUserTrigger: config.isUserTriggered).subscribe(onNext: { (result) in
            let result = TaskResult(completed: result.completed,
                                    costTime: result.costTime,
                                    size: .bytes(result.size))
            completion(result)
        }).disposed(by: cleanCacheDisposeBag)
        
        if let btAttachCache = DocsContainer.shared.resolve(BTUploadAttachCacheCleanable.self) {
            btAttachCache.clean()
        } else {
            DocsLogger.error("can't get BTUploadAttachCacheCleanable instance")
        }

        if config.isUserTriggered == false {
            CommentDraftManager.shared.removeExpiredModels() // 清理过期草稿
        }
        
        if config.isUserTriggered {
            // 必须用户手动触发才能够清除Wiki、Space的DB缓存
            if let wikiSrtorageAPI = try? userResolver.resolve(assert: WikiStorageBase.self) {
                wikiSrtorageAPI.deleteDB()
            } else {
                DocsLogger.warning("can not get wikiSrtorageAPI")
            }
            
            let workspaceStorage = DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)
            workspaceStorage?.deleteAll()
        }
    }

    public func size(config: CleanConfig, completion: @escaping Completion) {
        guard let newCache = DocsContainer.shared.resolve(NewCacheAPI.self) else {
            let result = TaskResult(completed: false,
                                    costTime: 0,
                                    size: .bytes(0))
            completion(result)
            return
        }
        newCache.cacheSize().subscribe(onNext: { (result) in
            let result = TaskResult(completed: result.completed,
                                    costTime: result.costTime,
                                    size: .bytes(result.size))
            completion(result)
        }).disposed(by: cleanCacheDisposeBag)
    }

    public func cancel() {
        guard let newCache = DocsContainer.shared.resolve(NewCacheAPI.self) else {
            return
        }
        newCache.cleanCancel()
    }
}
