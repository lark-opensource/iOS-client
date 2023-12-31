//
//  SKPDFPreviewController.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/6/7.

import UIKit
import SKResource
import SnapKit
import EENavigator
import PDFKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import SKFoundation
import UniverseDesignColor
import LarkTag

open class SKPDFPreviewController: UIViewController {

    public typealias Config = SKPDFViewModel.Config
    public var isCompact: Bool = false {
        didSet {
            if oldValue != isCompact {
                passwordView.mode = isCompact ? PasswordHintView.Mode.compact : PasswordHintView.Mode.normal
            }
        }
    }
    public private(set) lazy var pdfView: SKPDFView = {
        let view = SKPDFView()
        view.backgroundColor = UDColor.bgBase
        view.autoScales = true
        view.accessibilityIdentifier = "drive.pdf.view"
        if #available(iOS 13, *) {
            view.isHidden = false
        } else {
            // 参考文档: https://stackoverflow.com/questions/52854115/swift-pdfkit-autoscale-zooms-to-wrong-page
            // iOS 13 以下，设置autoScales = true会自动跳到第二页，需要手动跳转回首页，避免闪动，这里先隐藏
            view.isHidden = true
        }
        return view
    }()

    private lazy var passwordView: PasswordHintView = {
        let view = PasswordHintView()
        view.mode = isCompact ? PasswordHintView.Mode.compact : PasswordHintView.Mode.normal
        return view
    }()

    public var document: PDFDocument? {
        return pdfView.document
    }

    /// 右侧滚动球
    private(set) lazy var scrollBarView: SKPDFScrollBarView = {
        return SKPDFScrollBarView(pageCount: viewModel.pageCount, rollingballWidth: 43, rollingballHeight: 44)
    }()

    var shouldShowScrollBarView: Bool {
        return viewModel.currentConfig.enableScrollBar
    }

    var isInPresentationMode: Bool {
        return viewModel.currentConfig.enablePresentationMask
    }

    /// 滑动时的蒙版
    private(set) lazy var scrollingMaskView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .black
        view.alpha = 0.3
        return view
    }()

    /// 滑动时的缩略图
    private(set) lazy var thumbnailView: SKPDFThumbnailPreviewView = {
        let view = SKPDFThumbnailPreviewView()
        return view
    }()

    public private(set) lazy var gridModeView: SKPDFModeView = {
        let view = SKPDFModeView(mode: .preview, delegate: self)
        return view
    }()
    
    private(set) lazy var pageLabel: PaddingUILabel = {
        let label = PaddingUILabel()
        label.layer.cornerRadius = 4.0
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UDColor.primaryOnPrimaryFill
        label.color = UDColor.N900.withAlphaComponent(0.6).nonDynamic
        label.paddingRight = 4
        label.paddingLeft = 4
        return label
    }()

    var thumbnailGridView: UICollectionView?
    private(set) lazy var presentationView = SKPDFPresentationView()

    /// 上一页的页码，从1开始
    public private(set) var previousPageNumber: Int?
    /// 当前页码，从1开始
    public private(set) var currentPageNumber: Int?

    // 拖动滚动球时，控制请求缩略图的频率
    let thumbnailThrottleUpdatedSubject = PublishSubject<Int>()
    // PDF 载入事件
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    public var loadingStateChanged: Observable<Bool> {
        return loadingRelay.asObservable()
    }
    public var isPDFLoaded: Bool {
        return loadingRelay.value
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return supportedOrientations
    }

    private var supportedOrientations: UIInterfaceOrientationMask = [.all]
    public let viewModel: SKPDFViewModel
    public private(set) var isFirstAppear: Bool = true
    public let disposeBag = DisposeBag()

    public init(viewModel: SKPDFViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateLayoutAfterViewTransition()
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.reloadDocumentSubject.onNext(())
        /// 此处额外监听一下导航栏的方向变化，原因是 MagicShare 中没有调用 viewWillTransition 方法，无法正确处理旋转事件
        NotificationCenter.default.rx
            .notification(UIApplication.didChangeStatusBarOrientationNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateLayoutAfterViewTransition()
            })
            .disposed(by: disposeBag)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isFirstAppear else { return }
        isFirstAppear = false
        // pdfView.autoScales 为 true 时，无法控制最大最小缩放，但是 false 会导致打开时的缩放不正确
        // 先设 pdfView.autoScales 为 true，让 PDF 自动适应屏幕尺寸，再手动指定最大最小缩放
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit * CGFloat(viewModel.originConfig.minScale)
        pdfView.maxScaleFactor = pdfView.scaleFactorForSizeToFit * CGFloat(viewModel.originConfig.maxScale)
        resetUIIfNeed()
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBase
        view.addSubview(pdfView)
        pdfView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        }
        view.addSubview(pageLabel)
        pageLabel.isHidden = true
        pageLabel.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-16)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(20.0)
            make.width.greaterThanOrEqualTo(40.0)
        }
    }
    
    open func setScrollBarView(hidden: Bool) {
        scrollBarView.isHidden = hidden
    }
    
    open func setGridModeView(hidden: Bool) {
        gridModeView.isHidden = hidden
        if hidden {
            gridModeView.reset()
        }
    }
    
    open func setPageLabel(hidden: Bool) {
        pageLabel.isHidden = hidden
    }
    
    /// 更新缩略图页面布局
    public func updateThumbnailGridViewLayout() {
        thumbnailGridView?.collectionViewLayout.invalidateLayout()
    }

    private func bindViewModel() {
        viewModel.documentUpdated
            .drive(onNext: { [weak self] (document) in
                self?.pdfView.document = document
                self?.pageLabel.text = BundleI18n.SKResource.CreationMobile_Docs_PDFPreview_TotalPages(document.pageCount)
                DocsLogger.info("drive.pdfkit --- documentUpdated, count: \(document.pageCount)")
            })
            .disposed(by: disposeBag)

        viewModel.documentNeedUnlock
            .drive(onNext: { [weak self] needUnlock in
                guard let self = self else { return }
                DocsLogger.info("drive.pdfkit --- documentUpdated, needUnlock: \(needUnlock)")
                if needUnlock {
                    self.showPasswordView()
                } else {
                    self.additionSetup()
                }
            })
            .disposed(by: disposeBag)

        viewModel.unlockDocumentUpdated
            .drive(onNext: { [weak self] (unlocked) in
                DocsLogger.info("drive.pdfkit --- documentUpdated, unlockDocumentUpdated")
                self?.updateUnlockState(unlockSuccess: unlocked)
            })
            .disposed(by: disposeBag)

        loadingRelay
            .bind(to: viewModel.uiReadyRelay)
            .disposed(by: disposeBag)

        viewModel.configChanged
            .drive(onNext: {[weak self] config in
                guard let self = self else { return }
                self.change(config: config)
            })
            .disposed(by: disposeBag)

        viewModel.goPrevious
            .drive(onNext: {[weak self] _ in
                self?.goPrevious()
            })
            .disposed(by: disposeBag)

        viewModel.goNext
            .drive(onNext: {[weak self] _ in
                self?.goNext()
            })
            .disposed(by: disposeBag)
    }

    open func additionSetup() {
        guard !isPDFLoaded else { return }
        // 初始化的时候注意view的层级，不要随便改顺序
        setupScrollingMaskView()
        setupScrollBarView()
        // thumbnailView 必须在 scrollBar setup 之后初始化
        if viewModel.originConfig.enableThumbnail {
            setupThumbnailView()
            setupGridModeView()
        }
        setupPresentationView()

        for view in pdfView.subviews {
            if let scrollView = view as? UIScrollView {
                bindScrollViewOffset(scrollView)
                scrollView.showsVerticalScrollIndicator = false
                scrollView.showsHorizontalScrollIndicator = false
                DocsLogger.debug("drive.pdfkit --- did hide PDFScrollView scroll indicator")
                break
            }
        }

        thumbnailThrottleUpdatedSubject
            .distinctUntilChanged()
            .throttle(DispatchQueueConst.MilliSeconds_100, scheduler: MainScheduler.instance)
            .bind { [weak self] (pageNumber) in
                let thumbnailSize = CGSize(width: 160 * SKDisplay.scale, height: 160 * SKDisplay.scale)
                self?.viewModel.thumbnailRequestSubject.onNext((pageNumber, thumbnailSize))
            }
        .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pdfPageChanged),
                                               name: .PDFViewPageChanged,
                                               object: nil)
        loadingRelay.accept(true)
    }

    private func bindScrollViewOffset(_ scrollView: UIScrollView) {
        scrollView.rx.contentOffset
            .distinctUntilChanged { (lhs, rhs) -> Bool in
                // 若变化前后的偏移量都大于0，则不做特殊处理
                if lhs.y > 0 && rhs.y > 0 {
                    return true
                }
                return false
            }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] offset in
            guard let self = self else { return }
            // 全屏模式下不处理
            guard !self.isInPresentationMode else { return }
            
            DocsLogger.info("drive.pdfkit --- handle PDF Scroll Offset Changed")
            self.pdfPageChanged()
        })
            .disposed(by: disposeBag)
    }

    open func change(config: Config) {
        DocsLogger.info("pdf change config \(config)")
        let currentPage = currentPageNumber ?? 1
        // ui
        updateAdditionalElement(config)
        
        // update pdfView
        if config.mode == .singlePage {
            // 演示模式重新设置单页内容的 scale，避免内容显示不正确
            // 设置 scaleFactorForSizeToFit 无效
            // pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
            pdfView.autoScales = true
        }
        self.pdfView.layoutDocumentView()
    }

    private func updateAdditionalElement(_ config: Config) {
        if #available(iOS 13, *), config.enableScrollBar {
            scrollBarView.fadeIn()
        } else {
            scrollBarView.fadeOut()
        }
        gridModeView.isHidden = !config.enableGrid
        presentationView.isHidden = !config.enablePresentationMask
        gridModeView.reset()

        pdfView.backgroundColor = config.backgroundColor
        pdfView.displayMode = config.mode
    }

    private func resetUIIfNeed() {
        if #available(iOS 13, *) {
            return
        } else {
            // iOS 13 以下，设置autoScales = true会自动跳到第二页，需要手动跳回首页T_T
            guard let page = document?.page(at: 0) else { return }
            pdfView.go(to: page)
            pdfView.isHidden = false
            if shouldShowScrollBarView {
                scrollBarView.fadeIn()
            }
        }
    }

    private func showPasswordView() {
        view.addSubview(passwordView)
        passwordView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        passwordView.passwordHandler = { [weak self] password in
            self?.viewModel.passwordSubject.onNext(password)
        }
    }

    private func updateUnlockState(unlockSuccess: Bool) {
        if unlockSuccess {
            additionSetup()
            passwordView.isHidden = true
            passwordView.removeFromSuperview()
            pdfView.autoScales = true
            pdfView.layoutDocumentView() // 强制 PDFView 刷新布局，保证 autoScales 到适合屏幕的缩放比例
            pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit * CGFloat(viewModel.originConfig.minScale)
            pdfView.maxScaleFactor = pdfView.scaleFactorForSizeToFit * CGFloat(viewModel.originConfig.maxScale)
        } else {
            passwordView.showPasswordError()
        }
    }
    
    // MARK: - 翻页相关

    /// 跳转到指定页数
    /// - Parameter pageNumber: 从0开始的页码
    public func go(to pageNumber: Int) -> Bool {
        guard let page = viewModel.document?.page(at: pageNumber) else {
            DocsLogger.error("drive.pdfkit --- get page failed when try to change page", extraInfo: ["pageNumber": pageNumber])
            return false
        }
        pdfView.go(to: page)
        return true
    }

    func goNext() {
        let nextPageIndex = currentPageNumber ?? 1
        guard nextPageIndex < viewModel.pageCount else {
            let hud = UDToast.showTips(with: BundleI18n.SKResource.Drive_Drive_AlreadyTheLastPage, on: view)
            hud.setCustomBottomMargin(view.frame.height / 2)
            return
        }
        _ = go(to: nextPageIndex)
        DocsLogger.info("pdf go next at \(nextPageIndex)")
    }

    func goPrevious() {
        let previousPageIndex = (currentPageNumber ?? 1) - 2
        guard previousPageIndex >= 0 else {
            let hud = UDToast.showTips(with: BundleI18n.SKResource.Drive_Drive_AlreadyTheFirstPage, on: view)
            hud.setCustomBottomMargin(view.frame.height / 2)
            return
        }
        _ = go(to: previousPageIndex)
        DocsLogger.info("pdf go next at \(previousPageIndex)")
    }

    // scrollView 的偏移量小于 0 时，部分PDF因为页码较宽，第一页高度不够覆盖屏幕中间，需要特殊处理
    func resetToFirstPage() {
        guard currentPageNumber != 1 else { return }
        previousPageNumber = currentPageNumber
        currentPageNumber = 1
        DocsLogger.debug("drive.pdfkit --- manual changed page for offset", extraInfo: ["from": String(describing: previousPageNumber), "to": 1])
        DispatchQueue.main.async {
            self.pageNumberChanged(from: self.previousPageNumber, to: 1)
        }
    }

    @objc
    private func pdfPageChanged() {
        guard let currentPage = pdfView.currentPage else {
            DocsLogger.error("drive.pdfkit --- failed to get current pdf page when page did changed")
            return
        }
        // pageNumber 是从1开始的
        guard let pageNumber = currentPage.pageRef?.pageNumber else {
            DocsLogger.error("drive.pdfkit --- failed to get current page number when page did changed")
            return
        }
        guard pageNumber > 0 else {
            DocsLogger.error("drive.pdfkit --- invalid page number!", extraInfo: ["pageNumber": pageNumber])
            return
        }
        guard currentPageNumber != pageNumber else {
            DocsLogger.info("drive.pdfkit --- no need to update pageNumber", extraInfo: ["pageNumber": pageNumber])
            return
        }
        
        previousPageNumber = currentPageNumber
        currentPageNumber = pageNumber
        DocsLogger.info("drive.pdfkit --- page changed", extraInfo: ["from": String(describing: previousPageNumber), "to": pageNumber])
        DispatchQueue.main.async {
            self.pageNumberChanged(from: self.previousPageNumber, to: pageNumber)
        }
    }

    /// PDF 翻页事件
    /// - Parameter currentPageNumber: 1 开始的页码
    open func pageNumberChanged(from: Int?, to: Int) {
        // scrollBar 需要使用 1 开始的页码
        notifyScrollBarViewForPageChanged(from: from, to: to)
        notifyThumbnailGridViewForPageChanged(from: from, to: to)
    }
    
    func scrollThumbnailGridToCurrentItem() {
        guard thumbnailGridView?.isHidden == false else { return }
        guard let numberOfItems = thumbnailGridView?.numberOfItems(inSection: 0) else { return }
        guard let currentPageNumber = currentPageNumber else { return }

        let pageCount = viewModel.pageCount
        guard currentPageNumber > 0 && currentPageNumber <= pageCount && currentPageNumber <= numberOfItems else {
            DocsLogger.warning("drive.pdfkit --- trying to scroll thumbnailGird to \(currentPageNumber), " +
                               "pageCount is \(pageCount), numberOfItems is \(numberOfItems)")
            return
        }

        DocsLogger.info("drive.pdfkit --- thumbnailGird scroll to \(currentPageNumber), " +
                        "pageCount is \(pageCount), numberOfItems is \(numberOfItems)")
        // 滑动到当前页
        let indexPath = IndexPath(item: currentPageNumber - 1, section: 0)
        thumbnailGridView?.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        thumbnailGridView?.layoutIfNeeded()
        thumbnailGridView?.reloadData()
        // 高亮当前页码
        thumbnailGridView?.visibleCells.forEach { ($0 as? SKPDFThumbnailCell)?.resetHighlightLabel() }
        guard let cell = thumbnailGridView?.cellForItem(at: indexPath) as? SKPDFThumbnailCell else {
            return
        }
        cell.highlightLabel()
    }

    private func updateLayoutAfterViewTransition() {
        pdfView.autoScales = true
        pdfView.layoutDocumentView()
        // 旋转后需要重新刷新布局
        thumbnailGridView?.collectionViewLayout.invalidateLayout()
        scrollThumbnailGridToCurrentItem()
    }
}
