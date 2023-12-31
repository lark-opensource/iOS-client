//
//  SSRWebViewContainer.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/23.
//  https://bytedance.feishu.cn/wiki/VYUYw8PGQiB7NWkB8kVcaXdYngf#PEmmdqecuoEK6wxXVWflYMmmgBD


import SKFoundation
import SKUIKit
import SKCommon
import WebKit
import LarkWebViewContainer
import UniverseDesignLoading
import UniverseDesignColor
import SKInfra
import UniverseDesignIcon

protocol SSRWebViewContainerDelegate: AnyObject {
    func onRequestCloseSSRWebView()
    func onRequestHideSSRLoading()
}

class SSRWebViewContainer: UIView {
    
    lazy var webView = WebBrowserView.makeDefaultWebView(
        bizType: LarkWebViewBizType("docs.ssr")
    ) as WKWebView
    
    private(set) weak var browserView: BrowserView?
    let tipsLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        label.text = "SSR WebView"
        label.backgroundColor = .orange
        label.textColor = .white
        return label
    }()
    
    let jsServiceManager = SSRWebServiceManager()
    weak var delegate: SSRWebViewContainerDelegate?
    private var ssrData: [String: Any]?
    var hasSSRData: Bool {
        self.ssrData != nil
    }
    private(set) var isRenderEnd = false
    private(set) var hasLoadUrl = false
    
    init(hostView: BrowserView) {
        browserView = hostView
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupUI() {
        addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        if OpenAPI.docs.enableSSRCahceToastForTest || OpenAPI.docs.enableKeepSSRWebViewTest{
            addSubview(tipsLabel)
            tipsLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(30)
                make.right.equalToSuperview().offset(-30)
            }
        }
        
        if OpenAPI.docs.enableKeepSSRWebViewTest {
            
            let closeBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            closeBtn.backgroundColor = .orange
            closeBtn.setBackgroundImage(UDIcon.closeOutlined, for: .normal)
            addSubview(closeBtn)
            closeBtn.snp.makeConstraints { make in
                make.left.equalTo(tipsLabel.snp.right).offset(5)
                make.centerY.equalTo(tipsLabel.snp.centerY)
            }
            closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        }
        
        self.backgroundColor = UDColor.bgBody
        webView.isOpaque = false //避免DarkMode下有一瞬间白底
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        setupWebView()
    }
    
    private func setupWebView() {
        if let docsWebView = webView as? DocsWebViewV2 {
            docsWebView.setSKEditorConfigDelegate(browserView?.docsLoader)
        }
        registerBridge()
    }
    
    private func registerBridge() {
        guard let lkWebView = self.webView as? DocsWebViewV2 else {
            return
        }
        
        let bridge = lkWebView.lkwBridge
        bridge.registerBridge()
        let commonHandler = LarkWebViewAPIHandler(jsServiceManager: self.jsServiceManager)
        self.jsServiceManager.lkwBridge = bridge
        self.jsServiceManager.lkwAPIHandler = commonHandler
        
        if let browserView = self.browserView {
            let loadingService = SSRLoadingService(ui: browserView, model: browserView, navigator: browserView)
            loadingService.delegate = self
            _ = self.jsServiceManager.register(handler: loadingService)
    
            let preloadService = SSRPreloadReadyService(ui: browserView, model: browserView, navigator: browserView)
            preloadService.delegate = self
            _ = self.jsServiceManager.register(handler: preloadService)
            
            _ = self.jsServiceManager.register(handler: SSRReportService(ui: browserView, model: browserView, navigator: browserView))
        }
    }
    
    /// SSRWebView开始加载
    private func startToLoadIfNeed() {
        guard hasLoadUrl == false else {
            spaceAssertionFailure()
            DocsLogger.error("[ssr] has already LoadUrl", component: LogComponents.ssrWebView)
            return
        }
        guard let url = DocsUrlUtil.ssrFrameTemplateURL() else {
            spaceAssertionFailure()
            return
        }
        //统计ssrWebView耗时 start
        OpenFileRecord.startRecordTimeConsumingFor(sessionID: self.browserView?.browserInfo.openSessionID,
                                                   stage: OpenFileRecord.Stage.ssrWebView.rawValue,
                                                   parameters: nil)
        webView.load(URLRequest(url: url))
        hasLoadUrl = true
        DocsLogger.info("[ssr] startToLoad:\(url)", component: LogComponents.ssrWebView)
        self.isRenderEnd = false
    }

    func render(ssr: [String: Any]) -> Bool {
        self.ssrData = ssr
        self.startToLoadIfNeed()
        return true
    }
    
    @objc
    func close() {
        self.delegate?.onRequestCloseSSRWebView()
    }


}

extension SSRWebViewContainer: SSRPreloadReadyServiceDelegate {
    func onSSRTemplatePreloadReady() {
        guard let ssr = self.ssrData,
              let ssrString = ssr.ext.toString() else {
            DocsLogger.error("[ssr] data is nil", component: LogComponents.ssrWebView)
            return
        }
        DocsLogger.info("[ssr] start to render ssrwebview", component: LogComponents.ssrWebView)
        let script = "window.renderCacheHTML(\(ssrString))"
        webView.isOpaque = true //真正render前改为不透明，提高渲染性能
        self.webView.evaluateJavaScript(script) { (_, error) in
            guard let error = error else { return }
            DocsLogger.error("[ssr] render ssr js fail,", error: error, component: LogComponents.ssrWebView)
        }
    }
}

extension SSRWebViewContainer: SSRLoadingServiceDelegate {
    func onHideLoading() {
        DocsLogger.info("[ssr] hide loading", component: LogComponents.ssrWebView)
        self.isRenderEnd = true
        
        //统计ssrWebView耗时 end
        OpenFileRecord.endRecordTimeConsumingFor(sessionID: self.browserView?.browserInfo.openSessionID,
                                                 stage: OpenFileRecord.Stage.ssrWebView.rawValue,
                                                 parameters: nil)
        self.delegate?.onRequestHideSSRLoading()
    }
}
