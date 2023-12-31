//
//  LeaveConfirmExtensionItem.swift
//  EcosystemWeb
//
//  Created by yinyuan on 2022/5/17.
//
import LarkWebViewContainer
import LKCommonsLogging
import UniverseDesignDialog
import WebBrowser
import WebKit

public enum WebLeaveComfirmEffect: String {
    case back
    case close
}

public struct WebLeaveComfirmModel {
    
    public let title: String
    public let content: String
    public let confirmText: String
    public let cancelText: String
    public let effect: [String]
    
    public init(title: String, content: String, confirmText: String, cancelText: String, effect: [String]) {
        self.title = title
        self.content = content
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.effect = effect
    }
}

public protocol WebLeaveConfirmProtocol {
    
    var leaveConfirm: WebLeaveComfirmModel? { get set }
    
}


private let logger = Logger.webBrowserLog(LeaveConfirmExtensionItem.self, category: "LeaveConfirmExtensionItem")

final public class LeaveConfirmExtensionItem: WebBrowserExtensionItemProtocol, WebLeaveConfirmProtocol {
    public var itemName: String? = "LeaveConfirm"
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = LeaveConfirmWebBrowserNavigation(item: self)
        
    public var leaveConfirm: WebLeaveComfirmModel? {
        didSet {
            logger.info("leaveConfirm info set \(leaveConfirm)")
        }
    }
    
    public init() {
        logger.info("LeaveConfirmExtensionItem loaded")
    }
    
    public func showConfirmIfNeeded(browser: WebBrowser, effect: WebLeaveComfirmEffect, callback: ((_ confirm: Bool) -> Void)?) -> Bool {
        guard let leaveConfirm = leaveConfirm else {
            // 未设置确认信息
            logger.info("leaveConfirm is nil")
            return false
        }
        guard leaveConfirm.effect.isEmpty || leaveConfirm.effect.contains(where: { effectStr in
            return WebLeaveComfirmEffect(rawValue: effectStr) == effect
        }) else {
            // 不处理目标场景
            logger.info("leaveConfirm.effect not match \(effect.rawValue)-\(leaveConfirm.effect)")
            return false
        }
        logger.info("show leaveConfirm from \(effect.rawValue)")
        let dialog = UDDialog()
        if !leaveConfirm.title.isEmpty {
            dialog.setTitle(text: leaveConfirm.title)
        }
        if !leaveConfirm.content.isEmpty {
            dialog.setContent(text: leaveConfirm.content)
        }
        dialog.addSecondaryButton(
            text: leaveConfirm.cancelText,
            dismissCompletion: { [weak browser] in
                logger.info("show leaveConfirm canceled")
                do {
                    let str = try LarkWebViewBridge.buildCallBackJavaScriptString(callbackID: "onLeaveConfirmCancel", params: [:], extra: nil, type: .continued)
                    browser?.webview.evaluateJavaScript(str)
                } catch {
                    logger.error("buildCallBackJavaScriptString failed.", error: error)
                }
                callback?(false)
            }
        )
        dialog.addPrimaryButton(
            text: leaveConfirm.confirmText,
            dismissCompletion: {
                logger.info("show leaveConfirm confirmed")
                callback?(true)
            }
        )
        browser.present(dialog, animated: true)
        return true
    }
    
}

final public class LeaveConfirmWebBrowserNavigation: WebBrowserNavigationProtocol {
    
    private weak var item: LeaveConfirmExtensionItem?
    
    init(item: LeaveConfirmExtensionItem) {
        self.item = item
    }

    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        // 页面跳转时先重置设置
        logger.info("reset leaveConfirm to nil")
        item?.leaveConfirm = nil
    }
}
