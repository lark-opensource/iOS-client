//
//  SKBaseAlertPlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/15.
//  

import Foundation
import EENavigator
import SKCommon
import UniverseDesignDialog
import UniverseDesignInput
import SKUIKit
import SKFoundation
import LarkExtensions

class SKBaseAlertPluginConfig {
    weak var executeJsService: SKExecJSFuncService?
    weak var hostView: UIView?
    weak var hostService: BaseJSService?
    init(executeJsService: SKExecJSFuncService?, hostView: UIView?) {
        self.executeJsService = executeJsService
        self.hostView = hostView
    }
}

class SKBaseAlertPlugin: JSServiceHandler {
    
    var logPrefix: String = ""
    var docsInfo: DocsInfo?
    private let config: SKBaseAlertPluginConfig

    var currentAlertWindow: UIWindow? // 暴露给外部，判断是否有 alert 展示
    private weak var showingAlert: UDDialog?
    private weak var confirmButton: UIButton?
    private weak var inputField: UDTextField?

    init(_ config: SKBaseAlertPluginConfig) {
        self.config = config
    }

    var handleServices: [DocsJSService] {
        return [.utilAlert]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard serviceName == DocsJSService.utilAlert.rawValue else {
            skAssertionFailure(logPrefix + "can not handler \(serviceName)")
            return
        }

        if let showingAlert = showingAlert {
            showingAlert.dismiss(animated: false, completion: nil)
            self.showingAlert = nil
        }

        let supportLandscape = self.config.hostService?.topMostOfBrowserVC()?.supportedInterfaceOrientations == .allButUpsideDown
        if let alertController = _constructAlertController(params, supportLandscape: supportLandscape),
           let window = config.hostView?.affiliatedWindow {
            if supportLandscape {
                DispatchQueue.main.async {
                    self.showAlert(alertController, in: window, supportLandscape: supportLandscape)
                }
            } else {
                LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                    self?.showAlert(alertController, in: window, supportLandscape: supportLandscape)
                }
            }
        }
    }

    private func _constructAlertController(_ params: [String: Any], supportLandscape: Bool) -> UDDialog? {
        guard let callback = params["callback"] as? String else {
            skInfo(logPrefix + "can not get call back")
            skAssertionFailure()
            return nil
        }

        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.isAutorotatable = supportLandscape

        let rawTitle = params["title"] as? String ?? ""
        let rawMessage = params["message"] as? String ?? ""
        let options = params["options"] as? [String: Any]
        var alignment = NSTextAlignment.left
        if let rawMessageAlign = options?["message_align"] as? Int,
            let messageAlign = Align(rawValue: rawMessageAlign) {
            alignment = messageAlign.parseToNSTextAlignment
        }
        
        var hasCheckBox = false
        if let checkBoxHint = params["checkBoxHint"] as? String {
            hasCheckBox = true
            var textStyle = UDDialog.TextStyle.content()
            textStyle.alignment = alignment
            dialog.setTitle(text: rawTitle, checkButton: true)
            dialog.setContent(text: rawMessage, style: textStyle, checkButton: true)
            dialog.setCheckButton(text: checkBoxHint, style: .square)
        } else {
            dialog.setTitle(text: rawTitle)
            dialog.setContent(text: rawMessage, alignment: alignment)
        }

        if let buttonInfos = params["buttons"] as? [[String: Any]] {
            buttonInfos.forEach { (rawInfo) in
                if let text = rawInfo["text"] as? String,
                    let id = rawInfo["id"] as? String,
                    let color = rawInfo["color"] as? Int {
                    let info = AlertActionInfo(text: text, id: id, color: color)

                    let dismissCompletion = { [weak self, weak dialog] in
                        guard let self = self else { return }
                        self.currentAlertWindow?.resignKey()
                        self.currentAlertWindow?.isHidden = true
                        self.currentAlertWindow?.removeFromSuperview()
                        self.currentAlertWindow = nil

                        var params: [String: Any] = ["id": id]
                        if let inputField = self.inputField, let text = inputField.text {
                            params["input"] = text
                        }
                        if hasCheckBox {
                            params["isChecked"] = dialog?.isChecked ?? false
                        }
                        self.config.executeJsService?.callFunction(DocsJSCallBack(callback), params: params, completion: { [weak self] (_, error) in
                            if let message = error?.localizedDescription {
                                skInfo((self?.logPrefix ?? "") + message)
                            }
                        })
                    }

                    var button: UIButton

                    switch info.color {
                    case 0:
                        button = dialog.addSecondaryButton(text: text, dismissCompletion: dismissCompletion)
                    case 1:
                        button = dialog.addDestructiveButton(text: text, dismissCompletion: dismissCompletion)
                    case 2:
                        button = dialog.addPrimaryButton(text: text, dismissCompletion: dismissCompletion)
                    default:
                        button = dialog.addSecondaryButton(text: text, dismissCompletion: dismissCompletion)
                    }
                    if id == "confirm" {
                        confirmButton = button
                    }
                }
            }
        }

        if let inputText = params["input"] as? String { // 如果前端传了这个字段，说明要在 alert 里面插入一个文本输入框，且 inputText 是框内初始文本
            inputField = dialog.addTextField(placeholder: "", text: inputText)
            // 是否需要单一文档控制，UDDialog是在另外个window打开的，所以这里需要单独传pointId
            let encryptToken: String?
            if let srcToken = params["srcObjToken"] as? String, !srcToken.isEmpty {
                // 优先用前端传的 token 进行加密
                encryptToken = srcToken
            } else {
                // 前端没传用文档的 token 进行加密
                encryptToken = docsInfo?.objToken
            }
            let encryptId = ClipboardManager.shared.getEncryptId(token: encryptToken)
            inputField?.input.pointId = encryptId
            
            if let confirmButton = confirmButton {
                dialog.bindInputEventWithConfirmButton(confirmButton)
            }
        }

        return dialog
    }
    
    func showAlert(_ alertController: UDDialog, in window: UIWindow, supportLandscape: Bool) {
        self.currentAlertWindow = self.innerShowAlert(alertController, in: window, supportLandscape: supportLandscape)
        self.showingAlert = alertController
    }

    private func innerShowAlert(_ alertController: UDDialog, in currentWindow: UIWindow, supportLandscape: Bool) -> UIWindow? {
        let alertWindow: UIWindow
        if let currentAlertWindow = currentAlertWindow {
            // 有可能存在 alert 上再弹 alert 的情况，这个时候旧的 alert 被 dismiss，window 得以复用
            alertWindow = currentAlertWindow
        } else {
            if #available(iOS 13.0, *), let scene = currentWindow.windowScene {
                alertWindow = UIWindow(windowScene: scene) // iOS 13 以上一定要用这种方式来创建 window
            } else {
                alertWindow = UIWindow(frame: currentWindow.frame)
            }
        }
        alertWindow.windowIdentifier = "SKBrowser.alertWindow"
        alertWindow.windowLevel = currentWindow.windowLevel + 1
        alertWindow.backgroundColor = .clear
        if let tintColor = currentWindow.tintColor {
            alertWindow.tintColor = tintColor
        }
       
        alertWindow.rootViewController = AlertHostViewController(supportLandscape)
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true) { [weak self] in
            if self?.inputField != nil {
                self?.inputField?.input.becomeFirstResponder()
            }
        }

        return alertWindow
    }
}

extension SKBaseAlertPlugin {

    private enum Align: Int {
        case left = 0 // 居中
        case center = 1 // 居左
        case right = 2 // 居右

        var parseToNSTextAlignment: NSTextAlignment {
            return NSTextAlignment(rawValue: self.rawValue) ?? .left // 默认左对齐
        }
    }

    private struct AlertActionInfo {
        let text: String
        let id: String
        /// 按钮文字颜色，对应不同类型按钮
        /// 0: secondaryButton 黑字
        /// 1: destructiveButton 红字
        /// 2: primaryButton 蓝字
        let color: Int
    }

}

private class AlertHostViewController: UIViewController {
    var supportLandscape: Bool = false
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return supportLandscape ? .allButUpsideDown : .portrait
    }
    init(_ supportLandscape: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.supportLandscape = supportLandscape
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
