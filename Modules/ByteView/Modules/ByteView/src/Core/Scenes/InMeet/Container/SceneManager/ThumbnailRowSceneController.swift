//
// Created by liujianlong on 2022/8/20.
//

import Foundation
import RxSwift
import SnapKit
import ByteViewSetting
import ByteViewNetwork
import ByteViewUI

protocol ShareContentGuideProvider {
    var parentContainerGuide: UIView { get }

    // 外部定义，传入 ShareContentVC
    var topBarGuide: UILayoutGuide { get }

    // 外部定义，传入 ShareContentVC
    var bottomBarGuide: UILayoutGuide { get }

    func addMeetLayoutStyleListener(_ listener: MeetingLayoutStyleListener)
}

protocol ShareContentVC {
    func setupExternalLayoutGuide(container: InMeetViewContainer)
}

extension ThumbnailRowSceneController: ShareContentGuideProvider {
    var parentContainerGuide: UIView {
        self.view
    }
    var topBarGuide: UILayoutGuide {
        shrinkGuide
    }
    var bottomBarGuide: UILayoutGuide {
        self.container!.bottomBarGuide
    }

    func addMeetLayoutStyleListener(_ listener: MeetingLayoutStyleListener) {
        self.container?.addMeetLayoutStyleListener(listener)
    }
}

class ThumbnailRowSceneController: BaseSceneController, MeetingLayoutStyleListener {
    private let meeting: InMeetMeeting

    // 包含 flow shrinkView
    private let topView = UIView()

    private let shrinkView: InMeetFlowShrinkView
    private var flowVC: InMeetFlowViewControllerV2!
    private var contentVC: UIViewController?
    private let fullScreenAuxTopGuide = UILayoutGuide()
    private let mainContentGuide = UILayoutGuide()
    private let shrinkGuide = UILayoutGuide()
    private let flowContentGuide = UILayoutGuide()

    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private var shrinkBarGuideToken: MeetingLayoutGuideToken?

    private let disposeBag = DisposeBag()

    override var content: InMeetSceneManager.ContentMode {
        didSet {
            guard oldValue != self.content else {
                return
            }
            updateContent()
            updateBackgroundColor()
            adaptBottomShadow()
        }
    }
    var enableSelfAsActiveSpeaker: Bool = false {
        didSet {
            guard oldValue != self.enableSelfAsActiveSpeaker else {
                return
            }
            updateContent()
        }
    }

    private var meetingLayoutStyle: MeetingLayoutStyle {
        didSet {
            if self.isMounted {
                self.flowVC.meetingLayoutStyle = self.meetingLayoutStyle
            }
            adaptBottomShadow()
            let oldIsOverlayFullScreen = oldValue != .tiled
            let newIsOverlayFullScreen = meetingLayoutStyle != .tiled
            guard oldIsOverlayFullScreen != newIsOverlayFullScreen else {
                return
            }
            if let container = container {
                updateLayoutGuides(container: container)
            }
            if let followContainerVC = self.contentVC as? FollowContainerViewController,
               let container = container {
                followContainerVC.respondToMeetingLayoutStyleChange(container: container)
            }
            updateBackgroundColor()
        }
    }

    private var isMobileLandscapeMode: Bool {
        didSet {
            guard self.isMobileLandscapeMode != oldValue else {
                return
            }
            if isMounted,
               let container = self.container {
                self.updateLayoutGuides(container: container)
            }
            self.shouldAttachFlowVC = !isMobileLandscapeMode && !isFlowShrunken
        }
    }

    private var isFlowShrunken: Bool {
        didSet {
            guard self.isFlowShrunken != oldValue else {
                return
            }
            if let container = self.container {
                if container.sceneManager.isFocusing {
                    container.context.savedFocusIsShrink = isFlowShrunken
                }
                if self.content == .selfShareScreen {
                    container.context.savedSelfShareScreenIsShrink = self.isFlowShrunken
                }
            }
            if isMounted,
               let container = self.container {
                self.updateLayoutGuides(container: container)
            }
            self.updateFlowDisplayMode()
            self.updateBackgroundColor()
            if isFlowShrunken {
                self.adaptBottomShadow()
            } else {
                // 异步一下，否则和ShrinkView的展开动画耦合在一起、视图会有问题
                DispatchQueue.main.async {
                    self.adaptBottomShadow()
                }
            }
        }
    }

