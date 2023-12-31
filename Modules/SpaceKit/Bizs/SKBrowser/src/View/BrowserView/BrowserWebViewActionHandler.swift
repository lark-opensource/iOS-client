//
//  DocsBrowserWebViewActionHandler.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/3/27.
//
//

import WebKit
import SKCommon
import SKFoundation
import SKInfra
import EENavigator
import LarkUIKit
import LarkContainer

protocol DocsBrowserWebViewActionHandleDelegate: AnyObject {
    func webViewActionWebViewTerminate(_ browserView: BrowserView?, reason: UInt32)
    func failWithError(_ error: Error?)
    func didLoadFinish()
    func didReceiveRedirectResponse(_ response: URLResponse)
    func browserViewAuthorizedFaild(_ browserView: BrowserView)
    func removeTerminateErrorPage()
    func onFrameLoadFail(url: String, isMainFrame: Bool, error: Error)
}

class DocsBrowserWebViewActionHandler: NSObject, WKUIDelegate, WKNavigationDelegate {
    private weak var actionHandler: DocsBrowserWebViewActionHandleDelegate?
    private weak var browser: WebBrowserView?
    private var editorIdentity: String
    private var subPages = [WebSubPageWeakHolder]()
    let userResolver: UserResolver
    
    init(browser: WebBrowserView, identifier: String, actionHandler: DocsBrowserWebViewActionHandleDelegate) {
        self.userResolver = browser.userResolver
        self.editorIdentity = identifier
        self.browser = browser
        self.actionHandler = actionHandler
    }

