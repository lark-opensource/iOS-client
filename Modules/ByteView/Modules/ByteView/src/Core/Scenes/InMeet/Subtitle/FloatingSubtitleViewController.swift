//
//  FloatingSubtitleViewController.swift
//  ByteView
//
//  Created by panzaofeng on 2022/6/21.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewUI
import UniverseDesignIcon

/*
 * 字幕浮动面板
 * 层级位于宫格流之上，内容限制在 contentGuide 之间，通过重写 hitTest 限制可点击区域
 */
class FloatingSubtitleViewController: VMViewController<FloatingSubtitleViewModel> {
    var contentGuide: UILayoutGuide?
    var topBarGuide: UILayoutGuide?
    var bottomBarGuide: UILayoutGuide?
    var subtitleInitialGuide: UILayoutGuide?

    var layoutStyle: InMeetSceneManager.ContentMode?
    var isFullScreen = false

    // 打开历史字幕Block
    var openHistorySubtitlePageBlock: (() -> Void)?

    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var panStartingPoint: CGPoint = .zero

    // 用户是否用手指移动过字幕面板，没有移动过时，从共享态到非共享态，字幕面板要自动调整位置
    private var hasMovedPanel = false
    private var isDraggingPanel = false
    // floatSubtitleLayoutGuide 代表字幕面板的可显示区域，即拖拽范围
    private let floatSubtitleLayoutGuide = UILayoutGuide()

    private let defaultPadding = 8.0
    private var containerHeight: CGFloat = 98

    private enum ContainerWidth {
        static let phoneLandScape: CGFloat = Display.iPhoneXSeries ? 612 : 424
        static let pad: CGFloat = 640
    }

    private var floatingBottomPadding: CGFloat {
        if layoutStyle == .follow {
            return 8
        } else if currentLayoutContext.layoutType.isCompact {
            return 32
        } else if Display.iPhoneXSeries {
            return 3
        } else {
            return 16
        }
    }

    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard blockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    private var panBlockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard panBlockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    let floatingContainerView = UIView()

    private lazy var subtitleView: InMeetSubtitleView = {
        let view = InMeetSubtitleView(viewModel: viewModel)
        return view
    }()

    // 字幕面板隐藏Timer
    private var timeoutTimer: Timer?

    deinit {
        releaseTimer()
    }

    // MARK: - Override

    // 使用 VCMenuView 提供的支持自定义点击响应范围的能力
    override func loadView() {
        let menuView = VCMenuView()
        menuView.delegate = self
        view = menuView
    }

