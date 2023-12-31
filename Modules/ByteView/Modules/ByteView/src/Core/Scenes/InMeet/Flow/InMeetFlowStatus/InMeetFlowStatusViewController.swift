//
//  InMeetFlowStatusViewController.swift
//  ByteView
//
//  Created by Shuai Zipei on 2023/3/7.
//

import UIKit
import ByteViewUI
import ByteViewTracker
import ByteViewNetwork
import UniverseDesignIcon

class InMeetFlowStatusViewController: VMViewController<InMeetFlowStatusViewModel>, UIGestureRecognizerDelegate {

    private struct FloatingOriginMeta {
        let x: CGFloat
        let y: CGFloat
        let leftGuide: UILayoutGuide
        let topGuide: UILayoutGuide
    }

    weak var container: InMeetViewContainer?
    var contentGuide: UILayoutGuide?

    private var isSingleVideo = false
    private var isFullScreen = false
    private var isSharing: Bool {
        guard let meetingContent = container?.context.meetingContent else { return false }
        return meetingContent != .flow && meetingContent != .selfShareScreen
    }
    private var isSelfShareScreen: Bool {
        guard let meetingContent = container?.context.meetingContent else { return false }
        return meetingContent == .selfShareScreen
    }
    private var isScreenShare: Bool {
        guard let meetingContent = container?.context.meetingContent else { return false }
        return meetingContent == .shareScreen
    }
    private var isWhiteboardSharing: Bool {
        guard let meetingContent = container?.context.meetingContent else { return false }
        return meetingContent == .whiteboard
    }
    private lazy var dragContentLayoutToken: MeetingLayoutGuideToken? = {
        return container?.layoutContainer.requestOrderedLayoutGuide(topAnchor: .topNavigationBar, bottomAnchor: .bottomToolbar)
    }()
    private let flowStatusLayoutGuide = UILayoutGuide()
    private var topFloatingStatusBarToken: MeetingLayoutGuideToken?
    private var panStartingPoint: CGPoint = .zero
    private var hasPanMoved = false
    private var lastShowStatusBar: Bool = false
    private var lastPanMoved: Bool = false

    private var floatingBottomPadding: CGFloat {
        if currentLayoutContext.layoutType.isPhoneLandscape, (isWhiteboardSharing || isScreenShare) {
            return 24
        } else {
            return 8
        }
    }

    private var floatingMeetingStatusLeftPadding: CGFloat {
        if isOnSafeAreaSide {
            return 0
        } else {
            return 8
        }
    }

