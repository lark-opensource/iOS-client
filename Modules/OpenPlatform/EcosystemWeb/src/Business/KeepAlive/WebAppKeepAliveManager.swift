//
//  WebAppKeepAliveManager.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2023/5/30.
//

import Foundation
import RxSwift
import LarkTab
import WebBrowser
import LarkSetting
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import LarkTraitCollection
import LarkWebViewContainer
import LarkQuickLaunchInterface

final class WebAppKeepAliveManager: WebAppKeepAliveService {
    
    static let logger = Logger.ecosystemWebLog(WebAppKeepAliveManager.self, category: "WebAppKeepAliveManager")
    
    private let resolver: Resolver
        
    var keepAliveConfig: WebAppKeepAliveConfig?
    
    var appIds: Set<String> = Set<String>()
    
    var cacheBrowsers: Set<WebBrowser> = Set<WebBrowser>()
    
    private var webAppKeepAliveEnable: Bool
    
    // iphone端保活disable fg,允许在整体保活开启的前提下，单独关闭iPhone 端保活
    private var webAppKeepAlivePhoneDisable: Bool
    
    // iphone端保活disable fg,允许在整体保活开启的前提下，单独关闭iPad C 端保活
    private var webAppKeepAlivePadCDisable: Bool
    
    private var lock = NSLock()
    private let disposeBag = DisposeBag()

    init(_ resolver: UserResolver) {
        self.resolver = resolver
        let keepAliveEnable = resolver.fg.dynamicFeatureGatingValue(with: "openplatform.web.ipad.app.keepalive")
        
        webAppKeepAlivePhoneDisable = resolver.fg.dynamicFeatureGatingValue(with: "openplatform.web.keepalive.iphone.disable")
        
        webAppKeepAlivePadCDisable = resolver.fg.dynamicFeatureGatingValue(with: "openplatform.web.keepalive.ipadc.disable")

        if keepAliveEnable,
           let pageKeeperService = try? self.resolver.resolve(assert: PageKeeperService.self),
           pageKeeperService.hasSetting {
            webAppKeepAliveEnable = true
        } else {
            webAppKeepAliveEnable = false
        }
        
        if webAppKeepAliveEnable {
            Self.logger.info("keepalive webApp keepAlive strategy enable, iphone fg status:\(webAppKeepAlivePhoneDisable), ipadc fg status:\(webAppKeepAlivePadCDisable)")
            if Display.pad, let temporaryTabService = try? self.resolver.resolve(assert: TemporaryTabService.self) {
                temporaryTabService.removeTabsnotification().observeOn(MainScheduler.instance).subscribe(onNext:{ tabCandidates in
                    self.removeCache(tabCandidates: tabCandidates)
                }).disposed(by: self.disposeBag)
            }
        } else {
            Self.logger.info("keepalive webApp keepAlive strategy disable")
        }
    }
    
    deinit {
        Self.logger.info("keepalive manager deinit")
    }
    
    func isWebAppKeepAliveEnable() -> Bool {
        return webAppKeepAliveEnable
    }
    
    // iPhone端是否独立关闭
    func isWebAppKeepAliveIPhoneDisable() -> Bool {
        return webAppKeepAlivePhoneDisable
    }
    
    // iPad c视图是否独立关闭
    func isWebAppKeepAliveIPadCDisable() -> Bool {
        return webAppKeepAlivePadCDisable
    }

    
    func cacheBrowsers(browser: WebBrowser) {
        lock.lock()
        defer {
            lock.unlock()
        }
        Self.logger.info("keepalive cacheBrowser:\(browser.configuration.initTrace?.traceId)")
        cacheBrowsers.insert(browser)
    }
    
    func removeCache(tabCandidates: [TabCandidate]){
        Self.logger.info("keepalive removeCache for close tabs counts:\(tabCandidates.count)")
        for tabCandidate in tabCandidates {
            if tabCandidate.bizType == .WEB_APP || tabCandidate.bizType == .WEB {
                lock.lock()
                var deleteCaches = [WebBrowser]()
                for cacheWebBrowser in cacheBrowsers {
                    let tabContainable = cacheWebBrowser as TabContainable
                    if cacheWebBrowser.configuration.scene == .temporaryTab,
                       tabContainable.tabID == tabCandidate.id {
                        deleteCaches.append(cacheWebBrowser)
                    }
                }
                lock.unlock()
                for deleteBrowser in deleteCaches {
                    Self.logger.info("keepalive start removePage for close tabs, browser:\(deleteBrowser.configuration.initTrace?.traceId))")
                    if let pageKeeperService = try? resolver.resolve(assert: PageKeeperService.self) {
                        pageKeeperService.removePage(deleteBrowser, force: true, notice: true) { result in
                            Self.logger.info("keepalive end removePage for close tabs, browser:\(deleteBrowser.configuration.initTrace?.traceId), result:\(result)")
                        }
                    }
                }
            }
        }

    }
    
    func removeWebAppBrowser(browser: WebBrowser) {
        Self.logger.info("keepalive  start remove cached browser:\(browser.configuration.initTrace?.traceId)")
        lock.lock()
        defer {
            lock.unlock()
        }
        if cacheBrowsers.contains(browser){
            Self.logger.info("keepalive remove cachedbrowser:\(browser.configuration.initTrace?.traceId)")
            cacheBrowsers.remove(browser)
        }
    }
    