    // MARK: WKUIDelegate
    public func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
        guard let url = (previewingViewController as? WebViewController)?.url,
        let browser = browser else {
            return
        }
        _ = browser.navigator?.browserView(browser, requiresOpen: url)
    }
    public func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        guard let url = elementInfo.linkURL else { return UIViewController() }
        let web = WebViewController(url)
        return web
    }
    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        DocsLogger.info("[prompt] runJavaScriptWithPrompt: \(prompt)")
        if prompt == "__baseOpenWebSubpage__" {
            
            if let defaultText = defaultText {
                
                do {
                    let subPageModel = try CodableUtility.decode(
                        SubPageModel.self,
                        withJSONString: defaultText
                    )
                    WebSubPageHelper.set(model: subPageModel)
                } catch {
                    DocsLogger.error("decode SubPageModel error, text: \(defaultText)", error: error)
                }
                
                completionHandler(nil)
                return
            }
            
        }
        
        if prompt == "lark.biz.clipboard.getClipboard" {
            do {
                var pointId: String? = defaultText
                //空字符当成 nil 处理
                if let checkPointId = pointId, checkPointId.isEmpty {
                    pointId = nil
                }
                let dict = ClipboardService.convertPasteboard(encryptID: pointId)
                let data = try JSONSerialization.data(withJSONObject: dict)
                let jsonStr = String(data: data, encoding: .utf8)
                completionHandler(jsonStr)
                return
            } catch {
                DocsLogger.error("[getClipboard] json error: \(error)")
            }
        } else if prompt == "biz.util.getSSRScrollPos" {
            if let browser = self.browser {
                SSRGetScrollPositionService.getSSRScrollPositionSync(browser) { data in
                    if let result = data?.toJSONString() {
                        completionHandler(result)
                    } else {
                        completionHandler(nil)
                    }
                }
                return
            }
        }
        
        completionHandler(nil)
    }
    
    @available(iOS 13.0, *)
    public func webView(_ webView: WKWebView, contextMenuWillPresentForElement elementInfo: WKContextMenuElementInfo) {
        browser?.disableSecondaryClick()
    }
    
    @available(iOS 13.0, *)
    public func webView(_ webView: WKWebView, contextMenuDidEndForElement elementInfo: WKContextMenuElementInfo) {
        //如果webview上有其他上下文菜单弹出会让右键手势再次生效，这里再屏蔽一次
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [weak self] in
            self?.browser?.disableSecondaryClick()
        }
    }

    // MARK: WKNavigationDelegate

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        browser?.isWebViewTerminated = false
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        actionHandler?.webViewActionWebViewTerminate(browser, reason: normalTerminateReason)
        browser?.isWebViewTerminated = true
    }
    
    @objc
    public func _webView(_ webView: WKWebView, webContentProcessDidTerminateWithReason reason: UInt32) {
        // https://juejin.cn/post/7103463814246760485
        // typedef NS_ENUM(NSInteger, _WKProcessTerminationReason) {
        //     _WKProcessTerminationReasonExceededMemoryLimit,
        //     _WKProcessTerminationReasonExceededCPULimit,
        //     _WKProcessTerminationReasonRequestedByClient,
        //     _WKProcessTerminationReasonCrash,
        // } WK_API_AVAILABLE(macos(10.14), ios(12.0));
        actionHandler?.webViewActionWebViewTerminate(browser, reason: reason)
        browser?.isWebViewTerminated = true
    }
    
    @objc
    public func _webView(_ webView: WKWebView, navigation: WKNavigation!, didFailProvisionalLoadInSubframe subframe: WKFrameInfo, withError error: Error) {
        DocsLogger.error("didFailProvisionalLoadInSubframe, isMain:\(subframe.isMainFrame)", error: error)
        guard let url = (error as NSError).userInfo[NSURLErrorFailingURLStringErrorKey] as? String else {
            spaceAssertionFailure("subframe.url is empty")
            return
        }
        actionHandler?.onFrameLoadFail(url: url, isMainFrame: subframe.isMainFrame, error: error)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if let actionHandler = actionHandler {
            DocsLogger.info("decidePolicyFor navigationAction, call removeTerminateErrorPage")
            actionHandler.removeTerminateErrorPage()
        } else {
            DocsLogger.error("decidePolicyFor navigationAction has no actionHandler")
        }
        guard let browser = browser  else {
            decisionHandler(.cancel)
            return
        }
        // target frame 不是main frame允许 (内嵌视频）
        if let frame = navigationAction.targetFrame, frame.isMainFrame == false {
            decisionHandler(.allow)
            return
        }
        guard let naviUrl = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        // load current url
        if let webUrl = webView.url, webUrl == naviUrl {
            decisionHandler(.allow)
            return
        }
        SecLinkStatistics.didClickLink(sourceURL: webView.url)
        // location new url
        func obtianFromTag() -> String {
            guard let docsInfo = browser.docsInfo else {
                return FromSource.linkInDoc.rawValue
            }
            if docsInfo.type == .doc {
                return FromSource.linkInParentDocs.rawValue
            } else if docsInfo.type == .sheet {
                return FromSource.linkInParentSheet.rawValue
            } else if docsInfo.type == .mindnote {
                return FromSource.linkInParentMindnote.rawValue
            } else {
                return FromSource.linkInDoc.rawValue
            }
        }

        var fromTag = obtianFromTag()
        if browser.isInGroupTab {
            fromTag = FromSource.groupTab.rawValue
        }
        var requiresOpenUrl = naviUrl
        if URLValidator.isDocsURL(naviUrl) {
            requiresOpenUrl = naviUrl.docs.addOrChangeQuery(parameters: ["from": fromTag])
        }
        let requireOpenResult = browser.navigator?.browserView(browser, requiresOpen: requiresOpenUrl) ?? false
        let actionPolicy: WKNavigationActionPolicy = requireOpenResult ? .allow : .cancel
        decisionHandler(actionPolicy)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let browser = browser else {
            decisionHandler(.cancel)
            return
        }
        let shouldLoad: Bool = {
            guard let response = navigationResponse.response as? HTTPURLResponse else { return true }
            switch response.statusCode {
            case 401: // 401 means you need auth
                actionHandler?.browserViewAuthorizedFaild(browser)
                DocsLogger.info("\(editorIdentity) 401")
                return false
            case 301, 302: // In pratice, this callback won't be invoke when an redirect occurs!
                actionHandler?.didReceiveRedirectResponse(response)
                DocsLogger.info("\(editorIdentity) 301/302")
                return true
            default:
                return true
            }
        }()

        let actionPolicy: WKNavigationResponsePolicy = shouldLoad ? .allow : .cancel
        decisionHandler(actionPolicy)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DocsLogger.info("WKWebView didFinish", extraInfo: ["contentView": editorIdentity], component: nil)
        actionHandler?.didLoadFinish()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DocsLogger.error("WKWebView 加载失败", extraInfo: ["contentView": editorIdentity], error: error, component: nil)
        webViewAction(finishedLoad: webView.url, error: error)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DocsLogger.error("WKWebView 启动时加载数据发生错误", extraInfo: ["contentView": editorIdentity], error: error, component: nil)
        webViewAction(finishedLoad: webView.url, error: error)
    }

    private func webViewAction(finishedLoad url: URL?, error: Error?) {
        if error != nil {
            DocsLogger.error("webViewAction:\(error)")
            actionHandler?.failWithError(error)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.request.url?.absoluteString.contains("mobile_subpage.html") == true {
                if let subPageModel = WebSubPageHelper.get() {
                    if let pageType = subPageModel.pageStyle.getPageType() {
                        switch pageType {
                        case .page, .fullScreen:
                            if let webview = showWebPageViewController(webView: webView, configuration: configuration, subPageModel: subPageModel) {
                                return webview
                            }
                        }
                    }
                    return showWebSubPageViewController(webView: webView, configuration: configuration, subPageModel: subPageModel)
                } else {
                    DocsLogger.error("subPageModel is nil")
                }
            }
        guard let browser = browser, let naviUrl = navigationAction.request.url else {
            DocsLogger.error("window.open 打开失败，url获取不到", extraInfo: ["contentView": editorIdentity])
            return nil
        }
        let requiresOpenUrl = URLValidator.isDocsURL(naviUrl) ? naviUrl.docs.addOrChangeQuery(parameters: ["from": FromSource.linkInDoc.rawValue]) : naviUrl
        _ = browser.navigator?.browserView(browser, requiresOpen: requiresOpenUrl)
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        let weakSubPage = subPages.first { weakSubPage in
            weakSubPage.subPage?.webView == webView
        }
        weakSubPage?.subPage?.webViewDidClose(webView)
    }
}