    private var shouldAttachFlowVC: Bool {
        didSet {
            guard self.shouldAttachFlowVC != oldValue else {
                return
            }
            if self.shouldAttachFlowVC {
                attachFlowVC()
            } else {
                detachFlowVC()
            }
        }
    }

    // 宫格流无数据时，需要隐藏flow和shrinkView
    private var shouldHideFLowAndShrinkView: Bool = false {
        didSet {
            self.container?.context.isThumbnailFLowHidden = self.shouldHideFLowAndShrinkView
            guard self.shouldHideFLowAndShrinkView != oldValue else {
                return
            }

            if self.shouldHideFLowAndShrinkView {
                self.isShowSpeakerOnMainScreen = false
                self.container?.context.isShowSpeakerOnMainScreen = false
            }

            self.shrinkView.alpha = self.shouldHideFLowAndShrinkView ? 0 : 1
            if self.isMounted, let container = self.container {
                self.updateLayoutGuides(container: container)
            }
        }
    }

    private lazy var isFlowDataEmpty = !flowVC.viewModel.sortedVMsRelay.value.contains { $0.type == .participant }

    private var isShowSpeakerOnMainScreen: Bool = false {
        didSet {
            guard oldValue != self.isShowSpeakerOnMainScreen else {
                return
            }
            updateContent()
            updateBackgroundColor()
            adaptBottomShadow()
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    init(meeting: InMeetMeeting, container: InMeetViewContainer, content: InMeetSceneManager.ContentMode) {
        self.meeting = meeting
        self.meetingLayoutStyle = container.context.meetingLayoutStyle
        self.isShowSpeakerOnMainScreen = container.context.isShowSpeakerOnMainScreen
        self.isMobileLandscapeMode = VCScene.isPhoneLandscape
        self.shrinkView = InMeetFlowShrinkView(service: meeting.service)
        self.isFlowShrunken = shrinkView.isShrunken
        container.context.isFlowShrunken = self.isFlowShrunken
        self.shouldAttachFlowVC = !self.isFlowShrunken && !self.isMobileLandscapeMode
        super.init(container: container, content: content)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.flowVC = container!.flowComponent!.getOrCreateFlowVC()
        self.flowVC.loadViewIfNeeded()

        self.view.addLayoutGuide(mainContentGuide)
        self.view.addLayoutGuide(shrinkGuide)
        self.view.addLayoutGuide(fullScreenAuxTopGuide)
        self.view.addLayoutGuide(flowContentGuide)

        self.view.addSubview(self.topView)

        topView.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        topView.addSubview(self.shrinkView)
        #if DEBUG
            mainContentGuide.identifier = "thumbMainContentGuide"
            shrinkGuide.identifier = "thumbnailRowShrinkGuide"
            fullScreenAuxTopGuide.identifier = "thumbnailRowFullScreenAuxTopGuide"
            flowContentGuide.identifier = "thumbnailRowFlowContentGuide"
        #endif
        self.topView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(flowContentGuide)
            make.bottom.equalTo(shrinkGuide)
        }
        self.setupShrinkView(container: container!)

        self.updateContent()
    }

    override func onMount(container: InMeetViewContainer) {
        super.onMount(container: container)
        if let layoutAware = self.contentVC as? InMeetLayoutContainerAware {
            layoutAware.didAttachToLayoutContainer(container.layoutContainer)
        }
        if let contentVC = self.contentVC as? ShareContentVC {
            contentVC.setupExternalLayoutGuide(container: container)
        } else if let contentVC = self.contentVC as? InMeetASVideoContentVC {
            contentVC.topBarGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.topBarGuide)
            }
            contentVC.bottomBarGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.bottomBarGuide)
            }
        }

        self.shrinkBarGuideToken = container.layoutContainer.registerAnchor(anchor: .topShrinkBar)
        self.shrinkBarGuideToken?.layoutGuide.snp.remakeConstraints { make in
            make.edges.equalTo(shrinkGuide)
        }
        updateLayoutGuides(container: container)
        if self.shouldAttachFlowVC {
            self.attachFlowVC()
        }
        self.flowVC.meetingLayoutStyle = self.meetingLayoutStyle
        updateFlowDisplayMode()
        updateBackgroundColor()
        adaptBottomShadow()
        container.addMeetLayoutStyleListener(self)
        meeting.shareData.addListener(self)
        meeting.participant.addListener(self)
        self.enableSelfAsActiveSpeaker = meeting.setting.enableSelfAsActiveSpeaker
        meeting.setting.addListener(self, for: [.isVoiceModeOn, .enableSelfAsActiveSpeaker])
        container.context.addListener(self, for: [.flowShrunken, .showSpeakerOnMainScreen, .contentScene, .hideSelf])
    }

    override func onUnmount() {
        super.onUnmount()
        if let layoutAware = self.contentVC as? InMeetLayoutContainerAware,
           let layoutContainer = self.container?.layoutContainer {
            layoutAware.didDetachFromLayoutContainer(layoutContainer)
        }
        self.shrinkBarGuideToken?.invalidate()
        self.shrinkBarGuideToken = nil
        self.contentVC?.willMove(toParent: nil)
        self.contentVC?.view.removeFromSuperview()
        self.contentVC?.removeFromParent()

        self.detachFlowVC()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBackgroundColor()
        adaptBottomShadow()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            if Display.phone {
                self.isMobileLandscapeMode = self.view.isPhoneLandscape
            }
            updateBackgroundColor()
        }
    }

    private func removePrevContent() {

        if self.isMounted,
           let layoutAware = self.contentVC as? InMeetLayoutContainerAware,
           let layoutContainer = self.container?.layoutContainer {
            layoutAware.didDetachFromLayoutContainer(layoutContainer)
        }
        self.contentVC?.willMove(toParent: nil)
        self.contentVC?.view.removeFromSuperview()
        self.contentVC?.removeFromParent()
    }

    private func getOrCreateContentVC(content: InMeetSceneManager.ContentMode,
                                      hideSelf: Bool,
                                      enableSelfAsActiveSpeaker: Bool) -> UIViewController {
        guard let container = self.container else {
            return UIViewController()
        }
        if content.isShareContent, !isShowSpeakerOnMainScreen {
            return container.shareComponent?.makeVCWithContent(content) ?? UIViewController()
        } else {
            return container.flowComponent?.makeContentVC(asFlavor: enableSelfAsActiveSpeaker && !hideSelf ? .activeSpeaker : .activeSpeakerExcludeLocal,
                                                          sceneMode: .thumbnailRow) ?? UIViewController()
        }
    }

    private func updateContent() {
        guard let container = container else {
            return
        }
        if self.content == .flow || isShowSpeakerOnMainScreen,
           let contentVC = self.contentVC as? InMeetASVideoContentVC {
            contentVC.viewModel.asFlavor = enableSelfAsActiveSpeaker && !container.context.isHideSelf ? .activeSpeaker : .activeSpeakerExcludeLocal
            return
        }
        removePrevContent()
        let contentVC = getOrCreateContentVC(content: self.content,
                                             hideSelf: container.context.isHideSelf,
                                             enableSelfAsActiveSpeaker: self.enableSelfAsActiveSpeaker)
        self.contentVC = contentVC

        if self.isMounted {
            self.flowVC.sceneContent = isShowSpeakerOnMainScreen ? self.content : .flow
        }

        self.addChild(contentVC)
        self.view.insertSubview(contentVC.view, at: 0)
        contentVC.view.snp.remakeConstraints { make in
            make.edges.equalTo(self.mainContentGuide)
        }

        if self.isMounted {
            if let layoutAware = self.contentVC as? InMeetLayoutContainerAware {
                layoutAware.didAttachToLayoutContainer(container.layoutContainer)
            }

            if let shareContentVC = contentVC as? ShareContentVC,
               let container = self.container {
                shareContentVC.setupExternalLayoutGuide(container: container)
            } else if let contentVC = self.contentVC as? InMeetASVideoContentVC {
                contentVC.topBarGuide.snp.remakeConstraints { make in
                    make.edges.equalTo(self.topBarGuide)
                }
                contentVC.bottomBarGuide.snp.remakeConstraints { make in
                    make.edges.equalTo(self.bottomBarGuide)
                }
            }
        }
        contentVC.didMove(toParent: self)

        if Display.phone, #available(iOS 16.0, *) {
            self.viewModel.router.topMost?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    private func attachFlowVC() {
        guard flowVC.parent !== self else {
            return
        }
        flowVC.goBackShareContentAction = { [weak self] location in
            self?.sceneControllerDelegate?.goBackToShareContent(from: .pinActiveSpeaker, location: location)
        }
        // 避免裁剪 ActiveSpeaker 绿框
        flowVC.collectionView.clipsToBounds = false
        // 宫格中避免出现共享内容
        flowVC.sceneContent = isShowSpeakerOnMainScreen ? self.content : .flow
        self.addChild(flowVC)
        topView.addSubview(flowVC.view)
        flowVC.didMove(toParent: self)
        flowVC.view.snp.remakeConstraints { make in
            make.edges.equalTo(flowContentGuide)
        }
    }

    private func detachFlowVC() {
        guard flowVC.parent === self else {
            return
        }
        flowVC.collectionView.clipsToBounds = true
        self.flowVC.willMove(toParent: nil)
        self.flowVC.view.removeFromSuperview()
        self.flowVC.removeFromParent()
    }

    private func updateFlowDisplayMode() {
        guard self.isMounted else {
            return
        }
        self.flowVC.displayMode = self.isFlowShrunken ? .singleAudio : .singleRowVideo
    }

    private func updateLayoutGuides(container: InMeetViewContainer) {
        Logger.scene.info("update thumbnailRow isLandscapeMode \(isMobileLandscapeMode) isShrunken: \(self.isFlowShrunken), meetingLayoutStyle: \(meetingLayoutStyle)")
        let isOverlayFullScreen = meetingLayoutStyle != .tiled
        flowContentGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.greaterThanOrEqualTo(containerTopBarExtendGuide.snp.bottom)
            make.top.equalTo(containerTopBarExtendGuide.snp.bottom).priority(.veryHigh)
            make.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).priority(.veryHigh)
            let height: CGFloat
            if self.isMobileLandscapeMode || shouldHideFLowAndShrinkView {
                height = 0
            } else if isFlowShrunken {
                height = 0
            } else if Display.pad {
                height = 94
            } else {
                height = 94
            }
            make.height.equalTo(height)
        }
        let shrinkViewHeight: CGFloat
        // disable-lint: magic number
        if shouldHideFLowAndShrinkView {
            shrinkViewHeight = 0
        } else if self.isMobileLandscapeMode {
            shrinkViewHeight = 15
        } else if Display.pad && isFlowShrunken {
            shrinkViewHeight = 26
        } else {
            shrinkViewHeight = 24
        }
        // enable-lint: magic number
        shrinkGuide.snp.remakeConstraints { make in
            make.top.equalTo(flowContentGuide.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(shrinkViewHeight)
        }

        fullScreenAuxTopGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(flowContentGuide).offset(shrinkViewHeight)
        }
        mainContentGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            if isOverlayFullScreen {
                if self.isMobileLandscapeMode {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(self.fullScreenAuxTopGuide.snp.bottom)
                }
                make.bottom.equalToSuperview()
            } else {
                if self.isMobileLandscapeMode {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(shrinkGuide.snp.bottom)
                }
                make.bottom.lessThanOrEqualTo(containerBottomBarGuide.snp.top)
                make.bottom.equalTo(containerBottomBarGuide.snp.top).priority(.veryHigh)
                make.bottom.lessThanOrEqualToSuperview()
                make.bottom.equalToSuperview().priority(.veryHigh)
            }
        }
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
    }

    override var childVCForOrientation: InMeetOrderedViewController? {
        if let vc = self.contentVC {
            return InMeetOrderedViewController(orientation: .share, vc)
        }
        return nil
    }

    override var childVCForStatusBarStyle: InMeetOrderedViewController? {
        if let vc = self.contentVC {
            return InMeetOrderedViewController(orientation: .share, vc)
        }
        return nil
    }

    private func updateFlowAndShrinkViewVisibility() {
        // 缩略图视图顶部横排宫格流，隐藏自己等导致的宫格数据为空的情况，需要隐藏该横排，
        // 但是隐藏非视频参会者需求导致的宫格数据为空时，共享场景下依然显示横排，此时宫格中兜底显示一个 AS（sorter 中处理）
        let isHideNonVideo = flowVC.viewModel.isHideNonVideoParticipants.value
        shouldHideFLowAndShrinkView = isFlowDataEmpty && (!isHideNonVideo || !content.isShareContent)
    }

    private func updateBackgroundColor() {
        let isOverlayFullScreen = meetingLayoutStyle.isOverlayFullScreen
        // nolint-next-line: magic number
        backgroundView.alpha = isOverlayFullScreen ? 0.92 : 1.0
        if self.isMobileLandscapeMode {
            backgroundView.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff
        } else {
            if self.isFlowShrunken {
                if Display.phone || (self.content == .follow && !isShowSpeakerOnMainScreen) {
                    backgroundView.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff
                } else {
                    backgroundView.backgroundColor = UIColor.ud.bgBody
                }
            } else {
                backgroundView.backgroundColor = UIColor.ud.bgBody
            }
        }
    }

    private func adaptBottomShadow() {
        var shouldShowShadow = false
        if meetingLayoutStyle == .overlay {
            // 如果有shareBar，则在shareBar下方添加阴影
            if Display.phone {
                shouldShowShadow = true
            } else {
                shouldShowShadow = container?.context.hasShareBar == false || isShowSpeakerOnMainScreen
            }
        } else if (content == .follow && !isShowSpeakerOnMainScreen) && !self.isFlowShrunken && !isMobileLandscapeMode {
            shouldShowShadow = true
        }

        if shouldShowShadow {
            topView.vc.addOverlayShadow(isTop: true)
        } else {
            topView.vc.removeOverlayShadow()
        }
    }
}

