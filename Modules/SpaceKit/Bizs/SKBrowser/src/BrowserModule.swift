//
//  DocModule.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/8.
//  


import Foundation
import EENavigator
import SKCommon
import SKFoundation
import LarkRustClient
import RustPB
import SKInfra
import SpaceInterface
import LarkContainer

public final class BrowserModule: ModuleService {

    public init() {}

    public func setup() {
        DocsLogger.info("BrowserModule setup")
        let userContainer = Container.shared.inObjectScope(CCMUserScope.userScope)
        
        DocsContainer.shared.register(BrowserModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)
        
        userContainer.register(DocsOfflineSynManagerDependency.self) { ur in
            if let mgr = ur.docs.editorManager {
                return mgr
            }
            throw NSError(domain: "userscope.doc.ccm", code: -1, userInfo: [NSLocalizedDescriptionKey: "invalid login state"])
        }
        
        DocsContainer.shared.register(SKBrowserInterface.self, factory: { (_) -> SKBrowserInterface in
            return SKBrowserInterfaceImp()
        }).inObjectScope(.container)
    }

    /// 注册路由
    public func registerURLRouter() {
        Navigator.shared.registerRoute(type: LikeListViewControllerBody.self) {
            return LikeListViewControllerHandler()
        }
        Navigator.shared.registerRoute(type: SKShareViewControllerBody.self) {
            return SKShareViewControllerHandler()
        }
        Navigator.shared.registerRoute(type: ExportDocumentViewControllerBody.self) {
            return ExportDocumentViewControllerHandler()
        }
    }
    
    public func userDidLogin() {
        DocsLogger.info("[PushPreLoad] registerPushHandler", component: LogComponents.preload)
        if let rustService = DocsContainer.shared.resolve(RustService.self) {
            let factories: [Basic_V1_Command: RustPushHandlerFactory] = [
                .pushDocFeeds: {
                    PushDocsFeedHandler()
                }
            ]
            rustService.registerPushHandler(factories: factories)
        } else {
            spaceAssertionFailure("rustService is nil")
        }
        
        DocsUserBehaviorManager.shared.userDidLogin()
        
    }
}
