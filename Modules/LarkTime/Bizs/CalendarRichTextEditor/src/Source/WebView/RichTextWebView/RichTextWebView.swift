//
//  RichTextWebView.swift
//  CalendarRichTextEditor
//
//  Created by Rico on 2021/2/20.
//

import LarkWebViewContainer
import WebKit
import LarkOPInterface

/// 基于统一套件LarkWebView的类
final class RichTextWebView: LarkWebView {
    public weak var responderDelegate: DocsWebViewResponderDelegate?
    var inputInterceptor: RTWebViewInputInterceptor
    weak var rtWebViewDelegate: WebDelegate?
    public var openSelectTranslateHandler: ((String) -> Void)?

    public convenience init(frame: CGRect,
                            configuration: WKWebViewConfiguration,
                            performanceTimingEnable: Bool = false,
                            vConsoleEnable: Bool = false) {
        let config =
            LarkWebViewConfigBuilder()
            .setWebViewConfig(configuration)
            .build(bizType: LarkWebViewBizType.calendar,
                   isAutoSyncCookie: false,
                   performanceTimingEnable: true,
                   vConsoleEnable: vConsoleEnable)
        let trace = OPTraceService.default().generateTrace()
        self.init(frame: frame, config: config, parentTrace: trace, webviewDelegate: nil)
        backgroundColor = .clear
        self.scrollView.keyboardDismissMode = .interactive
        inputInterceptor.delegate = self
        self.webviewDelegate = self
        DispatchQueue.main.once {
            LarkWebView.allowDisplayingKeyboardWithoutUserAction()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView?.backgroundColor = .clear
    }

    public override init(frame: CGRect, config: LarkWebViewConfig, parentTrace: OPTrace?, webviewDelegate: LarkWebViewDelegate?) {
        inputInterceptor = RTWebViewInputInterceptor()
        super.init(frame: frame, config: config, parentTrace: parentTrace, webviewDelegate: webviewDelegate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - RTWebViewInputInterceptorDelegate
extension RichTextWebView: RTWebViewInputInterceptorDelegate {
    func shouldWebViewReloadInputViews(_ interceptor: RTWebViewInputInterceptor) {
        Logger.debug("RichTextWebView: did reload WebView's inputViews")
        reloadInputViews()
    }

    func shouldContentViewReloadInputViews(_ interceptor: RTWebViewInputInterceptor) {
        Logger.debug("RichTextWebView: did reload ContentView's inputViews")
        contentView?.reloadInputViews()
    }
}

// MARK: - LarkWebViewDelegate
extension RichTextWebView: LarkWebViewDelegate {
    /// 自定义Headers
    public func buildExtraHttpHeaders() -> [String: String]? {
        return rtWebViewDelegate?.webRequestHeaders
    }

    /// 自定义User-Agent
    public func buildCustomUserAgent() -> String? {
        return self.rtWebViewDelegate?.webRequestHeaders["User-Agent"]
    }
}
