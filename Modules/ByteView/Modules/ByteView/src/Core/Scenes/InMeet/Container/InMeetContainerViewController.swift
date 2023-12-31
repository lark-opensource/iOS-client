//
//  InMeetContainerViewController.swift
//  ByteView
//
//  Created by kiri on 2021/4/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUDColor
import ByteViewCommon
import UIKit
import ByteViewNetwork
import LarkKeyCommandKit
import ByteViewSetting
import UniverseDesignIcon
import ByteViewUI

/// 会中视图容器的实现
class InMeetContainerViewController: BaseViewController, InMeetViewContainer, MeetingSceneModeListener {
    let viewModel: InMeetViewModel
    let viewScope: InMeetViewScope
    private var containers: [ContainerView] = []
    private var customLayoutGuides: [InMeetLayoutGuideKey: UILayoutGuide] = [:]
    private var components: [InMeetViewComponent] = []
    private var isComponentLoaded = false

    lazy var sceneManager = InMeetSceneManager(meeting: viewModel.meeting, sceneControllerState: viewModel.viewContext.sceneControllerState, gridVM: viewModel.resolver.resolve()!)
    private var blockFullScreenToken: BlockFullScreenToken?
    /// 距离传感亮屏后，显示状态栏
    private var proximityBlockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard oldValue !== proximityBlockFullScreenToken else { return }
            oldValue?.invalidate()
        }
    }

    var meetingLayoutStyle: MeetingLayoutStyle {
        get {
            viewModel.viewContext.meetingLayoutStyle
        }

        set {
            viewModel.viewContext.meetingLayoutStyle = newValue
        }
    }
    var layoutStyleListeners: [WeakRef<AnyObject>] = []
    var sceneModeListeners: [WeakRef<AnyObject>] = []
    private var layoutGuideHelper: InMeetLayoutGuideHelper
    lazy var fullScreenDetector = InMeetFullScreenDetector(container: self)

    lazy private(set) var layoutContainer: InMeetLayoutContainer = MeetingLayoutContainer(containerView: self.view)
    private lazy var topNavigationBarGuideToken = self.layoutContainer.registerAnchor(anchor: .topNavigationBar)
    private lazy var bottomToolbarGuideToken = self.layoutContainer.registerAnchor(anchor: .bottomToolbar)
    private lazy var contentGuideToken: MeetingLayoutGuideToken = {
        return layoutContainer.requestLayoutGuideFactory { ctx in
            let query: InMeetLayoutGuideQuery
            if Display.pad || !ctx.isLandscapeOrientation {
                query = InMeetOrderedLayoutGuideQuery(topAnchor: .topShareBar,
                                                      bottomAnchor: .bottomSketchBar)
            } else {
                query = InMeetOrderedLayoutGuideQuery(topAnchor: .topShareBar,
                                                      bottomAnchor: .bottomSketchBar,
                                                      specificInsets: [.bottomSafeArea: -4.0])
            }
            return query
        }
    }()

    private lazy var accessoryGuideToken = makeAccessoryLayoutGuide()

    init(viewModel: InMeetViewModel, scope: InMeetViewScope = .fullScreen) {
        self.viewModel = viewModel
        self.viewScope = scope
        let storage = viewModel.meeting.storage
        let autoHideToolStatusBar = viewModel.meeting.setting.autoHideToolStatusBar
        self.layoutGuideHelper = autoHideToolStatusBar ? FullscreenLayoutGuideHelper(storage: storage) : TiledLayoutGuideHelper(storage: storage)
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        #if DEBUG
        self.layoutCheckTimer?.invalidate()
        #endif

        self.blockFullScreenToken?.invalidate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if DEBUG
    private var layoutCheckTimer: Timer?
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        (self.layoutContainer as? MeetingLayoutContainer)?.setupEvents(container: self)

        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true
        self.context.hostViewController = self
        self.context.fullScreenDetector = self.fullScreenDetector
        self.context.sceneManager = self.sceneManager
        self.meetingLayoutStyle = self.fullScreenDetector.autoHideToolStatusBar ? .overlay : .tiled

        InMeetRegistry.shared.loadComponents(self, viewModel: viewModel, layoutContext: self.currentLayoutContext, successHandler: { c in components.append(c) })
        isComponentLoaded = true
        components.forEach { $0.containerDidLoadComponent(container: self) }
        components.forEach { $0.setupConstraints(container: self) }

        self.layoutGuideHelper.updateLayoutGuides(container: self)
        viewModel.viewContext.addListener(self, for: [.topBarHidden, .bottomBarHidden, .singleVideo, .contentScene, .flowShrunken, .subtitle, .sketchMenu, .fullScreenMicHidden, .whiteboardMenu])

        Logger.ui.info("initial meetingLayoutStyle: \(self.meetingLayoutStyle), isLandscape: \(self.view.isLandscape), currentLayoutContext: \(self.currentLayoutContext)")
        self.components.forEach { comp in
            comp.containerDidChangeLayoutStyle(container: self, prevStyle: nil)
        }

        self.sceneManager.setupData(meeting: viewModel.meeting)
        self.sceneManager.setup(container: self)
        context.horizontalSizeClassIsRegular = self.traitCollection.horizontalSizeClass == .regular

        self.setupProximityMonitor()

        #if DEBUG
        self.layoutCheckTimer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
           self?.checkLayoutGuides()
        }
        RunLoop.current.add(self.layoutCheckTimer!, forMode: .common)
        #endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.viewContext.post(.containerDidLayout, userInfo: nil)
    }

    // 用户手动切换 Scene 入口
    var sceneMode: InMeetSceneManager.SceneMode {
        sceneManager.sceneMode
    }

    var contentMode: InMeetSceneManager.ContentMode {
        self.sceneManager.contentMode
    }

    func makeSceneController(content: InMeetSceneManager.ContentMode, scene: InMeetSceneManager.SceneMode) -> InMeetSceneController? {
        let resolver = viewModel.resolver
        switch scene {
        case .gallery:
            return GallerySceneController(container: self, content: content)
        case .thumbnailRow:
            return ThumbnailRowSceneController(meeting: self.viewModel.meeting, container: self, content: content)
        case .speech:
            return SpeechSceneController(container: self, content: content)
        case .webinarStage:
            assert(sceneManager.webinarStageInfo != nil)
            if let stageInfo = sceneManager.webinarStageInfo,
               let gridViewModel = resolver.resolve(InMeetGridViewModel.self),
               let activeSpeaker = resolver.resolve(InMeetActiveSpeakerViewModel.self) {
                return WebinarStageSceneController(container: self,
                                                   content: content,
                                                   meeting: viewModel.meeting,
                                                   stageInfo: stageInfo,
                                                   gridViewModel: gridViewModel,
                                                   activeSpeaker: activeSpeaker)
            } else {
                return nil
            }
        }
    }

    func switchMeetLayoutStyle(_ style: MeetingLayoutStyle, animated: Bool) {
        guard self.meetingLayoutStyle != style else {
            return
        }
        Logger.ui.info("meetingLayoutStyle changed: \(self.meetingLayoutStyle) --> \(style)")

        let oldStyle = self.meetingLayoutStyle
        self.meetingLayoutStyle = style

        showFullScreenGuideIfNeeded()

        switch style {
        case .tiled:
            self.layoutGuideHelper = TiledLayoutGuideHelper(storage: viewModel.meeting.storage)
        case .fullscreen, .overlay:
            self.layoutGuideHelper = FullscreenLayoutGuideHelper(storage: viewModel.meeting.storage)
            if context.shouldStartFirstOverlayTimeOut, style == .fullscreen {
                context.shouldStartFirstOverlayTimeOut = false
            }
        }
        let action = {
            self.layoutGuideHelper.updateLayoutGuides(container: self)
            self.components.forEach { comp in
                comp.containerDidChangeLayoutStyle(container: self, prevStyle: oldStyle)
            }
            self.layoutStyleListeners.forEach({ ($0.ref as? MeetingLayoutStyleListener)?.containerDidChangeLayoutStyle(container: self, prevStyle: oldStyle) })
            self.viewModel.viewContext.post(.containerLayoutStyle, userInfo: self.meetingLayoutStyle)
        }
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25) {
                action()
                self.view.layoutIfNeeded()
            }
        } else {
            action()
        }
    }

    var fullScreenGuideView: FullScreenGuideView?

    private func showFullScreenGuideIfNeeded() {
        if fullScreenGuideView != nil {
            fullScreenGuideView?.removeFromSuperview()
            fullScreenGuideView = nil
        }

        let autoHideToolStatusBar = viewModel.meeting.setting.autoHideToolStatusBar
        if autoHideToolStatusBar {
            if self.meetingLayoutStyle == .fullscreen,
               viewModel.service.shouldShowGuide(.toolbarAutoHide) {
                Toast.show(I18n.View_G_ClickAnyToolbar)
                viewModel.service.didShowGuide(.toolbarAutoHide)
            }
        } else if currentLayoutContext.layoutType.isPhoneLandscape {
            guard fullScreenGuideView == nil,
                  self.meetingLayoutStyle == .overlay,
                  viewModel.service.shouldShowGuide(.toolbarAccessHide) else {
                return
            }
            let guildView = FullScreenGuideView(frame: view.bounds)
            self.view.addSubview(guildView)
            guildView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            viewModel.service.didShowGuide(.toolbarAccessHide)

            self.fullScreenGuideView = guildView
        }
    }

    func addMeetLayoutStyleListener(_ listener: MeetingLayoutStyleListener) {
        listener.containerDidChangeLayoutStyle(container: self, prevStyle: nil)
        layoutStyleListeners.append(WeakRef(listener))
        layoutStyleListeners.removeAll(where: { $0.ref == nil })
    }

    func addMeetSceneModeListener(_ listener: MeetingSceneModeListener) {
        listener.containerDidChangeFocusing(container: self, isFocusing: self.sceneManager.isFocusing)
        listener.containerDidChangeSceneMode(container: self, sceneMode: sceneManager.sceneMode)
        listener.containerDidChangeWebinarStageInfo(container: self, webinarStageInfo: sceneManager.webinarStageInfo)
        listener.containerDidChangeContentMode(container: self, contentMode: sceneManager.contentMode)
        sceneModeListeners.append(WeakRef(listener))
        sceneModeListeners.removeAll(where: { $0.ref == nil })
    }

    func containerDidChangeSceneMode(container: InMeetViewContainer,
                                     sceneMode: InMeetSceneManager.SceneMode) {
        self.sceneModeListeners.forEach({ ($0.ref as? MeetingSceneModeListener)?.containerDidChangeSceneMode(container: self,
                                                                                                             sceneMode: sceneMode) })
    }

    func containerDidChangeFocusing(container: InMeetViewContainer, isFocusing: Bool) {
        self.sceneModeListeners.forEach {
            ($0.ref as? MeetingSceneModeListener)?.containerDidChangeFocusing(container: self, isFocusing: isFocusing)
        }
    }

    func containerDidChangeWebinarStageInfo(container: InMeetViewContainer, webinarStageInfo: WebinarStageInfo?) {
        self.sceneModeListeners.forEach {
            ($0.ref as? MeetingSceneModeListener)?.containerDidChangeWebinarStageInfo(container: self, webinarStageInfo: webinarStageInfo)
        }
    }

    func containerDidChangeContentMode(container: InMeetViewContainer, contentMode: InMeetSceneManager.ContentMode) {
        self.sceneModeListeners.forEach({ ($0.ref as? MeetingSceneModeListener)?.containerDidChangeContentMode(container: self, contentMode: contentMode) })
    }


    @objc
    func panAction(gesture: UISwipeGestureRecognizer) {
        let point = gesture.location(in: self.view)

        if gesture.state == .ended, point.x < 30 {
            viewModel.router.setWindowFloating(true)
        }
    }

    func loadContentViewIfNeeded(for level: InMeetContentLevel) -> UIView {
        return createContainerIfNeeded(for: level)
    }

    var context: InMeetViewContext {
        viewModel.viewContext
    }

    func addContent(_ viewController: UIViewController, level: InMeetContentLevel) -> UIView {
        addChild(viewController)
        let container = createContainerIfNeeded(for: level)
        container.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        return container
    }

    func addContent(_ view: UIView, level: InMeetContentLevel) -> UIView {
        let container = createContainerIfNeeded(for: level)
        container.addSubview(view)
        return container
    }

    func removeContent(_ view: UIView, level: InMeetContentLevel) {
        _ = removeContainer(level: level)
    }

    func removeContent(_ vc: UIViewController, level: InMeetContentLevel) {
        vc.willMove(toParent: nil)
        _ = removeContainer(level: level)
        vc.removeFromParent()
    }

    func addLayoutGuideIfNeeded(for key: InMeetLayoutGuideKey) -> UILayoutGuide {
        switch key {
        case .content:
            return self.contentGuideToken.layoutGuide
        case .topBar:
            return self.topNavigationBarGuideToken.layoutGuide
        case .bottomBar:
            return self.bottomToolbarGuideToken.layoutGuide
        case .accessory:
            return self.accessoryGuideToken.layoutGuide
        default:
            break
        }
        if let guide = customLayoutGuides[key] {
            return guide
        } else {
            let guide = UILayoutGuide()
            guide.identifier = "\(key)"
            view.addLayoutGuide(guide)
            customLayoutGuides[key] = guide
            return guide
        }
    }

    func component(by id: InMeetViewComponentIdentifier) -> InMeetViewComponent? {
        assert(isComponentLoaded, "Component is NOT loaded completely, shouldnot use component(by:)")
        return components.first(where: { $0.componentIdentifier == id })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showFullScreenGuideIfNeeded()
        components.forEach { $0.containerWillAppear(container: self) }
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        super.viewDidFirstAppear(animated)
        self.context.post(.containerDidFirstAppear)
        components.forEach { $0.containerDidFirstAppear(container: self) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        components.forEach { $0.containerDidAppear(container: self) }
        MeetingTracksV2.trackDisplayOnTheCallPage(false, isSharing: viewModel.viewContext.meetingContent.isShareContent,
                                                  meeting: viewModel.meeting)
        self.blockFullScreenToken?.invalidate()
        // 会中window背景需为黑色，以满足pagesheet设计要求
        viewModel.router.window?.backgroundColor = .ud.staticBlack
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        components.forEach { $0.containerWillDisappear(container: self) }
        // 离开会中页面时，window背景色恢复为clear
        viewModel.router.window?.backgroundColor = .clear
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        components.forEach { $0.containerDidDisappear(container: self) }
        self.blockFullScreenToken = self.fullScreenDetector.requestBlockAutoFullScreen(leaveFullScreen: false)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        Logger.ui.info("containerVC viewLayoutContextIsChanging to \(view.isLandscape) \(newContext.layoutChangeReason) \(newContext.layoutType) \(newContext.viewSize)")
        layoutGuideHelper.updateLayoutGuides(container: self)
        components.forEach { $0.viewLayoutContextIsChanging(from: oldContext, to: newContext) }
        if !oldContext.viewSize.equalSizeTo(newContext.viewSize) {
            self.fullScreenDetector.postInterruptEvent()
        }
        context.horizontalSizeClassIsRegular = self.traitCollection.isRegular
    }

    override func viewLayoutContextDidChanged() {
        ProximityMonitor.updateOrientation(isPortrait: !view.isLandscape)
        components.forEach { $0.viewLayoutContextDidChanged() }
    }

    override func viewLayoutContextWillChange(to layoutContext: VCLayoutContext) {
        components.forEach { $0.viewLayoutContextWillChange(to: layoutContext) }
    }

    override var childForStatusBarHidden: UIViewController? {
        components.compactMap { $0.childViewControllerForStatusBarHidden }.max()?.viewController
    }

    override var childForStatusBarStyle: UIViewController? {
        var childVCs = components.compactMap { $0.childViewControllerForStatusBarStyle }
        if let vc = sceneManager.childViewControllerForStatusBarStyle {
            childVCs.append(vc)
        }
        return childVCs.max()?.viewController
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        var childVCs = components.compactMap { $0.childViewControllerForOrientation }
        if let vc = sceneManager.childViewControllerForOrientation {
            childVCs.append(vc)
        }
        if let vc = childVCs.max()?.viewController {
            return vc.supportedInterfaceOrientations
        }
        return .portrait
    }

    private func removeContainer(level: InMeetContentLevel) -> ContainerView? {
        guard let index = containers.firstIndex(where: { v in v.level == level }) else {
            return nil
        }
        let view = containers.remove(at: index)
        view.removeFromSuperview()
        return view
    }

    private func createContainerIfNeeded(for level: InMeetContentLevel) -> ContainerView {
        if let v = containers.first(where: { $0.level == level }) {
            return v
        } else {
            let v = ContainerView(level: level)
            #if DEBUG
            v.accessibilityLabel = "\(level)"
            v.accessibilityIdentifier = "\(level)"
            #endif
            containers.append(v)
            containers.sort()
            if let below = containers.first(where: { $0.level < level }) {
                view.insertSubview(v, aboveSubview: below)
            } else {
                view.insertSubview(v, at: 0)
            }
            v.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }
    }

    private class ContainerView: IrregularHittableView, Comparable {
        let level: InMeetContentLevel
        init(level: InMeetContentLevel) {
            self.level = level
            super.init(frame: .zero)
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        static func < (lhs: ContainerView, rhs: ContainerView) -> Bool {
            lhs.level > rhs.level
        }
    }

    // MARK: - KeyCommand
    override func keyBindings() -> [KeyBindingWraper] {
        let muteMicOrCamKeyBindings = [
            KeyCommandBaseInfo(
                input: "D",
                modifierFlags: [.command, .shift],
                discoverabilityTitle: I18n.View_G_MuteOrUnmuteCut_Text
            ).binding(
                target: self,
                selector: #selector(switchAudioMuteStatus)
            ).wraper,
            KeyCommandBaseInfo(
                input: "V",
                modifierFlags: [.command, .shift],
                discoverabilityTitle: I18n.View_G_StartOrStopCamCut_Text
            ).binding(
                target: self,
                selector: #selector(switchVideoMuteStatus)
            ).wraper
        ]
        return super.keyBindings() + muteMicOrCamKeyBindings
    }

    @objc private func switchAudioMuteStatus() {
        // 非iPad或非纯音频模式不触发开关麦克风快捷键
        guard Display.pad, viewModel.meeting.myself.settings.audioMode == .internet, !viewModel.meeting.setting.isMicSpeakerDisabled, !viewModel.meeting.setting.isWebinarAttendee else { return }
        let isMicMuted = viewModel.meeting.microphone.isMuted
        Logger.ui.info("switch audio mute status to by keyboard shortcut, new isMicMuted = \(!isMicMuted), location: .onTheCall")
        viewModel.meeting.microphone.muteMyself(!isMicMuted, source: .keyboardShortcut, completion: nil)
        KeyboardTrack.trackClickShortcut(with: .muteMicrophone, to: isMicMuted, from: .onTheCall)
    }

    @objc private func switchVideoMuteStatus() {
        guard Display.pad else { return }
        let isCamMuted = viewModel.meeting.camera.isMuted
        Logger.ui.info("switch video mute status to by keyboard shortcut, new isCamMuted = \(!isCamMuted), location: .onTheCall")
        viewModel.meeting.camera.muteMyself(!isCamMuted, source: .keyboardShortcut, completion: nil)
        KeyboardTrack.trackClickShortcut(with: .muteMicrophone, to: isCamMuted, from: .onTheCall)
    }

    @objc private func proximityStateDidChangeNotification() {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            let proximityState = UIDevice.current.proximityState
            Logger.ui.info("proximityState \(proximityState)")
            if proximityState {
                self.proximityBlockFullScreenToken = self.fullScreenDetector.requestBlockAutoFullScreen()
            } else {
                self.proximityBlockFullScreenToken?.invalidate()
            }
        }
    }

}

