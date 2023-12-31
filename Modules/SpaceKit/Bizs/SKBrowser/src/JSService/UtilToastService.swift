//
//  UtilToastService.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/10/17.
//https://jira.bytedance.com/browse/DM-1048 iOS 提供全局 toast

//window.lark.biz.util.showToast({
//    message: '成功',
//    type: 0, // 0是成功， 1是失败， 2是底部弹框
//    duration: 1, // 1表示1s, 3是3s (Android 只有1和3)
//});

//window.lark.biz.util.hideToast();

import SKFoundation
import WebKit
import SKCommon
import SKUIKit
import EENavigator
import UniverseDesignToast

public final class UtilToastService: BaseJSService {
    private lazy var baseToastPlugin: SKBaseToastPlugin = {
        let plugin = SKBaseToastPlugin()
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        plugin.hostView = ui?.hostView ?? UIView()
        plugin.pluginProtocol = self
        return plugin
    }()
    var canShowToast = true
    var loadingTimer: Timer?
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UtilToastService: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        canShowToast = false
    }
    public func browserWillLoad() {
        canShowToast = true
    }
    public func browserWillDismiss() {
        baseToastPlugin.handle(params: [:], serviceName: DocsJSService.utilHideToast.rawValue)
    }
}

extension UtilToastService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return baseToastPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        baseToastPlugin.handle(params: params, serviceName: serviceName)
    }
}

extension UtilToastService: SKToastPluginProtocol {
    func actionCallback(callback: String, params: [String: Any]?) {
        model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: params, completion: nil)
    }

    func hideAllToast(animate: Bool) {
        var hostWindow = navigator?.currentBrowserVC?.rootWindow()
        if !UserScopeNoChangeFG.ZJ.windowNotFoundFixDisable {
            hostWindow = navigator?.currentBrowserVC?.view.affiliatedWindow
        }
        if let hostWindow = hostWindow {
            UDToast.removeToast(on: hostWindow)
        } else if let hostView = ui?.hostView {
            UDToast.removeToast(on: hostView)
        }
    }
    
    func cancelLoadingTimer() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

    func showToast(_ message: String, actionMessage: String?, actionCallback: String?, type: SKBaseToastPlugin.ToastType, duration: TimeInterval) {
        var hostWindow = navigator?.currentBrowserVC?.rootWindow()
        if !UserScopeNoChangeFG.ZJ.windowNotFoundFixDisable {
            hostWindow = navigator?.currentBrowserVC?.view.affiliatedWindow
        }
        
        guard let hostWindow = hostWindow,
              let browserViewVC = navigator?.currentBrowserVC as? BrowserViewController else { return }
        
        func toastWithAction(_ toastType: UDToastType) -> UDToast? {
            if let buttonMessage = actionMessage,
                  !buttonMessage.isEmpty,
                  let callback = actionCallback {

                let operation = UDToastOperationConfig(text: buttonMessage, displayType: buttonMessage.count > 5 ? .vertical : .auto)
                let config = UDToastConfig(toastType: toastType, text: message, operation: operation)
                
                return UDToast.showToast(with: config,
                                            on: hostWindow,
                                            delay: duration) { [weak self] _ in
                    self?.actionCallback(callback: callback, params: nil)
                }
                
            } else {
                let config = UDToastConfig(toastType: toastType, text: message, operation: nil)
                return UDToast.showToast(with: config, on: hostWindow, delay: duration)
            }
        }

        //不监听键盘高度，键盘上有工具栏等view，监听键盘高度会导致toast位置不对
        //键盘如果是在toast显示之后起来的，那这里就拿不到工具栏的高度，因此keyboardMargin默认设置为UDToast规范，距离底部安全区100
        var keyboardMargin: CGFloat = 100
        if browserViewVC.keyboard.isShow {
            let inputViewHeight = browserViewVC.getToolBarHeightWithKeyboard(false)
            keyboardMargin = max(inputViewHeight + 20, 100)
        }
        let hud: UDToast
        switch type {
        case .fail:
            hud = UDToast.showFailure(with: message, on: hostWindow)
        case .succ:
            hud = UDToast.showSuccess(with: message, on: hostWindow)
        case .successWithAction:
            guard let _hud = toastWithAction(.success) else { return }
            hud = _hud
        case .loading:
            hud = UDToast.showLoading(with: message, on: hostWindow)
            if duration > 0 {
                let timer = Timer(timeInterval: duration, repeats: false) { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    self.hideAllToast(animate: true)
                }
                self.loadingTimer = timer
                RunLoop.main.add(timer, forMode: .common)
            }
        case .warning:
            guard let _hud = toastWithAction(.warning) else { return }
            hud = _hud
        case .tipWithAction:
            guard let _hud = toastWithAction(.info) else { return }
            hud = _hud
        default:
            hud = UDToast.showTips(with: message, on: hostWindow)
        }
        hud.keyboardMargin = keyboardMargin
    }

    func canShowToastNow() -> Bool {
        return canShowToast
    }
}
