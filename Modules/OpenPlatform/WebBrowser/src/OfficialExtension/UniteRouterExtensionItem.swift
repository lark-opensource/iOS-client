//
//  UniteRouterExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/4.
//

import EENavigator
import LarkCloudScheme
import LarkSceneManager
import LarkSetting
import LarkSplitViewController
import LarkUIKit
import LarkWebViewContainer
import LKCommonsLogging
import WebKit
import UniverseDesignToast

/// 统一路由拦截
final public class UniteRouterExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "UniteRouter"
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = UniteRouterWebBrowserNavigation()
    
    public init() {}
}

final public class UniteRouterWebBrowserNavigation: WebBrowserNavigationProtocol {
    var optimizeNavigationPolicyEnbale : Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizenavigationpolicy.enable"))// user:global
    }()
    static func isBlobURLNavigationEnabled() -> Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.download.blob_preview.disabled"))// user:global
    }
    
    static var routerCache : Set<URL> = []
    static let logger = Logger.webBrowserLog(UniteRouterWebBrowserNavigation.self, category: "UniteRouterWebBrowserNavigation")
    
    public func browser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        let request = navigationAction.request
        let url = request.url
        let traceId = browser.webview.opTraceId()
        if LarkWebSettings.lkwEncryptLogEnabel {
            var targatMainFrame = "unknown"
            if let frame = navigationAction.targetFrame {
                targatMainFrame = frame.isMainFrame ? "true" : "false"
            }
            Self.logger.lkwlog(level: .info, "handleRequst for url{\(String(describing: url?.safeURLString))}, target frame isMainFrame:\(targatMainFrame)", traceId: traceId)
        } else {
            Self.logger.lkwlog(level: .info, "handleRequst for url{\(String(describing: url?.safeURLString))}, targetFrame{\(String(describing: navigationAction.targetFrame))}", traceId: traceId)
        }
        
        if url?.scheme == BrowserInternalScheme {
            return .allow
        }

        //  此处接入了主端的「云控」，拦截粒度是scheme
        //  如果需要进行URL级别的拦截，可以联系主端进行「URL级别」的云控开发
        if let url = url,
           CloudSchemeManager.shared.canOpen(url: url) {
            if canCloseBrowser(browser: browser, navigationAction: navigationAction) {
                browser.closeBrowser()
            }
            
            let closeSelf = browser.canCloseSelf(with: url, scene: .url_redirect)
            if (closeSelf) {
                //埋点统计
                browser.closeSelfMonitor(with: url, scene: .url_redirect)
                CloudSchemeManager.shared.open(url, options: [:], completionHandler: nil)
                browser.delayRemoveSelfInViewControllers()
            } else {
                //(默认，不关闭自身)原线上逻辑
                CloudSchemeManager.shared.open(url, options: [:], completionHandler: nil)
            }
            return .cancel
        }

        // 针对iframe场景，不再拦截url做额外处理，满足iframe内可以直接加载Docs而不是跳转Docs容器的需求 code from houzhiyou
        if let frame = navigationAction.targetFrame, frame.isMainFrame == false {
            Self.logger.lkwlog(level: .info, "detect iframe scene", traceId: traceId)
            return .allow
        }

        if let url = url {
            // 若 base64 图片, 则网页容器使用HTML加载页面
            let urlStr = url.absoluteString
            if previewBase64ImageEnabled() && browser.isBase64Image(urlStr) {
                let htmlStr: String
                if let settings = try? SettingManager.shared.setting(with: .make(userKeyLiteral: "web_settings")),// user:global
                   let base64CloudHtml = settings["base64_html_template"] as? String {
                    htmlStr = String(format: base64CloudHtml, urlStr)
                } else {
                    htmlStr = "<html><head><title>Image</title></head><body><img src='\(urlStr)'></body></html>"
                }
                browser.webview.loadHTMLString(htmlStr, baseURL: URL(fileURLWithPath: ""))
                return .allow
            }
            let value = self.canOpenInCurrentBrowser(url: url,browser: browser)
            if value {
                return .allow
            } else {
                if canCloseBrowser(browser: browser, navigationAction: navigationAction) {
                    browser.replaceBrowser(targetURL: url, fromURL: browser.browserURL)
                } else {
                    Self.logger.lkwlog(level: .info, "controller.openURL Navigator.shared.push \(url.safeURLString)", traceId: traceId)
                    
                    let closeSelf = browser.canCloseSelf(with: url, scene: .url_redirect)
                    let appId = browser.currrentWebpageAppID() ?? ""
                    if closeSelf {
                        browser.closeSelfMonitor(with: url, scene: .url_redirect)
                        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrower.redirectblank.optimize.disable")) {
                            Navigator.shared.push(// user:global
                                url,
                                context: [
                                    "from": browser.browserURL?.absoluteString,
                                    // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                                    "lk_web_from": "webbrowser",
                                    "open_doc_desc": browser.browserURL?.absoluteString ?? "",
                                    "open_doc_source": "web_applet",
                                    "open_doc_app_id": appId,
                                ],
                                from: browser)
                            browser.delayRemoveSelfInViewControllers()
                        } else {
                            browser.replaceBrowser(targetURL: url, fromURL: browser.browserURL)
                        }
                    } else {
                        //(默认，不关闭自身)原线上逻辑
                        Navigator.shared.push(// user:global
                            url,
                            context: [
                                "from": browser.browserURL?.absoluteString,
                                // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                                "lk_web_from": "webbrowser",
                                "open_doc_desc": browser.browserURL?.absoluteString ?? "",
                                "open_doc_source": "web_applet",
                                "open_doc_app_id": appId,
                            ],
                            from: browser
                        )
                        
                    }
                }
                return .cancel
            }
        }
        return .cancel
    }
    
    private func canCloseBrowser(browser: WebBrowser, navigationAction: WKNavigationAction) -> Bool {
        if browser.configuration.enableRedirectOptimization, browser.webview.backForwardList.backList.isEmpty, browser.webview.backForwardList.forwardList.isEmpty, browser.webview.backForwardList.currentItem == nil, navigationAction.sourceFrame.isMainFrame {
            if let url = navigationAction.request.url, Navigator.shared.response(for: url, test: true).parameters["_canCloseBrowser"] as? Bool == true {// user:global
                return true
            }
            return checkURLVaild(url: navigationAction.request.url)
        } else {
            return false
        }
    }
    
    private func checkURLVaild(url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        guard let bro = LarkWebSettings.shared.settings?["browser"] as? [String: Any], let regs = bro["supportedRedirectOptimizationReg"] as? [String] else {
            return false
        }
        if regs.contains(where: { reg in
            do {
                let re = try NSRegularExpression(pattern: reg)
                let result = re.matches(url.absoluteString)
                return !result.isEmpty
            } catch {
                return false
            }
        }) {
            return true
        } else {
            return false
        }
    }
    
    private func canOpenInCurrentBrowser(url: URL,browser:WebBrowser) -> Bool {
        if(self.optimizeNavigationPolicyEnbale && browser.bizType == .larkWeb){
            if Self.routerCache.contains(url) {
                return true
            }else{
                let result = browser.canOpenInCurrentBrowser(url: url)
                if(result == true){
                    Self.routerCache.insert(url)
                }
                return result
            }
        }else{
            return browser.canOpenInCurrentBrowser(url: url)
        }
    }
    
    private func previewBase64ImageEnabled() -> Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.download.disable_preview_base64"))// user:global
    }
}

