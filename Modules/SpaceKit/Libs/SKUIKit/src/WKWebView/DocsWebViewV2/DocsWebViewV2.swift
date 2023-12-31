//
//  DocsWebViewV2.swift
//  SKUIKit
//
//  Created by lijuyou on 2020/10/9.
//  接入LarkWebView，将现有WebView功能迁移到LarkWebView
//  技术方案：https://bytedance.feishu.cn/docs/doccnPHLRhFWm1uETkTyIXzEcye


import Foundation
import LarkWebViewContainer
import WebKit
import SKFoundation
import LarkOPInterface
import LarkSetting

open class DocsWebViewV2: LarkWebView {

    public weak var responderDelegate: DocsEditorViewResponderDelegate?
    var inputInterceptor: SKWebViewInputInterceptor
    weak var skWebViewDelegate: EditorConfigDelegate?

    public convenience init(
        frame: CGRect,
        configuration: WKWebViewConfiguration,
        vConsoleEnable: Bool = false,
        bizType: LarkWebViewBizType = LarkWebViewBizType.docs,
        disableClearBridgeContext: Bool = false
    ) {
        let config = LarkWebViewConfigBuilder()
            .setWebViewConfig(configuration)
            .setDisableClearBridgeContext(disableClearBridgeContext)
            .build(
                bizType: bizType,
                isAutoSyncCookie: true,
                vConsoleEnable: vConsoleEnable,
                promptFGSystemEnable: true
            )
        self.init(frame: frame, config: config, parentTrace: nil, webviewDelegate: nil)
        if #available(iOS 16.4, *) {
            do {
                let key = UserSettingKey.make(userKeyLiteral: "ccm_mobile_system_bugfix")
                let manager = SettingManager.shared
                let settings = try manager.setting(with: key)
                if let inspect = settings["inspect"] as? Bool, inspect {
                    isInspectable = true
                }
            } catch {
                DocsLogger.error("try manager.setting(with: ccm_mobile_system_bugfix) error", error: error)
            }
        }
        self.scrollView.keyboardDismissMode = .interactive
        inputInterceptor.delegate = self
        self.webviewDelegate = self
        DispatchQueue.main.once {
            LarkWebView.allowDisplayingKeyboardWithoutUserAction()
        }

    }

    public override init(frame: CGRect, config: LarkWebViewConfig, parentTrace: OPTrace?, webviewDelegate: LarkWebViewDelegate?) {
        inputInterceptor = SKWebViewInputInterceptor()
        super.init(frame: frame, config: config, parentTrace: parentTrace, webviewDelegate: webviewDelegate)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("DocsWebViewV2 deinit")
    }
    
}

// MARK: DocsEditorViewResponderDelegate
extension DocsWebViewV2 {
    open override var canBecomeFirstResponder: Bool {
        return responderDelegate?.docsEditorViewShouldBecomeFirstResponder(self) ?? true
    }

    open override var canResignFirstResponder: Bool {
        return responderDelegate?.docsEditorViewShouldResignFirstResponder(self) ?? true
    }

    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        responderDelegate?.docsEditorViewWillBecomeFirstResponder(self)
        let res = super.becomeFirstResponder()
        DocsLogger.info("DocsWebViewV2 becomeFirstResponder:\(res)")
        responderDelegate?.docsEditorViewDidBecomeFirstResponder(self)
        return res
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        responderDelegate?.docsEditorViewWillResignFirstResponder(self)
        let res = super.resignFirstResponder()
        DocsLogger.info("DocsWebViewV2 resignFirstResponder:\(res)")
        responderDelegate?.docsEditorViewDidResignFirstResponder(self)
        return res
    }
}

private var menuKey: UInt8 = 0
private var contentMenuKey: UInt8 = 0
// MARK: DocsWebViewProtocol
extension DocsWebViewV2: DocsWebViewProtocol {
    
