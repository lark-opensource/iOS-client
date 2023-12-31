//
//  File.swift
//  SpaceKit
//
//  Created by bytedance on 2018/10/19.
//
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import WebKit

class UtilLongPicService: BaseJSService {
    var tempRightBarButtonItems: [SKBarButtonItem]?
    var isEditButtonVisible = false
    var trackParams: [String: Any] = [:]
    var shouldShowWatermark: Bool = true
    
    private var _exportPictureAnimator: ExportPictureAnimator?
    var exportHelper: WebViewExportPNGHelper?
    var backInterceptor: BackInterceptor?
    private var reporter = AnalyticsReporter()
    private var isImageProcessing: Bool = false // 标志位，是否正在处理图片
    private var events = [Event]() // 在start之后与web ready之间如果发生了resize,用该标志位去中断本次操作
    lazy var waterConfig = WatermarkViewConfig()
    private weak var longPicVC: LongPicViewController?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        backInterceptor = LongPicBackInterceptor(navigator: navigator)
    }

    func startScreenShot() {
        DocsLogger.info("开始生成长图")
        model?.jsEngine.callFunction(DocsJSCallBack.screenShot, params: ["state": 0], completion: nil)
    }

    func endScreenShot() {
        DocsLogger.info("结束生成长图")
        exportHelper?.cancel()
        model?.jsEngine.callFunction(DocsJSCallBack.screenShot, params: ["state": 1], completion: nil)
        isImageProcessing = false
    }

    func screenshotReady() {
        guard self.ui != nil else { return }
        guard let model = self.model else { return }
        guard let webView = self.ui?.editorView as? WKWebView else { return }
        
        let shouldInterrupt = events.didResizedBetweenStartAndReady()
        events.removeAll()
        if shouldInterrupt {
            DocsLogger.info("interrupt when web-ready")
            _forceInterrupt()
            return
        }
        
        let docsInfo = hostDocsInfo
        
        exportHelper?.cancel()
        let duration: WebViewExportPNGHelper.MillisecondsPerPage
        duration = (docsInfo?.type == .docX) ? ._300 : ._50
        exportHelper = WebViewExportPNGHelper(compressLevel: 3, millisecondsPerPage: duration)
        exportHelper?.delegate = self
        _ = exportHelper?.exportPNGImage(webView: webView, fileName: docsInfo?.title)
        shouldShowWatermark = docsInfo?.shouldShowWatermarkFromServer ?? true
        
        isImageProcessing = true
    }
    
    func showErrorTipAndRecoverUI() {
        recoverUI()
        let hud = UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Docx_ExportFailed, on: navigator?.currentBrowserVC?.view.window ?? UIView())
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
            hud.remove()
        }
    }
    
    func recoverUI() {
        recoverNavigationItem()
        hideExportLongPicLoading()
    }

    func showScreenShotErrorTips(_ reason: String) {
        showErrorTipAndRecoverUI()
        self.reportFinishLongImage(errorCode: 233, reason: "Failed: The frontend returns an error message '\(reason)'")
        reportCompletionWith(result: .failure)
    }

    private func reportFinishLongImage(errorCode: Int = 0, reason: String? = "success") {
        var paras = generateParas()
        paras["status_code"] = errorCode
        paras["status_name"] = reason
        paras["image_count"] = trackParams["image_count"] ?? 0
        paras["image_load_count"] = trackParams["image_load_count"] ?? 0
        paras["image_load_timeout"] = trackParams["image_load_timeout"] ?? false
        // Deprecated, 现对齐Android端使用client_long_image_info
        DocsTracker.log(enumEvent: .clientGenerateLongImage, parameters: paras)
    }

    private func reportCompletionWith(result: AnalyticsReporter.StatusCode) {
        reporter.status = result
        reporter.fileSize = exportHelper?.imageFileSizeKB ?? 0
        if let docsInfo = hostDocsInfo {
            reporter.fileType = docsInfo.type.name
            reporter.fileId = DocsTracker.encrypt(id: docsInfo.objToken)
        }
        let imageSize = exportHelper?.imageSize ?? .zero
        reporter.width = imageSize.width
        reporter.height = imageSize.height
        reporter.pageCount = exportHelper?.imageCount ?? 0
        
        reporter.markNativeProcessDone()
        reporter.report()
    }
    
    private func generateParas() -> [AnyHashable: Any] {
        guard let model = self.model else { return [:] }
        var paras: [AnyHashable: Any] = [:]
        paras["file_type"] = hostDocsInfo?.type.name
        if let token = hostDocsInfo?.objToken {
            paras["file_id"] = DocsTracker.encrypt(id: token)
        }
        return paras
    }

    func finishExportImage() {
        endScreenShot()
        backInterceptor?.restorePopGestureAndBackAction()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [weak self] in
            self?.hideExportLongPicLoading()
        }
    }
    
    private func interruptImageProcessing() {
        guard isImageProcessing else { // 仅在导出过程中才打断
            return
        }
        DocsLogger.info("UtilLongPicService: interruptImageProcessing")
        _forceInterrupt()
    }
    
    private func _forceInterrupt() {
        finishExportImage()
        recoverNavigationItem()
    }
}

