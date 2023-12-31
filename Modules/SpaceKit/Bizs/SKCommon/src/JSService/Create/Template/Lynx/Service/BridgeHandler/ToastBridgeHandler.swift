//
//  ToastBridgeHandler.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/11.
//  


import Foundation
import BDXServiceCenter
import BDXBridgeKit
import UniverseDesignToast
import EENavigator
import UIKit

class ToastBridgeHandler: BridgeHandler {
    let methodName = "ccm.showToast"

    let handler: BDXLynxBridgeHandler

    init(hostController: UIViewController) {
        handler = { [weak hostController] (_, _, params, callback) in
            guard let hostController = hostController else {
                return
            }
            var durationType: DurationType = .short
            if let duration = params?["duration"] as? Int, let type = DurationType(rawValue: duration) {
                durationType = type
            }
            var toastType: ToastType = .normal
            if let typeValue = params?["type"] as? String, let type = ToastType(rawValue: typeValue) {
                toastType = type
            }
            var msg = ""
            if let message = params?["message"] as? String {
                msg = message
            }
            let onWindow = params?["onWindow"] as? Bool ?? true
            Self.showToast(hostController: hostController, onWindow: onWindow, msg: msg, type: toastType, duration: durationType)
        }
    }

    private static func showToast(hostController: UIViewController, onWindow: Bool, msg: String, type: ToastType, duration: DurationType) {
        let targetView: UIView
        if onWindow {
            targetView = hostController.view.window ?? hostController.view
        } else {
            targetView = hostController.view
        }
        let delay: TimeInterval = duration == .short ? 2 : 3
        switch type {
        case .normal:
            UDToast.showTips(with: msg, on: targetView, delay: delay)
        case .success:
            UDToast.showSuccess(with: msg, on: targetView, delay: delay)
        case .fail:
            UDToast.showFailure(with: msg, on: targetView, delay: delay)
        case .center:
            UDToast.showTipsOnScreenCenter(with: msg, on: targetView, delay: delay)
        case .showLoading:
            UDToast.showLoading(with: msg, on: targetView, disableUserInteraction: true)
        case .hideLoading:
            UDToast.removeToast(on: targetView)
        }
    }

    enum DurationType: Int {
        case short = 0
        case long = 1
    }
    enum ToastType: String {
        case normal
        case success
        case fail
        case center
        case showLoading
        case hideLoading
    }
}