    ///自定义添加到webview的UIEditMenuInteraction
    @available(iOS 16.0, *)
    public var editMenuInteraction: UIEditMenuInteraction? {
        if let interaction = objc_getAssociatedObject(self, &menuKey) as? UIEditMenuInteraction {
            return interaction
        }
        for interaction in self.interactions where interaction is UIEditMenuInteraction {
            objc_setAssociatedObject(self, &menuKey, interaction, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return interaction as? UIEditMenuInteraction
        }
        return nil
    }
    
    ///webview.contentView上系统默认的UIEditMenuInteraction
    @available(iOS 16.0, *)
    public var contentEditMenuInteraction: UIEditMenuInteraction? {
        guard let contentView = self.contentView else { return nil }
        if let interaction = objc_getAssociatedObject(self, &contentMenuKey) as? UIEditMenuInteraction {
            return interaction
        }
        for interaction in contentView.interactions where interaction is UIEditMenuInteraction {
            objc_setAssociatedObject(self, &contentMenuKey, interaction, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return interaction as? UIEditMenuInteraction
        }
        return nil
    }
    

    public var editorViewType: EditorViewType {
        .webView
    }

    public func becomeFirst() -> Bool {
        return self.becomeFirstResponder()
    }

    public func resign() -> Bool {
        return self.resignFirstResponder()
    }

    public var skContextMenu: SKWebViewContextMenuProtocol {
        get { return self.contextMenu }
        set {
            if let menu = newValue as? SKWebViewContextMenu {
                self.contextMenu = menu
            }
        }
    }
    
    public var identifyId: String {
        get { return self.editorIdentity ?? "" }
        set {
            self.editorIdentity = newValue
        }
    }

    public var skActionHelper: SKWebViewActionHelper {
        self.actionHelper
    }

    public func safeSendMethod(selector: Selector!) {
        interceptSelector(selector)
        if responds(to: selector) {
            perform(selector, with: nil)
        } else if let contentV = contentView, contentV.responds(to: selector) {
            contentV.perform(selector, with: nil)
        }
    }

    // 某些方法需要在 webview 扩展它的行为，在此处拦截
    private func interceptSelector(_ selector: Selector) {
        if sel_isEqual(selector, #selector(selectAll(_:))) {
            let jsStr = "window.lark.biz.util.onSelectAll()"
            evaluateJavaScript(jsStr) { (_, error) in
                if let err = error {
                    DocsLogger.error("webview select all fail", extraInfo: ["str": jsStr], error: err, component: nil)
                }
            }
        }
    }

    public func setSKResponderDelegate(_ delegate: DocsEditorViewResponderDelegate?) {
        self.responderDelegate = delegate
    }

    public func setSKEditorConfigDelegate(_ delegate: EditorConfigDelegate?) {
        self.skWebViewDelegate = delegate
    }

    public func setSKGestureDelegate(_ delegate: EditorViewGestureDelegate?) {
        self.gestureDelegate = delegate
    }
}

// MARK: SKWebViewInputInterceptorDelegate
extension DocsWebViewV2: SKWebViewInputInterceptorDelegate {
    func shouldWebViewReloadInputViews(_ interceptor: SKWebViewInputInterceptor) {
        DocsLogger.debug("SKWebView: Did reload WebView's inputViews")
        reloadInputViews()
    }

    func shouldContentViewReloadInputViews(_ interceptor: SKWebViewInputInterceptor) {
        DocsLogger.debug("SKWebView: Did reload ContentView's inputViews")
        contentView?.reloadInputViews()
    }
}

@objc extension LarkWebView.LKWInputAccessory: SKInputAccessory {

}

extension DocsWebViewV2: SKProtocol {
    public var skEditorViewInputAccessory: SKInputAccessory {
        return self.inputAccessory
    }
}

extension DocsWebViewV2: LarkWebViewDelegate {

    /// 自定义Headers
    public func buildExtraHttpHeaders() -> [String: String]? {
        return skWebViewDelegate?.editorRequestHeaders
    }

    /// 自定义User-Agent
    public func buildCustomUserAgent() -> String? {
        return self.skWebViewDelegate?.editorRequestHeaders["User-Agent"]
    }

    /// 构建前端传递过来的Data
    public func buildAPIMessage(with messageBody: Any) -> APIMessage? {
        guard let body = messageBody as? [String: Any] else {
            DocsLogger.error("invaild jsmessage body")
            return nil
        }
        guard let apiName = body["apiName"] as? String else {
            DocsLogger.error("invaild apiName")
            return nil
        }
        var data: [String: Any]
        if let tempData = body["data"] as? [String: Any] {
            data = tempData
        } else {
            data = [String: Any]()
        }
        let callbackID = body["callbackID"] as? String
        if data["callback"] == nil && callbackID != nil {
            data["callback"] = callbackID //改成旧Bridge熟悉的callback格式
        }
        return APIMessage(apiName: apiName, data: data, callbackID: callbackID)
    }
}
