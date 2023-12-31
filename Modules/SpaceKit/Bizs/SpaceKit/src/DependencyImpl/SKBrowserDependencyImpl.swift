//
//  SKBrowserDependencyImpl.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/12/27.
//  


import Foundation
import SKCommon
import SKBrowser
import SKDoc
import SKSpace
import SKDrive
import SKMindnote
import SKSheet
import SKUIKit
import SKWikiV2
import SKBitable
import LarkReleaseConfig
import SKFoundation
import SpaceInterface
import SKInfra
import SKSlides
import SKWorkspace
import LarkContainer

class SKBrowserDependencyImpl: SKBrowserDependency {
    
    let userResolver: UserResolver? // nil表示单例
    
    init(userResolver: UserResolver?) {
        self.userResolver = userResolver
    }
    
    func getBrowserViewControllerType(_ docsType: DocsType) -> BrowserViewController.Type {
        switch docsType {
        case .doc:
            return DocBrowserViewController.self
        case .docX:
            #if canImport(SKEditor)
            if EditorManager.shared.nativeDocxEnable {
                return NativeDocBrowserViewController.self
            } else {
                return DocBrowserViewController.self
            }
            #else
            return DocBrowserViewController.self
            #endif
        case .sheet:
            return SheetBrowserViewController.self
        case .bitable, .baseAdd:
            return BitableBrowserViewController.self
        case .mindnote:
            return MindNoteBrowserViewController.self
        case .slides:
            return SlidesBrowserViewController.self
        default:
            return BrowserViewController.self
        }
    }

    func getBrowserViewPluginType(_ docsType: DocsType) -> BrowserViewPlugin.Type? {
        switch docsType {
        case .doc, .docX:
            return DocBrowserViewPlugin.self
        default:
            return nil
        }
    }

    func isWikiTopViewController(_ curVC: UIViewController, topBrowser: UIViewController) -> Bool {
        return WikiVCFactory.isTopViewController(curVC, topBrowser: topBrowser)
    }

    func defaultDriveImagePreviewStrategy(for windowSize: CGSize) -> SKImagePreviewStrategy {
        return DriveImagePreviewStrategy.defaultStrategy(for: windowSize)
    }

    func isDriveMainViewController(_ viewController: UIViewController) -> Bool {
        return DriveVCFactory.shared.isDriveMainViewController(viewController)
    }

    func getWikiInfo(by wikiToken: String, version: String?) -> WikiInfo? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        guard let wikiSrtorageAPI = try? userResolver.resolve(assert: WikiStorageBase.self) else {
            return nil
        }
        return wikiSrtorageAPI.getWikiInfo(by: wikiToken)
    }

    func registerDocService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        DocsContainer.shared.resolve(DocModule.self)?.registerJSServices(type: .individualBusiness, ui: ui, model: model, navigator: navigator, register: register)
    }

    func registerSheetService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        DocsContainer.shared.resolve(SheetModule.self)?.registerJSServices(type: .individualBusiness, ui: ui, model: model, navigator: navigator, register: register)
    }

    func registerMindnoteService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        DocsContainer.shared.resolve(MindNoteModule.self)?.registerJSServices(type: .individualBusiness, ui: ui, model: model, navigator: navigator, register: register)
    }
    
    func registerSlidesService(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        DocsContainer.shared.resolve(SlidesModule.self)?.registerJSServices(type: .individualBusiness, ui: ui, model: model, navigator: navigator, register: register)
    }
    
    func registerVersion(_ url: URL, params: [AnyHashable: Any]?) -> UIViewController {
        guard DocsUrlUtil.getFileToken(from: url) != nil else {
            return UIViewController()
        }
        DocsLogger.info("start open version view", component: LogComponents.version)
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: true)
        let vm = VersionContainerViewModel(url: url, params: params, userResolver: userResolver ?? ur)
        return VersionsContainerViewController(viewModel: vm)
    }
}
