//
//  CommonModule.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/9.
//

import Foundation
import SKFoundation
import EENavigator
import RunloopTools
import SKInfra
import LarkRustClient
import SpaceInterface
import LarkContainer

public final class CommonModule: ModuleService {
    private var adjustSettingsHandler: AdjustSettingsHandler?

    public init() {}

    public func setup() {
        DocsLogger.info("CommonModule setup")

        // 文档操作记录上报逻辑
        DocsContainer.shared.register(DocumentActivityReporter.self) { _ in
            DocumentActivityManager.shared
        }.inObjectScope(.container)

        DocsContainer.shared.register(WorkspaceCrossRouteStorage.self) { _ in
            WorkspaceCrossRouteStorage()
        }.inObjectScope(.user)

        DocsContainer.shared.register(WorkspaceCrossRouter.self) { _ in
            WorkspaceCrossRouter()
        }.inObjectScope(.user)
        
        Container.shared.register(WebFeatureGating.self) { _ in
            WebFeatureGating()
        }.inObjectScope(CCMUserScope.userScope)
        
        let userContainer = Container.shared.inObjectScope(CCMUserScope.userScope)
        userContainer.register(PowerOptimizeConfigProvider.self) {
            PowerOptimizeConfigImpl(userResolver: $0)
        }
        
        //从DocsContainer迁移出来的注册
        registerAllServices()
        
        // 提前单例初始化时机，注册 userLogin logout 事件
        DocumentActivityManager.shared.config()
        registerRouterInterceptor()
        _ = PowerConsumptionExtendedStatistic.shared // 功耗检测工具
    }