extension InMeetContainerViewController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        self.layoutGuideHelper.handleViewChange(change, userInfo: userInfo, container: self)
    }
}

extension InMeetContainerViewController {
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        components.forEach { $0.floatingWindowWillTransition(to: frame, isFloating: isFloating) }
        if let sceneController = sceneManager.sceneController as? FloatingWindowTransitioning {
           sceneController.floatingWindowWillTransition(to: frame, isFloating: isFloating)
        }
    }

    func floatingWindowWillChange(to isFloating: Bool) {
        components.forEach { $0.floatingWindowWillChange(to: isFloating) }
        if let sceneController = sceneManager.sceneController as? FloatingWindowTransitioning {
            sceneController.floatingWindowWillChange(to: isFloating)
        }
    }

    func floatingWindowDidChange(to isFloating: Bool) {
        components.forEach { $0.floatingWindowDidChange(to: isFloating) }
        if let sceneController = sceneManager.sceneController as? FloatingWindowTransitioning {
            sceneController.floatingWindowDidChange(to: isFloating)
        }
    }
}

extension UILayoutGuide {
    /// LayoutGuide 能用在某个视图的先决条件是两者处于同一视图层级中
    func canUse(on view: UIView?) -> Bool {
        guard let owningView = owningView else { return false }
        var ancestor: UIView? = owningView
        while ancestor?.superview != nil {
            ancestor = ancestor?.superview
        }
        var viewAncestor = view
        while viewAncestor?.superview != nil {
            viewAncestor = viewAncestor?.superview
        }
        return ancestor == viewAncestor
    }
}