extension WebBrowser {
    //  此函数需要等路由统一提供能力后迁移过去
    // 历史背景https://bytedance.feishu.cn/wiki/wikcnYnGdlbh4aSxAv2YhMYUw7b
    // 打开的URL会自动302跳转，且跳转链接能够被其他业务路由处理，这个时候自动关闭当前webbrowser空白页
    func replaceBrowser(targetURL: URL, fromURL: URL?) {
        let traceId = webview.opTraceId()
        if Display.pad {
            if let navigationController = navigationController {
                if navigationController.viewControllers.count == 1, navigationController.viewControllers.first == self {
                    if isMainScene() {
                        if self.configuration.scene == .temporaryTab {
                            // ipad 标签页场景关闭空白页逻辑
                            let routerContext = [
                                "from": fromURL?.absoluteString,
                                "animatedValueFromRouter": false,
                                // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                                "lk_web_from": "webbrowser"
                            ] as [String : Any]
                            Navigator.shared.push(targetURL, context: routerContext, from: self, animated: false, completion: nil)
                            self.closeBrowser()
                        } else if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController { // user:global
                            let empty = LarkSplitViewController.SplitViewController.DefaultDetailController()
                            Navigator.shared.showDetail(empty, from: fromVC) {// user:global
                                
                                let routerContext = [
                                    "from": fromURL?.absoluteString,
                                    "animatedValueFromRouter": false,
                                    // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                                    "lk_web_from": "webbrowser"
                                ]
                                Navigator.shared.showDetail(targetURL, context:routerContext , wrap: LkNavigationController.self, from: empty, completion: nil)// user:global
                            }
                        } else {
                            Self.logger.lkwlog(level: .error, "Navigator.shared.mainSceneWindow?.fromViewController is nil, show detail empty has no from", traceId: traceId)
                            let routerContext = [
                                "from": fromURL?.absoluteString,
                                "animatedValueFromRouter": false,
                                // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                                "lk_web_from": "webbrowser"
                            ] as [String : Any]
                            Navigator.shared.push(targetURL, context: routerContext, from: navigationController, animated: false, completion: nil)// user:global
                        }
                    } else {
                        let routerContext = [
                            "from": fromURL?.absoluteString,
                            "animatedValueFromRouter": false,
                            // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                            "lk_web_from": "webbrowser"
                        ] as [String : Any]
                        Navigator.shared.push(targetURL, context: routerContext, from: navigationController, animated: false, completion: nil)// user:global
                    }
                } else {
                    Navigator.shared.pop(from: self, animated: false) { [weak navigationController] in // user:global
                        guard let navigationController = navigationController else { return }
                        let routerContext = [
                            "from": fromURL?.absoluteString,
                            "animatedValueFromRouter": false,
                            // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                            "lk_web_from": "webbrowser"
                        ] as [String : Any]
                        Navigator.shared.push(targetURL, context: routerContext, from: navigationController, animated: false, completion: nil)// user:global
                    }
                }
            } else {
                let routerContext = [
                    "from": fromURL?.absoluteString,
                    "animatedValueFromRouter": false,
                    // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                    "lk_web_from": "webbrowser"
                ] as [String : Any]
                Self.logger.lkwlog(level: .error, "navigationController is nil, from use self", traceId: traceId)
                Navigator.shared.push(targetURL, context: routerContext, from: self, animated: false, completion: nil)// user:global
            }
        } else {
            if let from = navigationController {
                Navigator.shared.pop(from: self, animated: false) { [weak from] in // user:global
                    guard let from = from else { return }
                    let routerContext = [
                        "from": fromURL?.absoluteString,
                        "animatedValueFromRouter": false,
                        // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                        "lk_web_from": "webbrowser"
                    ] as [String : Any]
                    Navigator.shared.push(targetURL, context: routerContext, from: from, animated: false, completion: nil)// user:global
                }
            } else {
                let routerContext = [
                    "from": fromURL?.absoluteString,
                    "animatedValueFromRouter": false,
                    // 单纯为了兼容上面这个from被历史乱用的问题，其他业务场景from都是固定值，这里就变成动态的值了, 目前没法枚举都有哪些地方在消费这个from，只能新增kv
                    "lk_web_from": "webbrowser"
                ] as [String : Any]
                Self.logger.lkwlog(level: .error, "navigationController is nil, from use self", traceId: traceId)
                Navigator.shared.push(targetURL, context: routerContext, from: self, animated: false, completion: nil)// user:global
            }
        }
    }
    
