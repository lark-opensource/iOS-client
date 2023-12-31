//
//  DarkModeThemeService.swift
//  SKBrowser
//
//  Created by Weston Wu on 2021/6/2.
//

import SKCommon
import SKFoundation
import UniverseDesignTheme
import RxSwift
import RxRelay
import RxCocoa

@available(iOS 13.0, *)
class DarkModeThemeService: BaseJSService {
    private var serviceCallback: String?
}

@available(iOS 13.0, *)
extension DarkModeThemeService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilThemeChanged, .simulateUserInterfaceChanged]
    }
    func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.utilThemeChanged.rawValue {
            DocsLogger.info("darkmode.service --- FE setup util theme change callback")
            handleGetTheme(params: params)
        } else if serviceName == DocsJSService.simulateUserInterfaceChanged.rawValue {
            DocsLogger.info("darkmode.service --- user interface change notification")
            notifyCurrentTheme(canRerenderWebview: true) // app theme 变更后刷新 webview
        }
    }
}

@available(iOS 13.0, *)
private extension DarkModeThemeService {
    func handleGetTheme(params: [String: Any]) {
        guard let callback = params["callback"] as? String else {
            DocsLogger.error("darkmode.service --- callback not found")
            return
        }
        serviceCallback = callback
        notifyCurrentTheme(canRerenderWebview: false) // 前端主动请求 theme 时不刷新 webview
    }

    func notifyCurrentTheme(canRerenderWebview: Bool) {
        let currntTheme = UDThemeManager.getRealUserInterfaceStyle()
        switch currntTheme {
        case .light, .unspecified:
            notifyThemeUpdated(isDarkMode: false, canRerenderWebview: canRerenderWebview)
        case .dark:
            notifyThemeUpdated(isDarkMode: true, canRerenderWebview: canRerenderWebview)
        @unknown default:
            notifyThemeUpdated(isDarkMode: false, canRerenderWebview: canRerenderWebview)
        }
    }

    func notifyThemeUpdated(isDarkMode: Bool, canRerenderWebview: Bool) {
        //修复短时间内重复render问题https://bytedance.feishu.cn/docx/doxcnrv58OvvP71VHNhKg5Ixe4A
        let curRenderDarMode = ui?.displayConfig.isRenderDarkMode ?? false
        let rerenderImmediately = canRerenderWebview && (isDarkMode != curRenderDarMode)

        DocsLogger.info("darkmode.service --- prepare to notify theme updated", extraInfo: [
            "isAppDarkMode": isDarkMode,
            "curRenderDarMode": curRenderDarMode,
            "systemUserInterfaceIsDark": UIScreen.main.traitCollection.userInterfaceStyle == .dark,
            "willRerenderWebview": rerenderImmediately
        ])
        guard let engine = model?.jsEngine,
              let callback = serviceCallback else {
            DocsLogger.error("darkmode.service --- callback not found")
            return
        }
        let params: [String: Any] = [
            "theme": isDarkMode ? "dark" : "light"
        ]
        engine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)

        if rerenderImmediately, shouldRerenderWebView() {
            // 下面的方法比较简单粗暴，会丢失很多很多状态，比如文档的滚动进度、当前正在打开的 native 面板……
            // 但是前端同学说如果客户端不强制刷新的话会有很多 UI 问题，所以我们就帮他做了这件事情
            ui?.displayConfig.rerenderWebview()
        }
    }
    
    private func shouldRerenderWebView() -> Bool {
        if model?.hostBrowserInfo.docsInfo?.inherentType == .baseAdd {
            // Base 新建记录模式，不需要 rerenderWebview
            return false
        }
        return true
    }
}

@available(iOS, deprecated: 13.0, message: "Use DarkModeThemeService for iOS 13+")
class MockDarkModeThemeService: BaseJSService, DocsJSServiceHandler {

    var handleServices: [DocsJSService] {
        return [.utilThemeChanged]
    }

    func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.utilThemeChanged.rawValue {
            DocsLogger.error("mock.darkmode.service --- FE setup util theme changed")
            handleGetTheme(params: params)
        }
    }

    private func handleGetTheme(params: [String: Any]) {
        guard let callback = params["callback"] as? String else {
            DocsLogger.error("mock.darkmode.service --- callback not found")
            return
        }
        guard let engine = model?.jsEngine else {
            DocsLogger.error("mock.darkmode.service --- jsEngine not found")
            return
        }
        let params: [String: Any] = [
            "theme": "light"
        ]
        engine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
    }
}
