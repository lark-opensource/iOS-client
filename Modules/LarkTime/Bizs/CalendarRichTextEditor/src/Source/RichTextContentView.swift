//
//  DocsRichTextView.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/8.
//

import UIKit
import Foundation
import WebKit
import SystemConfiguration
import LarkWebViewContainer
import LarkFeatureGating
import UniverseDesignFont

typealias RichTextWebViewType = RichTextWebView

protocol RichTextContentViewDelegate: AnyObject {
    @discardableResult
    func contentView(_ contentView: RichTextContentView, requireOpen url: URL) -> Bool

    func contentViewDidTerminate(_ contentView: RichTextContentView)

    func contentView(_ contentView: RichTextContentView, didFinishLoad url: URL?)
}

final class RichTextContentView: UIView {
    weak var delegate: RichTextContentViewDelegate?

    public var openSelectTranslateHandler: ((String) -> Void)? {
        didSet {
            webView.openSelectTranslateHandler = openSelectTranslateHandler
        }
    }
    lazy var webView: RichTextWebViewType = {
        makeRichTextWebView()
    }()

    var menuType: RichTextContentViewMenuType? {
        didSet {
            webView.contextMenu.items = (menuType == .readOnly ? readOnlyMenuItem() : readWriteMenuItem())
        }
    }

    var bridge: LarkWebViewBridge?

    var oldContentOffset: CGPoint = .zero

    private var scriptMessageHandlerNames: Set<String> = []
    internal var timeline = Timeline()
    private var wkProcessTeminateCount = 0

    var canScroll = true
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        webView.scrollView.delegate = self
        webView.backgroundColor = .clear
        registerBridge()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.scriptMessageHandlerNames.forEach { (name) in
            self.webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
    }
}

extension RichTextContentView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !canScroll {
            // 处理键盘弹起/双击时，webview抖动
            // https://jmsliu.com/3461/set-uiwebview-content-not-to-scroll-when-keyboard-is-shown.html
            // https://stackoverflow.com/questions/33111617/disable-double-tap-scroll-on-wkwebview
            guard scrollView == self.webView.scrollView else { return }
            scrollView.contentOffset = oldContentOffset
        }
    }
}

// MARK: - Switch
extension RichTextContentView {
    private func makeRichTextWebView() -> RichTextWebViewType {
        let webViewConfig = WKWebViewConfiguration()
        webViewConfig.websiteDataStore = WKWebsiteDataStore.default()
        webViewConfig.setURLSchemeHandler(SourceSchemeHandler(), forURLScheme: SourceSchemeHandler.scheme)
        // 替换字体的scheme
        if UDFontAppearance.isCustomFont {
            webViewConfig.setURLSchemeHandler(FontFaceHandler(), forURLScheme: FontFaceHandler.scheme)
        }

        func _makeRichTextWebView() -> RichTextWebViewType {
            let web = RichTextWebView(frame: .zero, configuration: webViewConfig)
            web.inputAccessory.realInputAccessoryView = nil
            return web
        }

        let webView = _makeRichTextWebView()
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView
    }

    private func registerBridge() {
        let bridge = self.webView.lkwBridge
        bridge.registerBridge()
        self.bridge = bridge
    }

    private func readWriteMenuItem() -> [UIMenuItem] {
        return [UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Normal_SelectAll, action: #selector(RichTextWebView.selectAllAction(_:))),
        UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Normal_MenuCut, action: #selector(RichTextWebView.cutAction(_:))),
        UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Doc_Copy, action: #selector(RichTextWebView.copyAction(_:))),
        UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Doc_Paste, action: #selector(RichTextWebView.pasteAction(_:)))]
    }

    private func readOnlyMenuItem() -> [UIMenuItem] {
        if LarkFeatureGating.shared.getStaticBoolValue(for: FeatureGatingKey.supportSelectTranslate.rawValue) {
            return [UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Normal_SelectAll, action: #selector(RichTextWebView.selectAllAction(_:))),
                    UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Doc_Copy, action: #selector(RichTextWebView.copyAction(_:))),
                    UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate, action: #selector(RichTextWebView.translateAction(_:)))]
        }
        return [UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Normal_SelectAll, action: #selector(RichTextWebView.selectAllAction(_:))),
                UIMenuItem(title: BundleI18n.CalendarRichTextEditor.Doc_Doc_Copy, action: #selector(RichTextWebView.copyAction(_:)))]

    }

}

// MARK: - WKUIDelegate
extension RichTextContentView: WKUIDelegate {
    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
    }
}

extension RichTextContentView: WKNavigationDelegate {
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let extraInfo = [
            "次数": wkProcessTeminateCount + 1,
            "URL": self.webView.url?.hashValue.description ?? "nourl"
            ] as [String: Any]
        wkProcessTeminateCount += 1
        Logger.error("RichTextContentView has been terminated", extraInfo: extraInfo)
        self.delegate?.contentViewDidTerminate(self)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        Logger.info("\(ObjectIdentifier(self)) RichTextContentView 处理导航: \(navigationAction.request.url?.hashValue.description ?? "")")

        guard let naviUrl = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let actionPolicy: WKNavigationActionPolicy = delegate?.contentView(self, requireOpen: naviUrl) == true ? .allow : .cancel
        decisionHandler(actionPolicy)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        Logger.info("\(ObjectIdentifier(self)) RichTextContentView 处理响应前")
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Logger.info("\(ObjectIdentifier(self)) RichTextContentView 开始请求")
        self.timeline = Timeline()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Logger.info("\(ObjectIdentifier(self)) RichTextContentView 加载成功")
        delegate?.contentView(self, didFinishLoad: webView.url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Logger.error("RichTextContentView 加载失败", extraInfo: ["contentView": "\(ObjectIdentifier(self))"], error: nil, component: nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Logger.error("RichTextContentView 启动时加载数据发生错误", extraInfo: ["contentView": "\(ObjectIdentifier(self))"], error: nil, component: nil)
    }
}