    private let floatingContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let floatingView: UIView = {
        let view = UIView()
        view.layer.ud.setShadow(type: .s4Down)
        view.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
        view.layer.cornerRadius = 6.0
        view.layer.borderWidth = 0.5
        view.layer.vc.borderColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private let networkfloatingView: UIView = {
        let view = UIView()
        view.layer.ud.setShadow(type: .s4Down)
        view.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.9)
        view.layer.cornerRadius = 6.0
        view.layer.borderWidth = 0.5
        view.layer.vc.borderColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private(set) lazy var statusView: InMeetFlowStatusView = {
        let view = InMeetFlowStatusView()
        view.showStatusDetail = { [weak self] in
            self?.showStatusDetail()
        }
        view.addGestureRecognizer(statusViewGusture)
        return view
    }()

    private(set) lazy var networkView = InMeetRtcNetworkStatusView()

    private lazy var statusViewGusture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(didTapStatusView))
        return gesture
    }()

    private var panBlockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard panBlockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    // MARK: - Override

    // 使用 VCMenuView 提供的支持自定义点击响应范围的能力
    override func loadView() {
        let menuView = VCMenuView()
        menuView.delegate = self
        view = menuView
    }

    override func setupViews() {
        super.setupViews()
        view.backgroundColor = .clear

        flowStatusLayoutGuide.identifier = "flowStatus"
        view.addLayoutGuide(flowStatusLayoutGuide)
        updateMeetingStatusLayoutGuide()

        view.addSubview(floatingContainerView)
        resetFloatingViewPosition()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanAction(_:)))
        floatingContainerView.addGestureRecognizer(pan)

        floatingContainerView.addSubview(floatingView)
        floatingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        floatingContainerView.addSubview(networkfloatingView)
        networkfloatingView.snp.makeConstraints { make in
            make.left.equalTo(floatingView.snp.right).offset(4)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(21)
            make.width.equalTo(24)
        }
        networkfloatingView.addSubview(networkView)
        networkView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(12)
        }
        floatingView.addSubview(statusView)
        statusView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        updateViewVisibility()
        updateMeetingStatusLayoutGuide()
        resetFloatingViewPosition()
    }

    // disable-lint: duplicated code
    private func updateStatusView() {
        floatingView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        networkfloatingView.snp.remakeConstraints { make in
            make.left.equalTo(floatingView.snp.right).offset(4)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(21)
            make.width.equalTo(24)
        }
        networkView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(12)
        }
        statusView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateViewVisibility()
        updateMeetingStatusLayoutGuide()
        resetFloatingViewPosition()
    }
    // enable-lint: duplicated code

    override func bindViewModel() {
        super.bindViewModel()
        viewModel?.delegate = self
        // status view
        if let statusViewModel = viewModel.statusViewModel {
            statusView.bindViewModel(statusViewModel)
            statusView.isHidden = false
        } else {
            statusView.isHidden = true
        }

        if let networkStatusViewModel = viewModel.networkStatusViewModel {
            networkView.bindViewModel(networkStatusViewModel)
            networkView.isHidden = false
        } else {
            networkView.isHidden = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.refreshStatusView()
    }

    private func refreshStatusView() {
        self.statusView.updateData()
        self.statusView.updateLayout()
        self.statusView.hideStatusIfNeeded(isFullScreen)
        self.updateViewVisibility()
        self.updateMeetingStatusLayoutGuide()
        self.resetMeetStatusViewPosition()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if oldContext.layoutType != newContext.layoutType {
            hasPanMoved = false
            self.refreshStatusView()
        } else if newContext.layoutChangeReason.isOrientationChanged || newContext.layoutChangeReason == .refresh {
            hasPanMoved = false
            self.updateMeetingStatusLayoutGuide()
            self.resetMeetStatusViewPosition()
        }
    }

    func updateMeetingStatusLayoutGuide() {
        if flowStatusLayoutGuide.owningView == nil { return }
        guard let contentGuide = contentGuide, contentGuide.canUse(on: view) else {
            flowStatusLayoutGuide.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.left.right.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalToSuperview().inset(floatingBottomPadding)
            }
            return
        }

        flowStatusLayoutGuide.snp.remakeConstraints { make in
            make.top.equalTo(contentGuide)
            make.bottom.equalTo(contentGuide)

            if Display.pad || !Display.iPhoneXSeries || !currentLayoutContext.layoutType.isPhoneLandscape {
                make.left.right.equalTo(view.safeAreaLayoutGuide)
            } else if view.orientation == .landscapeLeft {
                make.left.equalTo(0)
                make.right.equalTo(view.safeAreaLayoutGuide)
            } else {
                make.left.equalTo(view.safeAreaLayoutGuide)
                make.right.equalTo(0)
            }
        }
    }

    private func updateTopFloatingStatusBarLayoutGuide() {
        guard let container = container else { return }
        let showStausBar = !view.isHidden && !statusView.isEmpty
        let statusBarToken: MeetingLayoutGuideToken
        var needUpdate = true
        if let topFloatingStatusBarToken = topFloatingStatusBarToken {
            statusBarToken = topFloatingStatusBarToken
            needUpdate = showStausBar != lastShowStatusBar || hasPanMoved != lastPanMoved
            lastShowStatusBar = showStausBar
            lastPanMoved = hasPanMoved
        } else {
            statusBarToken = container.layoutContainer.registerAnchor(anchor: .topFloatingStatusBar)
            self.topFloatingStatusBarToken = statusBarToken
        }
        if !needUpdate { return }
        statusBarToken.layoutGuide.snp.remakeConstraints { make in
            if showStausBar && !hasPanMoved {
                make.edges.equalTo(floatingContainerView)
            } else {
                make.top.left.right.equalTo(container.contentGuide)
                make.height.equalTo(0)
            }
        }
    }

    @objc private func didTapStatusView() {
        guard viewModel.isPopupEnabled else { return }
        showStatusDetail()
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "mobile_status_bar", "non_pc_type": Display.phone ? "ios_mobile" : "ios_pad", "if_landscape_screen": view.isLandscape ? "true" : "false"])
    }

    func showStatusDetail() {
        guard !viewModel.statusManager.statuses.isEmpty,
                let navigationBar = container?.topBar else { return }
        var bounds = navigationBar.statusView.bounds
        bounds.origin.y += 20
        let sourceView: UIView = isFullScreen ? self.statusView : navigationBar.statusView
        let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                      sourceRect: bounds,
                                                      backgroundColor: UIColor.ud.bgFloat,
                                                      permittedArrowDirections: .up)
        let vm = InMeetStatusDetailViewModel(resolver: self.viewModel.resolver)
        let vc = InMeetStatusDetailViewController(viewModel: vm)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
        self.viewModel.router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: .init(presentationStyle: .pan))
    }

    func resetFloatingViewPosition() {
        if hasPanMoved { return }
        let meta = floatingViewOriginMeta()
        floatingContainerView.snp.remakeConstraints { make in
            make.left.equalTo(meta.leftGuide).offset(meta.x)
            make.top.equalTo(meta.topGuide).offset(meta.y)
        }
    }

    private func floatingViewOriginMeta() -> FloatingOriginMeta {
        if isFullScreen {
            let meetingScene = container?.context.meetingScene
            let vm = InMeetWhiteboardViewModel(resolver: self.viewModel.resolver)
            let canPadEditWhiteboard = vm.canPadEditWhiteboard
            if Display.pad, currentLayoutContext.layoutType.isRegular {
                if meetingScene == .gallery {
                    //make.left.equalTo(flowStatusLayoutGuide).offset(16)
                    //make.top.equalTo(flowStatusLayoutGuide).offset(8)
                    return FloatingOriginMeta(x: 16, y: 8, leftGuide: flowStatusLayoutGuide, topGuide: flowStatusLayoutGuide)
                } else if canPadEditWhiteboard, meetingScene == .speech {
                    //make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(16)
                    //make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
                    return FloatingOriginMeta(x: 16, y: 16, leftGuide: view.safeAreaLayoutGuide, topGuide: view.safeAreaLayoutGuide)
                } else if canPadEditWhiteboard, meetingScene == .thumbnailRow {
                    //make.left.equalTo(flowStatusLayoutGuide).offset(16)
                    //make.top.equalTo(flowStatusLayoutGuide).offset(-23)
                    return FloatingOriginMeta(x: 16, y: -23, leftGuide: flowStatusLayoutGuide, topGuide: flowStatusLayoutGuide)
                } else {
                    //make.left.equalTo(flowStatusLayoutGuide).offset(16)
                    //make.top.equalTo(flowStatusLayoutGuide).offset(16)
                    return FloatingOriginMeta(x: 16, y: 16, leftGuide: flowStatusLayoutGuide, topGuide: flowStatusLayoutGuide)
                }
            } else if Display.phone || Display.pad && currentLayoutContext.layoutType.isCompact {
                if currentLayoutContext.layoutType.isPhoneLandscape, isScreenShare || isWhiteboardSharing {
                    //make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(floatingMeetingStatusLeftPadding)
                    //make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
                    return FloatingOriginMeta(x: floatingMeetingStatusLeftPadding, y: 24, leftGuide: view.safeAreaLayoutGuide, topGuide: view.safeAreaLayoutGuide)
                } else if meetingScene == .gallery {
                    //make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(floatingMeetingStatusLeftPadding)
                    //make.top.equalTo(flowStatusLayoutGuide).offset(8)
                    return FloatingOriginMeta(x: floatingMeetingStatusLeftPadding, y: 8, leftGuide: view.safeAreaLayoutGuide, topGuide: flowStatusLayoutGuide)
                } else if isWhiteboardSharing, meetingScene == .speech {
                    //make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(16)
                    //make.top.equalTo(view.safeAreaInsets.top).offset(16)
                    return FloatingOriginMeta(x: 16, y: 16, leftGuide: view.safeAreaLayoutGuide, topGuide: view.safeAreaLayoutGuide)
                } else if isWhiteboardSharing, meetingScene == .thumbnailRow {
                    if Display.phone {
                        //make.left.equalTo(flowStatusLayoutGuide).offset(16)
                        //make.top.equalTo(flowStatusLayoutGuide).offset(8)
                        return FloatingOriginMeta(x: 16, y: 8, leftGuide: flowStatusLayoutGuide, topGuide: flowStatusLayoutGuide)
                    } else {
                        //make.left.equalTo(flowStatusLayoutGuide).offset(16)
                        //make.top.equalTo(flowStatusLayoutGuide).offset(-23)
                        return FloatingOriginMeta(x: 16, y: -23, leftGuide: flowStatusLayoutGuide, topGuide: flowStatusLayoutGuide)
                    }
                } else {
                    //make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(floatingMeetingStatusLeftPadding)
                    //make.top.equalTo(flowStatusLayoutGuide).offset(8)
                    return FloatingOriginMeta(x: floatingMeetingStatusLeftPadding, y: 8, leftGuide: view.safeAreaLayoutGuide, topGuide: flowStatusLayoutGuide)
                }
            }
        }
        return FloatingOriginMeta(x: floatingMeetingStatusLeftPadding, y: floatingBottomPadding, leftGuide: flowStatusLayoutGuide, topGuide: flowStatusLayoutGuide)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    func containerDidTransition() {
        updateMeetingStatusLayoutGuide()
        resetMeetStatusViewPosition()
    }

    // MARK: - Private
    /// 横屏模式下悬浮面板是否在刘海屏一侧
    private var isOnSafeAreaSide: Bool {
        return Display.iPhoneXSeries && view.orientation == .landscapeRight
    }

    private func resetMeetStatusViewPosition() {
        self.resetFloatingViewPosition()
        updateTopFloatingStatusBarLayoutGuide()
    }

    private func updateViewVisibility() {
        view.isHidden = isSingleVideo || (Display.pad && !isFullScreen && self.view.isRegular)
        updateTopFloatingStatusBarLayoutGuide()
    }

    // MARK: - Dragging
    @objc
    private func handlePanAction(_ recognizer: UIPanGestureRecognizer) {
        if Display.pad, currentLayoutContext.layoutType.isRegular {
            return
        }
        let point = recognizer.translation(in: view)

        switch recognizer.state {
        case .began:
            panBlockFullScreenToken = viewModel.fullScreenDetector?.requestBlockAutoFullScreen()
            let origin = floatingContainerView.frame.origin
            panStartingPoint = origin
            hasPanMoved = true
            updateFloatingViewPosition(panStartingPoint)
        case .changed:
            let targetPosition = CGPoint(x: panStartingPoint.x + point.x, y: panStartingPoint.y + point.y)
            updateFloatingViewPosition(targetPosition)
        case .ended, .cancelled:
            panBlockFullScreenToken = nil
            let targetPosition = CGPoint(x: panStartingPoint.x + point.x, y: panStartingPoint.y + point.y)
            lockFloatingViewPosition(targetPosition)
        default:
            break
        }
    }

    private func updateFloatingViewPosition(_ point: CGPoint) {
        guard let contentGuide = dragContentLayoutToken?.layoutGuide else { return }
        let width = floatingView.frame.width
        let meta = floatingViewOriginMeta()
        let offsetX = min(max(meta.x, point.x), view.safeAreaLayoutGuide.layoutFrame.maxX - width - 8)
        floatingContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(point.y).priority(.high)
            make.left.equalTo(meta.leftGuide).offset(offsetX)
            make.top.greaterThanOrEqualTo(contentGuide).offset(8)
            make.bottom.lessThanOrEqualTo(contentGuide).offset(-8)
            make.leading.greaterThanOrEqualTo(contentGuide)
        }
        updateTopFloatingStatusBarLayoutGuide()
    }

    private func lockFloatingViewPosition(_ point: CGPoint) {
        guard let contentGuide = dragContentLayoutToken?.layoutGuide else { return }
        let meta = floatingViewOriginMeta()
        let minY = floatingContainerView.frame.minY

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
                           self?.floatingContainerView.snp.remakeConstraints { make in
                               make.top.equalToSuperview().offset(minY).priority(.high)
                               make.bottom.lessThanOrEqualTo(contentGuide).offset(-8)
                               make.left.equalTo(meta.leftGuide).offset(meta.x)
                           }
                           self?.view.layoutIfNeeded()
                       },
                       completion: { [weak self] _ in
                           self?.updateTopFloatingStatusBarLayoutGuide()
                           VCTracker.post(name: .vc_meeting_onthecall_click,
                                          params: [.click: "mobile_status_bar_haul"])
                       })
    }
}

