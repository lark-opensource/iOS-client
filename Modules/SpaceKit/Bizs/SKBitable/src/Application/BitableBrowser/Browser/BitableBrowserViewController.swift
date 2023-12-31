//
//  BitableBrowserViewController.swift
//  SKBitable
//
//  Created by bupozhuang on 2021/3/18.
//

import Foundation
import LarkUIKit
import SKBrowser
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import LarkSplitViewController
import SkeletonView
import UniverseDesignTheme

public final class BitableBrowserViewController: BrowserViewController {
    
    lazy var container: BTContainer = {
        let container = BTContainer(delegate: self)
        return container
    }()
    
    lazy var nativeRenderViewManager: BTNativeRenderViewManager = {
        let viewManager = BTNativeRenderViewManager()
        return viewManager
    }()
    
    var currentCatalogData: SKBitableCatalogData?
        
    /// 用来控制工作台onboarding接口的请求量
    private var hasRequestWorkBenchOnboarding = false
    // 临时存预加载的Doc容器
    private static var preloadVC: BrowserViewController?
    // 主容器不显示主区域loading
    private var onlyShowHeaderLoading: Bool = false

    var isIndRecord: Bool {
        DocsUrlUtil.isBaseRecordUrl(docsURL.value)
    }
    
    var isAddRecord: Bool {
        DocsUrlUtil.isBaseAddUrl(docsURL.value)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        generateTraceId()
        if onlyShowHeaderLoading {
            // 预加载其他vc，把容器的位置占了，只需要显示title的loading
            showBitableLoading(from: "preload embedVC", loadingType: .onlyHeader)
        } else {
            showBitableLoading(from: "viewDidLoad", loadingType: .main)
        }
        onlyShowHeaderLoading = false
    }
    
    public override var canShowInNewScene: Bool {
        get {
            if isAddRecord {
                return false
            }
            return super.canShowInNewScene
        }
    }
    
    private(set) lazy var newShowInNewSceneItem = {
        return generateNewSceneItem(clickCallBack: { [weak self] in
            self?.showInNewSceneItemAction()
        }, sceneId: getURL())
    }()
    
    public override var showInNewSceneItem: SKBarButtonItem {
        get {
            return newShowInNewSceneItem
        }
    }
    
    func switchBaseHeader(_ model: BTShowHeaderModel) {
        container.getOrCreatePlugin(BTContainerPluginSet.baseHeaderContainer).setBaseHeaderHiddenForWeb(model)
    }

    public override func insertBrowser(_ browser: BrowserView) {
        container.getOrCreatePlugin(BTContainerPluginSet.browserView).insertBrowser(browser)
    }
    