    public func registerURLRouter() {
        // 注意，在 Lark 中，scheme 为 lark、feishu 的情况，主端为了保证飞书和lark的兼容性，会在匹配时将 URL 的 scheme 移除
        // 注册时，需要去掉 scheme 再注册
        // 租户无权限：lark://ccm.bytedance.net/gpe/operation/quota?suite_type=X
        Navigator.shared.registerRoute(plainPattern: "//ccm.bytedance.net/gpe/operation/quota") { request, response in
            var suiteType: Int?
            if let typeFromQuery = request.parameters["suite_type"] as? Int {
                suiteType = typeFromQuery
            } else if let typeString = request.parameters["suite_type"] as? String,
                      let typeFromQuery = Int(typeString) {
                suiteType = typeFromQuery
            } else {
                spaceAssertionFailure("unable to parse suite_type from quota url")
            }
            let controller = DocumentActivityUpgradeController(suiteType: suiteType)
            response.end(resource: controller)
        }

        // 用户无权限：lark://ccm.bytedance.net/gpe/operation/no_permission
        Navigator.shared.registerRoute(plainPattern: "//ccm.bytedance.net/gpe/operation/no_permission") { _, response in
            let controller = DocumentActivityNoPermissionController()
            response.end(resource: controller)
        }

        // CCM 通用 Lynx 路由 ccm-lynx://lynxview/card_path
        // 举例：ccm-lynx://lynxview/pages/ccm-demo/template.js
        Navigator.shared.registerRoute { url in
            guard url.scheme == "ccm-lynx" else {
                return false
            }
            guard url.host == "lynxview" else {
                return false
            }
            return true
        } _: { request, response in
            SKLynxRouteHandler.handle(request: request, response: response)
        }

        Navigator.shared.registerRoute(match: { url in
            guard url.scheme == "ccm-lynx",
                    url.host == "lynxview",
                    url.path == "/pages/adjust-settings-panel/template.js"
            else {
                return false
            }
            return true
        }, priority: .high) { request, response in
            let vc = AdjustSettingsHandler.createController(request: request)
            response.end(resource: vc)
        }

        Navigator.shared.registerRoute(type: AdjustSettingsBody.self) { [weak self] body, request, response in
            guard let self = self else { return }
            let url = URL(string: body.docURL.fromBase64() ?? "")
            let isWiki = url?.docs.isWikiDocURL ?? false
            let docsType = ShareDocsType(rawValue: body.objType)
            self.adjustSettingsHandler = AdjustSettingsHandler(token: body.objToken, type: docsType, isSpaceV2: true, isWiki: isWiki)
            self.adjustSettingsHandler?.toAdjustSettingsIfEnabled(sceneType: .imShareExternalMember(body.targetTenantID), topVC: request.from.fromViewController) { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .success, .disabled:
                    self.adjustSettingsHandler?.inviteMemberAndRefreshCard(chatId: body.chatID, chatType: body.chatType, docCardId: body.docCardID, topVC: request.from.fromViewController)
                default: break
                }
            }
        }
    }
    
    public func registerRouterInterceptor() {
        
        // lark feed或者push进来时，提前拉取Feed数据
        SKRouter.shared.register(checker: { (resource, params) -> (Bool) in
            guard let params = params else { return false }
            let fromFeed = (params["docs_entrance"] as? String) == "docs_feed"
            let fromPush = (params["is_from_pushnotification"] as? Bool) ?? false
            let timestamp = (params["timestamp"] as? Double) ?? 0
            if fromFeed || fromPush {
                DocsLogger.feedInfo("loadFeedData fromFeed:\(fromFeed) fromPush:\(fromPush)")
                DocsFeedService.loadFeedData(url: resource.url, timestamp: timestamp)
            }
            return false
        }, interceptor: { (_, _) -> (UIViewController) in
            // 上面返回false时，这里不会执行
            return UIViewController()
        })

        // workspace 重定向
        SKRouter.shared.register { resource, params in
            guard let workspaceRouter = DocsContainer.shared.resolve(WorkspaceCrossRouter.self) else {
                return nil
            }
            return workspaceRouter.redirect(resource: resource, params: params)
        }
        
        // 域名替换重定向
        SKRouter.shared.register { resource, params in
            guard UserScopeNoChangeFG.HZK.correctDomainEnable else {
                return nil
            }
            guard let redirectUrl =  URLValidator.replaceOriginUrlIfNeed(originUrl: resource.url) else {
                //没有替换域名，返回空，不做任何处理
                return nil
            }
            return (redirectUrl, params)
        }
        
        
        SKRouter.shared.register { resource, params in
            guard UserScopeNoChangeFG.PLF.authEmailEnable else {
                DocsLogger.info("authEmailEnable fg is disabled")
                return false
            }
            guard let queryParams = resource.url.docs.queryParams,
                  let _ = queryParams["invite"] else {
                DocsLogger.info("It is not email invite url")
                return false
            }
            return true
        } interceptor: { resource, params in
            EmailDocRedirector.redirectToVCAfterBindEmail(resource: resource, params: params)
            return nil
        }
    }

    public func userDidLogin() {
        RunloopDispatcher.shared.addTask(priority: .low) {
            DocsLogger.info("cpu.task: workspace.crossRouter --- leisure preloading storage")
            // 触发 storage 类的构造方法，内部会执行预加载
            _ = DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)
        }.waitCPUFree().withIdentify("CommonModule.asyncLeisure")
    }
    
    
    func registerAllServices() {
        
        let userContainer = Container.shared.inObjectScope(CCMUserScope.userScope)
        
        DocsContainer.shared.register(DocsOfflineSyncManager.self, factory: { (_) -> DocsOfflineSyncManager in
            let dd = DocsOfflineSyncManager.shared
            return dd
        }).inObjectScope(.container)

        DocsContainer.shared.register(DocsBulletinManager.self, factory: { (_) -> DocsBulletinManager in
            let bulletinManager = DocsBulletinManager()
            return bulletinManager
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(RNMangerAPI.self, factory: { _ in return RNManager.manager }).inObjectScope(.container)
        
        userContainer.register(DocPreloaderManagerAPI.self) {
            return DocPreloaderManager(userResolver: $0)
        }

        DocsContainer.shared.register(NewCacheAPI.self, factory: { (_) -> NewCacheAPI in
            let cache = NewCache.shard
//            cache.clear()
            return cache
        }).inObjectScope(.container)
        DocsContainer.shared.register(ClientVarMetaDataManagerAPI.self, factory: { (_) -> ClientVarMetaDataManagerAPI in
            return ClientVarMetaDataManager()
        }).inObjectScope(.container)

        DocsContainer.shared.register(SKCreateEnableTypesCache.self, factory: { (_) -> SKCreateEnableTypesCache in
            return SKCreateEnableTypesCacheImpl()
        }).inObjectScope(.container)

        DocsContainer.shared.register(OnboardingManager.self, factory: { (_) -> OnboardingManager in
            return OnboardingManager()
        }).inObjectScope(.container)

        DocsContainer.shared.register(SpaceThumbnailManager.self, factory: { (_) -> SpaceThumbnailManager in
            return SpaceThumbnailManager()
        }).inObjectScope(.container)
        
        DocsContainer.shared.register(ListConfigAPI.self, factory: { (_) -> ListConfigAPI in
            return ListConfig()
        }).inObjectScope(.container)

        DocsContainer.shared.register(DomainConfigRNWatcher.self, factory: { (_) -> DomainConfigRNWatcher in
            return DomainConfigRNWatcher()
        }).inObjectScope(.container)

        DocsContainer.shared.register(SimpleModeManager.self, factory: { (_) -> SimpleModeManager in
            return SimpleModeManager()
        }).inObjectScope(.container)

        DocsContainer.shared.register(PermissionManager.self, factory: { _ in
            return PermissionManager()
        }).inObjectScope(.container)

        DocsContainer.shared.register(DlpManager.self, factory: { _ in
            return DlpManager()
        }).inObjectScope(.container)

        userContainer.register(CCMUserSettings.self) { userResolver in
            CCMUserSettings(userResolver: userResolver)
        }
    }

}
