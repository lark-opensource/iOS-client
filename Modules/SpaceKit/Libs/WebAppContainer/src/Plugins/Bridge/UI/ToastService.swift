//
//  ToastService.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation
import LarkWebViewContainer
import UniverseDesignToast
import SKUIKit
import SKFoundation


class ToastService: WABridgeService {
    override var serviceType: WABridgeServiceType {
        return .UI
    }
    
    
    override func getBridgeHandlers() -> [WABridgeHandler] {
        return [ShowToastHandler(self),
                HideToastHandler(self)]
    }
    
    var loadingTimer: Timer?
    var fromVC: UIViewController? {
        self.context?.host.uiAgent?.bridgeVC
    }
    
    deinit {
        cancelLoadingTimer()
    }
    
    func hideAllToast(animate: Bool) {
        guard let hostView = self.fromVC?.view else {
            spaceAssertionFailure()
            return
        }
        UDToast.removeToast(on: hostView)
    }
    
    func cancelLoadingTimer() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }
    
    func showToast(toastModel: ToastModel, actionCallback: APICallbackProtocol?) {
        
        guard let hostView = self.fromVC?.view else { return }
        
        let duration = TimeInterval(toastModel.duration ?? 0)
        let type = toastModel.type
        let message = toastModel.message
        
        func toastWithAction(_ toastType: UDToastType) -> UDToast? {
            if let buttonMessage = toastModel.buttonMessage,
                  !buttonMessage.isEmpty,
                  let callback = actionCallback {

                let operation = UDToastOperationConfig(text: buttonMessage, displayType: buttonMessage.count > 5 ? .vertical : .auto)
                let config = UDToastConfig(toastType: toastType, text: message, operation: operation)
                
                return UDToast.showToast(with: config,
                                            on: hostView,
                                         delay: duration, dismissCallBack:  {
                    callback.callbackSuccess()
                })
                
            } else {
                let config = UDToastConfig(toastType: toastType, text: message, operation: nil)
                return UDToast.showToast(with: config, on: hostView, delay: duration)
            }
        }

        var keyboardMargin: CGFloat = 100
        let hud: UDToast
        switch type {
        case .fail:
            hud = UDToast.showFailure(with: message, on: hostView)
        case .succ:
            hud = UDToast.showSuccess(with: message, on: hostView)
        case .successWithAction:
            guard let _hud = toastWithAction(.success) else { return }
            hud = _hud
        case .loading:
            hud = UDToast.showLoading(with: message, on: hostView)
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
            hud = UDToast.showTips(with: message, on: hostView)
        }
        hud.keyboardMargin = keyboardMargin
    }
}


class ShowToastHandler: WABridgeHandler {
    var name: WABridgeName {
        return .showToast
    }
    
    var serviceType: WABridgeServiceType {
        return .UI
    }
    
    weak var toastService: ToastService?
    
    init(_ service: ToastService) {
        self.toastService = service
    }
    
    
    func handle(invocation: WABridgeInvocation) {
        guard let toastModel = try? CodableUtility.decode(ToastModel.self, withJSONObject: invocation.params) else {
            spaceAssertionFailure("error toast params")
            return
        }
        toastService?.hideAllToast(animate: false)
        toastService?.cancelLoadingTimer()
        toastService?.showToast(toastModel: toastModel,
                                actionCallback: invocation.callback)
    }
    
}


class HideToastHandler: WABridgeHandler {
    
    var name: WABridgeName {
        return .hideToast
    }
    
    var serviceType: WABridgeServiceType {
        return .UI
    }
    
    weak var toastService: ToastService?
    
    init(_ service: ToastService) {
        self.toastService = service
    }
    
    func handle(invocation: WABridgeInvocation) {
        toastService?.hideAllToast(animate: true)
    }
}