    public override func setupView() {
        super.setupView()
        topPlaceholder.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.height.equalTo(topContainer)
        }
        topPlaceholder.isUserInteractionEnabled = false
        setupForTemplatePreview()
        container.setupView(hostView: view)
        if UserScopeNoChangeFG.XM.docxBaseOptimized {
            if let docxVC = Self.preloadVC {
                let plugin = container.getOrCreatePlugin(BTContainerLinkedDocxPlugin.self)
                onlyShowHeaderLoading = true
                plugin.showLinkedDocx(docxVC: docxVC)
            }
        }
        // 确保不泄露
        Self.preloadVC = nil
    }
    
    private func setupForTemplatePreview() {
        if isFromTemplatePreview {
            container.setHostType(hostType: .templatePreview)
            if let templateVC = parent as? TemplatesPreviewViewController {
                let trailingBarButtonItems = templateVC.navigationBar.trailingBarButtonItems
                let replacingTrailingBarButtonItems = trailingBarButtonItems.map { item in
                    return SKBarButtonItem(image: item.image, style: item.style, target: item.target, action: item.action)
                }
                navigationBar.trailingBarButtonItems = replacingTrailingBarButtonItems
            }
        }
    }
    
    private func generateTraceId() {
        if let config = fileConfig, !isAddRecord, config.getOpenFileTraceId() == nil {
            BTOpenFileReportMonitor.handleOpenBrowserView(vc: self, fileConfig: config)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        container.setContainerSize(containerSize: view.frame.size)
    }
    
    public override func updateNavBarHeightIfNeeded() {
        container.getOrCreatePlugin(BTContainerPluginSet.topContainer).updateNavBarHeightIfNeeded()
    }
    
    public override func forceFullScreen() {
        super.forceFullScreen()
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait)
        if isFromTemplatePreview {
            container.loadingPlugin.hideAllSkeleton(from: "TemplatePreview")
        }
        container.setForceFullScreen(forceFullScreen: forceFull)
    }
    
    public override func cancelForceFullScreen() {
        super.cancelForceFullScreen()
        container.setForceFullScreen(forceFullScreen: forceFull)
    }
    
    public override func updateEditorConstraints(forOrientation orientation: UIInterfaceOrientation) {
        container.setOrientation(orientation: orientation)
        view.layoutIfNeeded()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        BTOpenFileReportMonitor.reportFetchSDKLoadCost(engine: editor.jsEngine, traceId: fileConfig?.getOpenFileTraceId(), isRecord: isIndRecord)
    }

    public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
    }
    
    override public func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        if !UserScopeNoChangeFG.YY.bitableTemplateCreateFixDisable,
            let templateDocsCreateViewController = parent as? TemplateDocsCreateViewController {
            // 从模板创建 Bitable 场景，需要适配，测试 case https://www.feishu.cn/space/api/obj_template/create_i18n_obj/?template_i18n_id=7197781008152854556
            templateDocsCreateViewController.navigationBar.isHidden = true
            templateDocsCreateViewController.statusBar.isHidden = true
        }
    }

    deinit {
        if let openFileTraceId = fileConfig?.getOpenFileTraceId() {
            // 这里兜底上报一下，正常 deinit 前加载流程就已经结束
            BTOpenFileReportMonitor.reportOpenCancel(traceId: openFileTraceId, extra: [BTStatisticConstant.reason: "destroy"])
        }
        BitableCacheProvider.clear() // Bitable 释放时释放一次缓存资源
    }

    public override func setFullScreenProgress(_ progress: CGFloat, forceUpdate: Bool = false, editButtonAnimated: Bool = true, topContainerAnimated: Bool = true) {
        container.getOrCreatePlugin(BTContainerPluginSet.topContainer).setFullScreenProgress(progress, forceUpdate: forceUpdate, editButtonAnimated: editButtonAnimated, topContainerAnimated: topContainerAnimated)
    }

    public override func updateTopPlaceholderHeight(webviewContentOffsetY: CGFloat, scrollView: EditorScrollViewProxy? = nil, forceUpdate: Bool = false) {
        // sheet 的 top container 和 top placeholder 是永远同高度的，自动布局有约束，所以不用做任何处理
    }

    public override func topContainerDidUpdateSubviews() {
        topPlaceholder.setNeedsLayout()
        topPlaceholder.layoutIfNeeded()
        container.setTopContainerHeight(topContainerHeight: topPlaceholder.frame.height)
    }

    public override func fillOnboardingMaterials() {
        // 按照当前的设计，点击 sikp 以后，OnboardingManager 会 stopExecuting 并且设置一个标志位不再展示
        // 虽然 super BrowserViewController 里面在 didMove(toParent:) 里面重置了标志位，但配置 onboarding 会在重置之前执行
        // 因此外部 skip 一次后，第一次进入 bitable 引导设置不进去，所有引导均不会展示，所以这里需要提前将标志位重置
        OnboardingManager.shared.setTemporarilyRejectsUpcomingOnboardings(false)
        
        _fillBitableOnboardingTypes()
        _fillBitableOnboardingArrowDirections()
        _fillBitableOnboardingTitles()
        _fillBitableOnboardingHints()
    }

    public override func showOnboarding(id: OnboardingID) {
        if forceFull {
            return
        }
        guard let type = onboardingTypes[id] else {
            DocsLogger.onboardingError("bitable 前端调用的引导 \(id) 没有被注册")
            return
        }

        DocsLogger.onboardingInfo("bitable 前端调用显示 \(id)")
        switch type {
        case .text: OnboardingManager.shared.showTextOnboarding(id: id, delegate: self, dataSource: self)
        case .flow: OnboardingManager.shared.showFlowOnboarding(id: id, delegate: self, dataSource: self)
        case .card: OnboardingManager.shared.showCardOnboarding(id: id, delegate: self, dataSource: self)
        }
    }
    
    public override func trailingButtonBarItemsDidChange(from oldValue: [SKBarButtonItem], to newValue: [SKBarButtonItem]) {
        if isFromTemplatePreview {
            return  // 模板中心不支持这里设置
        }
        
        super.trailingButtonBarItemsDidChange(from: oldValue, to: newValue)
    }
    
    public override func willShowNoPermissionView() {
        hideBitableLoading(from: "willShowNoPermissionView", loadingType: .all)
        super.willShowNoPermissionView()
    }
    
    public override func stateHostConfig() -> CustomStatusConfig? {
        return CustomStatusConfig(hostView: container.getOrCreatePlugin(BTContainerPluginSet.loading).stateContainer, onlyAcceptFailTipsView: true)
    }
    
    public override func permissionHostView() -> UIView? {
        return container.getOrCreatePlugin(BTContainerPluginSet.loading).stateContainer
    }
    
    public override func ignoreLoadingInViewAppear() -> Bool {
        return true
    }
    
    public override func showCustomLoading() -> Bool {
        showBitableLoading(from: "showCustomLoading", loadingType: .main)
        return true
    }
    
    public override func setShowTemplateTag(_ showTemplateTag: Bool) {
        super.setShowTemplateTag(showTemplateTag)
        container.getOrCreatePlugin(BTContainerPluginSet.baseHeaderContainer).setShowTemplateTag(showTemplateTag)
    }
    
    public override func setShowExternalTag(needDisPlay: Bool, tagValue: String) {
        super.setShowExternalTag(needDisPlay: needDisPlay, tagValue: tagValue)
        container.getOrCreatePlugin(BTContainerPluginSet.baseHeaderContainer).setShowExternalTag(needDisPlay: needDisPlay, tagValue: tagValue)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
                container.updateDarkMode()
            }
        }
    }
    
    public override func handleBrowserViewNotFoundEvent() {
        super.handleBrowserViewNotFoundEvent()
        container.setWebFailed(webFailed: true)
        container.loadingPlugin.hideAllSkeleton(from: "ViewNotFound")
    }
    
    public override func setSearchMode(searchMode: BrowserViewController.SearchMode) {
        super.setSearchMode(searchMode: searchMode)
        container.getOrCreatePlugin(BTContainerSearchPlugin.self).searchMode = searchMode
        container.nativeRendrePlugin.searchMode = searchMode
    }
    
    public override func handleShowBitableAdvancedPermissionsSettingVC(data: BitableBridgeData, listener: BitableAdPermissionSettingListener?) {
        container.getOrCreatePlugin(BTContainerAdPermPlugin.self).showBitableAdvancedPermissionsSettingVC(data: data, listener: listener)
    }
    
    public override func updateNavBarTitleAlignment() {
        navigationBar.layoutAttributes.titleHorizontalAlignment = .leading
    }
    
    var sourceTabContainableIdentifier: String? // iPad 快捷新建页跳转记录分享页，但共享了 TabContainable，退出时需要以记录新建页的 tabContainableIdentifier 进行关闭
    public override func back(canEmpty: Bool = false) {
        super.back(canEmpty: canEmpty)
        if let sourceTabContainableIdentifier = sourceTabContainableIdentifier {
            temporaryTabService.removeTab(id: sourceTabContainableIdentifier)
        }
        if let traceId = fileConfig?.getOpenFileTraceId() {
            BTOpenFileReportMonitor.reportOpenCancel(traceId: traceId, engine: editor.jsEngine, isRecord: isIndRecord, forceFetchCostData: true)
        }
        container.addRecordPlugin.handleBack()
    }
    
    public override class func preloadEmbedVC(url: URL) {
        if let token = url.bitable.getBitableLinkedDocxToken() {
            Self.preloadVC = BTContainerLinkedDocxPlugin.newDocxVC(with: token)
        }
    }
    
    public override func updateConfig(_ config: FileConfig) {
        if !UserScopeNoChangeFG.XM.docxBaseOptimized {
            super.updateConfig(config)
            return
        }
        var config = config
        if let traceId = self.fileConfig?.getOpenFileTraceId() {
            config.update(openBaseTraceId: traceId)
        }
        super.updateConfig(config)
        generateTraceId()
    }
}

// MARK: - onboarding configs
extension BitableBrowserViewController {
    private func _fillBitableOnboardingTypes() {
        onboardingTypes = [:]
    }

    private func _fillBitableOnboardingArrowDirections() {
        onboardingArrowDirections = [:]
    }

    private func _fillBitableOnboardingTitles() {
        onboardingTitles = [:]
    }

    private func _fillBitableOnboardingHints() {
        onboardingHints = [:]
    }
}
