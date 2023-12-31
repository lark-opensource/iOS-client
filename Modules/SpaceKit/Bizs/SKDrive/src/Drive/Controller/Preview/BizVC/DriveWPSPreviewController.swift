//
//  DriveWPSPreviewController.swift
//  SKECM
//
//  Created by ZhangYuanping on 2021/4/2.
//  
// swiftlint:disable cyclomatic_complexity file_length
//

import UIKit
import WebKit
import SKFoundation
import SKCommon
import EENavigator
import RxSwift
import JavaScriptCore
import SKUIKit
import SKResource
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignLoading
import SKInfra

class DriveWPSPreviewController: UIViewController {

    weak var bizVCDelegate: DriveBizViewControllerDelegate?
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    private var displayMode: DrivePreviewMode
    private let presentationModeEnable: Bool
    private let viewModel: DriveWPSPreviewViewModel
    private let tapHandler = DriveTapEnterFullModeHandler()
    private let draggingHandler = DriveDraggingEnterFullModeHandler()
    private let disposeBag = DisposeBag()
    private var didSetupEditButton = false
    private var secretLevelSelectProxy: SecretLevelSelectProxy?
    private lazy var webView: WKWebView = {
        let view = WKWebView()
        // WPS 内容目前不支持 DarkMode，避免在 DarkMode 下出现闪现黑白的情况，这里配置为 primaryOnPrimaryFill
        view.backgroundColor = UDColor.primaryOnPrimaryFill
        view.navigationDelegate = self
        return view
    }()
    