extension DocsBrowserWebViewActionHandler {
    private func showWebSubPageViewController(webView: WKWebView, configuration: WKWebViewConfiguration, subPageModel: SubPageModel) -> WKWebView {
        let webSubPageViewController = WebSubPageViewController(
            subPageModel: subPageModel,
            configuration: configuration
        )
        if let webViewWindow = webView.window {
            if let rootVC = webViewWindow.rootViewController {
                if let topMostVC = UIViewController
                    .docs
                    .topMost(of: rootVC) {
                    topMostVC.present(webSubPageViewController, animated: true)
                } else {
                    DocsLogger.error("rootVC.topMost is nil")
                }
            } else {
                DocsLogger.error("webViewWindow.rootViewController is nil")
            }
        } else {
            DocsLogger.error("webView.window is nil")
        }
        subPages.append(WebSubPageWeakHolder(webSubPageViewController))
        return webSubPageViewController.webView
    }
    
    private func showWebPageViewController(webView: WKWebView, configuration: WKWebViewConfiguration, subPageModel: SubPageModel) -> WKWebView? {
        let webSubPageViewController = WebPageViewController(
            subPageModel: subPageModel,
            configuration: configuration
        )
        webView.resignFirstResponder() // 关闭webview键盘
        
        func findNearestNavigationController(from viewController: UIViewController?) -> UINavigationController? {
            if viewController == nil {
                return nil
            }
            // 检查当前视图控制器是否嵌入在导航控制器中
            if let navigationController = viewController as? UINavigationController {
                return navigationController
            }
            
            // 如果没有找到任何导航控制器，则返回 nil
            return findNearestNavigationController(from: viewController?.parent)
        }

        if Display.pad {
            if let nav = findNearestNavigationController(from: browser?.currentBrowserVC) {
                let nv = LkNavigationController(rootViewController: webSubPageViewController)
                nv.modalPresentationStyle = .formSheet
                self.userResolver.navigator.present(nv, from: nav)
                subPages.append(WebSubPageWeakHolder(webSubPageViewController))
                return webSubPageViewController.webView
            } else {
                DocsLogger.error("nav not found")
            }
        } else {
            if let nav = findNearestNavigationController(from: browser?.currentBrowserVC) {
                nav.pushViewController(webSubPageViewController, animated: true)
                subPages.append(WebSubPageWeakHolder(webSubPageViewController))
                return webSubPageViewController.webView
            } else {
                DocsLogger.error("nav not found")
            }
        }
        return nil
    }
}
