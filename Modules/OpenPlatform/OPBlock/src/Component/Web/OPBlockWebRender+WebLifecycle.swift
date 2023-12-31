//
//  OPBlockWebRender+WebLifecycle.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/31.
//

import Foundation
import WebBrowser
import WebKit
import ECOProbe
import OPSDK
import UniverseDesignToast
import OPFoundation
import OPBlockInterface

// web 页面信息，目前只给出url
public final class OPBlockWebPageInfo: NSObject, OPRenderPageDataProtocol {
    public let url: String?

    init(webBrowser: WebBrowser) {
        self.url = webBrowser.webview.url?.absoluteString
        super.init()
    }
}

// 实现WebBrowserNavigationProtocol，提供web相关生命周期回调
extension OPBlockWebRender: WebBrowserNavigationProtocol {

    /// Invoked when a main frame navigation starts.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.start_render_page)
            .addMap(["render_type": "block_h5",
                     "path": browser.webview.url?.safeURLString])
            .setUniqueID(context.containerContext.uniqueID)
            .tracing(context.containerContext.blockContext.trace)
            .flush()
        context.containerContext.trace?.info("web render start navigation", additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                                                             "url": browser.webview.url?.safeURLString ?? "nil"])
        handleLoading(browser: browser, show: true)
        delegate?.onPageStartRender(info: OPBlockWebPageInfo(webBrowser: browser))
    }

    /// Invoked when an error occurs while starting to load data for the main frame.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    ///  - error: The error that occurred.
    func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoading(browser: browser, show: false)
        handleWebError(browser: browser, error: error)
    }

    /// Invoked when a main frame navigation completes.
    /// - Parameters:
    ///  - browser: he browser invoking the delegate method.
    ///  - navigation: The navigation.
    func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        context.containerContext.trace?.info("web render finish navigation", additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                                                              "url": browser.webview.url?.safeURLString ?? "nil"])
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.render_page_result)
            .addMap(["render_type": "block_h5",
                     "path": browser.webview.url?.safeURLString])
            .setResultTypeSuccess()
            .tracing(context.containerContext.blockContext.trace)
            .flush()
        handleLoading(browser: browser, show: false)
        delegate?.onPageSuccess(info: OPBlockWebPageInfo(webBrowser: browser))
    }

    /// Invoked when an error occurs during a committed main frame
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    ///  - error: The error that occurred.
    func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoading(browser: browser, show: false)
        handleWebError(browser: browser, error: error)
    }

    /// Invoked when the browser's web view's web content process is terminated.
    /// - Parameter browser: The browser invoking the delegate method.
    func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        context.containerContext.trace?.error("web render crash",
                                              additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                               "url": browser.webview.url?.safeURLString ?? "nil"])
        handleLoading(browser: browser, show: false)
        delegate?.onPageCrash(info: OPBlockWebPageInfo(webBrowser: browser), error: nil)
    }

    /// 处理web错误
    private func handleWebError(browser: WebBrowser, error: Error) {
        let fatalError = WKNavigationDelegateFailFix.isFatalWebError(error: error)
        context.containerContext.trace?.error("web render receive error",
                                              additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                               "fatalError": "\(fatalError)",
                                                               "url": browser.webview.url?.safeURLString ?? "nil"], error: error)
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountLaunchComponent.render_page_result)
            .addMap(["render_type": "block_h5",
                     "path": browser.webview.url?.safeURLString,
                     "fatal_error": fatalError])
            .setResultTypeFail()
            .setError(error)
            .tracing(context.containerContext.blockContext.trace)
            .flush()
        if fatalError {
            delegate?.onPageError(info: OPBlockWebPageInfo(webBrowser: browser),
                                  error: error.newOPError(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail))
        } else {
            delegate?.onPageSuccess(info: OPBlockWebPageInfo(webBrowser: webBrowser))
        }
    }

    private func handleLoading(browser: WebBrowser, show: Bool) {
        guard !((context.containerContext.containerConfig as? OPBlockContainerConfigProtocol)?.useCustomRenderLoading ?? false) else {
            context.containerContext.trace?.info("web render handle loading by host",
                                                 additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                                  "url": browser.webview.url?.safeURLString ?? "nil"])
            return
        }
        OPFoundation.executeOnMainQueueAsync {
            if show {
                UDToast.showLoading(with: "", on: browser.view)
            } else {
                UDToast.removeToast(on: browser.view)
            }
        }
    }
}