    private var loadingIndicatorView: UDSpin = {
        let view = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 20, color: UDColor.N400), textLabelConfig: nil))
        view.isHidden = true
        return view
    }()
    
    private lazy var cardModeLoadingView: DriveFileBlockLoadingView = {
        let view = DriveFileBlockLoadingView()
        view.isHidden = true
        return view
    }()
    
    private lazy var loadFailedView: DriveFetchFailedView = {
        let view = DriveFetchFailedView(frame: .zero)
        view.retryAction = { [weak self] in
            self?.reloadTemplate()
        }
        view.render(status: .failed)
        return view
    }()
    
    private var supportedOrientations: UIInterfaceOrientationMask = [.portrait]
    
    private var editButton: SKEditButton = SKEditButton()
    private var isInPresentationMode: Bool = false
    private var webviewTemplateDidLoaded: Bool = false
    private var currentRetryCount = 0
    
    init(previewInfo: DriveWPSPreviewInfo, displayMode: DrivePreviewMode, presentationModeEnable: Bool = true) {
        viewModel = DriveWPSPreviewViewModel(info: previewInfo)
        self.displayMode = displayMode
        self.presentationModeEnable = presentationModeEnable
        super.init(nibName: nil, bundle: nil)

        // slardar memory warning from Lark iOS 内存压力监听方案: https://bytedance.feishu.cn/wiki/wikcnBptylmllRsEZDSQ0WkzcFg
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryLevelNotification(_:)),
                                               name: NSNotification.Name(rawValue: SKMemoryMonitor.memoryWarningNotification),
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        SKMemoryMonitor.logMemory(
            when: "drive.wps.preview - DriveWPSPreviewController deinit",
            component: LogComponents.drive)

        unregisterJSEventHandler()
        DocsLogger.driveInfo("drive.wps.preview - DriveWPSPreviewController deinit")
    }
    
    override func viewDidLoad() {
        SKMemoryMonitor.logMemory(
            when: "drive.wps.preview - DriveWPSPreviewController viewDidLoad",
            component: LogComponents.drive)

        super.viewDidLoad()
        setupUI()
        setupWebkitTouchCallout()
        registerJSEventHandler()
        bindViewModel()
        loadWPSTemplate()
        disableScaleIfNeeded()
        monitorTemplateLoadingTimeout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setToLandscapeIfNeed()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return supportedOrientations
    }
    
    private func setupUI() {
        view.accessibilityIdentifier = "drive.wpsPreview.view"
        view.backgroundColor = UIColor.ud.N00
        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingIndicatorView.reset()
        
        UIView.performWithoutAnimation {
            view.insertSubview(webView, belowSubview: loadingIndicatorView)
            webView.snp.makeConstraints { make in
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
                make.top.bottom.equalToSuperview()
            }
            view.layoutIfNeeded()
        }
        view.addSubview(editButton)
        editButton.layer.cornerRadius = 24
        editButton.isHidden = true
        
        if displayMode == .card {
            view.addSubview(cardModeLoadingView)
            cardModeLoadingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func showLoading() {
        if displayMode == .card {
            cardModeLoadingView.isHidden = false
            cardModeLoadingView.startAnimate()
        } else {
            loadingIndicatorView.reset()
            loadingIndicatorView.isHidden = false
        }
    }
    
    private func hideLoading() {
        loadingIndicatorView.isHidden = true
        cardModeLoadingView.isHidden = true
    }
    
    private func setupEditButton() {
        let canEdit = viewModel.previewInfo.context.editModeEnable
        guard canEdit else { return }
        /// 暂不支持csv格式的文件进入编辑状态
        guard viewModel.previewInfo.fileType != .csv else { return }
        guard !didSetupEditButton else {
            DocsLogger.driveInfo("drive.wps.preview --- did setup edit button")
            return
        }
        didSetupEditButton = true
        viewModel.showEditBtn.debug("drive.wps.preview --- showEditBtn")
            .map { !$0 }
            .drive(editButton.rx.isHidden)
            .disposed(by: disposeBag)
        viewModel.showEditBtn
            .drive(onNext: {[weak self] show in
                if show {
                    let params: [String: Any] = [:]
                    self?.bizVCDelegate?.statistic(event: DocsTracker.EventType.driveEditView, params: params)
                }
            }).disposed(by: disposeBag)

        viewModel.editPermissionChangedToast
            .skip(1)
            .drive(onNext: { [weak self] isEditable in
                guard let self = self else { return }
                if isEditable {
                    let bundleString = BundleI18n.SKResource.CreationMobile_ECM_PermissionChanged_toast(BundleI18n.SKResource.Doc_Share_LinkCanEdit)
                    UDToast.showTips(with: bundleString, on: self.view.window ?? self.view, delay: 3)
                } else {
                    let bundleString = BundleI18n.SKResource.CreationMobile_ECM_PermissionChanged_toast(BundleI18n.SKResource.Doc_Share_LinkCanView)
                    UDToast.showTips(with: bundleString, on: self.view.window ?? self.view, delay: 3)
                }
        }).disposed(by: disposeBag)
        viewModel.downgradeToReadOnly.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.loadWPSTemplate()
            self.screenModeDelegate?.setCommentBar(enable: true)
            self.viewModel.previewMode = .readOnly
        }).disposed(by: disposeBag)
        
        editButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            // 密级强制打标需求，当FA用户被admin设置强制打标时，不可编辑文档
            if SecretBannerCreater.checkForcibleSL(canManageMeta: self.viewModel.previewInfo.permissionInfo?.value.userPermissions?.isFA ?? false,
                                                   level: self.viewModel.previewInfo.docsInfo?.value.secLabel) {
                self.showForcibleWarning()
                return
            }
            if self.isInPresentationMode {
                // 编辑前退出演示模式样式
                self.exitPresentationMode()
            }
            self.viewModel.previewMode = .edit
            self.loadWPSTemplate()
            self.editButton.isHidden = true
            // WPS 编辑态下，禁止任何形式弹出评论栏
            self.screenModeDelegate?.setCommentBar(enable: false)
            let params: [String: Any] = ["click": "edit", "target": "none"]
            self.bizVCDelegate?.statistic(event: DocsTracker.EventType.driveEditClick, params: params)
        }).disposed(by: disposeBag)
        
        editButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.width.height.equalTo(48)
        }
    }
    
    private func loadWPSTemplate() {
        guard let templateURL = viewModel.htmlTemplateURL else {
            self.bizVCDelegate?.previewFailedWithAutoRetry(self, type: openType, extraInfo: [:])
            spaceAssertionFailure("drive.wps.preview --- failed to get template")
            return
        }
        showLoading()
        // 加载模板起点
        bizVCDelegate?.stageBegin(stage: .wpsLoadTemplate)
        // loadHTMLString 存在读取沙盒 js 文件权限问题
        // webView.loadHTMLString(templateContent, baseURL: templateURL.deletingLastPathComponent())
        webView.loadFileURL(templateURL, allowingReadAccessTo: templateURL.deletingLastPathComponent())
    }
    
    private func registerJSEventHandler() {
        webView.configuration.userContentController.add(LeakAvoider(self), name: "jsObj")
    }
    
    private func unregisterJSEventHandler() {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "jsObj")
    }
    
    private func bindViewModel() {
        viewModel.wpsPreviewState.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case let .needEvaluateJS(script, event):
                if event == .setInitialData { // 初始化数据加载完成
                    self.bizVCDelegate?.stageEnd(stage: .wpsGetInitailData)
                    self.bizVCDelegate?.stageBegin(stage: .wpsRender)
                }
                self.webView.evaluateJavaScript(script) { [weak self] (result, error) in
                    guard let self = self else { return }
                    DocsLogger.driveInfo("drive.wps.preview - sendDataToJS success with result", extraInfo: ["result": result as Any, "error": error ?? "no error"])
                    // 卡片模式下需要延迟到加载完成再停止loading， 正常模式下在请求accessToken并配置初始化信息后停止loading，后续会展示wps的loading界面
                    if event == .setInitialData && self.displayMode == .normal {
                        self.hideLoading()
                    }
                }
            case .loadStatus(let isSuccess):
                DocsLogger.driveInfo("drive.wps.preview - WPS Load Status: \(isSuccess)")
                if isSuccess {
                    self.bizVCDelegate?.stageEnd(stage: .wpsRender)
                    self.setupEditButton()
                    self.bizVCDelegate?.openSuccess(type: self.openType)
                } else {
                    // 加载模版失败，显示失败重试 View
                    self.showReloadView()
                }
                self.hideLoading()
            case .throwError(let wpsErrorInfo):
                DocsLogger.warning("drive.wps.preview - WPS Throw Error: \(wpsErrorInfo.description)")
                // WPS 抛出错误降级为旧的预览方式；取消订阅模版 JS 事件，避免 Error 多次触发
                self.unregisterJSEventHandler()
                let extraInfo = [DrivePerformanceRecorder.ReportKey.errorMsg.rawValue: wpsErrorInfo.description]
                self.bizVCDelegate?.previewFailedWithAutoRetry(self, type: self.openType, extraInfo: extraInfo)
            case .pointKill:
                // 服务端点杀文件，进入降级预览
                self.unregisterJSEventHandler()
                self.bizVCDelegate?.previewFailedWithAutoRetry(self, type: self.openType, extraInfo: ["pointKill": "pointKill"])
            case .openLink(let urlString):
                guard let url = URL(string: urlString) else {
                    DocsLogger.warning("drive.wps.preview - Open Link Error: Not a valid URL")
                    return
                }
                Navigator.shared.push(url, from: self)
            case .quotaAlert(let type):
                let canEdit = self.viewModel.previewInfo.context.editModeEnable
                guard canEdit else { return }
                if type == .tenant {
                    guard QuotaAlertPresentor.shared.enableTenantQuota else { return }
                    QuotaAlertPresentor.shared.showQuotaAlert(type: .cannotEditFullCapacity, from: self)
                } else {
                    guard QuotaAlertPresentor.shared.enableUserQuota else { return }
                    let token = self.viewModel.previewInfo.fileToken
                    QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: token, mountPoint: DriveConstants.driveMountPoint, from: self)
                }
            case let .reportStage(stage, costTime):
                self.bizVCDelegate?.reportStage(stage: stage, costTime: costTime)
            case .mutilGoStopWriting:
                DocsLogger.driveInfo("drive.wps.preview - Muti-Go had stop writing, can not eidt file")
            case .toast(let tips):
                UDToast.showTips(with: tips, on: self.view.window ?? self.view, delay: 3)
            case .showPassword:
                self.hideLoading()
            }
        }).disposed(by: disposeBag)
        
        viewModel.showPresentationBarButton.drive(onNext: { [weak self] (shouldShow) in
            guard let self = self else { return }
            guard self.presentationModeEnable else { return }
            self.addPresentationModeButton(shouldShow: shouldShow)
        }).disposed(by: disposeBag)
        
        viewModel.presentationStatus.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .begin:
                self.isInPresentationMode = true
                self.screenModeDelegate?.changePreview(situation: .presentaion)
                self.changeOrientation(shouldLandscape: true)
                // 演示模式下，网页内容会适配 SafeArea 导致有白边，这里设置 body 背景色为黑色，退出演示模式则改回白色
                self.changeBodyBackgroundColor(.black)
            case .end:
                self.exitPresentationMode()
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // 横竖屏切换 PPT 演示模式的时候，避免奇怪的放大效果，这里在 completion 的时候把 zoomScale 切换为 1
        coordinator.animateAlongsideTransition(in: nil, animation: nil) { _ in
            self.webView.scrollView.setZoomScale(1, animated: true)
        }
    }
    
    private func setupWebkitTouchCallout() {
        guard CacheService.isDiskCryptoEnable() else { return }
        // KACrypto 禁止长按避免导出图片
        let wkUScript = WKUserScript(source: "document.documentElement.style.webkitTouchCallout='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(wkUScript)
        DocsLogger.driveInfo("DriveWebView can not long press")
    }
    
    private func monitorTemplateLoadingTimeout() {
        guard viewModel.previewInfo.context.wpsOptimizeEnable else { return }
        let timeout = Double(viewModel.previewInfo.context.wpsTemplateTimeout)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            DocsLogger.warning("drive.wps.preview - retry asyncAfter deadline")
            guard self.webviewTemplateDidLoaded == false else { return }
            self.retryLoading(reason: .templateTimeout)
        }
    }
    
    private func showReloadView() {
        if loadFailedView.superview == nil {
            view.addSubview(loadFailedView)
            loadFailedView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            loadFailedView.isHidden = false
        }
    }
    
    private func reloadTemplate() {
        loadFailedView.isHidden = true
        webView.stopLoading()
        loadWPSTemplate()
    }
    
    private func retryLoading(reason: RetryReason) {
        guard viewModel.previewInfo.context.wpsOptimizeEnable else { return }
        let retryCount = viewModel.previewInfo.context.retryCount
        if self.currentRetryCount < retryCount {
            DocsLogger.driveError("drive.wps.preview - retry for \(reason.rawValue), retryCount: \(currentRetryCount)")
            currentRetryCount = currentRetryCount + 1
            reloadTemplate()
            monitorTemplateLoadingTimeout()
        } else {
            DocsLogger.driveError("drive.wps.preview - retry for \(reason.rawValue), downgrade")
            let extraInfo = [DrivePerformanceRecorder.ReportKey.errorMsg.rawValue: reason.rawValue]
            bizVCDelegate?.previewFailedWithAutoRetry(self, type: .wps, extraInfo: extraInfo)
        }
    }
    
    private func addPresentationModeButton(shouldShow: Bool) {
        let items = shouldShow ? [DriveNavBarItemData(type: .switchPresentationMode,
                                                            enable: true,
                                                            target: self,
                                                            action: #selector(enterPresentation))] : []
        bizVCDelegate?.append(leftBarButtonItems: [], rightBarButtonItems: items)
    }
    
    @objc
    func enterPresentation() {
        viewModel.presentationModeChange.onNext(true)
        let params: [String: Any] = ["click": DriveStatistic.DriveTopBarClickEventType.show.clickValue,
                                     "target": DriveStatistic.DriveTopBarClickEventType.show.targetValue]
        bizVCDelegate?.statistic(event: DocsTracker.EventType.navigationBarClick, params: params)
    }
    
    private func changeOrientation(shouldLandscape: Bool) {
        guard SKDisplay.phone else { return }
        if shouldLandscape {
            supportedOrientations = [.landscape]
            if !UIApplication.shared.statusBarOrientation.isLandscape {
                LKDeviceOrientation.setOritation(UIDeviceOrientation.landscapeLeft)
            }
        } else {
            supportedOrientations = [.portrait]
            LKDeviceOrientation.setOritation(UIDeviceOrientation.portrait)
        }
    }
    
    private func changeBodyBackgroundColor(_ color: WPSHtmlBackgroundColor) {
        view.backgroundColor = color.udColor
        webView.evaluateJavaScript("document.body.style.backgroundColor=\"\(color.rawValue)\"", completionHandler: nil)
    }
    
    private func exitPresentationMode() {
        guard isInPresentationMode else { return }
        self.isInPresentationMode = false
        self.screenModeDelegate?.changePreview(situation: .exitFullScreen)
        self.changeOrientation(shouldLandscape: false)
        self.changeBodyBackgroundColor(.white)
    }
    
    private func setToLandscapeIfNeed() {
        if isInPresentationMode {
            // 从 WPS 演示模式跳转到 Wiki 等只支持竖屏的页面再回来，需回到演示模式的横屏样式
            // https://meego.feishu.cn/larksuite/issue/detail/5404698
            changeOrientation(shouldLandscape: true)
        }
    }
    
    /// 非 iPhone 的设备，配置 UA 以让 WPS 强制展示 iPhone 端的样式
//    private func setupUserAgent() {
//        guard !SKDisplay.phone else { return }
//        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
//    }
    
    private func disableScaleIfNeeded() {
        // 禁用网页缩放，内容缩放交给 WPS 处理
        // https://meego.feishu.cn/larksuite/issue/detail/13020798
        let jsString = """
        viewport = document.querySelector("meta[name=viewport]");
        viewport.setAttribute('content', 'width=device-width,user-scalable=no,initial-scale=1,maximum-scale=1,minimum-scale=1,viewport-fit=cover');
        """
        let wkUScript = WKUserScript(source: jsString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(wkUScript)
    }

    private func showForcibleWarning() {
        UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requird_Toast,
                            operationText: BundleI18n.SKResource.LarkCCM_Workspace_Security_Button_Set,
                            on: self.view.window ?? self.view) { [weak self] _ in
            guard let self = self else { return }
            if let docsInfo = self.viewModel.previewInfo.docsInfo?.value,
               let userPermission = self.viewModel.previewInfo.permissionInfo?.value.userPermissions,
               self.secretLevelSelectProxy == nil {
                self.secretLevelSelectProxy = SecretLevelSelectProxy(docsInfo: docsInfo, userPermission: userPermission, topVC: self)
            }
            self.secretLevelSelectProxy?.toSetSecretVC()
        }
    }

    @objc
    private func didReceiveMemoryLevelNotification(_ notification: Notification) {
        SKMemoryMonitor.logMemory(
            when: "drive.wps.preview - didReceiveMemoryLevelNotification",
            component: LogComponents.drive)
        
        let userInfo = notification.userInfo
        if let flag = userInfo?["type"] as? Int32, flag >= OpenAPI.docs.memoryWarningLevel {
            DocsLogger.driveWarning("drive.wps.preview - receive MemoryLevel change: \(flag)")
        }
    }

    enum WPSHtmlBackgroundColor: String {
        case white
        case black
        
        var udColor: UIColor {
            switch self {
            case .white: return UDColor.primaryOnPrimaryFill
            case .black: return UDColor.staticBlack
            }
        }
    }
    
    enum RetryReason: String {
        case templateTimeout = "wps_template_error"
        case webviewRenderFail = "wps_render_error"
    }
}

// MARK: - DriveAutoRotateAdjustable
extension DriveWPSPreviewController: DriveAutoRotateAdjustable {
    func orientationDidChange(orientation: UIDeviceOrientation) {
        guard presentationModeEnable else { return }
        if orientation == .portrait, isInPresentationMode {
            // 竖屏情况，自动退出演示模式
            viewModel.presentationModeChange.onNext(false)
        }
    }
}


// MARK: - WKNavigationDelegate
extension DriveWPSPreviewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated:
            decisionHandler(.cancel)
            guard let url = navigationAction.request.url else { return }
            // secLink数据上报
            self.bizVCDelegate?.statistic(action: .secLink, source: .unknow)
            Navigator.shared.push(url, from: self)
        default:
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        SKMemoryMonitor.logMemory(
            when: "drive.wps.preview - DriveWPSPreviewController webView didFinish",
            component: LogComponents.drive)
        SKMemoryMonitor.logMemory(
            when: "drive.wps.preview - DriveWPSPreviewController webView didFinish delay5",
            delay: 5,
            component: LogComponents.drive)
        DocsLogger.driveInfo("drive.wps.preview - webview didFinish")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DocsLogger.driveInfo("drive.wps.preview - webview didFail error: \(error.localizedDescription)")
        retryLoading(reason: .webviewRenderFail)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        DocsLogger.driveError("drive.wps.preview -webview DidTerminate")
        retryLoading(reason: .webviewRenderFail)
    }
}