extension ThumbnailRowSceneController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        guard let container = self.container else {
            return
        }
        if change == .flowShrunken {
            if container.context.isFlowShrunken != self.shrinkView.isShrunken {
                self.shrinkView.updateShrunken(container.context.isFlowShrunken)
            }
        }

        if change == .showSpeakerOnMainScreen {
            self.isShowSpeakerOnMainScreen = container.context.isShowSpeakerOnMainScreen
        }

        if change == .contentScene {
            self.adaptBottomShadow()
        }

        if change == .hideSelf {
            self.updateContent()
            self.updateFlowAndShrinkViewVisibility()
        }
    }
}

extension ThumbnailRowSceneController: InMeetFlowShrinkViewDelegate {

    /// - [x] 焦点视频、语音模式自动收起
    /// - [x] shrinkView SpeakerUserName, FocusingUserName
    /// - [x] swipe gesture
    /// - [x] layout constraints
    /// - [x] shrinkDelegate
    func setupShrinkView(container: InMeetViewContainer) {
        self.shrinkView.delegate = self
        self.shrinkView.snp.makeConstraints { make in
            make.edges.equalTo(shrinkGuide)
        }
        let swipe = UISwipeGestureRecognizer()
        topView.addGestureRecognizer(swipe)
        shrinkView.swipeGestureRecognizer = swipe

        flowVC.viewModel.shrinkViewSpeakingUser
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [shrinkView = self.shrinkView] name, showFocusPrefix in
                guard let name = name else {
                    shrinkView.setSpeakerUserName(nil)
                    return
                }
                if showFocusPrefix {
                    shrinkView.setFocusingUserName(name)
                } else {
                    shrinkView.setSpeakerUserName(name)
                }
            })
            .disposed(by: self.disposeBag)

        // 是否显示
        Observable.combineLatest(flowVC.viewModel.sortedVMsRelay.asObservable(),
                                 flowVC.viewModel.isHideNonVideoParticipants.asObservable())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] pair in
                self?.isFlowDataEmpty = !pair.0.contains { $0.type == .participant }
                self?.updateFlowAndShrinkViewVisibility()
            })
            .disposed(by: self.disposeBag)
    }

    func shrinkViewDidChangeShrink(_ shrinkView: InMeetFlowShrinkView, alongsideAnimation: @escaping () -> Void,
                                   completion: @escaping (Bool) -> Void) {
        guard let container = self.container else {
            return
        }
        if Display.pad {
            InMeetSceneTracks.trackToggleVideoBar(videoBarFold: shrinkView.isShrunken,
                                                  scene: container.sceneMode,
                                                  isSharing: container.contentMode.isShareContent,
                                                  isSharer: meeting.shareData.isSelfSharingContent)
        }
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            alongsideAnimation()
            self.isFlowShrunken = shrinkView.isShrunken
            container.context.isFlowShrunken = shrinkView.isShrunken
            container.view.layoutIfNeeded()
        }, completion: { b in
            self.shouldAttachFlowVC = !self.isFlowShrunken && !self.isMobileLandscapeMode
            completion(b)
        })
    }
}

