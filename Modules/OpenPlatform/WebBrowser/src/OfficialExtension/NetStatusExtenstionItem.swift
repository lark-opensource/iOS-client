//
//  NetStatusExtenstionItem.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/1/30.
//

import Foundation
import WebKit
import LarkSetting
import LKCommonsLogging
import OPFoundation
import UniverseDesignToast

final public class NetStatusExtenstionItem: WebBrowserExtensionItemProtocol {
    static let logger = Logger.webBrowserLog(NetStatusExtenstionItem.self, category: "NetStatus")
    public var itemName: String? = "NetStatus"
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = NetStatusLifecycleImpl(item: self)
    public lazy var browserDelegate: WebBrowserProtocol? = NetStatusBrowserLoadImpl(item: self)
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = NetStatusBrowserNavigationImpl(item: self)
    private weak var browser: WebBrowser?
    private var isReconnect: Bool = false
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
    
    func onNetStatusChange() {
        guard let browser = browser,
              let delegate = browserDelegate as? NetStatusBrowserLoadImpl else {
            return
        }
        guard browser.processStage == .PrepareLoadURL || browser.processStage == .HasStartedURL else {
            return
        }
        // 若网页加载中断开网络连接, 则清空提示计时器, 待恢复网络重新计时
        if browser.netStatus == .unavailable {
            Self.logger.info("web loading net status unavailable")
            isReconnect = true
            delegate.stopTipsTimer()
        } else if isReconnect && browser.netStatus != .unknown {
            Self.logger.info("web loading net status recover \(browser.netStatus)")
            isReconnect = false
            delegate.startTipsTimer(browser: browser)
        }
    }
}

final public class NetStatusLifecycleImpl: WebBrowserLifeCycleProtocol {
    private weak var item: NetStatusExtenstionItem?
    
    init(item: NetStatusExtenstionItem) {
        self.item = item
    }
    
    public func webBrowserDeinit(browser: WebBrowser) {
        guard let item = item else {
            return
        }
        if let delegate = item.browserDelegate as? NetStatusBrowserLoadImpl {
            delegate.stopTipsTimer()
        }
    }
}

final public class NetStatusBrowserLoadImpl: WebBrowserProtocol {
    private weak var item: NetStatusExtenstionItem?
    private var tipsTimer: Timer?
    private var weakDelay: TimeInterval? = {
        guard let settings = try? SettingManager.shared.setting(with: .make(userKeyLiteral: "web_settings")),// user:global
              let time = settings["weakCheckSeconds"] as? Int else {
            return nil
        }
        return TimeInterval(time)
    }()
    private var isWeakTipsDone: Bool = false
    
    deinit {
        stopTipsTimer()
    }
    
    init(item: NetStatusExtenstionItem? = nil) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, willLoadURL url: URL) {
        if !isWeakTipsDone {
            startTipsTimer(browser: browser)
        }
    }
    
    public func browser(_ browser: WebBrowser, didReloadURL url: URL) {
        if !isWeakTipsDone {
            startTipsTimer(browser: browser)
        }
    }
    
    fileprivate func stopTipsTimer() {
        guard tipsTimer != nil else {
            return
        }
        NetStatusExtenstionItem.logger.debug("weak net timer did cancel")
        tipsTimer?.invalidate()
        tipsTimer = nil
    }
    
    fileprivate func startTipsTimer(browser: WebBrowser) {
        guard let delay = weakDelay else {
            return
        }
        stopTipsTimer()
        NetStatusExtenstionItem.logger.debug("weak net timer will start")
        tipsTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self, weak browser] _ in
            guard let self = self, let browser = browser else {
                return
            }
            let isCompleted = browser.processStage == .HasFinishedURL || browser.processStage == .HasFailedURL
            if !isCompleted && !self.isWeakTipsDone && browser.netStatus == OPNetStatusHelper.OPNetStatus.weak {
                NetStatusExtenstionItem.logger.info("web show weak net tips due to \(delay)s from load url to complete timeout")
                self.isWeakTipsDone = true
                DispatchQueue.main.async {
                    UDToast.showTips(with: BundleI18n.WebBrowser.AppErr_AppDetect_WeakNet_Toast, on: browser.view)
                }
            } else {
                NetStatusExtenstionItem.logger.info("web \(browser.netStatus) net status not show tips even if weak net timeout")
            }
        }
    }
}

final public class NetStatusBrowserNavigationImpl: WebBrowserNavigationProtocol {
    private weak var item: NetStatusExtenstionItem?
    
    init(item: NetStatusExtenstionItem? = nil) {
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        stopTipsTimer()
    }
    
    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        stopTipsTimer()
    }
    
    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        stopTipsTimer()
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        stopTipsTimer()
    }
    
    private func stopTipsTimer() {
        guard let item = item else {
            return
        }
        if let delegate = item.browserDelegate as? NetStatusBrowserLoadImpl {
            delegate.stopTipsTimer()
        }
    }
}
