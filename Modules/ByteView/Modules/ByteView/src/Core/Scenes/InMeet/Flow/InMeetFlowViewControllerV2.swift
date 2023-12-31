//
// Created by liujianlong on 2022/8/21.
//

import UIKit
import RxRelay
import ByteViewTracker
import RxSwift
import ByteViewUI
import ByteViewNetwork

protocol InMeetFlowViewControllerDelegate: AnyObject {
    func flowDidShowSingleVideo(pid: ByteviewUser, from: UIView, avatarView: UIView)
    func flowDidHideSingleVideo()
}

class InMeetFlowViewControllerV2: VMViewController<InMeetGridViewModel>, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, InMeetLayoutContainerAware {
    lazy var collectionViewWrapper = UIView()
    // flow流显示 二级视图
    lazy var collectionView: UICollectionView = {
        let collectionLayout: UICollectionViewLayout
        if isPadGalleryEnabled {
            collectionLayout = self.padGridFlowLayout
        } else {
            if self.isWebinar {
                collectionLayout = self.webinarPhoneLayout
            } else {
                collectionLayout = self.squareFlowLayout
            }
        }
        var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.delaysContentTouches = false
        if #available(iOS 15.0, *) {
            // iOS 15, `performBatchUpdates` 增量刷新有 BUG，可能会影响 Cell 复用逻辑
            collectionView.isPrefetchingEnabled = false
        }
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(InMeetingParticipantGridCell.self, forCellWithReuseIdentifier: CellReuseIdentifier.video)
        collectionView.register(InMeetShareScreenGridCell.self, forCellWithReuseIdentifier: CellReuseIdentifier.shareScreen)
        collectionView.register(InMeetGalleryShareContentCell.self, forCellWithReuseIdentifier: CellReuseIdentifier.galleryShareContent)
        if Display.pad {
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
        }
        return collectionView
    }()

    //  外部 weak 持有宫格共享内容 cell, 用于在停止共享或者切换布局时，及时清除共享内容，（CollectionView 复用缓存可能持续持有 共享内容 Cell）
    weak var galleryShareContentCell: InMeetGalleryShareContentCell?
    lazy var isWebinar: Bool = viewModel.meeting.info.settings.subType == .webinar

    var displayMode: InMeetGridViewModel.ContentDisplayMode = .gridVideo {
        didSet {
            guard self.displayMode != oldValue else {
                return
            }
            Logger.grid.info("displayMode: \(oldValue) -> \(self.displayMode)")
            self.updateFlowDisplayMode()
        }
    }

    var goBackShareContentAction: ((BackToShareLocation) -> Void)?

    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard self.meetingLayoutStyle != oldValue else {
                return
            }
            updateMeetingLayoutStyle()
            updateBackgroundColor()
        }
    }

    private lazy var gridLandscapeFlowLayout = InMeetingLandscapeCollectionLayout(cfgs: viewModel.multiResolutionConfig)
    private lazy var singleRowLayout = InMeetingCollectionViewSingleRowLayout(cfgs: viewModel.multiResolutionConfig)
    private lazy var squareFlowLayout = InMeetingCollectionViewSquareGridFlowLayout(cfgs: viewModel.multiResolutionConfig, context: viewModel.context)
    private lazy var padGridFlowLayout = InMeetingPadGridLayout(cfgs: viewModel.multiResolutionConfig,
                                                                showFullVideoFrame: isWebinar)
    private lazy var webinarPhoneLayout = WebinarPhoneCollectionLayout(cfgs: viewModel.multiResolutionConfig)

    private let topBarGuide = UILayoutGuide()
    private let bottomBarGuide = UILayoutGuide()
    private let maxChangeCount: Int = 40

    var diagoseController: InMeetDiagnoseController?

    weak var assignNewSharerConfirmAlertController: ByteViewDialog?

    weak var container: InMeetViewContainer?

    lazy var pageControl: FlexiblePageControl = {
        let pageControl = FlexiblePageControl()
        pageControl.currentPageIndicatorTintColor = UIColor.ud.primaryContentDefault
        pageControl.pageIndicatorTintColor = UIColor.ud.iconDisabled
        pageControl.hidesForSinglePage = true
        return pageControl
    }()

    private(set) var cellVMs: [InMeetGridCellViewModel] = []

    weak var delegate: InMeetFlowViewControllerDelegate?
    private var timeoutTimer: Timer?

    // 用于临时中断当前拖拽操作，如视图切换、分组讨论等场景
    @RwAtomic
    var dropEnabled = true

    var sceneContent: InMeetSceneManager.ContentMode = .flow {
        didSet {
            // 共享白板的时候，由于VC被持有却没有刷新动作导致显示不出来，因此先在此情况下走update流程
            guard self.sceneContent != oldValue || self.sceneContent == .whiteboard else {
                return
            }
            Logger.scene.info("flowVC updateContent \(oldValue) --> \(self.sceneContent)")
            updateSharingContent()
        }
    }
    private var isDisplayingShareContent: Bool = false {
        didSet {
            guard self.isDisplayingShareContent != oldValue else {
                return
            }
            Logger.scene.info("FlowVC isDisplayingShareContent \(oldValue) --> \(isDisplayingShareContent)")
            updateShareContentCell()
        }
    }

    override func setupViews() {
        collectionViewWrapper.addSubview(collectionView)
        collectionView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(collectionViewWrapper)
        view.addLayoutGuide(topBarGuide)
        view.addLayoutGuide(bottomBarGuide)
        #if DEBUG
        topBarGuide.identifier = "flowTopBarGuide"
        bottomBarGuide.identifier = "flowBottomBarGuide"
        #endif
        view.addSubview(pageControl)
        let swipe = UISwipeGestureRecognizer()
        view.addGestureRecognizer(swipe)
        makeConstraints()
        updateVisibleRange()
        setupCallkitInBackground()
        updateShareContentCell()

        self.diagoseController = InMeetDiagnoseController(meetingID: self.viewModel.meetingId,
                                                          collectionView: self.collectionView,
                                                          rtc: self.viewModel.meeting.rtc.engine)
        updateLayout()
    }

    override func bindViewModel() {
        bindGrid()
        addReportTimer()

        #if DEBUG
        FlowDebugUtil.setupDebugView(on: self.view, meeting: viewModel.meeting)
        #endif
    }

    override func viewWillFirstAppear(_ animated: Bool) {
        super.viewWillFirstAppear(animated)
        logger.info("viewWillFirstAppear")
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        super.viewDidFirstAppear(animated)
        var picName = "no_background"
        if let bgModel = viewModel.meeting.effectManger?.virtualBgService.currentVirtualBgsModel {
            picName = LabTrack.virtualBgNameType(model: bgModel).0
        }
        VCTracker.post(name: viewModel.meeting.type.trackName,
                       params: [.action_name: "display", "msg_notifications": viewModel.meeting.setting.shouldShowMessage, "picture_name": picName])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        diagoseController?.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        diagoseController?.stop()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let offset = collectionView.contentOffset
        let width = collectionView.bounds.size.width
        let prevPageIndex: CGFloat
        if width > 0 {
            prevPageIndex = max(round(offset.x / width), 0)
        } else {
            prevPageIndex = 0
        }
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self,
                  !self.collectionView.isHidden else {
                return
            }
            self.setNeedsStatusBarAppearanceUpdate()
            if self.displayMode == .gridVideo,
               let pageLayout = self.collectionView.collectionViewLayout as? PagedCollectionLayout {
                let pageIndex = max(min(prevPageIndex, CGFloat(pageLayout.pageCount - 1)), 0)
                let newOffset = CGPoint(x: pageIndex * size.width, y: offset.y)
                self.collectionView.setContentOffset(newOffset, animated: false)
            }
        }, completion: { [weak self] _ in
            // 更新visibleRange；延时以确保拿到正确的数值
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateVisibleRange()
            }
        })
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if oldContext.layoutType != newContext.layoutType {
            dismissManipulator()
        }
        if Display.phone {
            updateLayout()
        }
    }

    func updateLayout() {
        self.updateFlowDisplayMode()
        self.updatePageControlConfig()
        self.updatePageControlLayout()
        self.updateCollectionViewConstraints()
    }

    func didAttachToLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
    }

    func didDetachFromLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
    }

    func setupExternalContainerGuides(topBarGuide: UILayoutGuide, bottomBarGuide: UILayoutGuide) {
        self.topBarGuide.snp.remakeConstraints { make in
            make.edges.equalTo(topBarGuide)
        }

        self.bottomBarGuide.snp.remakeConstraints { make in
            make.edges.equalTo(bottomBarGuide)
        }
    }

    func scrollToFirstPage() {
        let offset = collectionView.contentOffset
        let newOffset = CGPoint(x: 0, y: offset.y)
        guard !self.collectionView.isHidden else {
            return
        }

        if self.displayMode == .gridVideo || self.displayMode == .singleRowVideo {
            self.collectionView.setContentOffset(newOffset, animated: true)
        }
    }

    func handleTopBottomGuideChanged() {
        let topBarFrame = self.collectionView.convert(topBarGuide.layoutFrame, from: topBarGuide.owningView)
        self.padGridFlowLayout.topBarFrame = topBarFrame
        self.gridLandscapeFlowLayout.topBarFrame = topBarFrame
        self.squareFlowLayout.topBarFrame = topBarFrame
        self.singleRowLayout.topBarFrame = topBarFrame

        let bottomBarFrame = self.collectionView.convert(bottomBarGuide.layoutFrame, from: bottomBarGuide.owningView)
        self.padGridFlowLayout.bottomBarFrame = bottomBarFrame
        self.squareFlowLayout.bottomBarFrame = bottomBarFrame
    }

    // 整体布局发生变化时，尝试dismiss单流操作视图；能够覆盖分屏、旋转、共享视图切换场景
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBackgroundColor()

        // 部分设备在viewDidLayoutSubviews中仍无法立刻拿到正确坐标（UICollectionView cellView的subview坐标）
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.dismissManipulatorIfNeeded()
        }
    }

    private func updateBackgroundColor() {
        if displayMode == .singleRowVideo && meetingLayoutStyle.isOverlayFullScreen {
            view.backgroundColor = .clear
        } else {
            view.backgroundColor = currentLayoutContext.layoutType.isPhoneLandscape ? .clear : UIColor.ud.bgBody
        }
    }

    private func addReportTimer() {
        timeoutTimer?.invalidate()
        // nolint-next-line: magic number
        let currentTimer = Timer(timeInterval: 60, repeats: true, block: { [weak self] _ in
            self?.reportAvatarMemory()
        })
        RunLoop.main.add(currentTimer, forMode: .common)
        timeoutTimer = currentTimer
    }

    private func reportAvatarMemory() {
        VCTracker.shared.trackAvatar()
    }

    func makeConstraints() {
        collectionViewWrapper.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        updateMeetingLayoutStyle()
    }

    func updateCollectionViewConstraints() {
        guard Display.phone else { return }
        collectionViewWrapper.snp.remakeConstraints { (maker) in
            // phone+竖屏，collectionView需要对齐safeArea
            if currentLayoutContext.layoutType.isCompact {
                maker.top.bottom.equalTo(view.safeAreaLayoutGuide)
            } else {
                maker.top.bottom.equalToSuperview()
            }
            maker.left.right.equalToSuperview()
        }
    }

    let isPadGalleryEnabled = Display.pad
    func updatePageControlLayout() {
        let style = meetingLayoutStyle

        if currentLayoutContext.layoutType.isPhoneLandscape {
            pageControl.snp.remakeConstraints {
                $0.centerX.equalToSuperview()
                if Display.iPhoneXSeries {
                    $0.bottom.equalToSuperview().inset(17.0)
                } else {
                    $0.bottom.equalToSuperview().inset(4.0)
                }
            }
        } else {
            pageControl.snp.remakeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                if isPadGalleryEnabled {
                    if style == .tiled {
                        maker.bottom.equalTo(bottomBarGuide.snp.top)
                    } else if style == .overlay {
                        maker.bottom.equalTo(bottomBarGuide.snp.top)
                    } else {
                        maker.bottom.equalToSuperview().offset(self.view.safeAreaInsets.bottom > 0 ? -13.0 : 0.0)
                    }
                    return
                }
                maker.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(2).priority(.low)
                // 沉浸模式下需要特殊布局适配
                if style != .tiled {
                    let collectionVisible = collectionView.window != nil && !collectionView.isHidden
                    if style == .overlay {
                        maker.bottom.lessThanOrEqualTo(bottomBarGuide.snp.top).offset(-4).priority(.high)
                    } else if !InMeetFlowComponent.isNewLayoutEnabled && style == .fullscreen && collectionVisible {
                        maker.top.greaterThanOrEqualTo(collectionView.snp.bottom).priority(.veryHigh)
                    }
                    maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-4).priority(.required)
                }
            }
        }
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var prefersStatusBarHidden: Bool {
        return currentLayoutContext.layoutType.isPhoneLandscape
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    deinit {
        viewModel.endDragging()
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    func updateMeetingLayoutStyle() {
        updateCollectionViewLayoutIsOverlayFullScreen()
        updatePageControlLayout()
    }

    func reloadVMs(cellViewModels: [InMeetGridCellViewModel], currentAsVM: InMeetGridCellViewModel?) {
        let begin = CACurrentMediaTime()
        defer {
            let cost = CACurrentMediaTime() - begin
            if cost > 2.0 {
                let msg = "reloadVMs \(cellViewModels.count) takes \(cost)"
                Logger.grid.error(msg)
                BizErrorTracker.trackBizError(key: .gridReloadTimeout, msg)
            }
            // 需等待reload完成再尝试，否则可能拿不到visibleCells
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.dismissManipulatorIfNeeded()
                // fix: 修复舞台模式开启共享时，手机横竖屏切换导致卡死。此时会同时存在多个
                // todo: @chenyizhuo 问题根因排查+displayInfo多实例支持
                if self?.parent != nil {
                    self?.updateVisibleRange()
                }
            }
        }

        let oldVMs = self.cellVMs
        var newVMs = cellViewModels
        if let asIndex = newVMs.firstIndex(where: { $0.type == .activeSpeaker }), let asVM = currentAsVM {
            newVMs[asIndex] = asVM
        }

        if Display.phone, !(self is InMeetFlowAndShareContainerViewControllerV2), newVMs.first?.type == .share {
            newVMs.remove(at: 0)
        }

        if !collectionView.frame.isEmpty,
           let batchUpdate = DiffUtils.computeBatchAction(origin: oldVMs, target: newVMs, maxChangeCnt: maxChangeCount) {
            if batchUpdate.isEmpty {
                Logger.grid.info("batch update flow skip empty")
                return
            }
            Logger.grid.info("batch update flow insert: \(batchUpdate.insertions.count), delete: \(batchUpdate.deletions.count), move: \(batchUpdate.moves.count)")
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates {
                    if self.isWebinar {
                        self.webinarPhoneLayout.indexPathFor1x1 = newVMs.firstIndex(where: { $0.pid == self.viewModel.meeting.account }).map({ IndexPath(row: $0, section: 0) })
                    } else {
                        self.squareFlowLayout.gridInfos = newVMs.map { $0.squareInfo }
                    }
                    self.gridLandscapeFlowLayout.viewModels = newVMs
                    self.cellVMs = newVMs
                    if !batchUpdate.deletions.isEmpty {
                        self.collectionView.deleteItems(at: batchUpdate.deletions.map({ IndexPath(item: $0, section: 0) }))
                    }
                    for move in batchUpdate.moves {
                        self.collectionView.moveItem(at: IndexPath(item: move.from, section: 0),
                                                     to: IndexPath(item: move.to, section: 0))
                    }
                    if !batchUpdate.insertions.isEmpty {
                        self.collectionView.insertItems(at: batchUpdate.insertions.map({ IndexPath(item: $0, section: 0) }))
                    }
                }
            }
        } else {
            Logger.grid.info("full reload flow \(newVMs.count)")
            if self.isWebinar {
                self.webinarPhoneLayout.indexPathFor1x1 = newVMs.firstIndex(where: { $0.pid == self.viewModel.meeting.account }).map({ IndexPath(row: $0, section: 0) })
            } else {
                self.squareFlowLayout.gridInfos = cellViewModels.map { $0.squareInfo }
            }
            self.gridLandscapeFlowLayout.viewModels = newVMs
            self.cellVMs = newVMs
            self.collectionView.reloadData()
        }
    }

    enum CellReuseIdentifier {
        static let video = "VideoGridCell"
        static let shareScreen = "SharedScreenGridCell"
        static let galleryShareContent = "GallerySharedContentGridCell"
    }

    func bindGrid() {
        collectionView.dataSource = self
        collectionView.delegate = self

        let asVMObs: Observable<InMeetGridCellViewModel?> = viewModel.singleGridViewModel(asIncludeLocal: true).map { $0 }
        Observable.combineLatest(viewModel.sortedVMsRelay,
                                 asVMObs.startWith(nil).distinctUntilChanged())
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (vms, asvm) in
                    guard let self = self else { return }
                    if !self.viewModel.isGridDragging {
                        self.reloadVMs(cellViewModels: vms, currentAsVM: asvm)
                    }
                })
                .disposed(by: rx.disposeBag)

        let pageObservable = pageObservable
        pageObservable
                .asDriver(onErrorJustReturn: 0)
                .drive(onNext: { [weak self] (pages) in
                    Self.logger.info("flow page count is:\(pages)")
                    guard let self = self else {
                        return
                    }
                    self.pageControl.numberOfPages = pages
                    self.viewModel.context.isFlowPageControlVisible = pages > 1
                    if self.pageControl.currentPage >= pages - 1 && pages > 0 {
                        self.pageControl.setCurrentPage(at: pages - 1, animated: true)
                    }
                })
                .disposed(by: rx.disposeBag)

        viewModel.shouldGoToFirstPage
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.scrollToFirstPage()
            })
            .disposed(by: rx.disposeBag)

        viewModel.shouldHideSingleVideo
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.delegate?.flowDidHideSingleVideo()
            })
            .disposed(by: rx.disposeBag)

        viewModel.shouldCancelDragging
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.cancelCurrentDragSession()
            })
            .disposed(by: rx.disposeBag)
    }

    private func setupCallkitInBackground() {
        if UIApplication.shared.applicationState == .background {
            // CallKit VoIP Push 拉活 用户接听电话后, Lark 没有进入前台, ImageServiceManager.Dependency 模块未被初始化,
            // 需要在应用进前台后 reload 重新加载头像
            NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
                    .take(1)
                    .subscribe(onNext: { [weak self] _ in
                        self?.collectionView.visibleCells.forEach({ ($0 as? InMeetingParticipantGridCell)?.reloadImageInfo() })
                    })
                    .disposed(by: rx.disposeBag)
        }
    }

    // 判断是否需要关闭当前展示的单流操作视图
    func dismissManipulatorIfNeeded() {
        let info = viewModel.gridViewManipulatorInfo
        guard !viewModel.context.isSingleVideoVisible, info.isShowing else { return }
        for cell in collectionView.visibleCells {
            // 通过记录的id、在visibleCells中搜索相应的cell，再判断sourceView的全局坐标是否已经发生变化：若没变化，则不用dismiss
            if let gridCell = cell as? InMeetingParticipantGridCell, let id = gridCell.deviceId, id == info.targetID {
                let point1 = info.sourcePoint
                let point2 = gridCell.moreButtonPoint
                // 1页 => 多页 时会新增slider，导致纵轴坐标出现10左右的offset（尽管此时visibleCells本身可能没有变化），因此容许了一定的y轴偏移
                if point1.x != point2.x || abs(point1.y - point2.y) >= 5 {
                    info.dismiss()
                }
                return
            }
        }
        info.dismiss()
    }

    // 直接关闭当前展示的单流操作视图
    func dismissManipulator() {
        viewModel.gridViewManipulatorInfo.dismiss()
    }

    // MARK: - UICollectionViewDataSource & UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cellVMs.count
    }

    private var visibleCellIDs: Set<ObjectIdentifier> = []
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        Logger.grid.info("cell for item at: \(indexPath)")
        let reuseIdentifier: String
        let gridVM = cellVMs[indexPath.item]
        switch gridVM.type {
        case .activeSpeaker, .participant: reuseIdentifier = Self.CellReuseIdentifier.video
        case .share: reuseIdentifier = Self.CellReuseIdentifier.galleryShareContent
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let cellID = ObjectIdentifier(cell)
        if visibleCellIDs.contains(cellID) {
            // iOS 14 drag & drop 有一定的概率会直接复用一个 visibleCell, 在后续不会回调 willDisplay 方法
            Logger.grid.warn("reuse a visibleCell \(cell)")
        }
        if let videoCell = cell as? InMeetingParticipantGridCell, case .participant = gridVM.type {
            videoCell.bind(viewModel: gridVM)
            videoCell.delegate = self
        } else if let shareContentCell = cell as? InMeetGalleryShareContentCell {
            self.galleryShareContentCell?.setShareContentVC(nil)
            self.galleryShareContentCell = shareContentCell
            shareContentCell.fullScreenDetector = self.viewModel.fullScreenDetector
            shareContentCell.doubleTapAction = { [weak self] location in
                self?.goBackShareContentAction?(location)
            }
            shareContentCell.changeOrderEnabled = { [weak self] in
                return self?.changeOrderEnable != InMeetFlowViewControllerV2.CustomOrderEnableType.none
            }
            shareContentCell.changeOrderAction = { [weak self] in
                guard let self = self, let shareIndex = self.cellVMs.firstIndex(where: { $0.type == .share }) else { return }
                self.changeGridOrderBySelection(from: shareIndex)
            }
            Logger.scene.info("create ShareContentCell \(cell)")
            let shareComponent = self.container?.shareComponent
            if sceneContent == .shareScreen {
                shareComponent?.configureShareScreenCell(shareContentCell)
            } else if sceneContent == .follow {
                shareComponent?.configureMSCell(shareContentCell)
            } else if sceneContent == .whiteboard {
                shareComponent?.configureWhiteBoardCell(shareContentCell)
            }
            if let vc = shareContentCell.shareContentVC as? InMeetShareScreenVideoVC {
                // iOS 14 drag & drop 有一定的概率会直接复用一个 visibleCell, 在后续不会回调 willDisplay 方法
                if visibleCellIDs.contains(cellID) {
                    vc.isCellVisible = true
                } else {
                    vc.isCellVisible = false
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cellID = ObjectIdentifier(cell)
        assert(!visibleCellIDs.contains(cellID))
        visibleCellIDs.insert(cellID)
        if let participantCell = cell as? InMeetingParticipantGridCell {
            participantCell.participantView.isCellVisible = true
            viewModel.fetchFullGridOrderIfNeeded(visibleIndex: indexPath.row)
        } else if let shareContentCell = cell as? InMeetGalleryShareContentCell {
            if let vc = shareContentCell.shareContentVC as? InMeetShareScreenVideoVC {
                vc.isCellVisible = true
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cellID = ObjectIdentifier(cell)
        if !visibleCellIDs.contains(cellID) {
            // iOS 14 drag & drop，有概率出现一个未知的 UICollectionViewCell 实例触发这个回调
            Logger.grid.warn("end display an unknown Cell \(cell)")
        }
        if cell is InMeetingParticipantGridCell || cell is InMeetGalleryShareContentCell {
            assert(visibleCellIDs.contains(cellID))
        }
        visibleCellIDs.remove(cellID)
        if let participantCell = cell as? InMeetingParticipantGridCell {
            participantCell.participantView.isCellVisible = false
        } else if let shareContentCell = cell as? InMeetGalleryShareContentCell {
            if let vc = shareContentCell.shareContentVC as? InMeetShareScreenVideoVC {
                vc.isCellVisible = false
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView, scrollView.bounds.size.width > 0 else {
            return
        }
        let point = scrollView.contentOffset

        let mode = displayMode
        switch mode {
        case .gridVideo:
            let pageWidth = collectionView.bounds.size.width
            let offsetX = point.x
            pageControl.setProgress(contentOffsetX: offsetX, pageWidth: pageWidth)
        case .singleRowVideo, .singleAudio:
            break
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else {
            return
        }
        // 更新visibleRange
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.updateVisibleRange()
        }

        let pageWidth = collectionView.bounds.size.width
        if displayMode == .gridVideo && pageWidth > 0 {
            let offsetX = collectionView.contentOffset.x
            let currentPage = Int(ceil(offsetX / pageWidth))
            MeetingTracks.trackSlide()
            // 埋点页数从1开始
            MeetingTracks.trackScreenDisplay(page: currentPage + 1)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == collectionView, displayMode == .singleRowVideo else {
            return
        }
        // 若decelerate==true，会调用scrollViewDidEndDecelerating
        if !decelerate {
            updateVisibleRange()
        }
    }

    // MARK: - UICollectionViewDragDelegate & UICollectionViewDropDelegate
    private let dragObjectIdentifier = "vc_drag_object_identifier"

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let enable = self.changeOrderEnable
        if enable != .enable || !self.dropEnabled {
            switch enable {
            case .isSynced: Toast.show(I18n.View_G_HostSyncedOrderNoMoveToast)
            case .isFocused: Toast.show(I18n.View_G_NoMoveInFocus_Toast)
            default: break
            }
            return []
        }
        let provider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = self.dragObjectIdentifier
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let cell = collectionView.cellForItem(at: indexPath) as? InMeetingParticipantGridCell {
            let previewParameters = UIDragPreviewParameters()
            let path = UIBezierPath(roundedRect: cell.participantView.frame, cornerRadius: cell.participantView.styleConfig.cornerRadius)
            previewParameters.visiblePath = path
            return previewParameters
        } else if let cell = collectionView.cellForItem(at: indexPath) as? InMeetGalleryShareContentCell {
            let previewParameters = UIDragPreviewParameters()
            let path = UIBezierPath(roundedRect: cell.contentView.frame, cornerRadius: cell.contentView.layer.cornerRadius)
            previewParameters.visiblePath = path
            return previewParameters
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        viewModel.beginDragging()
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let source = item.sourceIndexPath, source.item < cellVMs.count,
              let destination = coordinator.destinationIndexPath, destination.item < cellVMs.count else { return }

        viewModel.moveGrid(from: source.item, to: destination.item)

        collectionView.performBatchUpdates {
            if source.item != destination.item {
                // drap & drop 要求必须同步更新数据源，并且在用户拖动时宫格不会刷新，所以这里必须本地更新 cellVMs
                let vm = self.cellVMs.remove(at: source.item)
                self.cellVMs.insert(vm, at: destination.item)
                self.collectionView.moveItem(at: source, to: destination)
                self.viewModel.showReorderTagOnSyncing()
                InMeetSceneTracks.trackDragGrid(fromIndex: source.item,
                                                toIndex: destination.item,
                                                isSharing: self.container?.contentMode.isShareContent ?? false,
                                                isSharer: self.viewModel.meeting.shareData.isSelfSharingContent,
                                                scene: self.container?.sceneMode ?? .gallery)
            }
        }
        coordinator.drop(item.dragItem, toItemAt: destination)
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if let identifier = session.items.first?.localObject as? String, identifier == self.dragObjectIdentifier {
            return true
        }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if !self.dropEnabled {
            return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        if let cell = collectionView.cellForItem(at: indexPath) as? InMeetingParticipantGridCell {
            let previewParameters = UIDragPreviewParameters()
            let path = UIBezierPath(roundedRect: cell.participantView.frame, cornerRadius: cell.participantView.styleConfig.cornerRadius)
            previewParameters.visiblePath = path
            return previewParameters
        } else if let cell = collectionView.cellForItem(at: indexPath) as? InMeetGalleryShareContentCell {
            let previewParameters = UIDragPreviewParameters()
            let path = UIBezierPath(roundedRect: cell.contentView.frame, cornerRadius: cell.contentView.layer.cornerRadius)
            previewParameters.visiblePath = path
            return previewParameters
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        viewModel.endDragging()
        viewModel.showResetOrderGuide()
        dropEnabled = true
    }
}

extension InMeetFlowViewControllerV2: InMeetingParticipantGridCellDelegate {
    func didSingleTapContent(cellVM: InMeetGridCellViewModel, isSingleVideoEnabled: Bool, cell: UICollectionViewCell) {
        viewModel.fullScreenDetector?.postSwitchFullScreenEvent()
    }

    func didDoubleTapContent(participant: Participant, isSingleVideoEnabled: Bool, from view: UIView, avatarView: UIView) {
        guard participant.status == .onTheCall, isSingleVideoEnabled else {
            return
        }
        delegate?.flowDidShowSingleVideo(pid: participant.user, from: view, avatarView: avatarView)
        ParticipantTracks.trackFullScreen(click: "double_click_fullscreen")
    }

    func didTapCancelInvite(participant: Participant) {
        MeetingTracks.trackDidTapCancelInvite()
        if participant.status == .ringing {
            let role = self.viewModel.meeting.myself.meetingRole
            viewModel.httpClient.meeting.cancelInviteUser(participant.user, meetingId: viewModel.meetingId, role: role)
        }
    }

    func didTapMoreSelection(cellVM: InMeetGridCellViewModel, isFullscreen: Bool, isSingleVideoEnabled: Bool, from view: UIView, avatarView: UIView) {
        let participant = cellVM.participant.value
        // 记录宫格序号
        let gridIndex = self.cellVMs.firstIndex(where: { $0.pid == cellVM.pid })
        let participantService = self.viewModel.meeting.httpClient.participantService
        participantService.participantInfo(pid: participant, meetingId: self.viewModel.meeting.meetingId) { [weak self] ap in
            guard let self = self else { return }
            let changeOrderEnable = self.changeOrderEnable != .none
            if let sourceView = (view as? InMeetingParticipantView)?.moreSelectionButton,
               let container = self.container,
               let vc = self.viewModel.actionService.actionVC(participant: participant, userInfo: ap, source: .grid, heterization: {
                   $0.hasSignleVideo = isSingleVideoEnabled
                   $0.hasChangeOrder = changeOrderEnable
               }, callBack: { [weak self] in
                   guard let self = self else { return }
                   if $0 == .adjustPosition, let gridIndex = gridIndex {
                       self.changeGridOrderBySelection(from: gridIndex)
                       InMeetSceneTracks.trackClickChangeOrder(fromIndex: gridIndex,
                                                               isSharing: container.contentMode.isShareContent,
                                                               isSharer: self.viewModel.meeting.shareData.isSelfSharingContent,
                                                               scene: container.sceneMode)
                   } else if $0 == .fullScreen {
                       if isFullscreen {
                           self.delegate?.flowDidHideSingleVideo()
                       } else {
                           guard participant.status == .onTheCall else { return }
                           self.delegate?.flowDidShowSingleVideo(pid: participant.user, from: view, avatarView: avatarView)
                       }
                   }
               }) {
                if Display.pad {
                    self.presentByPopover(vc, sourceView: sourceView)
                } else {
                    self.presentByAlignPopover(vc, sourceView: sourceView)
                }

                if let sourcePoint = sourceView.superview?.convert(sourceView.frame.center, to: nil) {
                    self.viewModel.gridViewManipulatorInfo.manipulatorVC = vc
                    self.viewModel.gridViewManipulatorInfo.sourcePoint = sourcePoint
                    self.viewModel.gridViewManipulatorInfo.targetID = participant.deviceId
                }
            }
        }
    }

    private func presentByPopover(_ vc: ParticipantActionViewController, sourceView: UIView) {
        let originBounds = sourceView.bounds
        let sourceRect = CGRect(x: originBounds.minX - 4,
                                y: originBounds.minY - 4,
                                width: originBounds.width + 8,
                                height: originBounds.height + 8)
        let margins = ParticipantActionViewController.Layout.popoverLayoutMargins
        let config = DynamicModalPopoverConfig(sourceView: sourceView,
                                               sourceRect: sourceRect,
                                               backgroundColor: UIColor.ud.bgBody,
                                               popoverSize: .zero,
                                               popoverLayoutMargins: .init(edges: margins))
        let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: config, backgroundColor: .clear)
        viewModel.meeting.router.presentDynamicModal(vc, config: regularConfig)
    }

    private func presentByAlignPopover(_ vc: ParticipantActionViewController, sourceView: UIView) {
        let anchor: AlignPopoverAnchor
        let size = vc.totalPopoverSize
        let defalutContentWidth: CGFloat = 132
        if view.isLandscape {
            anchor = AlignPopoverAnchor(sourceView: sourceView,
                                        alignmentType: .top,
                                        arrowDirection: .right,
                                        contentWidth: .fixed(max(size.width, defalutContentWidth)),
                                        contentHeight: size.height,
                                        positionOffset: CGPoint(x: -4, y: 0),
                                        minPadding: UIEdgeInsets(top: InMeetNavigationBar.contentHeight + 10,
                                                                 left: 0,
                                                                 bottom: max(VCScene.safeAreaInsets.bottom, 10),
                                                                 right: 0),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        shadowColor: nil,
                                        containerColor: UIColor.ud.bgBody,
                                        shadowType: .s3Down)
        } else {
            anchor = AlignPopoverAnchor(sourceView: sourceView,
                                        alignmentType: .auto,
                                        contentWidth: .fixed(max(size.width, defalutContentWidth)),
                                        contentHeight: size.height,
                                        positionOffset: CGPoint(x: 0, y: 4),
                                        minPadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        shadowColor: nil,
                                        containerColor: UIColor.ud.bgBody,
                                        shadowType: .s3Down)
        }
        AlignPopoverManager.shared.present(viewController: vc, anchor: anchor)
    }

    func didTapUserName(participant: Participant) {
        if viewModel.browserUserProfileEnable, !participant.isLarkGuest {
            if let userId = participant.participantId.larkUserId {
                MeetingTracks.trackDidTapUserProfile()
                ParticipantTracks.trackParticipantAction(.userInformation,
                                                         isFromGridView: true,
                                                         isSharing: viewModel.meeting.shareData.isSharingContent)
                InMeetUserProfileAction.show(userId: userId, meeting: viewModel.meeting)
            }
        }
    }

    var tapParticipantFromSource: TapMeetingParticipantFromSource? {
        switch displayMode {
        case .gridVideo:
            return .commonGrid
        case .singleRowVideo:
            return .singleRow
        default:
            return nil
        }
    }

    private func changeGridOrderBySelection(from gridIndex: Int) {
        let enableType = changeOrderEnable
        if enableType == .isSynced {
            Toast.show(I18n.View_G_HostSyncedOrderNoMoveToast)
            return
        } else if enableType == .isFocused {
            Toast.show(I18n.View_G_NoMoveInFocus_Toast)
            return
        }

        let viewModel = ParticipantSearchViewModel(meeting: viewModel.meeting,
                                                   title: I18n.View_G_ReplaceParticipantsInThisPosition,
                                                   fromSource: .changeOrder)
        viewModel.selectedClosure = { [weak self] result in
            guard let self = self, case .inMeet(let participant) = result.type else { return }
            if let selectedIndex = self.cellVMs.firstIndex(where: { $0.pid == participant.user }) {
                InMeetSceneTracks.trackChangeOrderBySearch(fromIndex: gridIndex)
                self.viewModel.swapGridOrderAt(gridIndex, selectedIndex)
                if gridIndex != selectedIndex {
                    self.viewModel.showReorderTagOnSyncing()
                }
            } else if let name = result.name {
                Toast.show(I18n.View_G_NameHideNoChange(name))
                return
            }
            result.searchVC.dismiss(animated: true)
        }
        let vc = ParticipantSearchViewController(viewModel: viewModel)
        self.viewModel.router.presentDynamicModal(vc,
                                                  regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                  compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
        InMeetSceneTracks.trackClickChangeOrder(fromIndex: gridIndex,
                                                isSharing: container?.contentMode.isShareContent ?? false,
                                                isSharer: viewModel.meeting.shareData.isSelfSharingContent,
                                                scene: container?.sceneMode ?? .gallery)
    }

    var pageObservable: Observable<Int> {
        if isPadGalleryEnabled {
            return self.padGridFlowLayout.pageObservable.distinctUntilChanged()
        }
        let o2 = self.isWebinar ? self.webinarPhoneLayout.pageObservable : self.squareFlowLayout.pageObservable
        let o3 = self.gridLandscapeFlowLayout.pageObservable

        return Observable.merge([o2, o3])
            .distinctUntilChanged()
    }
}

extension InMeetFlowViewControllerV2: InMeetShareScreenGridCellActionDelegate {
    func didSingleTapContent(cell: UICollectionViewCell) {
        viewModel.fullScreenDetector?.postSwitchFullScreenEvent()
    }
}

extension InMeetFlowViewControllerV2 {
    private func updateFlowDisplayMode() {
        let mode = displayMode
        switch mode {
        case .gridVideo:
            attachCollectionView()
            collectionView.isPagingEnabled = true
            collectionView.alpha = 1
            if Display.pad {
                updateCollectionLayout(padGridFlowLayout)
            } else if currentLayoutContext.layoutType.isPhoneLandscape {
                updateCollectionLayout(gridLandscapeFlowLayout)
            } else {
                if self.isWebinar {
                    updateCollectionLayout(webinarPhoneLayout)
                } else {
                    updateCollectionLayout(squareFlowLayout)
                }
            }
            pageControl.alpha = 1
        case .singleRowVideo:
            attachCollectionView()
            collectionView.isPagingEnabled = false
            collectionView.alpha = 1
            updateCollectionLayout(singleRowLayout)
            pageControl.alpha = 0
            viewModel.context.isFlowPageControlVisible = false
        case .singleAudio:
            collectionView.alpha = 0
            if #unavailable(iOS 13.0) {
                // iOS 11、12，共享栏收起 + squareFlowLayout 可能crash
                // https://t.wtturl.cn/YT9C5Kb/
                if collectionView.collectionViewLayout === squareFlowLayout {
                    updateCollectionLayout(singleRowLayout)
                }
            }
            pageControl.alpha = 0
            viewModel.context.isFlowPageControlVisible = false
            detachCollectionView()
            cancelCurrentDragSession()
        }
        updateVisibleRange()
    }

    func attachCollectionView() {
        guard collectionView.superview == nil else {
            return
        }
        collectionViewWrapper.addSubview(collectionView)
        collectionView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func detachCollectionView() {
        guard collectionView.superview != nil else {
            return
        }
        collectionView.snp.removeConstraints()
        collectionView.removeFromSuperview()
    }

    private func updateCollectionLayout(_ layout: UICollectionViewLayout) {
        guard collectionView.collectionViewLayout !== layout else {
            return
        }
        Self.logger.info("refresh flow layout: \(layout.self)")
        collectionView.collectionViewLayout = layout
        collectionView.setContentOffset(.zero, animated: false)
        updateVisibleRange()
    }

    func updateVisibleRange() {
        guard let layout = collectionView.collectionViewLayout as? PagedCollectionLayout else { return }
        viewModel.context.currentGridVisibleRange = layout.visibleRange
        let info = GridDisplayInfo(visibleRange: layout.visibleRange, displayMode: displayMode)
        viewModel.postGridUpdateEvent(.displayInfo, context: info)
    }

    private func updateCollectionViewLayoutIsOverlayFullScreen() {
        let style = meetingLayoutStyle
        gridLandscapeFlowLayout.meetingLayoutStyle = style
        padGridFlowLayout.meetingLayoutStyle = style
        if self.isWebinar {
            webinarPhoneLayout.meetingLayoutStyle = style
        } else {
            squareFlowLayout.meetingLayoutStyle = style
        }
        singleRowLayout.meetingLayoutStyle = style

    }

    private func updatePageControlConfig() {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            pageControl.config = FlexiblePageControl.Config(dotSize: 5, verticalPadding: 0.0)
        } else if isPadGalleryEnabled {
            pageControl.config = FlexiblePageControl.Config(dotSize: 5.0, verticalPadding: 4.0)
        } else {
            if Display.phone && currentLayoutContext.layoutType.isCompact {
                pageControl.config = FlexiblePageControl.Config(dotSize: 5)
            } else {
                pageControl.config = FlexiblePageControl.Config()
            }
        }
    }

    // MARK: - drag & drop

    enum CustomOrderEnableType {
        case none // 不展示入口
        case isSynced // 正在被同步顺序，展示入口但功能不可用
        case isFocused // 正在看焦点视频，如果本端是主持人或主共享人，展示入口但功能不可用
        case enable // 功能可用
    }

    var changeOrderEnable: CustomOrderEnableType {
        /// 能够调整视频顺序的条件：
        ///  - Pad
        ///  - 宫格总数大于1 && 会中人数大于1
        ///  - 无焦点视频
        ///  - Webinar中，本端不是“观众”
        ///  - 未被主持人同步顺序
        if !Display.pad {
            return .none
        }
        if cellVMs.count < 2 || viewModel.meeting.participant.currentRoom.nonRingingCount < 2 {
            return .none
        }
        if viewModel.meeting.participant.focusing != nil {
            let isHost = viewModel.meeting.myself.isHost
            let isSelfSharingContent = viewModel.meeting.shareData.isSelfSharingContent
            if isHost || isSelfSharingContent {
                return .isFocused
            }
            return .none
        }
        if viewModel.isWebinarAttendee {
            return .none
        }
        if viewModel.isSyncedByHost {
            return .isSynced
        }
        return .enable
    }

    func cancelCurrentDragSession() {
        Util.runInMainThread {
            if self.viewModel.isGridDragging {
                self.collectionView.cancelInteractiveMovement()
                self.dropEnabled = false
            }
        }
    }
}

extension InMeetFlowViewControllerV2 {
    private func updateSharingContent() {
        switch self.sceneContent {
        case .shareScreen, .whiteboard, .follow, .webSpace:
            isDisplayingShareContent = true
            reloadShareContent()
        case .selfShareScreen, .flow:
            isDisplayingShareContent = false
        }
    }

    private func reloadShareContent() {
        if isDisplayingShareContent, let shareIndex = cellVMs.firstIndex(where: { $0.type == .share }) {
            collectionView.reloadItems(at: [IndexPath(row: shareIndex, section: 0)])
        }
    }

    private func updateShareContentCell() {
        if !isDisplayingShareContent {
            self.galleryShareContentCell?.setShareContentVC(nil)
        }
        self.cancelCurrentDragSession()

        viewModel.postGridUpdateEvent(.shareGridEnabled, context: isDisplayingShareContent)
    }
}
