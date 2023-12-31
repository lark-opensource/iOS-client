//
//  SKBrowserDependency.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/12/26.
//  


import Foundation
import SKCommon
import SKUIKit
import SpaceInterface
import SKFoundation
import LarkContainer

public extension CCMExtension where Base == UserResolver {

    var browserDependency: SKBrowserDependency? {
        if CCMUserScope.docEnabled {
            let obj = try? base.resolve(type: SKBrowserDependency.self)
            return obj
        } else {
            let obj = try? Container.shared.resolve(type: SKBrowserDependency.self)
            return obj
        }
    }
}

public protocol SKBrowserDependency {
    func getBrowserViewControllerType(_ docsType: DocsType) -> BrowserViewController.Type

    func getBrowserViewPluginType(_ docsType: DocsType) -> BrowserViewPlugin.Type?

    /// 判断是否是Wiki的TopVC
    func isWikiTopViewController(_ curVC: UIViewController, topBrowser: UIViewController) -> Bool

    func defaultDriveImagePreviewStrategy(for windowSize: CGSize) -> SKImagePreviewStrategy

    func isDriveMainViewController(_ viewController: UIViewController) -> Bool

    func getWikiInfo(by wikiToken: String, version: String?) -> WikiInfo?

    func registerDocService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void)

    func registerSheetService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void)

    func registerMindnoteService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void)
    
    func registerSlidesService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void)
    
    func registerVersion(_ url: URL, params: [AnyHashable: Any]?) -> UIViewController
}
