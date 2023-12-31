//
//  SyncContainerViewModel.swift
//  SKDoc
//
//  Created by liujinwei on 2023/10/12.
//  


import Foundation
import SKCommon
import SKInfra
import SKFoundation
import SwiftyJSON
import SKBrowser
import SpaceInterface
import LarkDocsIcon
import LarkContainer

public protocol SyncedBlockContainerDelegate: AnyObject {
    func backToOriginDocIfNeed(token: String, type: DocsType)
    func refresh()
}

//同步块独立页
public protocol SyncedBlockSeparatePage: UIViewController {
    func setup(delegate: SyncedBlockContainerDelegate)
}

public enum SyncContainerState {
    case prepare
    case failed(error: NSError)
    case success(token: String)
    case noPermission
}

public final class SyncContainerViewModel: NSObject {
    
    private let userResolver: UserResolver
    
    public var currentUrl: URL
    
    public let token: String?
    
    public let type: DocsType?
    
    private(set) var parentToken: String?
    
    private let cacheAPI: NewCacheAPI?
    
    private var cacheKey: String {
        return (userResolver.docs.user?.info?.cacheKeyPrefix ?? "") + "sync_to_source"
    }
    
    init(userResolver: UserResolver, url: URL) {
        self.userResolver = userResolver
        self.currentUrl = url
        (token, type) = DocsUrlUtil.getFileInfoNewFrom(currentUrl)
        if type == .sync {
            //同步块添加appid的query
            self.currentUrl = url.docs.addEncodeQuery(parameters: ["doc_app_id": "601"])
        }
        self.cacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)
    }
    
    public var bindState: ((SyncContainerState) -> Void)?
    
    func loadSyncInfoIfNeed() {
        guard type == .sync else {
            self.bindState?(.success(token: ""))
            return
        }
        self.bindState?(.prepare)
        guard let type, let token else { return }
        //无网且有缓存，使用缓存的parentToken发起render
        if !DocsNetStateMonitor.shared.isReachable,
           let parentToken = cacheAPI?.object(forKey: token, subKey: cacheKey) as? String {
            DocsLogger.info("has no network, render with cache", component: LogComponents.syncBlock)
            self.parentToken = parentToken
            self.bindState?(.success(token: parentToken))
            return
        }
        
        let param: [String: Any] = ["obj_type": type.rawValue,
                                     "token": token]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.syncedBlockPermission
                , params: param)
            .set(method: .GET)
            .start(callbackQueue: DispatchQueue.main) { [weak self] (info, error) in
                guard let self else { return }
                if let error {
                    if (error as NSError).code == DocsNetworkError.Code.forbidden.rawValue, UserScopeNoChangeFG.LJW.syncBlockPermissionEnabled {
                        //独立授权fg开启场景才单独处理无权限场景
                        self.bindState?(.noPermission)
                    } else {
                        self.bindState?(.failed(error: error as NSError))
                    }
                    return
                }
                guard let info, let parentToken = info["data"]["parent_doc_info"]["token"].string else {
                    DocsLogger.error("synced_block check_apply_permission return nil", component: LogComponents.syncBlock)
                    let tokenError = NSError(domain: LoaderErrorDomain.getSyncedBlockParent, code: LoaderErrorCode.syncedBlockParentTokenError.rawValue)
                    self.bindState?(.failed(error: tokenError as NSError))
                    return
                }
                self.parentToken = parentToken
                self.bindState?(.success(token: parentToken))
                self.cacheAPI?.set(object: parentToken as NSCoding, for: token, subkey: self.cacheKey, needSync: false, cacheFrom: nil)
            }
        request.makeSelfReferenced()
    }

    #if DEBUG
    //单测用
    init(userResolver: UserResolver, token: String, type: DocsType) {
        self.userResolver = userResolver
        self.token = token
        self.type = type
        self.currentUrl = DocsUrlUtil.url(type: .sync, token: token)
        self.cacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)
    }
    #endif
}
