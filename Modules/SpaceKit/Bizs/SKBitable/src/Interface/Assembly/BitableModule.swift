//
//  BitableModule.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/8.
//


import Foundation
import SKCommon
import SKFoundation
import LarkReleaseConfig
import SpaceInterface
import SKInfra
import LarkContainer

public final class BitableModule: ModuleService {

    public init() { }
    
    public func setup() {
        DocsLogger.info("BitableModule setup")
        DocsContainer.shared.register(BitableModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)
        DocsContainer.shared.register(BTUploadAttachCacheCleanable.self, factory: { _ in
            return BTUploadAttachCacheManager.shared
        }).inObjectScope(.container)
    }

    public func registerURLRouter() {
        // 针对 bitable.feishu.cn/appXXXXX 的单品链接做适配，避免在 webview 中两跳
        // https://bytedance.feishu.cn/docs/doccnKc17OHYoJKTq0YBvDk14Fh
        SKRouter.shared.register(checker: { resource, _ in
            return URLValidator.isBitableAppURL(resource.url)
        }, interceptor: { (resource, params) -> (UIViewController) in
            let originURL = resource.url
            let path = originURL.path
            // bitable 单品链接只考虑国内 SaaS 域名，海外、KA 场景固定访问 feishu 域名
            var urlString = "https://www.feishu.cn/base\(path)"
            if let query = originURL.query {
                urlString += "?\(query)"
            }
            guard let redirectURL = URL(string: urlString) else {
                return SKRouter.shared.defaultRouterView(originURL)
            }
            let (redirectVC, _) = SKRouter.shared.open(with: redirectURL, params: params)
            guard let viewController = redirectVC else {
                return SKRouter.shared.defaultRouterView(originURL)
            }
            return viewController
        })

        // 如果私有化有重大问题，会关闭 FG，if 条件为 true，进入兜底页
        if !DocsType.enableDocTypeDependOnFeatureGating(type: .bitable) {
            SKRouter.shared.register(types: [.bitable]) { _, _, _ -> UIViewController in
                return BTUnsupportedViewController()
            }
        }
    }
    
    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        switch type {
        case .commonBusiness: // doc、docX、sheets、bitable 中都要使用到的放在这里
            register(BTJSService(ui: ui, model: model, navigator: navigator))
            register(BTTipsService(ui: ui, model: model, navigator: navigator))
            register(BTPanelService(ui: ui, model: model, navigator: navigator))
            register(BTDDUIService(ui: ui, model: model, navigator: navigator))
            register(BTBaseReportService(ui: ui, model: model, navigator: navigator))
            register(BTViewContainerService(ui: ui, model: model, navigator: navigator))
            register(BlockCatalogService(ui: ui, model: model, navigator: navigator))
            register(BTContainerJSService(ui: ui, model: model, navigator: navigator))
            register(BTAdPermJSService(ui: ui, model: model, navigator: navigator))
            register(BTRecordJSService(ui: ui, model: model, navigator: navigator))
            if UserScopeNoChangeFG.XM.nativeCardViewEnable {
                register(BTNativeViewService(ui: ui, model: model, navigator: navigator))
            }
        case .individualBusiness: // 只有独立 bitable 才会用到的放在这里
            break
        default:
            break
        }
    }
}
