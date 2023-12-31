//
//  DocModule.swift
//  SKDoc
//
//  Created by lijuyou on 2021/1/19.
//  


import Foundation
import EENavigator
import SKCommon
import SKFoundation
import SKInfra
import SKBrowser
import LarkContainer

public final class DocModule: ModuleService {

    public init() {}

    public func setup() {
        DocsLogger.info("DocModule setup")
        DocsContainer.shared.register(DocModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)
    }

    public func registerURLRouter() {
        //syncedBlock独立页路由
        SKRouter.shared.register(types: [.sync]) { resource, _, _ -> UIViewController in
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            return SyncContainerViewController(userResolver: userResolver, url: resource.url)
        }
    }

    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        switch type {
        case .individualBusiness: // 纯 doc 才能用的业务，放在这里
            reisgterDocSevice(ui: ui, model: model, navigator: navigator, register: register)
        default:
            break
        }
    }
    
    private func reisgterDocSevice(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        register(BlockMenuService(ui: ui, model: model, navigator: navigator))
        register(SmartComposeService(ui: ui, model: model, navigator: navigator))
        register(CodeBlockService(ui: ui, model: model, navigator: navigator))
        register(UtilCatalogService(ui: ui, model: model, navigator: navigator))
        register(DocsCoverService(ui: ui, model: model, navigator: navigator))
        register(ReadEditModeService(ui: ui, model: model, navigator: navigator))
        register(DocXOopsService(ui: ui, model: model, navigator: navigator))
        register(EnterpriseTopicService(ui: ui, model: model, navigator: navigator))
        register(UtilVoteService(ui: ui, model: model, navigator: navigator))
        register(HyperLinkService(ui: ui, model: model, navigator: navigator))
        register(DocComponentInvokeNativeService(ui: ui, model: model, navigator: navigator))
        register(DocXBlockInfoService(ui: ui, model: model, navigator: navigator))
        register(SyncedBlockService(ui: ui, model: model, navigator: navigator))
    }
}