extension ThumbnailRowSceneController: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingSettingKey, isOn: Bool) {
        if key == .isVoiceModeOn, isOn {
            Util.runInMainThread {
                // 开启语音模式，需要收起
                self.shrinkView.updateShrunken(true)
            }
        }
        if key == .enableSelfAsActiveSpeaker {
            Util.runInMainThread {
                self.enableSelfAsActiveSpeaker = isOn
            }
        }
    }
}

extension ThumbnailRowSceneController: InMeetShareDataListener {
    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if newScene.isSelfSharingScreen {
                self.shrinkView.updateShrunken(self.container?.context.savedSelfShareScreenIsShrink ?? true)
            } else {
                self.container?.context.savedSelfShareScreenIsShrink = nil
            }
        }
    }
}

extension ThumbnailRowSceneController: InMeetParticipantListener {
    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?) {
        // 共享时进入焦点视频，需要收起
        Util.runInMainThread {
            if oldValue == nil && participant != nil {
                if let savedShrunken = self.container?.context.savedFocusIsShrink {
                    self.shrinkView.updateShrunken(savedShrunken)
                } else {
                    self.shrinkView.updateShrunken(true)
                }
            } else if participant == nil {
               self.container?.context.savedFocusIsShrink = nil
            }
        }
    }
}

extension ThumbnailRowSceneController: FloatingWindowTransitioning {
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        if let msVC = self.contentVC as? FollowContainerViewController {
            msVC.floatingWindowWillTransition(to: frame, isFloating: isFloating)
        }
    }

    func floatingWindowWillChange(to isFloating: Bool) {
        if let msVC = self.contentVC as? FollowContainerViewController {
            msVC.floatingWindowWillChange(to: isFloating)
        }
    }

    func floatingWindowDidChange(to isFloating: Bool) {
        if let msVC = self.contentVC as? FollowContainerViewController {
            msVC.floatingWindowDidChange(to: isFloating)
        }
    }
}
