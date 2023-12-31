//
//  UtilMSFloatWindowService.swift
//  SKBrowser
//
//  Created by ByteDance on 2022/11/28.
//

import Foundation
import SKFoundation
import SKCommon
import WebKit

/// 告知前端: MS的小窗状态
class UtilMSFloatWindowService: BaseJSService {

    private let floatWindowChangeCallback = DocsJSCallBack("window.lark.biz.util.changeFloatWindow")

    private var lastAudiovisualMediaTypes: WKAudiovisualMediaTypes?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UtilMSFloatWindowService: DocsJSServiceHandler {

    public var handleServices: [DocsJSService] {
        []
    }

    public func handle(params: [String: Any], serviceName: String) {

    }
}

extension UtilMSFloatWindowService: BrowserViewLifeCycleEvent {

    func browserDidChangeFloatingWindow(isFloating: Bool) {
        let webview = ui?.editorView as? WKWebView
        if isFloating { // 进入小窗
            let types = webview?.configuration.mediaTypesRequiringUserActionForPlayback
            lastAudiovisualMediaTypes = types // 记录当前的配置
            DocsLogger.info("lastAudiovisualMediaTypes: \(String(describing: types))")
            webview?.configuration.mediaTypesRequiringUserActionForPlayback = []
        } else { // 恢复大窗
            if let types = lastAudiovisualMediaTypes {
                webview?.configuration.mediaTypesRequiringUserActionForPlayback = types // 恢复上次的配置
                lastAudiovisualMediaTypes = nil
            }
        }
        DocsLogger.info("change float window state, isFloating => \(isFloating)")
        let params: [String: Any] = ["isFloating": isFloating]
        model?.jsEngine.callFunction(floatWindowChangeCallback, params: params, completion: nil)
    }
}
