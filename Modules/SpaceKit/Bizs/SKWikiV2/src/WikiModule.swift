//
//  WikiModule.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/8.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import SKInfra
import SKWorkspace
import LarkContainer


public final class WikiModuleV2: ModuleService {
    
    private var userResolver: UserResolver {
        Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    }
    
    public init() { }
    
    public func setup() {
        
        DocsLogger.info("WikiModuleV2 setup")
        let userContainer = Container.shared.inObjectScope(CCMUserScope.userScope)
        
        DocsContainer.shared.register(WikiModuleV2.self, factory: { _ in
            return self
        }).inObjectScope(.container)
        
        // 需要先注入WikiStorage，然后获取WikiStorageBase实例
        userContainer.register(WikiStorage.self) { userResolver in
            if CCMUserScope.wikiEnabled {
                let instance = WikiStorage(userResolver: userResolver)
                DocsLogger.info("create WikiStorage instance in userScope \(ObjectIdentifier(instance))")
                return instance
            } else {
                let instance = WikiStorage.shared
                DocsLogger.info("create WikiStorage shared instance  \(ObjectIdentifier(instance))")
                return instance
            }
        }
        
        userContainer.register(WikiStorageBase.self) { userResolver in
            let instance = try userResolver.resolve(assert: WikiStorage.self)
            DocsLogger.info("create WikiStorageBase instance in userScope \(ObjectIdentifier(instance))")
            return instance
        }
        
        userContainer.register(WikiPickerProvider.self) { userResolver in
            return WikiPickerProviderFactory(userResolver: userResolver)
        }
        
        userContainer.register(WikiRouterBaseAPIProtocol.self) { userResolver in
            return WikiRouterBaseAPI(userResolver: userResolver)
        }
    }

    public func registerURLRouter() {
        // Wiki
        registerWikiHome()
        SKRouter.shared.register(types: [.wiki]) { [weak self] resource, params, _ -> UIViewController in
            guard let self = self else {
                spaceAssertionFailure("somethine wrong here, so that i just return an empty VC")
                return UIViewController()
            }
            
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            if userResolver.isPlaceholder {
                DocsLogger.warning("userResolver isPlaceholder")
                return BaseViewController()
            }

            if let wikiEntry = resource as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
                return self.registerWiki(userResolver: userResolver, wikiInfo: wikiInfo, params: params)
            } else {
                return self.registerWiki(userResolver: userResolver, url:resource.url, params: params)
            }
        }
    }

    public func userDidLogout() {
        
    }
}

extension WikiModuleV2 {
    func registerWikiHome() {
        SKRouter.shared.register(checker: { (resource, _) -> (Bool) in
            return URLValidator.isWikiHomePath(url: resource.url)
        }, interceptor: { (_, params) -> (UIViewController) in
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            if userResolver.isPlaceholder {
                DocsLogger.warning("userResolver isPlaceholder")
                return BaseViewController()
            }
            return WikiVCFactory.makeWikiHomePageVC(userResolver: userResolver, params: params)
        })
        SKRouter.shared.register(checker: { (resource, _) -> (Bool) in
            return URLValidator.isWikiSpacePath(url: resource.url)
        }, interceptor: { (res, _) -> (UIViewController) in
            if let spaceId = res.url.pathComponents.last {
                let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
                if userResolver.isPlaceholder {
                    DocsLogger.warning("userResolver isPlaceholder")
                    return BaseViewController()
                }
                
                return WikiVCFactory.makeWikiSpaceVC(userResolver: userResolver, spaceId: spaceId, url: res.url)
            } else {
                return SKRouter.shared.defaultRouterView(res.url)
            }
        })
        SKRouter.shared.register(checker: { (resource, _) -> (Bool) in
            return URLValidator.isWikiTrashPath(url: resource.url)
        }, interceptor: { _, _ -> (UIViewController) in
            // 回收站，暂未开发
            return WikiTreeTrashViewController()
        })
    }

    func registerWiki(userResolver: UserResolver, url: URL, params: [AnyHashable: Any]?) -> UIViewController {
        guard DocsUrlUtil.getFileToken(from: url, with: .wiki) != nil else {
            DocsLogger.error("[wiki] router error token is nil")
            spaceAssertionFailure("somethine wrong here, so that i just return an empty VC")
            return UIViewController()
        }
                
        var wikiParams: [AnyHashable: Any] = [
            "fragment": url.fragment
        ]
        wikiParams.merge(url.queryParameters) { old, _ in
            return old
        }
        if let params = params {
            wikiParams.merge(params, uniquingKeysWith: { $1 })
        }
        return WikiVCFactory.makeWikiContainerVC(userResolver: userResolver, wikiURL: url, params: params, extraInfo: [:])
    }

    func registerWiki(userResolver: UserResolver, wikiInfo: WikiInfo, params: [AnyHashable: Any]?) -> UIViewController {
        return WikiVCFactory.makeWikiContainerVC(userResolver: userResolver, wikiInfo: wikiInfo, params: params, extraInfo: [:])
    }
}