extension InMeetFlowStatusViewController: VCMenuViewDelegate {
    func menuView(_ menu: VCMenuView, shouldRespondTouchAt point: CGPoint) -> VCMenuViewHitTestResult {
            let converted = menu.convert(point, to: floatingContainerView)
            if floatingContainerView.hitTest(converted, with: nil) != nil {
                return .default
            } else {
                return .ignore
            }
        }
}

extension InMeetFlowStatusViewController: MeetingLayoutStyleListener {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        isFullScreen = container.meetingLayoutStyle == .fullscreen
        statusView.isFullScreen = isFullScreen
        networkView.isFullScreen = isFullScreen
        networkView.updateStatus()
        statusView.updateData()
        statusView.updateLayout()
        statusView.hideStatusIfNeeded(isFullScreen)
        statusView.recordView.recoverAnimationIfNeed()
        updateMeetingStatusLayoutGuide()
        resetMeetStatusViewPosition()
        updateViewVisibility()
    }
}

extension InMeetFlowStatusViewController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .singleVideo:
            guard let isSingleVideo = userInfo as? Bool else { return }
            self.isSingleVideo = isSingleVideo
            updateViewVisibility()
        case .contentScene:
            updateMeetingStatusLayoutGuide()
            resetMeetStatusViewPosition()
        case .whiteboardMenu:
            if Display.pad {
                updateMeetingStatusLayoutGuide()
                resetMeetStatusViewPosition()
            }
        default:
            break
        }
    }
}
extension InMeetFlowStatusViewController: InMeetFlowStatusViewModelDelegate {
    func statusItemsDidChange(_ items: [InMeetStatusThumbnailItem]) {
        Util.runInMainThread {
            self.statusView.updateFlowStatusView(items)
            self.statusView.recordView.recoverAnimationIfNeed()
            self.updateViewVisibility()
            self.updateMeetingStatusLayoutGuide()
            self.resetMeetStatusViewPosition()
        }
    }
}
