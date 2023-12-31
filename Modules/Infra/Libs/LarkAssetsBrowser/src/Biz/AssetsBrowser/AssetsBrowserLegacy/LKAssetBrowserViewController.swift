//
//  LKAssetBrowserViewController.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/4/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging
import RoundedHUD
import LarkUIKit
import LarkKeyCommandKit
import ByteWebImage
import LarkImageEditor
import EENavigator
import LarkFeatureGating
import UniverseDesignFont
import UniverseDesignDialog
import LarkKAFeatureSwitch
import LarkSetting
import LarkStorage
import UniverseDesignToast
import LarkVideoDirector
import LKCommonsTracker
import LarkLocalizations

open class LKAssetBrowserViewController: BaseUIViewController,
                                         UIScrollViewDelegate,
                                         UIViewControllerTransitioningDelegate,
                                         UIGestureRecognizerDelegate {
    public enum DragStaus {
        case drag
        case endDragToNormal
        case endDragToDismiss
    }

    public enum ButtonType {
        case onlySave
        case stack(config: ExtensionsConfiguration)
    }

    public struct ExtensionsConfiguration {
        let getAllAlbumsBlock: (() -> LKMediaAssetsDataSource)?
        public init(getAllAlbumsBlock: (() -> LKMediaAssetsDataSource)?) {
            self.getAllAlbumsBlock = getAllAlbumsBlock
        }
    }

    /// 实际上是控制所有按钮显隐的，应该是历史遗留问题
    open var isSavePhotoButtonHidden: Bool = false
    open var isPhotoIndexLabelHidden: Bool = true
    open var isLoadMoreEnabled: Bool = false
    open var hasMoreOldAssets: Bool = true
    open var hasMoreNewAssets: Bool = true
    open var isAutoHideButton: Bool = true
    open var longPressEnable: Bool = true
    open var videoShowMoreButton: Bool = true
    open var showImageOnly: Bool = false
    open var showSavePhoto: Bool = true
    open var showEditPhoto: Bool = true

    // 外部传入
    open var getExistedImageBlock: GetExistedImageBlock?
    open var setImageBlock: SetImageBlock?
    open var prepareAssetInfo: PrepareAssetInfo?
    open var videoPlayProxyFactory: VideoPlayProxyFactory?
    open var setSVGBlock: SetSVGBlock?
    open var dismissCallback: (() -> Void)?
    open var handleLoadCompletion: ((AssetLoadCompletionInfo) -> Void)?

    // 是否检测图片 OCR
    open var checkImageOCR: Bool = false

    // 是否检测图片翻译
    open var checkImageTranlation: Bool = false

    // 配置图片加载额外的ImageRequestOptions，与内部策略归并
    open var additonImageRequestOptions: ImageRequestOptions?

    // 通知外部 AssetBrowser 状态变化
    open func currentPageIndexWillChange(_ newValue: Int) {}
    open func onCurrentDragStatusChangeTo(_ status: DragStaus) {}

    open lazy var supportAnimationOrientation: [UIInterfaceOrientation] =
        Display.pad ? self.allOrientation : self.portraitOrientation

    private func isSupportAnimationOrientation() -> Bool {
        let orientation = UIApplication.shared.statusBarOrientation
        return supportAnimationOrientation.contains(orientation)
    }

    private var allOrientation: [UIInterfaceOrientation] = [
        .portrait,
        .portraitUpsideDown,
        .landscapeLeft,
        .landscapeRight
    ]

    private var portraitOrientation: [UIInterfaceOrientation] = [.portrait, .portraitUpsideDown]

    public private(set) var currentThumbnail: UIImageView?
    public private(set) var currentPageView: LKAssetPageView?

    private var fixedAssetsArray: ObservableArray<LKDisplayAssetViewModel> = ObservableArray(
        array: [],
        observeBlock: { _, _ in },
        defaultSubscriptValue: LKDisplayAssetViewModel(asset: LKDisplayAsset())
    )

    public private(set) var currentPageIndex: Int = 0 {
        willSet {
            self.photoIndexLabel.text = "  \(newValue + 1)/\(self.fixedAssetsArray.count)  "
            let oldAsset = self.fixedAssetsArray[currentPageIndex].asset
            let newAsset = self.fixedAssetsArray[newValue].asset
            if newValue < currentPageIndex {
                self.actionHandler.handlePreviousShowedAsset(previousAsset: newAsset, currentAsset: oldAsset)
            } else if newValue > currentPageIndex {
                self.actionHandler.handleNextShowedAsset(nextAsset: newAsset, currentAsset: oldAsset)
            }
            preloadMoreAssetsIfNeeded(newValue)
            currentPageIndexWillChange(newValue)
        }
    }

    fileprivate var isPerformingLayout = false

    fileprivate var visiblePages: [Int: LKAssetPageView] = [:]

    fileprivate var availableSVGPages: [LKAssetPageView] = []

    fileprivate var shouldSwipe: Bool = false

    fileprivate let PADDING: CGFloat = 10

    private var actionHandler: LKAssetBrowserActionHandler
    private let translationService: LKAssetBrowserTranslateService?

    // MARK: UI Elements

    private lazy var browserView = LKAssetBrowserView()

    public var backgroundView: UIView {
        return browserView
    }

    public var backScrollView: UIScrollView! {
        return browserView.backScrollView
    }

    private var photoIndexLabel: UILabel {
        return browserView.photoIndexLabel
    }

    private var showOriginButton: ShowOriginButton {
        return browserView.showOriginButton
    }

    private var buttonStack: UIStackView {
        return browserView.actionButtonContainer
    }

    private lazy var imageOCRButton: UIButton = {
        let button = makeActionButton(withIcon: Resources.extractTextIcon)
        button.addTarget(self, action: #selector(imageOCRButtonClicked(sender:)), for: .touchUpInside)
        return button
    }()

    private lazy var translationButton: UIButton = {
        let button = makeActionButton(withIcon: Resources.translateIcon)
        button.addTarget(self, action: #selector(imageTranslationButtonClicked(sender:)), for: .touchUpInside)
        return button
    }()

    private lazy var translationOriginButton: UIButton = {
        let button = makeActionButton(withIcon: Resources.translateIcon)
        button.backgroundColor = LKAssetBrowserView.Cons.buttonHighlightColor
        button.addTarget(self, action: #selector(imageTranslationButtonClicked(sender:)), for: .touchUpInside)
        return button
    }()

    public lazy var savePhotoButton: UIButton = {
        let button = makeActionButton(withIcon: Resources.new_save_photo)
        button.addTarget(self, action: #selector(savePhotoButtonClicked), for: .touchUpInside)
        return button
    }()

    private lazy var editPhotoButton: UIButton = {
        let button = makeActionButton(withIcon: Resources.asset_photo_edit)
        button.addTarget(self, action: #selector(editPhotoButtonClicked), for: .touchUpInside)
        return button
    }()

    private lazy var lookUpAssetButton: UIButton = {
        let button = makeActionButton(withIcon: Resources.asset_photo_lookup)
        button.addTarget(self, action: #selector(lookUpAssetButtonClicked), for: .touchUpInside)
        return button
    }()

    private lazy var photoMoreOperationButton: UIButton = {
        let button = makeActionButton(withIcon: Resources.asset_more)
        button.addTarget(self, action: #selector(photoMoreButtonClicked), for: .touchUpInside)
        return button
    }()

    private func makeActionButton(withIcon icon: UIImage) -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(icon, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.backgroundColor = LKAssetBrowserView.Cons.buttonColor
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        button.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
        return button
    }

    private let extensionsType: ButtonType

    @FeatureGating("core.ocr.image_to_text")
    private var imageOCREnable: Bool // 是否支持 ocr 检测

    fileprivate var timer: Timer?

    private let preloadThreshold: Int = 1

    // 是否正在下载原图时保存图片
    private let saveImageInLoadingImage = "SaveImageInLoadingImage"

    private lazy var loadMoreHelper: LKAssetBrowserLoadMoreHelper = {
        let loadMoreHelper = LKAssetBrowserLoadMoreHelper(handler: actionHandler,
                                                          browser: self)
        loadMoreHelper.hasMoreOld = hasMoreOldAssets
        loadMoreHelper.hasMoreNew = hasMoreNewAssets
        return loadMoreHelper
    }()

    // MARK: Configuration

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    open override var shouldAutorotate: Bool {
        return true
    }

    open override var prefersStatusBarHidden: Bool {
        return true
    }

    open override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    static private let logger = Logger.log(LKAssetBrowserViewController.self,
                                           category: "LarkAssersBrowser")

    public init(assets: [LKDisplayAsset],
                pageIndex: Int,
                actionHandler: LKAssetBrowserActionHandler = LKAssetBrowserActionHandler(),
                translateService: LKAssetBrowserTranslateService? = nil,
                buttonType: ButtonType = .onlySave) {
        assert(!assets.isEmpty, "传入的Photo数量必须大于0")
        self.translationService = translateService
        self.actionHandler = actionHandler
        self.extensionsType = buttonType
        self.currentPageIndex = pageIndex
        super.init(nibName: nil, bundle: nil)

        self.fixedAssetsArray = self.createObservableDisplayAssets(assets)

        self.actionHandler.delegate = self
        self.actionHandler.viewController = self
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let dismissCallback = dismissCallback {
            dismissCallback()
            Self.logger.error("LKAssetBrowserController is not dismissed manually, trying call dismissCall on deinit.")
            Tracker.post(SlardarEvent(name: "chat_mask_by_cell", metric: [:], category: [:], extra: [:]))
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    private func appDidEnterBackground() {
        Self.logger.warn("LKAssetBrowserController might be closed because app is entering background.")
    }

    private func setupActionButtons(withType buttonType: ButtonType) {
        buttonStack.isHidden = isSavePhotoButtonHidden
        switch buttonType {
        case .onlySave:
            break
        case .stack(let config):
            showOriginButton.isHidden = false
            let tapGesture = UITapGestureRecognizer()
            tapGesture.addTarget(self, action: #selector(showOriginButtonClicked(sender:)))
            showOriginButton.isUserInteractionEnabled = true
            showOriginButton.addGestureRecognizer(tapGesture)
        }
        self.updateActionButtons(withType: buttonType, asset: nil)
    }

    // 刷新当前 action menu
    private func updateActionButtons(withType buttonType: ButtonType, asset: LKDisplayAsset?) {
        self.buttonStack.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        // 是否显示翻译 icon
        var hasTranslateIcon = false
        // 是否存在翻译结果
        var hasTranslateResult = false

        switch buttonType {
        case .onlySave:
            if self.showSavePhoto {
                buttonStack.addArrangedSubview(savePhotoButton)
            }
        case .stack(let config):
            // 检查是否有翻译结果
            if let asset = asset,
               let ability = self.translateAbility(assetKey: asset.originalImageKey ?? "") {
                hasTranslateResult = true
            }
            if self.checkImageTranlation,
               let asset = asset,
               asset.translateProperty == .translated {
                hasTranslateIcon = true
                // 如果外部直接传入的翻译后的 asset，则直接判断为拥有翻译结果
                hasTranslateResult = true
                buttonStack.addArrangedSubview(translationOriginButton)
            } else if self.checkImageTranlation,
                let asset = asset,
                let ability = self.translateAbility(assetKey: asset.originalImageKey ?? ""),
                ability.canTranslate,
                let firstLanguage = ability.srcLanguage.first,
                let mainLanguage = translationService?.mainLanguage(),
                firstLanguage != mainLanguage {
                hasTranslateIcon = true
                buttonStack.addArrangedSubview(translationButton)
            }
            // 判断是否需要展示 OCR 按钮, 第一期 OCR 按钮和编辑按钮互斥
            else if let asset = asset,
               let result = asset.extraInfo[ImageShowOcrButtonKey] as? Bool,
               result {
                buttonStack.addArrangedSubview(imageOCRButton)
            } else if showEditPhoto {
                buttonStack.addArrangedSubview(editPhotoButton)
            }
            if showSavePhoto {
                buttonStack.addArrangedSubview(savePhotoButton)
            }
            if let _ = config.getAllAlbumsBlock {
                buttonStack.addArrangedSubview(lookUpAssetButton)
            }
            buttonStack.addArrangedSubview(photoMoreOperationButton)
        }
        if hasTranslateResult {
            Tracker.post(TeaEvent("public_image_translate_icon_view", params: [
                "occasion": "picbrowser",
                "has_translate_icon": hasTranslateIcon ? true : false
            ]))
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            view.overrideUserInterfaceStyle = .light
        }

        view.backgroundColor = .clear

        // Tricky:
        // 采用 loadView 方式将 browserView 加载为根 view，会导致某些情况下（文档）页面旋转异常，原因暂时未知。
        view.addSubview(browserView)
        browserView.frame = view.bounds

        isNavigationBarHidden = true

        backScrollView.delegate = self

        // TODO: 必不可少，否则会出问题？？
        backScrollView.frame = frameForPagingScrollView()

        photoIndexLabel.isHidden = isPhotoIndexLabelHidden
        photoIndexLabel.text = "  \(self.currentPageIndex + 1)/\(self.fixedAssetsArray.count)  "

        setupActionButtons(withType: extensionsType)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPanGesture))
        if #available(iOS 13.4, *) {
            panGesture.allowedScrollTypesMask = .continuous
        }
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        self.backgroundView.addGestureRecognizer(panGesture)

        reloadData()

        if let currentPage = visiblePages[currentPageIndex] as? LKVideoDisplayView {
            currentPage.initialPlay()
        }

        preloadMoreAssetsIfNeeded(currentPageIndex)
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        browserView.frame = view.bounds
        layoutVisiblePages()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        capturesStatusBarAppearance(true)
        // 在视频播放时，点击lookup按钮后进入下一个页面，视频暂停，返回后需要继续播放
        // 未来预期是否可以暴露声明周期给page，这样就不用在里面写具体的特化逻辑
        if let currentPage = visiblePages[currentPageIndex] as? LKVideoDisplayView {
            currentPage.continueToPlayIfNeeded()
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let currentPage = visiblePages[currentPageIndex] as? LKVideoDisplayView {
            currentPage.pause()
        }
        if #available(iOS 16, *) {
            // iOS 16 禁用 KVC 方式设置 orientation
        } else {
            // NOTE: 暂时强制横屏
            UIDevice.current.setValue(UIInterfaceOrientationMask.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
        self.timer?.invalidate()
    }
    
    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            if let dismissCallback = self.dismissCallback {
                Self.logger.info("LKAssetBrowserController did dismiss, dismissCallback called.")
                dismissCallback()
                self.dismissCallback = nil
            } else {
                Self.logger.warn("LKAssetBrowserController did dismiss, but dismissCallback is nil.")
            }
            completion?()
        }
    }

    private func capturesStatusBarAppearance(_ flag: Bool) {
        /*
         * 接管控制系统 StatusBar 的样式，当 modalPresentationStyle 不为 fullScreen 时，
         * 设置 modalPresentationCapturesStatusBarAppearance 为 true 才能接管控制系统 StatusBar 的样式
         */
        if let navi = self.navigationController {
            navi.modalPresentationCapturesStatusBarAppearance = flag
            navi.setNeedsStatusBarAppearanceUpdate()
        }
        self.modalPresentationCapturesStatusBarAppearance = flag
        self.setNeedsStatusBarAppearanceUpdate()
    }

    // 添加快捷键
    open override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + saveKeycommand()
    }

    /// “保存”快捷键
    private func saveKeycommand() -> [KeyBindingWraper] {
        let asset = fixedAssetsArray[currentPageIndex].asset
        let currentPage = currentPageView as? LKPhotoZoomingScrollView

        if let videoDisplayView = currentPageView as? LKVideoDisplayViewProtocol {
            return self.actionHandler.getSaveVideoKeyCommand(videoDisplayView: videoDisplayView, asset: asset)
        } else {
            return self.actionHandler.getSaveImageKeyCommand(asset: asset, relatedImage: currentPage?.image)
        }
    }

    private func reloadData() {
        guard isViewLoaded else { return }
        for view in backScrollView.subviews {
            view.removeFromSuperview()
        }
        performLayout()
        self.backgroundView.setNeedsLayout()
    }

    // Docs协同刷新图片查看器 和 图片查看器lookup按钮后删除部分视/图消息 使用
    // 传入新的图片数据源数据: assets  需要跳转展示的图片下标: newCurrentPageIndex
    public func reloadAssets(_ assets: [LKDisplayAsset], newCurrentPageIndex: Int) {
        guard !assets.isEmpty else { return }
        currentPageIndex = 0
        fixedAssetsArray = createObservableDisplayAssets(assets)
        currentPageIndex = newCurrentPageIndex
        visiblePages.removeAll()
        reloadData()
        layoutVisiblePages()
    }

    // Use for load more.
    internal func insertAssets(_ assets: [LKDisplayAsset], type: LKAssetBrowserLoadMoreHelper.MoreType) {
        let assets = assets.filter { showImageOnly ? !$0.isVideo : true }
            .map({ LKDisplayAssetViewModel(asset: $0) })
        if assets.isEmpty {
            return
        }
        switch type {
        case .old:
            self.fixedAssetsArray.insert(newElements: assets, at: 0)
            let originalIndex = self.currentPageIndex
            self.currentPageIndex += assets.count
            if let originalPage = self.visiblePages[originalIndex] {
                self.visiblePages.forEach { (dic) in
                    if dic.key != originalIndex {
                        dic.value.removeFromSuperview()
                    }
                }
                self.visiblePages.removeAll()
                originalPage.displayIndex = currentPageIndex
                originalPage.frame = frameForPageAtIndex(currentPageIndex)
                self.visiblePages[currentPageIndex] = originalPage
            }
        case .new:
            self.fixedAssetsArray.append(newElements: assets)
        }
        self.performLayout()
    }

    // MARK: ScrollView Delegate

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isPerformingLayout {
            return
        }

        let visibleBounds = backScrollView.bounds
        var index = Int(floor(visibleBounds.minX / visibleBounds.width))
        index = max(0, min(index, numberOfAssets() - 1))
        if currentPageIndex != index {
            let halfWidth = visibleBounds.width / 2
            let currentSeperate = visibleBounds.width * CGFloat(currentPageIndex)
            if abs(currentSeperate - visibleBounds.minX) > halfWidth {
                currentPageIndex = index
                rearrangeVisiblePages()
            }
        }

        if self.isLoadMoreEnabled {
            let offsetX = scrollView.contentOffset.x
            if offsetX < 0 {
                self.loadMoreHelper.showLoadMoreView(type: .old, to: backgroundView)
            } else if offsetX > scrollView.contentSize.width - scrollView.bounds.width {
                self.loadMoreHelper.showLoadMoreView(type: .new, to: backgroundView)
            } else {
                self.loadMoreHelper.dismissLoadMoreView()
            }
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.isLoadMoreEnabled {
            self.loadMoreHelper.isDataTaskBuffered = true
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            if self.isLoadMoreEnabled {
                self.loadMoreHelper.isDataTaskBuffered = false
            }
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.isLoadMoreEnabled {
            self.loadMoreHelper.isDataTaskBuffered = false
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if self.isLoadMoreEnabled {
            let offsetX = scrollView.contentOffset.x
            if offsetX < 0 {
                self.loadMoreHelper.loadMore(.old)
            } else if offsetX > scrollView.contentSize.width - scrollView.bounds.width {
                self.loadMoreHelper.loadMore(.new)
            }
        }
    }

    // MARK: Layout Calculation

    private func layoutVisiblePages() {
        isPerformingLayout = true
        defer { isPerformingLayout = false }

        let pagingScrollViewFrame = frameForPagingScrollView()
        if !backScrollView.frame.equalTo(pagingScrollViewFrame) {
            backScrollView.frame = pagingScrollViewFrame

            backScrollView.contentSize = contentSizeForPagingScrollView()
            backScrollView.contentOffset = contentOffsetForPageAtIndex(currentPageIndex)

            for (pageIndex, pageView) in visiblePages {
                pageView.frame = frameForPageAtIndex(pageIndex)
                if let page = pageView as? LKPhotoZoomingScrollView {
                    page.setMaxMinZoomScalesForCurrentBounds(.zero)
                }
            }
        }
    }

    private func performLayout() {
        isPerformingLayout = true
        defer { isPerformingLayout = false }

        rearrangeVisiblePages()
        backScrollView.contentSize = contentSizeForPagingScrollView()
        backScrollView.contentOffset = contentOffsetForPageAtIndex(currentPageIndex)
    }

    // MARK: Paging

    private func configurePage(page: LKAssetPageView, forIndex index: Int) {
        page.frame = frameForPageAtIndex(index)
        page.displayAsset = displayAssetAtIndex(index)
        page.displayIndex = index

        page.getExistedImageBlock = self.getExistedImageBlock
        page.setImageBlock = self.setImageBlock
        page.handleLoadCompletion = self.handleLoadCompletion
        page.prepareAssetInfo = self.prepareAssetInfo
        page.setSVGBlock = self.setSVGBlock

        // 图片回调触发 ocr 检测
        if checkImageOCR && imageOCREnable,
            let page = page as? LKPhotoZoomingScrollView {
            page.setImageFinishedCallback = { [weak self, weak page] (image, asset) in
                guard var image, let page, let self else { return }
                let imageSize = image.size
                var needCheckOCR = true
                var isAnimatedImage = asset.isGIf()
                if let byteImage = image as? ByteImage {
                    isAnimatedImage = byteImage.isAnimatedImage
                }
                // 目前超大图也会有缩略图在 photoImageView 上，不用超大图进行扫描防止 OOM
                if let notHugeImage = page.photoImageView.image {
                    image = notHugeImage
                } else {
                    Self.logger.warn("cannot find image on photoImageView, use image to do ve ocr scan: \(image)")
                }
                // 有结果的情况判断结果未 false 且 size 大于上次识别才需要继续识别
                if let result = asset.extraInfo[ImageShowOcrButtonKey] as? Bool,
                    let resultSize = asset.extraInfo[ImageShowOcrButtonSizeKey] as? CGSize {
                    if result {
                        needCheckOCR = false
                    } else if imageSize.width <= resultSize.width &&
                        imageSize.height <= resultSize.height {
                        needCheckOCR = false
                    }
                }
                // 没有结果的时候 判断是否有正在进行中的识别，只有 size 大于原有 size 才需要识别
                else if let resultSize = asset.extraInfo[ImageShowOcrButtonSizeKey] as? CGSize,
                    imageSize.width <= resultSize.width &&
                    imageSize.height <= resultSize.height {
                    needCheckOCR = false
                }

                if needCheckOCR && !isAnimatedImage {
                    Self.logger.info("start image scan \(index), imageSize \(image.size)")
                    asset.extraInfo[ImageShowOcrButtonSizeKey] = imageSize
                    let callback: (Bool) -> Void = { [weak self] result in
                        guard let self = self else { return }
                        Self.logger.info("finish image scan \(index), imageSize \(image.size), result \(result)")
                        // 如果已经有识别结果了，则跳过本次结果上报
                        if let oldResult = asset.extraInfo[ImageShowOcrButtonKey] as? Bool,
                            oldResult {
                            return
                        }
                        // 如果本次识别结果比正在识别的 size 小，则跳过本次结果上报
                        if let currentSize = asset.extraInfo[ImageShowOcrButtonSizeKey] as? CGSize,
                            imageSize.width < currentSize.width &&
                            imageSize.height < currentSize.height {
                            return
                        }
                        asset.extraInfo[ImageShowOcrButtonKey] = result
                        if self.fixedAssetsArray[self.currentPageIndex].asset === asset {
                            self.updateActionButtons(withType: self.extensionsType, asset: asset)
                            Self.logger.info("update image scan actions \(index), imageSize \(image.size), result \(result)")
                        }
                        Self.logger.info("upload image scan \(index), imageSize \(image.size), result \(result)")
                        Tracker.post(TeaEvent("public_identify_image_icon_view", params: [
                            "occasion": "picbrowser",
                            "has_identify_icon": result ? true : false
                        ]))
                    }
                    VideoEditorScanManager.shared.scan(image: image, callback: callback)
                }
            }
        }

        page.dismissCallback = { [weak self] in
            guard let self = self else {
                return
            }
            let animated = self.isSupportAnimationOrientation()
            self.capturesStatusBarAppearance(false)
            Self.logger.info("LKAssetBrowserController will dismiss with single tap.")
            self.dismiss(animated: animated)
        }

        page.longPressCallback = { [weak self, weak page] (image, asset, sourceView) in
            guard let `self` = self, self.longPressEnable else {
                return
            }
            if let image = image {
                self.actionHandler.handleLongPressFor(image: image, asset: asset, browser: self, sourceView: sourceView)
            } else if let videoDisplayView = page as? LKVideoDisplayViewProtocol {
                self.actionHandler.handleLongPressForVideo(
                    asset: asset,
                    videoDisplayView: videoDisplayView,
                    browser: self,
                    sourceView: sourceView
                )
            } else if page is LKSVGDisplayView {
                self.actionHandler.handleLongPressForSVG(asset: asset, browser: self, sourceView: sourceView)
            }
        }

        page.moreButtonClickedCallback = { [weak self, weak page] (_, asset, sourceView) in
            guard let `self` = self else {
                return
            }

            if let videoDisplayView = page as? LKVideoDisplayViewProtocol {
                self.actionHandler.handleClickMoreButtonForVideo(
                    asset: asset,
                    videoDisplayView: videoDisplayView,
                    browser: self,
                    sourceView: sourceView
                )
            }
        }

        page.prepareDisplayAsset { [weak self] in
            if self?.currentPageIndex == index {
                self?.hideSomeStackButtonsIfNeeded()
            }
        }
    }

    private func hideSomeStackButtonsIfNeeded() {
        guard case .stack = self.extensionsType else { return }
        if currentPageView is LKVideoDisplayView,
            !self.actionHandler.canHandleSaveVideoToAlbum {
            savePhotoButton.isHidden = true
        } else {
            savePhotoButton.isHidden = false
        }
        if let currentPage = currentPageView as? LKPhotoZoomingScrollView {
            editPhotoButton.isHidden = currentPage.saveImage?.bt.isAnimatedImage ?? false
            photoMoreOperationButton.isHidden = false
            return
        }
        if let currentPage = currentPageView as? NotPermissionView {
            if currentPage.displayState.canNotPreview {
                editPhotoButton.isHidden = true
                photoMoreOperationButton.isHidden = true
            } else if currentPage.displayState.canNotReceive {
                // 接收权限拦截时，只保留相册按钮
                self.buttonStack.arrangedSubviews.forEach { view in
                    if view != lookUpAssetButton {
                        view.isHidden = true
                    }
                }
                showOriginButton.isHidden = true
            }
            return
        }
        editPhotoButton.isHidden = true
        photoMoreOperationButton.isHidden = false
    }

    func displayAssetAtIndex(_ index: Int) -> LKDisplayAsset? {
        var asset: LKDisplayAsset?
        if index < fixedAssetsArray.count {
            asset = fixedAssetsArray[index].asset
        }
        return asset
    }

    private func rearrangeVisiblePages() {
        let firstVisibleIndex = max(0, currentPageIndex - preloadThreshold)
        let lastVisibleIndex = min(numberOfAssets() - 1, currentPageIndex + preloadThreshold)
        guard lastVisibleIndex >= firstVisibleIndex else {
            LKAssetBrowserViewController.logger.error("page index out of range: total \(numberOfAssets()), current \(currentPageIndex), threshold \(preloadThreshold)")
            assertionFailure("Can not init a AssetBrowser with empty asset list, please check it.")
            return
        }
        let visibleRange = firstVisibleIndex...lastVisibleIndex

        // Recycle no longer needed pages
        for (pageIndex, page) in visiblePages where !visibleRange.contains(pageIndex) {
            visiblePages.removeValue(forKey: pageIndex)
            if page.displayAsset?.isSVG ?? false {
                availableSVGPages.append(page)
            }
            page.prepareForReuse()
            page.removeFromSuperview()
        }

        // Add missing pages
        for index in visibleRange where !isDisplayingPageForIndex(index) {
            let asset = self.fixedAssetsArray[index].asset
            let newPage: LKAssetPageView

            if !asset.permissionState.isAllow {
                let failView = NotPermissionView(isVideo: asset.isVideo, displayState: asset.permissionState)
                newPage = failView
            } else if asset.isVideo {
                guard let videoPlayProxyFactory = videoPlayProxyFactory else {
                    assertionFailure("If you have video, you must set a video play proxy, otherwise it is meaningless.")
                    continue
                }
              do {
                let proxy = try videoPlayProxyFactory()
                let shouldDisplayAssetsButton: Bool = {
                    switch self.extensionsType {
                    case .stack(let config):
                        return config.getAllAlbumsBlock != nil
                    case .onlySave:
                        return false
                    }
                }()
                let videoPage = LKVideoDisplayView(proxy: proxy,
                                                   showMoreButton: videoShowMoreButton,
                                                   showAssetButton: shouldDisplayAssetsButton,
                                                   delegate: self)
                videoPage.additonImageRequestOptions = self.additonImageRequestOptions
                newPage = videoPage
              } catch {
                  LKAssetBrowserViewController.logger.warn("create video display newPage throw error", error: error)
                  continue
              }
            } else if asset.isSVG {
                if !availableSVGPages.isEmpty {
                    newPage = availableSVGPages.removeFirst()
                } else {
                    let svgDisplayView = LKSVGDisplayView()
                    newPage = svgDisplayView
                }
            } else {
                let photoZoomingView = LKPhotoZoomingScrollView()
                photoZoomingView.photoImageView.autoPlayAnimatedImage = false
                photoZoomingView.additonImageRequestOptions = self.additonImageRequestOptions
                newPage = photoZoomingView
            }
            visiblePages[index] = newPage
            configurePage(page: newPage, forIndex: index)
            backScrollView.addSubview(newPage)
        }

        updateCurrentViews(currentPageIndex)
    }

    func updateAssets(with deletedKeys: [String]) {
        let newIndexInOldAssets: Int
        if let index = self.fixedAssetsArray.internalArray[..<currentPageIndex]
            .lastIndex { !deletedKeys.contains($0.asset.key) } {
            newIndexInOldAssets = index
        } else if let index = self.fixedAssetsArray.internalArray[currentPageIndex...]
                    .lastIndex { !deletedKeys.contains($0.asset.key) } {
            newIndexInOldAssets = index
        } else {
            newIndexInOldAssets = 0
            self.dismissViewController(completion: nil)
            return
        }

        let newAssets = self.fixedAssetsArray.map(transform: { $0.asset }).filter { !deletedKeys.contains($0.key) }
        let newCurrentPageIndex = newAssets.firstIndex { $0.key == self.fixedAssetsArray[newIndexInOldAssets].asset.key }

        self.reloadAssets(newAssets, newCurrentPageIndex: newCurrentPageIndex ?? 0)
    }

    /// 滑动过程中，当前页面被滑入时调用
    private func didAppearPageView() {
        guard let photoZoomingView = currentPageView as? LKPhotoZoomingScrollView else {
            return
        }
        photoZoomingView.photoImageView.startAnimating()
    }

    /// 滑动过程中，当前页面被滑出时调用
    private func didDisappearPageView() {
        if let photoZoomingView = currentPageView as? LKPhotoZoomingScrollView {
            photoZoomingView.photoImageView.stopAnimating()
        } else if let videoPlayProxy = currentPageView as? LKVideoDisplayView {
            videoPlayProxy.resetInitStatus()
        }
    }

    /// 滑动过程中，image 被展示到当前页面时调用
    private func didDisplayImage(_ assetVM: LKDisplayAssetViewModel) {
        let asset = assetVM.asset
        if !asset.isGIf() {
            currentThumbnail = asset.visibleThumbnail
        }
        let originImageKey = asset.originalImageKey ?? ""
        showOriginButton.activeKey = originImageKey
        if assetVM.state == .none {
            self.showOriginButton.isHidden = true
            assetVM.updateStateCallback = nil
            return
        }
        assetVM.updateStateCallback = { [weak self] (state, asset) in
            guard let self = self else { return }
            guard asset.originalImageKey == self.showOriginButton.activeKey else { return }
            switch state {
            case .none:
                self.showOriginButton.isHidden = true
            case .start:
                self.showOriginButton.isHidden = false
                self.setActionButtonsHidden(false)
                self.showOriginButton.state = .start(key: originImageKey, fileSize: asset.originalImageSize)
            case .progress(let value):
                self.showOriginButton.isHidden = false
                self.setActionButtonsHidden(true)
                self.showOriginButton.state = .progress(key: originImageKey, value: value)
            case .end:
                self.showOriginButton.isHidden = false
                self.setActionButtonsHidden(false)
                self.showOriginButton.state = .end(key: originImageKey)
            }
        }
        if !originImageKey.isEmpty, asset.isAutoLoadOriginalImage {
            showOriginButtonClicked(sender: nil)
        }
    }

    private func updateCurrentViews(_ index: Int) {
        guard index >= 0 && index < fixedAssetsArray.count else {
            assertionFailure("index is out of range")
            return
        }

        /*
         判断当前正在展示 page 是否就是需要刷新的 index，如果需要刷新的页面与当前索引一致，则不进行后面的页面刷新逻辑

         这个修复主要是由于追查视频播放过程中突然，进度消失以及播放按钮状态错误的问题
         追查到这个 bug 是由于 loadMore 触发 insert 逻辑，触发 updateCurrentViews
         而后面的 didDisappearPageView 会修改 LKDisplayView 的状态，导致 UI bug
         */
        if let currentPage = self.currentPageView,
           currentPage.displayIndex == index,
           let updatePage = visiblePages[index],
           currentPage == updatePage {
            return
        }

        didDisappearPageView()
        currentPageView = visiblePages[index]
        didDisplayImage(fixedAssetsArray[index])
        didAppearPageView()

        if let videoDisplayView = currentPageView as? LKVideoDisplayViewProtocol {
            self.actionHandler.handleCurrentVideoShowedAsset(
                asset: fixedAssetsArray[index].asset,
                videoDisplayView: videoDisplayView
            )
        } else {
            self.actionHandler.handleCurrentShowedAsset(asset: fixedAssetsArray[index].asset)
        }

        if !(isSavePhotoButtonHidden && isPhotoIndexLabelHidden) {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(
                timeInterval: 5,
                target: self,
                selector: #selector(didTriggerAutoHidingUIElements),
                userInfo: nil,
                repeats: false
            )
        }

        if !isSavePhotoButtonHidden && (!fixedAssetsArray[index].asset.isVideo || !fixedAssetsArray[index].asset.permissionState.isAllow) {
            self.setActionButtonsHidden(false)
            // 显示图片的时候刷新 actionButton
            let asset = fixedAssetsArray[index].asset
            self.updateActionButtons(withType: self.extensionsType, asset: asset)
        } else {
            self.setActionButtonsHidden(true)
        }

        self.photoIndexLabel.isHidden = isPhotoIndexLabelHidden
        hideSomeStackButtonsIfNeeded()
    }

    @objc
    private func didTriggerAutoHidingUIElements() {
        guard isAutoHideButton else { return }
        self.photoIndexLabel.isHidden = true
        fixedAssetsArray[currentPageIndex].updateState(.none)
        self.setActionButtonsHidden(true)
    }

    private func setActionButtonsHidden(_ isHidden: Bool) {
        guard !isSavePhotoButtonHidden else { return }
        buttonStack.isHidden = isHidden
    }

    private func isDisplayingPageForIndex(_ index: Int) -> Bool {
        for page in visiblePages.values where page.displayIndex == index {
            // TODO: Side Effect
            if index != currentPageIndex {
                page.recoverToInitialState()
            } else {
                page.handleCurrentDisplayAsset()
            }
            return true
        }
        return false
    }

    // MARK: Frame Calculations

    private func frameForPagingScrollView() -> CGRect {
        var frame = self.backgroundView.bounds
        frame.origin.x -= PADDING
        frame.size.width += 2 * PADDING
        return frame.integral
    }

    private func contentSizeForPagingScrollView() -> CGSize {
        // TODO: Where is padding?
        let bounds = backScrollView.bounds
        return CGSize(width: bounds.size.width * CGFloat(numberOfAssets()), height: bounds.size.height)
    }

    private func frameForPageAtIndex(_ index: Int) -> CGRect {
        let bounds = backScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= 2 * PADDING
        pageFrame.origin.x = bounds.width * CGFloat(index) + PADDING
        return pageFrame.integral
    }

    private func contentOffsetForPageAtIndex(_ index: Int) -> CGPoint {
        let pageWidth = backScrollView.bounds.width
        let newOffset = pageWidth * CGFloat(index)
        return CGPoint(x: newOffset, y: 0)
    }

    private func numberOfAssets() -> Int {
        return fixedAssetsArray.count
    }

    // MARK: Handle user interactions

    @objc
    private func imageTranslationButtonClicked(sender: UIControl?) {
        self.handleTranslate(asset: fixedAssetsArray[currentPageIndex].asset)
        actionHandler.handleClickTranslate()
    }

    @objc
    private func imageOCRButtonClicked(sender: UIControl?) {
        guard let currentPageView = self.currentPageView as? LKPhotoZoomingScrollView,
              let currentImage = currentPageView.image else {
            return
        }
        actionHandler.handleClickPhotoOCR(image: currentImage, asset: fixedAssetsArray[currentPageIndex].asset, from: self)
    }

    @objc
    private func showOriginButtonClicked(sender: UIControl?) {
        loadOriginImage(sender: sender, loadFinishCallback: nil)
        actionHandler.handleClickLoadOrigin()
    }

    private func loadOriginImage(sender: UIControl?, loadFinishCallback: ((LKDisplayAsset, LKPhotoZoomingScrollView) -> Void)?) {
        let assetVM = fixedAssetsArray[currentPageIndex]
        guard case let .start = self.showOriginButton.state,
              let pageView = self.currentPageView as? LKPhotoZoomingScrollView,
              let _ = assetVM.asset.originalImageKey else {
            return
        }
        assetVM.asset.forceLoadOrigin = true
        assetVM.updateState(.progress(0))
        // TODO: ??? 没有使用 originalImageKey
        /// 用户点击“查看原图”按钮，如果磁盘空间不足，提示toast并返回
        if sender != nil, !checkImageLoadEnable(on: browserView) {
            return
        }
        pageView.displayImage(
            progressCallback: {
                assetVM.updateState(.progress($0))
            },
            completionCallback: { isSuccess in
                if isSuccess {
                    assetVM.updateState(.end)
                    assetVM.updateState(.none)
                } else {
                    assetVM.updateState(.start)
                }
                loadFinishCallback?(assetVM.asset, pageView)
            }
        )
    }

    // 检查是否有充足的磁盘空间
    private func checkImageLoadEnable(on view: UIView?) -> Bool {
        let result = self.hasFreeDiskForImage()
        if !result {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkAssetsBrowser.Lark_IM_InsufficientStorageUnableToViewImageOrVideo_Toast(
                                BundleI18n.LarkAssetsBrowser.Lark_IM_InsufficientStorageUnableToSendImage_Variable),
                    on: view
                )
            } else {
                LKAssetBrowserViewController.logger.error("show disk toast view is nil")
            }
        }
        return result
    }

    private func hasFreeDiskForImage() -> Bool {
        var result = true
        var params: [String: Any] = [:]
        // 获取剩余空间
        let freeDiskSpace = SBUtil.importantDiskSpace
        var limitDiskSpace = 52_428_800
        // 从setting获取允许磁盘剩余的空间
        if let uploadConfig = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "image_upload_component_config")),
           let checkConfig = uploadConfig["file_size_check_config"] as? [String: Any],
           let freeSize = checkConfig["disk_free_size_limit"] as? Int {
            limitDiskSpace = freeSize
        }
        params["limitDiskSpace"] = limitDiskSpace
        params["freeDiskSpace"] = freeDiskSpace
        if Double(limitDiskSpace) > Double(freeDiskSpace) {
            result = false
        }
        LKAssetBrowserViewController.logger.info("check image disk enable, result \(result), params \(params)")
        return result
    }

    @objc
    private func savePhotoButtonClicked() {
        if let currentPage = currentPageView as? NotPermissionView {
            let actionHandler = self.actionHandler
            let assetVM = fixedAssetsArray[currentPageIndex]
            actionHandler.handleSaveAsset(assetVM.asset, relatedImage: nil, saveImageCompletion: nil)
            return
        }
        if let currentPage = currentPageView as? LKPhotoZoomingScrollView {
            let actionHandler = self.actionHandler
            let assetVM = fixedAssetsArray[currentPageIndex]
            switch assetVM.state {
            case .start:
                loadOriginImage(sender: nil, loadFinishCallback: { asset, photoView in
                    actionHandler.handleSaveAsset(asset, relatedImage: photoView.saveImage, saveImageCompletion: nil)
                })
            case .end:
                actionHandler.handleSaveAsset(assetVM.asset, relatedImage: currentPage.saveImage, saveImageCompletion: nil)
            case .none:
                guard !(assetVM.asset.extraInfo[saveImageInLoadingImage] as? Bool == true) else { return }
                assetVM.asset.extraInfo[saveImageInLoadingImage] = true
                actionHandler.handleSaveAsset(assetVM.asset, relatedImage: currentPage.saveImage, saveImageCompletion: { [weak self] _ in
                    guard let self = self else { return }
                    assetVM.asset.extraInfo[self.saveImageInLoadingImage] = nil
                })
            default:
                break
            }
        } else if let currentPage = currentPageView as? LKSVGDisplayView {
            actionHandler.handleSaveSVG(fixedAssetsArray[currentPageIndex].asset)
        }
    }

    @objc
    private func editPhotoButtonClicked() {
        guard let currentPageView = self.currentPageView as? LKPhotoZoomingScrollView,
              let currentImage = currentPageView.image else {
            return
        }
        guard currentImage.size.width * currentImage.size.height < 2160 * 3840 else {
            // 新版图片编辑器（VEImage）编辑大图会 crash，认为宽*高大于4k大图
            // 4k是一个画幅尺寸标准~~移动端是2160 * 3840
            if let window = self.view.window {
                UDToast.showFailure(with: BundleI18n.LarkAssetsBrowser.Lark_IM_EditImage_ExtraLargeNotSupported_Toast, on: window)
            }
            return
        }
        actionHandler.handleClickPhotoEditting(image: currentImage, asset: fixedAssetsArray[currentPageIndex].asset, from: self)
    }

    @objc
    private func lookUpAssetButtonClicked() {
        guard case .stack(let config) = self.extensionsType,
              let dataSource = config.getAllAlbumsBlock?(),
              let navigationController = self.navigationController else {
            return
        }
        self.actionHandler.handleClickAlbum()
        let assetCollectionVC = LKAssetsCollectionViewController(
            dataSource: dataSource,
            actionHandler: self.actionHandler,
            browser: self)
        navigationController.pushViewController(assetCollectionVC, animated: true)
    }

    @objc
    private func photoMoreButtonClicked() {
        guard let currentPageView = self.currentPageView as? LKPhotoZoomingScrollView,
              let currentImage = currentPageView.image else {
            return
        }

        self.actionHandler.handleClickMoreButton(image: currentImage,
                                                 asset: self.fixedAssetsArray[currentPageIndex].asset,
                                                 browser: self,
                                                 sourceView: self.photoMoreOperationButton)
    }

    private func preloadMoreAssetsIfNeeded(_ index: Int) {
        guard isLoadMoreEnabled else { return }

        if index <= preloadThreshold {
            self.loadMoreHelper.loadMore(.old)
        }

        if index >= self.numberOfAssets() - 1 - preloadThreshold {
            self.loadMoreHelper.loadMore(.new)
        }
    }

    private func createObservableDisplayAssets(_ initialAssets: [LKDisplayAsset]) -> ObservableArray<LKDisplayAssetViewModel> {
        return ObservableArray<LKDisplayAssetViewModel>(
            array: initialAssets.map({ LKDisplayAssetViewModel(asset: $0) }),
            filterCondition: { (diff: LKDisplayAssetViewModel) -> Bool in
                /// 过滤不支持翻译的asset类型
                !diff.asset.isVideo && !diff.asset.isGIf()
            },
            observeBlock: { [weak self] (diffAssets, currentAssets) in
                let supportedAssets = currentAssets.map { $0.asset }.filter { (asset) -> Bool in
                    /// 过滤不支持翻译的asset类型
                    !asset.isVideo && !asset.isGIf() && asset.detectCanTranslate
                }
                LKAssetBrowserViewController.logger.info("diffAssets: \(diffAssets.map { $0.asset.key }), currentAssets: \(currentAssets.map { $0.asset.key })")
                LKAssetBrowserViewController.logger.info("supportedAssets: \(supportedAssets.map { $0.key })")
                /// 这里为了保证上一次可能因网络原因检测失败的assets，进行二次检测
                /// 所以会带上当前所有的assets，重复情况由detectService内部去过滤
                if let detectService = self?.translationService {
                    detectService.detectTranslationAbilityIfNeeded(assets: supportedAssets) { [weak self] result in
                        // 识别结果返回后刷新当前页面
                        DispatchQueue.main.async {
                            if result,
                               let self = self {
                                let asset = self.fixedAssetsArray[self.currentPageIndex].asset
                                self.updateActionButtons(withType: self.extensionsType, asset: asset)
                            }
                        }
                    }
                }
            },
            defaultSubscriptValue: LKDisplayAssetViewModel(asset: LKDisplayAsset())
        )
    }

    // MARK: Handle dismiss gesture

    @objc
    private func handleDismissPanGesture(gesture: UIPanGestureRecognizer) {
        guard let currentPage = currentPageView else {
            return
        }

        let translation = gesture.translation(in: self.backgroundView)
        let velocity = gesture.velocity(in: self.backgroundView)
        switch gesture.state {
        case .began:
            if self.isLoadMoreEnabled {
                self.loadMoreHelper.isDataTaskBuffered = true
            }
            shouldSwipe = translation.y >= 0
        case .changed:
            guard shouldSwipe else {
                return
            }

            var fraction = translation.y / backgroundView.bounds.height
            fraction = max(fraction, 0)

            if fraction > 0 {
                // 取消接管控制系统 StatusBar 的样式
                self.capturesStatusBarAppearance(false)
            } else {
                // 接管控制系统 StatusBar 的样式
                self.capturesStatusBarAppearance(true)
            }

            if self.isSupportAnimationOrientation() {
                self.backgroundView.backgroundColor = UIColor.black.withAlphaComponent(1 - fraction)
            }
            self.onCurrentDragStatusChangeTo(.drag)
            let scaleTransform = CGAffineTransform(scaleX: 1 - fraction, y: 1 - fraction)
            let translationTransform = CGAffineTransform(translationX: translation.x, y: translation.y)
            currentPage.transform = scaleTransform.concatenating(translationTransform)
            currentPage.handleSwipeDown()
        case .ended, .cancelled:
            let dataTaskContinueBlock = { [weak self] in
                if self?.isLoadMoreEnabled ?? false {
                    self?.loadMoreHelper.isDataTaskBuffered = false
                }
            }

            guard shouldSwipe else {
                dataTaskContinueBlock()
                return
            }

            let shouldComplete = velocity.y > 50

            if !shouldComplete || gesture.state == .cancelled {
                // 接管控制系统 StatusBar 的样式
                self.capturesStatusBarAppearance(true)

                UIView.animate(withDuration: 0.25, animations: {
                    currentPage.transform = CGAffineTransform.identity
                    self.backgroundView.backgroundColor = UIColor.black
                }, completion: {  [weak self] (_) in
                    dataTaskContinueBlock()
                    self?.onCurrentDragStatusChangeTo(.endDragToNormal)
                })
            } else {
                self.onCurrentDragStatusChangeTo(.endDragToDismiss)
                self.didDisappearPageView()
                Self.logger.info("LKAssetBrowserController will dismiss with pan gesture.")
                self.dismiss(animated: self.isSupportAnimationOrientation())
            }
        default:
            break
        }
    }

    // MARK: Update current image

    open func updateCurrentImage(_ image: UIImage) {
        if let currentPage = currentPageView as? LKPhotoZoomingScrollView {
            currentPage.photoImageView.image = image
            currentPage.imageViewContainer.transform = .identity
            currentPage.imageViewContainer.bounds = CGRect(origin: .zero, size: image.size)
            currentPage.updateNotUseHugeImage()
            currentPage.setMaxMinZoomScalesForCurrentBounds(image.size)
        }
    }

    open func updateCurrentImageByKey(_ key: String) {
        guard let currentPage = currentPageView as? LKPhotoZoomingScrollView else {
            return
        }
        currentPage.updateNotUseHugeImage()
        currentPage.photoImageView.bt.setLarkImage(
            with: .avatar(key: key, entityID: "", params: .defaultBig),
            trackStart: {
                return TrackInfo(scene: .ImageViewer, fromType: .avatar)
            },
            completion: { result in
                switch result {
                case .success(let imageResult):
                    guard let image = imageResult.image else { return }
                    func task() {
                        currentPage.imageViewContainer.transform = .identity
                        currentPage.imageViewContainer.bounds = CGRect(origin: .zero, size: image.size)
                        currentPage.setMaxMinZoomScalesForCurrentBounds(image.size)
                    }
                    if Thread.isMainThread {
                        task()
                    } else {
                        DispatchQueue.main.async {
                            task()
                        }
                    }
                case .failure(let error):
                    currentPage.photoImageView.backgroundColor = UIColor.ud.N300
                    Self.logger.error("photoImageView setFace error: \(error)")
                }
            }
        )
    }

    // MARK: Transition animation

    public var customTransition: LKAssetBrowserTransitionProvider? {
        didSet {
            transition.provider = customTransition
        }
    }
    private var transition = LKAssetBrowserTransition(with: nil)

    public func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transition.present
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transition.dismiss
    }

    // MARK: Gesture conflict

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? LKPhotoZoomingScrollView {
            let trans = scrollView.panGestureRecognizer.translation(in: scrollView)
            if scrollView.contentOffset.y <= 0 && trans.y > 0 {
                return true
            }
        }
        return false
    }

    // MARK: LKAssetBrowserActionHandlerDelegate

    public func photoDenied() {
        let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkAssetsBrowser.Lark_Core_PhotoAccessForSavePhoto,
                                                 detail: BundleI18n.LarkAssetsBrowser.Lark_Core_PhotoAccessForSavePhoto_Desc())
        guard let fromVC = Navigator.shared.mainSceneWindow?.lu.visibleViewController() else {
            return
        }
        Navigator.shared.present(dialog, from: fromVC)
    }

    public func dismissViewController(completion: (() -> Void)?) {
        Self.logger.info("LKAssetBrowserController will dismiss with api call.")
        self.dismiss(animated: false, completion: completion)
    }

    public func canTranslate(assetKey: String) -> Bool {
        return self.translateAbility(assetKey: assetKey)?.canTranslate ?? false
    }

    public func translateAbility(assetKey: String) -> AssetTranslationAbility? {
        return translationService?.assetTranslationAbility(assetKey: assetKey)
    }

    public func handleTranslate(asset: LKDisplayAsset) {
        let cancelBlock: () -> Void = { [weak self] in
            self?.translationService?.cancelCurrentTranslate()
            self?.view.stopImageTranslateAnimation()
        }
        currentPageView?.handleTranslateProcess(baseView: view,
                                                cancelHandler: cancelBlock,
                                                processHandler: { [weak self] (sideEffect, animationCompletion) in
            self?.translationService?.translateAsset(asset: asset,
                                                     languageConflictSideEffect: sideEffect,
                                                     completion: { (newAsset, error) in
                guard let `self` = self else { return }
                if let err = error {
                    RoundedHUD.showTipsOnScreenCenter(
                        with: BundleI18n.LarkAssetsBrowser.Lark_Chat_ImageTextUnsupportTranslate,
                        on: self.view)
                }
                animationCompletion(error == nil, newAsset)
            })
        }, dataSourceUpdater: { [weak self] (newAsset) in
            guard let `self` = self else { return }
            /// 数据源中替换原图/译图
            self.fixedAssetsArray[self.currentPageIndex] = LKDisplayAssetViewModel(asset: newAsset)
            self.currentPageView?.displayAsset = newAsset
            self.updateActionButtons(withType: self.extensionsType, asset: newAsset)
        })
    }

    // MARK: LKVideoDisplayViewDelegate

    var targetVC: UIViewController? {
        return self
    }

    func assetButtonDidClicked() {
        self.lookUpAssetButtonClicked()
    }
}

public struct AssetLoadCompletionInfo {
    public var index: Int
    public var data: AssetData
    public var error: Error?

    public enum AssetData {
        case image(ImageResult?)
        case video
        case svg(String?)
    }
}

extension LKAssetBrowserViewController: LKVideoDisplayViewDelegate {}
extension LKAssetBrowserViewController: LKAssetBrowserActionHandlerDelegate {}

public final class AssetsNavigationController: LkNavigationController {
    public override var prefersStatusBarHidden: Bool {
        true
    }
}