    func getWebAppBrowser(identifier: String, scene: PageKeeperScene, tabContainableIdentifier: String? ) -> WebBrowser? {
        if !webAppKeepAliveEnable {
            Self.logger.info("keepalive webAppKeepAliveEnable:\(webAppKeepAliveEnable)")
            return nil
        }
        if identifier.isEmpty {
            Self.logger.info("keepalive identifier empty")
            return nil
        }
        if let tabContainableIdentifier = tabContainableIdentifier, !tabContainableIdentifier.isEmpty {
            lock.lock()
            let cachingBrowsers = cacheBrowsers
            lock.unlock()
            for cacheWebBrowser in cachingBrowsers {
                let cacheBrowserScene = createKeepAliveScene(browser: cacheWebBrowser)
                if cacheWebBrowser.tabContainableIdentifier == tabContainableIdentifier, scene == cacheBrowserScene {
                    // 从tab上点击过来的，直接复用
                    Self.logger.info("keepalive tab browser reuse for:\(tabContainableIdentifier)")
                    return cacheWebBrowser
                }
            }
        }
        if let pagekeepService = try? resolver.resolve(assert: PageKeeperService.self), let browser = pagekeepService.getCachePage(id: identifier, scene: scene.rawValue) as? WebBrowser {
            Self.logger.info("keepalive get cache browser:\(browser.configuration.initTrace?.traceId)")
            if let tabContainableIdentifier = tabContainableIdentifier, !tabContainableIdentifier.isEmpty, !browser.tabContainableIdentifier.isEmpty, tabContainableIdentifier != browser.tabContainableIdentifier {
                // 上面通过tabContainableIdentifier 没有取到缓存vc,然后下面又拿到了带tabContainableIdentifier的vc
                // 这里属于异常的场景,通过  ，两个URL一样，但是唯一标识不一样，直接创建新的vc
                Self.logger.info("keepalive get cache browser fail , has diff tabContainableIdentifier")
                return nil
            }
            return browser
        }
        Self.logger.info("keepalive get cache browser nil")
        return nil
    }
    
    func isAppInKeppAliveConfigList(appId:String) -> Bool {
        return appIds.contains(appId)
    }
    
    func createKeepAliveIdentifier(browser: WebBrowser) -> String {
        return createKeepAliveIdentifier(fromScene: browser.configuration.fromScene, scene: browser.configuration.scene, appId: browser.configuration.appId, url:browser.browserURL, isCollapsed: browser.initIsCollapsed, tabContainableIdentifier: browser.tabContainableIdentifier)
    }

    func createKeepAliveIdentifier(fromScene: WebBrowserFromScene, scene: WebBrowserScene, appId: String?, url: URL?, isCollapsed: Bool, tabContainableIdentifier: String?) -> String {
        Self.logger.info("keepalive createKeepAliveIdentifier, fromScene\(fromScene), scene:\(scene), appId:\(String(describing: appId)), isCollapsed\(isCollapsed)")
        if scene == .temporaryTab {
            // 标签页场景，所有网页都保活
            // url 维度保活
            if let url = url, !url.absoluteString.isEmpty {
                LKWSecurityLogUtils.webSafeAESURL(url.absoluteString ?? "", msg: "createKeepAliveIdentifier")
                return "ipadr_" + url.absoluteString
            }
        } else {
            if Display.phone, scene == .normal, !webAppKeepAlivePhoneDisable, let tabContainableIdentifier = tabContainableIdentifier, !tabContainableIdentifier.isEmpty, (fromScene == .launcherFromMain || fromScene == .launcherFromQuick) {
                return "iphone_" + tabContainableIdentifier
            } else if Display.pad , isCollapsed, !webAppKeepAlivePadCDisable, let tabContainableIdentifier = tabContainableIdentifier, !tabContainableIdentifier.isEmpty , (fromScene == .launcherFromMain || fromScene == .launcherFromQuick){
                return "ipadc_" + tabContainableIdentifier
            }
        }
        Self.logger.info("keepalive create identifier failed")
        return ""
    }
    
    func createKeepAliveScene(browser: WebBrowser) -> PageKeeperScene {
        return createKeepAliveScene(fromScene: browser.configuration.fromScene, scene: browser.configuration.scene, appId: browser.configuration.appId, url:browser.browserURL, isCollapsed: browser.initIsCollapsed, tabContainableIdentifier: browser.tabContainableIdentifier)
    }
    
    func createKeepAliveScene(fromScene: WebBrowserFromScene, scene: WebBrowserScene, appId: String?, url: URL?, isCollapsed: Bool, tabContainableIdentifier: String?) -> PageKeeperScene {
        Self.logger.info("keepalive createKeepAliveScene, fromScene\(fromScene), scene:\(scene), appId:\(String(describing: appId)), isCollapsed\(isCollapsed)")
        if scene == .temporaryTab {
            // 标签页场景，所有网页都保活
            return PageKeeperScene.temporary
        } else {
            if Display.phone, scene == .normal, !webAppKeepAlivePhoneDisable, let tabContainableIdentifier = tabContainableIdentifier, !tabContainableIdentifier.isEmpty, (fromScene == .launcherFromMain || fromScene == .launcherFromQuick) {
                return .main
            } else if Display.pad , isCollapsed, !webAppKeepAlivePadCDisable, let tabContainableIdentifier = tabContainableIdentifier, !tabContainableIdentifier.isEmpty , (fromScene == .launcherFromMain || fromScene == .launcherFromQuick) {
                return .main
            }
        }
        Self.logger.info("keepalive create scene failed")
        return .normal
    }
    
}
