//
//  SKBaseToastService.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/15.
//

import Foundation
import SKCommon
import SKUIKit
import EENavigator
import UniverseDesignToast

protocol SKToastPluginProtocol: AnyObject {
    func canShowToastNow() -> Bool
    func hideAllToast(animate: Bool)
    func showToast(_ message: String, actionMessage: String?, actionCallback: String?, type: SKBaseToastPlugin.ToastType, duration: TimeInterval)
    func actionCallback(callback: String, params: [String: Any]?)
    func cancelLoadingTimer()
}

class SKBaseToastPlugin: JSServiceHandler {
    weak var pluginProtocol: SKToastPluginProtocol?
    var logPrefix: String = ""
    var loadingTimer: Timer?
    lazy var hostView: UIView = {
        UIView()
    }()
    var handleServices: [DocsJSService] = [.utilHideToast, .utilShowToast]
    func handle(params: [String: Any], serviceName: String) {
        guard pluginProtocol?.canShowToastNow() ?? false else {
            skInfo(logPrefix + "can not show toast now")
            return
        }
        switch serviceName {
        case DocsJSService.utilHideToast.rawValue:
            hideAllToast()
        case DocsJSService.utilShowToast.rawValue:
            guard let message = params["message"] as? String,
                let typeRaw = params["type"] as? Int,
                let type = ToastType(rawValue: typeRaw) else {
                    skInfo(logPrefix + "error toast params", extraInfo: params, error: nil, component: nil)
                    skAssertionFailure("error toast params")
                    return
            }
            let duration = params["duration"] as? Float ?? 0
            hideAllToast(animate: false)
            cancelLoadingTimer()
            let buttonMessage = params["buttonMessage"] as? String
            let callback = params["callback"] as? String
            showToast(message, actionMessage: buttonMessage, actionCallback: callback, type: type, duration: TimeInterval(duration))
        default:
            skAssertionFailure("can not handler \(serviceName)")
        }
    }

    private func hideAllToast(animate: Bool = true) {
        if pluginProtocol != nil {
            pluginProtocol?.hideAllToast(animate: animate)
        } else {
            UDToast.removeToast(on: hostView)
        }
    }
    
    private func cancelLoadingTimer() {
        if pluginProtocol != nil {
            pluginProtocol?.cancelLoadingTimer()
        } else {
            loadingTimer?.invalidate()
            loadingTimer = nil
        }
    }

    private func showToast(_ message: String, actionMessage: String?, actionCallback: String?, type: SKBaseToastPlugin.ToastType, duration: TimeInterval) {
        func showToastWithAction(toastType: UDToastType) {
            guard let window = hostView.affiliatedWindow else {
                return
            }
            if let buttonMessage = actionMessage,
                  !buttonMessage.isEmpty,
                  let callback = actionCallback {
                let operation = UDToastOperationConfig(text: buttonMessage, displayType: buttonMessage.count > 5 ? .vertical : .auto)
                let config = UDToastConfig(toastType: toastType, text: message, operation: operation)

                UDToast.showToast(with: config,
                                  on: window,
                                  delay: duration) { [weak self] _ in
                    self?.pluginProtocol?.actionCallback(callback: callback, params: nil)
                }
            } else {
                let config = UDToastConfig(toastType: toastType, text: message, operation: nil)
                UDToast.showToast(with: config, on: window)
            }
        }
        if pluginProtocol != nil {
            pluginProtocol?.showToast(message, actionMessage: actionMessage, actionCallback: actionCallback, type: type, duration: duration)
            return
        }
        guard let window = hostView.affiliatedWindow else { return }
        switch type {
        case .fail:
            UDToast.showFailure(with: message, on: window)
        case .succ:
            UDToast.showSuccess(with: message, on: window)
        case .successWithAction:
            showToastWithAction(toastType: .success)
        case .warning:
            showToastWithAction(toastType: .warning)
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
        case .loading:
            UDToast.showLoading(with: message, on: window)
        case .tipWithAction:
            showToastWithAction(toastType: .info)
        default:
            UDToast.showTips(with: message, on: window)
        }
    }
}

extension SKBaseToastPlugin {
    enum ToastType: Int {
        case succ = 0
        case fail = 1
        case tipBottom = 2
        case tipCenter = 3
        case tipTop = 4
        case successWithAction = 5
        case tipWithAction = 6
        case warning = 7
        case loading = 8
    }
}
