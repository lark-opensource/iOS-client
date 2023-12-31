//
//  UtilFocusableService.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/9/23.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

// 控制BrowserView 的focus逻辑 (包括前端 focus, iOS firstResponder)
// 当前职责
// 1. 决定前端何时可以拉起键盘，避免过早拉起键盘导致WebKit bug产生异常动画
// 2. 对于Sheet等非contentEditable的DOM结构页面，保证启动时可以成为第一响应者，从而支持键盘等action响应
class UtilFocusableService: BaseJSService {
    private var _bridgeCallback: String?
    private var _canFoucusable: Bool?
    private static let _shouldFocusType: Set<DocsType> = [.sheet]

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UtilFocusableService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.notifySetFocusableReady, .simulateCanSetFocusable]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.notifySetFocusableReady.rawValue:
            _setFocusbaleReady(params: params)
        case DocsJSService.simulateCanSetFocusable.rawValue:
            _setCanFocusbale(params: params)
        default: return
        }
    }

    private func _setFocusbaleReady(params: [String: Any]) {
        guard let callback = params["callback"] as? String else {
            DocsLogger.error("UtilFousableService can't find bridge callback from params", extraInfo: ["params": params])
            return
        }
        _bridgeCallback = callback
        _flushCurrentState()
    }

    private func _setCanFocusbale(params: [String: Any]) {
        guard let canFocusable = params["canFocusable"] as? Bool else {
            DocsLogger.error("UtilFousableService can't find key params from dict", extraInfo: ["dict": params])
            return
        }
        _canFoucusable = canFocusable
        _flushCurrentState()
    }

    private func _flushCurrentState() {
        guard let callback = _bridgeCallback, let canFocusable = _canFoucusable else { return }
        let parameter = ["enable": canFocusable]
        let logExtraInfo: [String: Any] = ["callback": callback, "params": parameter]
        DocsLogger.info("UtilFocusableService will set focusable state", extraInfo: logExtraInfo)
        callFunction(DocsJSCallBack(callback), params: parameter) { _, err in
            if let err = err {
                DocsLogger.error("UtilFocusableService evaluate js script failed.", extraInfo: logExtraInfo, error: err)
                return
            }
        }
    }
}

extension UtilFocusableService: SKExecJSFuncService {
    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((Any?, Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
}

extension UtilFocusableService: BrowserViewLifeCycleEvent {
    public func browserDidAppear() {
        // Notify frontend that webView is focusable when the transition is completely done
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateCanSetFocusable.rawValue, params: ["canFocusable": true])
    }

    public func browserWillDismiss() {
        // Notify frontend that webView is not focusable when the transition is will begin
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateCanSetFocusable.rawValue, params: ["canFocusable": false])
    }

    public func browserDidHideLoading() {
        guard let type = model?.browserInfo.docsInfo?.type else { return }
        // 对于DOM结构非contentEditable的 (如Sheet的canvas方案)，设置为第一响应者
        if UtilFocusableService._shouldFocusType.contains(type) {
            ui?.uiResponder.becomeFirst()
        }
        // TODO: junlin https://jira.bytedance.com/browse/DM-7059
        // 当前发现div 为 contentEditable也可以这样，判断是否起键盘可能只和前端的focus及selection有关，需要在3.10~11 研究下WebKit
        // ui?.webView.becomeFirstResponder()
    }
}