extension UtilLongPicService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.screenShot, .screenShotReady, .screenShotStart]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.screenShotReady.rawValue:
            reporter.markJSProcessDone()
            let success = (params["success"] as? Bool) ?? true
            if success {
                screenshotReady()
            } else {
                trackParams = params
                showScreenShotErrorTips("Unsuccess")
                endScreenShot()
            }
        case DocsJSService.screenShotStart.rawValue:
            events.onStart()
            reporter.reset()
            hideNavigationItem()
            startScreenShot()
            showExportLongPicLoading(duration: Int.max)
 
        default:
            break
        }
    }


    private func recoverNavigationItem(duration: Double = 0.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else {
                DocsLogger.info("恢复导航栏按钮 self is nil")
                return
            }
            self.ui?.displayConfig.trailingButtonItems = self.tempRightBarButtonItems ?? []
            
            self.ui?.displayConfig.setFullScreenModeButtonEnable(true)
            
            if self.isEditButtonVisible {
                self.ui?.displayConfig.setEditButtonVisible(true)
                self.isEditButtonVisible = false
            }
            
            DocsLogger.info("恢复导航栏按钮 \(self.tempRightBarButtonItems != nil)")
        }
    }

    private func hideNavigationItem() {
        tempRightBarButtonItems = ui?.displayConfig.trailingButtonItems
        ui?.displayConfig.trailingButtonItems = []
        isEditButtonVisible = ui?.displayConfig.isEditButtonVisible ?? false
        if isEditButtonVisible {
             self.ui?.displayConfig.setEditButtonVisible(false) //导出长图时先把编辑按钮隐藏
        }
        DocsLogger.info("隐藏导航栏按钮 \(tempRightBarButtonItems != nil)")
        
        ui?.displayConfig.setFullScreenModeButtonEnable(false) //全屏模式临时固定，避免webview渲染内容中途变化引起越界crash
        
        backInterceptor?.disablePopGestureAndBackAction { [weak self] in
            guard let `self` = self else { return }
            self.endScreenShot()
            self.backInterceptor?.restorePopGestureAndBackAction()
            self.recoverNavigationItem()
            // 防止Web页闪屏
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                self.hideExportLongPicLoading()
            }
        }
    }
}

// MARK: - 导出长图
extension UtilLongPicService {
    private var hostView: UIView? {
        return ui?.hostView
    }

    private var exportPictureAnimator: ExportPictureAnimator {
        if _exportPictureAnimator == nil {
            _exportPictureAnimator = ExportPictureAnimator(hostView: self.hostView)
        }
        return _exportPictureAnimator!
    }

    private func showExportLongPicLoading(duration: Int = 5) {
        exportPictureAnimator.showExportLongPicLoading(duration: duration)
    }

    private func hideExportLongPicLoading() {
        exportPictureAnimator.hideExportLongPicLoading()
    }
}

