//
//  LarkLiveManager.swift
//  LarkLive
//
//  Created by yangyao on 2021/6/15.
//

import Foundation
import Swinject
import EENavigator
import LarkSuspendable
import LarkWebViewContainer
import MinutesFoundation
import LKCommonsLogging

public final class LarkLiveManager {

    private let windowKey = "LarkLive.LiveService.windowKey"

    private static let logger = Logger.live

    public static let shared = LarkLiveManager()

    private var resolver: Resolver?

    public var url: URL?

    public var title: String?

    private var webviewContainer: LiveWebViewContainer?

    public var floatViewSize: CGSize = CGSize(width: FloatViewLayout.floatWindowWidth, height: FloatViewLayout.floatWindowHeight)
    
    public var isLiveInFloatView: Bool = false  // 直播是否在小窗状态

    init() {

    }

    public func setup(resolver: Resolver) {
        self.resolver = resolver
    }

    public func destroy() {
        LarkLiveManager.logger.info("LarkLiveManager destroy")
        self.stopAndCleanLive()
    }

    public func startLive(url: URL, webViewContainer: LiveWebViewContainer? = nil, fromLink: Bool = true) {
        LarkLiveManager.logger.info("LarkLiveManager start live with url: \(url.absoluteString)")
        // 如果自己的 url 不存在或者新的 url 跟自己的不一样，则是新打开了一个链接
        var oldWebViewContainer: LiveWebViewContainer? = webViewContainer
        if self.url == nil || self.url!.strWithoutParameters() != url.strWithoutParameters() {
            oldWebViewContainer = LiveWebViewContainer(url: url)
            oldWebViewContainer?.delegate = self
            if let newUrl = oldWebViewContainer?.renewURL(with: url) {
                oldWebViewContainer?.loadURL(newUrl, showLoading: true)
            }
            self.webviewContainer = oldWebViewContainer
        } else {
            oldWebViewContainer = self.webviewContainer
            oldWebViewContainer?.setFloatMode(false)
        }

        if let oldWebViewContainer = oldWebViewContainer {
            self.url = url

            let vc = LarkLiveViewController(url: self.url!, webViewContainer: oldWebViewContainer, fromLink: fromLink)

            var navigatorFrom: NavigatorFrom? = Navigator.shared.mainSceneTopMost
            if let from = navigatorFrom {
                Navigator.shared.push(vc, from: from) { [weak self] in
                    if self?.isLiveInFloatView == true {
                        self?.removeViewFromFloatWindow()
                        vc.setupView()
                    }
                }
            }
        } else {
            LarkLiveManager.logger.info("LarkLiveManager Not show detail view: oldWebViewContainer is nil")
        }
    }

    func tryShowFloatView() {
        if isInMeeting() {
            LarkLiveManager.logger.info("LarkLiveManager Not show float view: in meeting")
            stopAndCleanLive()
            return
        }

        if isInRecording() {
            LarkLiveManager.logger.info("LarkLiveManager Not show float view: in recording")
            stopAndCleanLive()
            return
        }

        // 播客模式下进入直播详情页面，退出展示直播时要结束播客播放
        stopPodcast()

        LiveNativeTracks.trackDisplayFloatWindow(liveId: self.webviewContainer?.realLiveId ?? "", liveSessionId: self.webviewContainer?.viewModel.liveData.liveID)
        LiveNativeTracks.trackModeChangeInLive(mode: LiveMode.floatWindow.rawValue)
        if let webviewContainer = self.webviewContainer {
            webviewContainer.setFloatMode(true)
            addViewToFloatWindow(webviewContainer, size: floatViewSize)
        } else {
            LarkLiveManager.logger.info("LarkLiveManager Not show float view: webviewContainer is nil")
        }
    }

    public func stopAndCleanLive() {
        LarkLiveManager.logger.info("LarkLiveManager clean Live Data")
        Util.runInMainThread { [weak self] in
            self?.removeViewFromFloatWindow()
        }
        webviewContainer?.delegate = nil
        webviewContainer = nil
        url = nil
        title = nil
    }

    public func trackFloatWindow(isConfirm: Bool) {
        LiveNativeTracks.trackJoinMeetingPopupInLiving(isConfirm, liveId: self.webviewContainer?.realLiveId ?? "", liveSessionId: self.webviewContainer?.viewModel.liveData.liveID)
    }
}

extension LarkLiveManager {
    private func stopPodcast() {
        if let dependency = resolver?.resolve(LarkLiveDependency.self) {
            if dependency.isInPodcast {
                LarkLiveManager.logger.info("LarkLiveManager will show live float, close podcast")
                dependency.stopPodcast()
            }
        }
    }

    private func isInPodcasst() -> Bool {
        if let dependency = resolver?.resolve(LarkLiveDependency.self) {
            return dependency.isInPodcast
        }
        return false
    }

    private func isInMeeting() -> Bool {
        if let dependency = resolver?.resolve(LarkLiveDependency.self) {
            return dependency.isInMeeting
        }
        return false
    }

    private func isInRecording() -> Bool {
        if let dependency = resolver?.resolve(LarkLiveDependency.self) {
            return dependency.isInRecording
        }
        return false
    }

    func pushOrPresentShareContentBody(text: String, from: NavigatorFrom?,  style: Int) {
        if let dependency = resolver?.resolve(LarkLiveDependency.self) {
            LarkLiveManager.logger.info("LarkLiveManager push share contentBody")
            dependency.pushOrPresentShareContentBody(text: text, from: from, style: style)
        }
    }
}

extension LarkLiveManager {
    private func addViewToFloatWindow(_ view: UIView, size: CGSize) {
        if SuspendManager.isFloatingEnabled {
            LarkLiveManager.logger.info("LarkLiveManager SuspendManager addViewToFloatWindow: \(windowKey)")
            SuspendManager.shared.addCustomView(view, size: size, forKey: windowKey)

            isLiveInFloatView = true
        }
    }

    func removeViewFromFloatWindow() {
        if SuspendManager.shared.customView(forKey: windowKey) != nil {
            LarkLiveManager.logger.info("LarkLiveManager SuspendManager removeViewFromFloatWindow: \(windowKey)")
            SuspendManager.shared.removeCustomView(forKey: windowKey)

            isLiveInFloatView = false
        }
    }
}

extension LarkLiveManager: LiveWebViewContainerDelegate {
    public func showFloatView(container: LiveWebViewContainer) {
        tryShowFloatView()
    }
    public func stopAndCleanLive(container: LiveWebViewContainer) {
        stopAndCleanLive()
    }
    public func stopLiveForMeeting(container: LiveWebViewContainer) {
        if isLiveInFloatView {
            stopAndCleanLive()
        }
    }
}

extension URL {
    func strWithoutParameters() -> String {
        return self.absoluteString.components(separatedBy: "?").first ?? self.absoluteString
    }
}