    private func isMainScene() -> Bool {
        if #available(iOS 13, *) {
            if let sceneInfo = currentScene()?.sceneInfo {
                return sceneInfo.isMainScene()
            } else {
                return true
            }
        } else {
            return true
        }
    }
    
    func canOpenInCurrentBrowser(url: URL) -> Bool {
        //  目前给passport单独开的入口，属于历史债务，回头通过extension统一迁移到passport管理，非passport请勿设置，如果乱设置导致线上事故，请revert代码，写case study，做复盘，承担事故责任
        if configuration.notUseUniteRoute {
            return true
        }
        if url.scheme == BrowserInternalScheme {
            return true
        }
        if UniteRouterWebBrowserNavigation.isBlobURLNavigationEnabled() && url.scheme == "blob" {
            return true
        }
        
        let optimizeNavigaitionPolicy = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.optimizenavigationpolicy.enable"))// user:global
        if optimizeNavigaitionPolicy && url.isFileURL {
            return true
        }
        
        var canOpenInWeb = false
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.navigator.tester.context.disable")) {// user:global
            canOpenInWeb = Navigator.shared.response(for: url, test: true).parameters["_canOpenInWeb"] as? Bool == true// user:global
        } else {
            // 给其他业务线路由拦截器添加的上下文，通过这个字段可以判断出是从网页容器跳过去的。可以根据此字段做个性化业务逻辑。
            canOpenInWeb = Navigator.shared.response(for: url, context: ["from":"LarkWebBrowser"], test: true).parameters["_canOpenInWeb"] as? Bool == true // user:global in
                //V7.6处理Base的独立容器和网页半屏容器or模态容器冲突问题。
                let panelOrFormSheet = self.viewMode == "panel" || self.isFormSheet
                var continueHandler = false
                if (panelOrFormSheet) {
                    continueHandler = Navigator.shared.response(for: url, context: [
                        "__handleInHalfOrPanelBrowserReq__": panelOrFormSheet
                    ], test: true).parameters["__handleInHalfOrPanelBrowserRes__"] as? Bool == true
                }
                canOpenInWeb = canOpenInWeb || continueHandler
        }
        if canOpenInWeb || url.isFileURL {
            Self.logger.lkwlog(level: .info, "canOpenInWeb or fileurl, canOpenInWeb:\(canOpenInWeb)", traceId: webview.opTraceId())
            return true
        } else {
            return false
        }
    }
    
    func isBase64Image(_ base64Str: String) -> Bool {
        if base64Str.hasPrefix("data:image/png;base64,")
            || base64Str.hasPrefix("data:image/x-icon;base64,")
            || base64Str.hasPrefix("data:image/jpg;base64,") {
            return true
        }
        return false
    }
}