extension UtilLongPicService: BrowserViewLifeCycleEvent {
    func browserWillClear() {
        spaceAssert(Thread.isMainThread)
        exportHelper?.cancel()
        endScreenShot()
        hideExportLongPicLoading()
        _exportPictureAnimator = nil
        backInterceptor?.restorePopGestureAndBackAction()
    }
    
    func browserWillLoad() {
        exportHelper?.cancel()
    }
    
    func browserDidTransition(from: CGSize, to: CGSize) {
        if from != to { // 尺寸改变时中断生成图片，因为webview宽度变化会使得图片内容异常或图片写入方法越界异常
            DocsLogger.info("from:\(from), to:\(to)")
            refreshLayout()
        }
    }
    
    func browserDidSplitModeChange() {
        refreshLayout()
    }
    
    func browserDidChangeOrientation(from oldOrentation: UIInterfaceOrientation, to newOrentation: UIInterfaceOrientation) {
        if oldOrentation != newOrentation { // 方向改变时中断生成图片，因为webview宽度变化会使得图片内容异常或图片写入方法越界异常
            DocsLogger.info("from:\(oldOrentation), to:\(newOrentation)")
            events.onChangeSize()
            interruptImageProcessing()
            longPicVC?.didChangeStatusBarOrientation(to: newOrentation)
        }
    }
    
    private func refreshLayout() {
        events.onChangeSize()
        interruptImageProcessing()
    }
}

extension UtilLongPicService: WebViewExportPNGHelperDelegate {
    func helperDidDrawImage(_: WebViewExportPNGHelper, context: CGContext, size: CGSize) {
        
        //使用水印sdk 绘制水印
        if LKFeatureGating.enabelUseLarkWaterMarkSDK && shouldShowWatermark {
            waterConfig.renderWatermarkImage(context: context, size: size)
        } else {
            let watermarkText = User.current.watermarkText()
            let logText: String
            if let text = watermarkText {
                logText = text.isEmpty ? "" : "[some]"
            } else {
                logText = "nil"
            }
            DocsLogger.info("UtilLongPicService: watermarkText: \(logText), hasWatermark: \(shouldShowWatermark)")
            if let text = watermarkText, shouldShowWatermark {
                UIImage.watermarkImage(text: text, context: context, size: size)
            }
        }
    }
    
    func helperDidFinishExport(_: WebViewExportPNGHelper, isFinished: Bool, imagePath: SKFilePath) {
        guard let hostViewController = navigator?.currentBrowserVC as? BaseViewController,
              let docsInfo = hostDocsInfo else {
            DocsLogger.info("navigator currentBrowserVC is nil")
            return
        }
        if isFinished {
            reportFinishLongImage()
            reportCompletionWith(result: .success)
            DispatchQueue.main.async {
                if let docsInfo = self.hostDocsInfo {
                    let longPicViewController = LongPicViewController(docsInfo: docsInfo, navigator: self.navigator, imagePath: imagePath)
                    if let type = HostAppBridge.shared.call(ShareImageEntity()) as? ShareAssistType {
                        longPicViewController.type = type
                    }
                    if docsInfo.inherentType.supportLandscapeShow {
                        longPicViewController.supportOrientations = hostViewController.supportedInterfaceOrientations
                    }
                    self.longPicVC = longPicViewController
                    self.navigator?.presentViewController(longPicViewController, animated: true, completion: nil)
                }
                self.finishExportImage()
            }
        } else {
            self.finishExportImage()
        }
        recoverNavigationItem()
    }
    
    func exportFailed(_ helper: WebViewExportPNGHelper) {
        DispatchQueue.main.async {
            self.showErrorTipAndRecoverUI()
        }
    }
}

extension UtilLongPicService {
    fileprivate enum Event {
        case start
        case resize // browser尺寸变化了
        case webReady
    }
}

extension Array where Element == UtilLongPicService.Event {
    
    fileprivate mutating func onStart() {
        self = [.start]
    }
    
    fileprivate mutating func onChangeSize() {
        if self.last == .start {
            self.append(.resize)
        }
    }
    
    fileprivate func didResizedBetweenStartAndReady() -> Bool {
        self.first == .start && self.last == .resize
    }
}