extension InMeetContainerViewController {
    private func makeAccessoryLayoutGuide() -> MeetingLayoutGuideToken {
        self.layoutContainer.requestLayoutGuide { anchor, ctx in
            let query: InMeetLayoutGuideQuery
            if Display.phone && ctx.isLandscapeOrientation {
                if anchor == .invisibleBottomShareBar {
                    return .above(0)
                }
                query = InMeetOrderedLayoutGuideQuery(topAnchor: ctx.isSingleVideoVisible ? .top : .topExtendBar,
                                                      bottomAnchor: .bottomSketchBar,
                                                      specificInsets: [.bottom: 8.0])
            } else if ctx.isSingleVideoVisible {
                query = InMeetOrderedLayoutGuideQuery(topAnchor: .topShareBar,
                                                      bottomAnchor: .bottom)
            } else {
                query = InMeetOrderedLayoutGuideQuery(topAnchor: .topShareBar,
                                                      bottomAnchor: .bottomSketchBar,
                                                      specificInsets: [.bottomSafeArea: ctx.isLandscapeOrientation ? -4.0 : 0.0])
            }
            return query.verticalRelationWithAnchor(anchor, context: ctx)
        } horizontal: { anchor, ctx in
            var leftAnchor: InMeetLayoutAnchor = .leftSafeArea
            var rightAnchor: InMeetLayoutAnchor = .rightSafeArea
            var leftInset: CGFloat = 0.0
            var rightInset: CGFloat = 0.0
            if Display.phone && ctx.isLandscapeOrientation {
                if Display.iPhoneXSeries {
                    let isTopOnLeft = ctx.interfaceOrientation == .landscapeRight
                    if isTopOnLeft {
                        rightAnchor = .right
                        rightInset = ctx.contentMode == .follow ? 14.0 : 24.0
                    } else {
                        leftAnchor = .left
                        leftInset = 24.0
                        rightInset = ctx.contentMode == .follow ? 14.0 : 0.0
                    }
                } else {
                    leftInset = 16.0
                    rightInset = 16.0
                }
            }
            let query = InMeetOrderedLayoutGuideQuery(leftAnchor: leftAnchor,
                                                      rightAnchor: rightAnchor,
                                                      specificInsets: [leftAnchor: leftInset, rightAnchor: rightInset])
            return query.horizontalRelationWithAnchor(anchor, context: ctx)
        }
    }
}

extension InMeetContainerViewController {
    private func setupProximityMonitor() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(proximityStateDidChangeNotification),
                                               name: UIDevice.proximityStateDidChangeNotification,
                                               object: nil)
    }


}
