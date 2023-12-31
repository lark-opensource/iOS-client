//
//  DocsRichTextView.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/11.
//

import UIKit
import Foundation

public protocol DocsRichTextViewDataSource: AnyObject {
//    func requireRenderDataWhenTerminate() -> String? //do it later
}

public final class DocsRichTextView: UIView {
    let eventDispatch: ViewLifeCycleDispatch
    let contentView: RichTextContentView
    let jsServiceManager: JSSerivceManager
    public var bridgeInvalid: Bool = false
    private let keyboardMonitor: KeyboardMonitor
    public weak var delegate: DocsRichTextViewDelegate?
    public weak var dataSource: DocsRichTextViewDataSource?
    public private(set) var didJsEngineReady: Bool = false
    let editor: RichTextEditorInterface
    let themeMonitor: ThemeMonitor
    public var disableBecomeFirstResponder: (() -> Bool)?
    public var customHandle: ((URL, [String: Any]?) -> Void)?
    public var openSelectTranslateHandler: ((String) -> Void)? {
        didSet {
            contentView.openSelectTranslateHandler = openSelectTranslateHandler
        }
    }

    public init(frame: CGRect = .zero, themeConfig: ThemeConfig? = nil) {
        self.contentView = RichTextContentView(frame: .zero)
        self.jsServiceManager = JSSerivceManager()
        self.keyboardMonitor = KeyboardMonitor()
        self.eventDispatch = ViewLifeCycleDispatch()
        self.editor = DocsRichTextView._makeEditor()
        self.themeMonitor = ThemeMonitor(webView: contentView.webView, editor: editor, themeConfig: themeConfig)
        super.init(frame: frame)

        contentView.webView.setCLDWebDelegate(self)
        contentView.webView.setCLDResponderDelegate(self)
        contentView.delegate = self

        jsServiceManager.registerServices(for: self, larkWebViewBridge: contentView.bridge)
        keyboardMonitor.delegate = self
        editor.jsEngine = self

        setupViews()
        themeMonitor.refreshStyle()
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        themeMonitor.refreshStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startMonitorKeyboard() {
        keyboardMonitor.start()
    }

    func stopMonitorKeyboard() {
        keyboardMonitor.stop()
    }

    func injectDomain(domainPool: [String], spaceApiDomain: String, mainDomain: String) {
        loader.injectDomain(domainPool: domainPool, spaceApiDomain: spaceApiDomain, mainDomain: mainDomain)
    }

    @discardableResult
    public func loadCalendar() -> Bool {
        assert(delegate != nil)
        // self.injectDomain(domainPool: [], spaceApiDomain: "", mainDomain: "")
        return loader.loadCalendar()
    }

    private func setupViews() {
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    static private func _makeEditor() -> RichTextEditorInterface {
        return RichTextEditorV2()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if let changed = previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) {
              themeMonitor.refreshStyle()
            }
        }
    }

    private lazy var loader: RichTextViewLoader = {
        return RichTextViewLoader(self.contentView.webView)
    }()
}

extension DocsRichTextView: WebDelegate {
    public var webRequestHeaders: [String: String] {
        return loader.webRequestHeaders
    }
}

extension DocsRichTextView: DocsWebViewResponderDelegate {
    func disableBecomeFirstResponder(_ webView: RichTextWebView) -> Bool {
        return disableBecomeFirstResponder?() ?? false
    }
}

extension DocsRichTextView: KeyboardMonitorDelegate {
    var richTextView: UIView { return self }
    var richTextInputAccessory: UIView? {
        return contentView.webView.cldWebViewInputAccessory.realInputAccessoryView
    }

    func keyboardMonitor(_ monitor: KeyboardMonitor, didChange keyboardInfo: KeyBoadInfo) {
        eventDispatch.browserKeyboardDidChange(keyboardInfo)
    }
    func updateWebViewOldContentOffset() {
        contentView.oldContentOffset = contentView.webView.scrollView.contentOffset
    }
    func setWebViewScroll(isEnable: Bool) {
        contentView.canScroll = isEnable
    }
}

extension DocsRichTextView: RichTextViewJSEngine {

    var webView: RichTextWebView { return contentView.webView }
    var webViewIdentity: String { return "\(ObjectIdentifier(self))" }

    func callFunction(_ function: JSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {

        var paramsStr: String?
        if let params = params, JSONSerialization.isValidJSONObject(params) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
                paramsStr = String(data: jsonData, encoding: .utf8)
            } catch {
                Logger.error("callFunction, JSONSerialization error=\(error), function=\(function), params=\(params)")
            }
        }

        let script = function.rawValue + "(\(paramsStr ?? ""))"
        evaluateJavaScript(script, completionHandler: completion)

    }

    public func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        contentView.webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    public var isBusy: Bool {
        get { return jsServiceManager.isBusy }
        set { jsServiceManager.isBusy = newValue }
    }

    func jsContextDidReady() {
        didJsEngineReady = true
        delegate?.richTextViewJSContextDidReady()
    }
}

extension DocsRichTextView: RichTextViewUIResponse {
    var inputAccessory: UIView? {
        get { contentView.webView.cldWebViewInputAccessory.realInputAccessoryView }
        set {
            if let newValue = newValue {
                contentView.webView.cldWebViewInputAccessory.realInputAccessoryView = newValue
            } else {
                contentView.webView.cldWebViewInputAccessory.realInputAccessoryView = UIView()
            }
        }
    }

    @discardableResult
    public func becomeFirst(trigger: String) -> Bool {
        return contentView.webView.becomeFirstResponder()
    }

    public func becomeFirst() -> Bool {
        return contentView.webView.becomeFirstResponder()
    }

    public func setTrigger(trigger: String) {
    }

    public func addKeyboardResponder(_ responder: UIResponder) {}

    @discardableResult
    public func resign() -> Bool {
        return contentView.webView.resignFirstResponder()
    }
}

extension DocsRichTextView: RichTextViewDisplayConfig {
    func setContextMenus(items: [UIMenuItem]) {
        contentView.webView.contextMenu.items = items
    }

    func updateContentHeight(_ height: CGFloat) {
        var size = self.frame.size
        size.height = height + 15
        delegate?.richTextViewContentSizeDidChange(size)
    }

    func pushOnpasteAutoAuth(_ authInfo: [Bool]) {
        delegate?.onPasteDetectedDocLinks(accessInfos: authInfo)
    }
}

extension DocsRichTextView: RichTextViewBridgeConfig {
    func setJSBridge(_ bridge: String, for jsName: String) {
        if let v2editor = editor as? RichTextEditorV2 {
            v2editor.updateJSBridge(bridge, for: jsName)
        }
    }
}

extension DocsRichTextView: RichTextContentViewDelegate {
    func contentView(_ contentView: RichTextContentView, requireOpen url: URL) -> Bool {
        let canHandle = loader.isTemplateURL(url)
        if !canHandle {
            return delegate?.richTextView(requireOpen: url) ?? false
        }
        return canHandle
    }

    func contentViewDidTerminate(_ contentView: RichTextContentView) {
        Logger.info("RichTextView did terminate")
        if let v2editor = editor as? RichTextEditorV2 {
            v2editor.clearBridges()
            v2editor.removeAllTasks()
            // 标记bridge不可用
            bridgeInvalid = true
        }
        if !loader.reloadWhenTerminate() {
            Logger.info("RichTextView resume fail")
        }
    }

    func contentView(_ contentView: RichTextContentView, didFinishLoad url: URL?) {
        self.themeMonitor.refreshStyle()
    }
}