    // viewDidLoad
    override func setupViews() {
        super.setupViews()

        view.backgroundColor = .clear

        view.addLayoutGuide(floatSubtitleLayoutGuide)
        updateFloatSubtitleLayoutGuide()

        floatingContainerView.isHidden = true
        view.addSubview(floatingContainerView)
        resetFloatingContainerPosition()

        floatingContainerView.addSubview(subtitleView)
        subtitleView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        resetFloatingContainerPosition()

        if Display.phone {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            floatingContainerView.addGestureRecognizer(tap)
        } else {
            subtitleView.openHistoryButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        floatingContainerView.addGestureRecognizer(pan)
    }

    override func bindViewModel() {
        super.bindViewModel()
    }

    // 更新限制区域
    func updateFloatSubtitleLayoutGuide() {
        if floatSubtitleLayoutGuide.owningView == nil { return }
        guard let contentGuide = contentGuide, contentGuide.canUse(on: view),
              let topBarGuide = topBarGuide, topBarGuide.canUse(on: view),
              let bottomBarGuide = bottomBarGuide, bottomBarGuide.canUse(on: view),
              let layoutStyle = layoutStyle
        else { return }
        /// 观看分享屏幕
        /// - 竖屏: shareScreen
        /// - 横屏: flowAndShareScreen
        /// - pad: shareScreen
        floatSubtitleLayoutGuide.snp.remakeConstraints { make in
//            make.left.greaterThanOrEqualTo(view.safeAreaLayoutGuide)
//            make.right.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview().inset(defaultPadding).priority(.high)
            switch (layoutStyle, isFullScreen, Display.pad) {
            case(.flow, _, _):
                make.top.bottom.equalTo(contentGuide)
            case(.follow, true, true), (.whiteboard, true, true), (.webSpace, true, true):
                make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            case(.follow, true, false), (.whiteboard, true, false), (.webSpace, true, false):
                make.top.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalTo(contentGuide)
            case(.follow, false, true), (.whiteboard, false, true), (.webSpace, false, true):
                make.top.equalTo(topBarGuide.snp.bottom)
                make.bottom.equalTo(bottomBarGuide.snp.top)
            case(.follow, false, false), (.whiteboard, false, false), (.webSpace, false, false):
                make.top.equalTo(topBarGuide.snp.bottom)
                make.bottom.equalTo(contentGuide)
            case(.shareScreen, false, true):
                make.top.equalTo(topBarGuide.snp.bottom)
                make.bottom.equalTo(bottomBarGuide.snp.top)
            case(.shareScreen, false, false):
                make.top.equalTo(topBarGuide.snp.bottom)
                make.bottom.equalTo(contentGuide)
            case(.shareScreen, true, _):
                make.top.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalTo(contentGuide)
            case(.selfShareScreen, false, _):
                make.top.equalTo(topBarGuide.snp.bottom)
                make.bottom.equalTo(contentGuide)
            case(.selfShareScreen, true, _):
                make.top.equalTo(view.safeAreaLayoutGuide)
                make.bottom.equalTo(contentGuide)
            }
        }
    }
    // 更新contianer
    func resetFloatingContainerPosition() {
        let isFlowPageControlVisible = viewModel.isFlowPageControlVisible()
        guard let layoutStyle = layoutStyle, let guide = subtitleInitialGuide, guide.canUse(on: view) && floatSubtitleLayoutGuide.canUse(on: view) else { return }
        guide.snp.remakeConstraints { make in
            make.height.equalTo(containerHeight).priority(.required)
            if !Display.pad {
                // Contianer bottom constraints
                switch (layoutStyle, isFullScreen, isFlowPageControlVisible, currentLayoutContext.layoutType.isCompact) {
                case (.flow, true, true, true):
                    make.bottom.equalTo(floatSubtitleLayoutGuide).inset(13)
                case (.flow, false, true, true):
                    make.bottom.equalTo(floatSubtitleLayoutGuide).inset(17)
                default:
                    make.bottom.equalTo(floatSubtitleLayoutGuide).inset(defaultPadding)
                }
                if currentLayoutContext.layoutType.isCompact {
                    make.left.right.equalTo(floatSubtitleLayoutGuide)
                } else {
                    make.width.equalTo(ContainerWidth.phoneLandScape)
                    make.centerX.equalTo(floatSubtitleLayoutGuide)
                }
            } else {
                make.centerX.equalToSuperview()

                let offset: CGFloat = isFullScreen ? .zero : 24
                make.bottom.equalTo(floatSubtitleLayoutGuide).inset(offset)

                if floatSubtitleLayoutGuide.layoutFrame.size.width < ContainerWidth.pad {
                    make.left.right.equalTo(floatSubtitleLayoutGuide)
                } else {
                    make.width.equalTo(ContainerWidth.pad)
                }
            }
        }
        floatingContainerView.snp.remakeConstraints { make in
            make.edges.equalTo(guide)
        }
    }

    // MARK: - Private
    private func updateFloatingContainerPosition(x: CGFloat, y: CGFloat) {
        let xInReactionLayoutGuide = x - floatSubtitleLayoutGuide.layoutFrame.minX
        let yInReactionLayoutGuide = y - floatSubtitleLayoutGuide.layoutFrame.minY
        floatingContainerView.snp.remakeConstraints { make in
            make.height.equalTo(containerHeight)
            make.top.equalTo(floatSubtitleLayoutGuide).offset(yInReactionLayoutGuide).priority(.high)
            make.top.left.greaterThanOrEqualTo(floatSubtitleLayoutGuide)
            make.bottom.lessThanOrEqualTo(floatSubtitleLayoutGuide)
            if !Display.pad {
                if currentLayoutContext.layoutType.isCompact {
                    make.left.right.equalTo(floatSubtitleLayoutGuide)
                } else {
                    make.left.equalTo(floatSubtitleLayoutGuide).offset(xInReactionLayoutGuide).priority(.high)
                    make.width.equalTo(ContainerWidth.phoneLandScape)
                    make.right.lessThanOrEqualTo(floatSubtitleLayoutGuide)
                }
            } else {
                if floatSubtitleLayoutGuide.layoutFrame.size.width < ContainerWidth.pad + 16 {
                    make.left.right.equalTo(floatSubtitleLayoutGuide)
                } else {
                    make.left.equalTo(floatSubtitleLayoutGuide).offset(xInReactionLayoutGuide).priority(.high)
                    make.width.equalTo(ContainerWidth.pad)
                    make.right.lessThanOrEqualTo(floatSubtitleLayoutGuide)
                }
            }
        }
    }

    @objc func handleTap() {
        self.openHistorySubtitlePageBlock?()
    }

    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.translation(in: view)

        switch recognizer.state {
        case .began:
            isDraggingPanel = true
            panStartingPoint = floatingContainerView.frame.origin
            generateImpactFeedback()
        case .changed:
            let xPosition = panStartingPoint.x + point.x
            let yPosition = panStartingPoint.y + point.y
            updateFloatingContainerPosition(x: xPosition, y: yPosition)
        case .ended, .cancelled:
            resetTimer()
            hasMovedPanel = true
            isDraggingPanel = false
            MeetingTracksV2.trackDragSubtitle()
        default:
            break
        }
    }