// MARK: - WKScriptMessageHandler
extension DriveWPSPreviewController: WKScriptMessageHandler {
    /**
     JS message 例子
     Message.name: jsObj
     Message.body: {
         method = wpsLoadStatus;
         params = "{\"isSuccess\":true}";
     }
     */
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            assertionFailure("parse JS Object failed with error: \(message.body)")
            return
        }
        guard let method = body["method"] as? String else {
            assertionFailure("can not get JS Object method")
            return
        }
        let params = body["params"] as? String ?? ""
        // 模板完成加载
        if let jsEvent = DriveWPSPreviewViewModel.ReceivedJSEvent(rawValue: method),
           jsEvent == DriveWPSPreviewViewModel.ReceivedJSEvent.getInitialData {
            webviewTemplateDidLoaded = true
            bizVCDelegate?.stageEnd(stage: .wpsLoadTemplate)
            bizVCDelegate?.stageBegin(stage: .wpsGetInitailData)
        }

        viewModel.receivedMessage.onNext((method, params))
    }
}

extension DriveWPSPreviewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return .wps
    }
    
    var panGesture: UIPanGestureRecognizer? {
        webView.scrollView.panGestureRecognizer
    }
    func willUpdateDisplayMode(_ mode: DrivePreviewMode) {
        if mode == .card {
            webView.scrollView.showsHorizontalScrollIndicator = false
            webView.scrollView.showsVerticalScrollIndicator = false
        }
    }
    
    func changingDisplayMode(_ mode: DrivePreviewMode) {
    }
    
    func updateDisplayMode(_ mode: DrivePreviewMode) {
        self.displayMode = mode
        if mode == .normal {
            webView.scrollView.showsHorizontalScrollIndicator = true
            webView.scrollView.showsVerticalScrollIndicator = true
        }
    }
}