    func containerDidTransition() {
        resetTimer()
        updateFloatSubtitleLayoutGuide()
        resetFloatingContainerPosition()
        hasMovedPanel = false
        subtitleView.trimSubtitleViewDatasWhenTransition()
    }

    private func generateImpactFeedback() {
        if Display.phone {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

extension FloatingSubtitleViewController {
    func layoutSubtitle() {
        subtitleView.layoutSubtitle()
    }

    func setupMeetingSubtitleLayout(openHistorySubtitlePage: (() -> Void)?,
                                    closeSubtile: (() -> Void)?) {
        self.openHistorySubtitlePageBlock = openHistorySubtitlePage
        subtitleView.closeSubtileBlock = closeSubtile
    }

    func restoreSubtitlesFrom(subtitles: [Subtitle]) {
        if floatingContainerView.isHidden {
            floatingContainerView.isHidden = false
        }

        subtitleView.restoreSubtitlesFrom(subtitles: subtitles)
    }

    func updateSubtitleStatus(status: AsrSubtitleStatus) {
        if floatingContainerView.isHidden {
            floatingContainerView.isHidden = false
        }
        subtitleView.updateSubtitleStatus(status: status)
    }

    func clearAllSubtitlesAndSwipeUpForPreviousSubtitles() {
        subtitleView.clearAllSubtitlesAndSwipeUpForPreviousSubtitles()
    }

    func removeMeetingSubtitleLayout() {
        subtitleView.updateSubtitleStatus(status: .closed)
        subtitleView.removeFromSuperview()
    }

    func didHideSubtitlePanel() {
        guard !isDraggingPanel else { return }
        floatingContainerView.isHidden = true
        subtitleView.removeInvalidSubtitlesIfNeeded()
    }
}

extension FloatingSubtitleViewController {
    private func releaseTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    func resetTimer() {
        releaseTimer()
        let currentTimer = Timer(timeInterval: 5, repeats: false, block: { [weak self] _ in
            self?.didHideSubtitlePanel()
        })
        RunLoop.main.add(currentTimer, forMode: .common)
        timeoutTimer = currentTimer
    }
}

extension FloatingSubtitleViewController: VCMenuViewDelegate {
    func menuView(_ menu: VCMenuView, shouldRespondTouchAt point: CGPoint) -> VCMenuViewHitTestResult {
        let converted = menu.convert(point, to: floatingContainerView)
        if floatingContainerView.hitTest(converted, with: nil) != nil {
            return .default
        }
        return .ignore
    }
}

// 沉浸态监听
extension FloatingSubtitleViewController: MeetingLayoutStyleListener {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        isFullScreen = container.meetingLayoutStyle == .fullscreen
        updateFloatSubtitleLayoutGuide()
        if !hasMovedPanel {
            resetFloatingContainerPosition()
        }
    }
}
// LayoutStyle监听
extension FloatingSubtitleViewController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .contentScene:
            guard let contentScene = userInfo as? InMeetSceneManager.ContentMode else { return }
            layoutStyle = contentScene
            updateFloatSubtitleLayoutGuide()
            if !hasMovedPanel {
                resetFloatingContainerPosition()
            }
        case .flowPageControl:
            if !hasMovedPanel {
                resetFloatingContainerPosition()
            }
        default:
            break
        }
    }
}
