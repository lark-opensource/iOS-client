//
// Created by liujianlong on 2022/8/20.
//

import Foundation
import RxSwift
import UIKit
import SnapKit
import ByteViewSetting
import ByteViewUI

extension SpeechSceneController: ShareContentGuideProvider {
    var parentContainerGuide: UIView {
        self.view
    }
    func addMeetLayoutStyleListener(_ listener: MeetingLayoutStyleListener) {
        self.container?.addMeetLayoutStyleListener(listener)
    }
}

class SpeechSceneController: BaseSceneController, MeetingLayoutStyleListener, MeetingSceneModeListener, InMeetViewChangeListener {
    var contentVC: UIViewController?
    var floatingVC: InMeetSpeechFloatingViewController!
    let fullScreenAuxTopGuide = UILayoutGuide()

    let topBarGuide = UILayoutGuide()
    let bottomBarGuide = UILayoutGuide()

    // 基于 topBar/bottomBar
    let floatingContentGuid = UILayoutGuide()
    let mainContentGuide = UILayoutGuide()
    private let disposeBag = DisposeBag()

    override var content: InMeetSceneManager.ContentMode {
        didSet {
            guard self.content != oldValue else {
                return
            }
            if isSwitch, !content.enableSpeechSwitch {
                self.isSwitch = false
                return
            }
            if isSwitch, content.isShareContent != oldValue.isShareContent {
                self.isSwitch = false
                return
            }
            if let container = self.container {
                if content.isShareContent, container.context.isShowSpeakerOnMainScreen {
                    self.isSwitch = true
                } else if container.context.isSpeechFlowSwitched {
                    self.isSwitch = true
                }
            }

            updateSpeechContents()
        }
    }

    private var mainContent: SpeechFloatingContent? {
        didSet {
            guard self.mainContent != oldValue,
                  let mainContent = mainContent else {
                return
            }
            Logger.scene.info("SpeechMainContent: \(oldValue) -> \(mainContent)")
            if mainContent.isParticipant && (oldValue?.isParticipant ?? false),
               let contentVC = self.contentVC as? InMeetASVideoContentVC {
                let flavor: InMeetASVideoContentVM.ASGridVMFlavor
                switch mainContent {
                case .activeSpeaker:
                    flavor = .activeSpeaker
                case .activeSpeakerWithoutLocal:
                    flavor = .activeSpeakerExcludeLocal
                case .local:
                    flavor = .local
                default:
                    assertionFailure()
                    flavor = .activeSpeaker
                }
                contentVC.viewModel.asFlavor = flavor
                return
            }
            removePrevContent()
            switch mainContent {
            case .local:
                self.contentVC = container?.flowComponent?.makeContentVC(asFlavor: .local, sceneMode: .speech) ?? UIViewController()
            case .activeSpeakerWithoutLocal:
                self.contentVC = container?.flowComponent?.makeContentVC(asFlavor: .activeSpeakerExcludeLocal, sceneMode: .speech) ?? UIViewController()
            case .activeSpeaker:
                self.contentVC = container?.flowComponent?.makeContentVC(asFlavor: .activeSpeaker, sceneMode: .speech) ?? UIViewController()
            case .shareScreen, .follow, .whiteBoard, .selfShareScreen, .webSpace:
                self.contentVC =  container?.shareComponent?.makeVCWithContent(content) ?? UIViewController()
            }
            let contentVC = self.contentVC ?? UIViewController()

            self.addChild(contentVC)
            self.view.insertSubview(contentVC.view, at: 0)
            contentVC.view.snp.makeConstraints { make in
                make.edges.equalTo(self.mainContentGuide)
            }


            if isMounted {
                if let layoutAware = self.contentVC as? InMeetLayoutContainerAware,
                   let layoutContainer = self.container?.layoutContainer {
                    layoutAware.didAttachToLayoutContainer(layoutContainer)
                }
                if let contentVC = self.contentVC as? ShareContentVC,
                   let container = self.container {
                    contentVC.setupExternalLayoutGuide(container: container)
                } else if let contentVC = self.contentVC as? InMeetASVideoContentVC {
                    contentVC.bottomBarGuide.snp.remakeConstraints { make in
                        make.edges.equalTo(self.bottomBarGuide)
                    }
                    contentVC.topBarGuide.snp.remakeConstraints { make in
                        make.edges.equalTo(self.topBarGuide)
                    }
                }
            }

            contentVC.didMove(toParent: self)

            if Display.phone, #available(iOS 16.0, *) {
                self.viewModel.router.topMost?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }
    private var speechFloatingContent: SpeechFloatingContent? {
        didSet {
            guard self.speechFloatingContent != oldValue,
                  let speechContent = speechFloatingContent else {
                return
            }
            Logger.scene.info("SpeechContent: \(oldValue) -> \(speechContent)")
            self.floatingVC.updateSpeechContent(speechContent)
        }
    }

    private func updateSpeechContents() {
        guard let container = container, self.isViewLoaded else {
            return
        }

        Logger.scene.info("updateSpeechContent: isSwitch:\(isSwitch), hideSelf:\(container.context.isHideSelf), enableSelfAS:\(enableSelfAsActiveSpeaker)")

        self.speechFloatingContent = content.speechFloatContentWithSwitch(isSwitch,
                                                                          hideMySelf: container.context.isHideSelf,
                                                                          enableSelfASActiveSpeaker: enableSelfAsActiveSpeaker)
        self.mainContent = content.speechFloatContentWithSwitch(!isSwitch,
                                                                hideMySelf: container.context.isHideSelf,
                                                                enableSelfASActiveSpeaker: enableSelfAsActiveSpeaker)
    }

    var enableSelfAsActiveSpeaker: Bool = false {
        didSet {
            guard self.enableSelfAsActiveSpeaker != oldValue else {
                return
            }
            updateSpeechContents()
        }
    }

    var isSwitch: Bool {
        didSet {
            guard self.isSwitch != oldValue else {
                return
            }

            if self.content.isShareContent {
                self.container?.context.isSpeechFlowSwitched = false
                if self.isSwitch {
                    self.container?.context.isShowSpeakerOnMainScreen = self.isSwitch
                } else {
                    self.sceneControllerDelegate?.goBackToShareContent(from: .pinActiveSpeaker, location: .singleClickSpeaker)
                }
            } else {
                self.container?.context.isShowSpeakerOnMainScreen = false
                self.container?.context.isSpeechFlowSwitched = self.isSwitch
            }

            updateSpeechContents()
        }
    }

    var isFocusing: Bool = false {
        didSet {
            guard self.isFocusing != oldValue, self.isFocusing else {
                return
            }
            if self.content == .flow, self.isSwitch {
                self.isSwitch = false
            }
        }
    }

    var meetingLayoutStyle: MeetingLayoutStyle {
        didSet {
            let oldIsOverlayFullScreen = oldValue != .tiled
            let newIsOverlayFullScreen = meetingLayoutStyle != .tiled
            guard oldIsOverlayFullScreen != newIsOverlayFullScreen else {
                return
            }
            if let container = container {
                updateLayoutGuides(container: container)
            }
        }
    }

    var isMobileLandscapeMode: Bool {
        didSet {
            guard self.isMobileLandscapeMode != oldValue else {
                return
            }
            if let container = self.container {
                self.updateLayoutGuides(container: container)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override init(container: InMeetViewContainer, content: InMeetSceneManager.ContentMode) {
        if content.isShareContent {
            self.isSwitch = content.enableSpeechSwitch ? container.context.isShowSpeakerOnMainScreen : false
        } else {
            self.isSwitch = container.context.isSpeechFlowSwitched
        }
        self.meetingLayoutStyle = container.context.meetingLayoutStyle
        self.isMobileLandscapeMode = VCScene.isPhoneLandscape
        super.init(container: container, content: content)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.floatingVC = container!.flowComponent!.makeSpeechFloatingVC()
        self.floatingVC.didTapSwitch = { [weak self] in
            guard let self = self, !self.floatingVC.speechFloatingView.forcedHidden else { return }
            self.isSwitch = !self.isSwitch
        }
        self.view.addLayoutGuide(mainContentGuide)
        self.view.addLayoutGuide(topBarGuide)
        self.view.addLayoutGuide(bottomBarGuide)
        self.view.addLayoutGuide(floatingContentGuid)

        self.addChild(floatingVC!)
        self.view.addSubview(floatingVC.view)
        floatingVC.view.snp.makeConstraints { make in
            make.edges.equalTo(floatingContentGuid)
        }
        floatingVC.didMove(toParent: self)

        floatingVC.delegate = self

        self.updateSpeechContents()
        self.container?.context.addListener(self, for: [.hideSelf, .hideNonVideoParticipants, .showSpeakerOnMainScreen])
    }

    override func onMount(container: InMeetViewContainer) {
        super.onMount(container: container)
        if let layoutAware = self.contentVC as? InMeetLayoutContainerAware {
            layoutAware.didAttachToLayoutContainer(container.layoutContainer)
        }
        if let contentVC = self.contentVC as? ShareContentVC {
            contentVC.setupExternalLayoutGuide(container: container)
        } else if let contentVC = self.contentVC as? InMeetASVideoContentVC {
            contentVC.bottomBarGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.bottomBarGuide)
            }
            contentVC.topBarGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.topBarGuide)
            }
        }
        updateLayoutGuides(container: container)
        container.addMeetLayoutStyleListener(self)
        container.addMeetSceneModeListener(self)
        self.topBarGuide.snp.remakeConstraints { make in
            make.top.left.right.equalTo(container.topBarGuide)
            make.bottom.equalTo(container.topExtendContainerGuide)
        }
        self.bottomBarGuide.snp.remakeConstraints { make in
            make.edges.equalTo(container.bottomBarGuide)
        }

        floatingVC.viewModel.forceHiddenFloatingViewRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] shouldHide in
                if shouldHide {
                    self?.isSwitch = false
                }
            }).disposed(by: disposeBag)
        self.enableSelfAsActiveSpeaker = self.viewModel.setting.enableSelfAsActiveSpeaker
        self.viewModel.setting.addListener(self, for: .enableSelfAsActiveSpeaker)
    }

    override func onUnmount() {
        super.onUnmount()

        if let layoutAware = self.contentVC as? InMeetLayoutContainerAware,
           let layoutContainer = self.container?.layoutContainer {
            layoutAware.didDetachFromLayoutContainer(layoutContainer)
        }

        self.floatingVC?.willMove(toParent: nil)
        self.floatingVC?.view.removeFromSuperview()
        self.floatingVC?.removeFromParent()

        self.removePrevContent()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if Display.phone {
            coordinator.animate { [weak self] _ in
                guard let self = self else { return }
                self.isMobileLandscapeMode = self.view.isPhoneLandscape
            }
        }
    }

    private func removePrevContent() {
        if let layoutAware = self.contentVC as? InMeetLayoutContainerAware,
           let layoutContainer = self.container?.layoutContainer,
           self.isMounted {
            layoutAware.didDetachFromLayoutContainer(layoutContainer)
        }
        self.contentVC?.willMove(toParent: nil)
        self.contentVC?.view.removeFromSuperview()
        self.contentVC?.removeFromParent()
    }


    private var floatingContentGuideToken: MeetingLayoutGuideToken?

    func updateLayoutGuides(container: InMeetViewContainer) {
        let isOverlayFullScreen = meetingLayoutStyle != .tiled
        Logger.scene.info("update speech isLandscapeMode \(isMobileLandscapeMode)")

        let token = container.layoutContainer.requestOrderedLayoutGuide(topAnchor: .topShareBar,
                                                                        bottomAnchor: .bottomToolbar,
                                                                        specificInsets: [
                                                                            .topSafeArea: 12.0,
                                                                            .topNavigationBar: 16.0,
                                                                            .topExtendBar: 8.0,
                                                                            .topShareBar: 16.0,
                                                                            .bottomToolbar: 8.0,
                                                                            .bottomSafeArea: 12.0
                                                                        ])
        floatingContentGuid.snp.remakeConstraints { make in
            make.edges.equalTo(token.layoutGuide)
        }
        self.floatingContentGuideToken = token

        mainContentGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            if isOverlayFullScreen {
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            } else {
                if self.isMobileLandscapeMode {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(container.topExtendContainerGuide.snp.bottom)
                }
                make.bottom.lessThanOrEqualTo(container.bottomBarGuide.snp.top)
                make.bottom.equalTo(container.bottomBarGuide.snp.top).priority(.veryHigh)
                make.bottom.lessThanOrEqualToSuperview()
                make.bottom.equalToSuperview().priority(.veryHigh)
            }
        }

    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
    }

    func containerDidChangeFocusing(container: InMeetViewContainer,
                                    isFocusing: Bool) {
        self.isFocusing = isFocusing
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if self.content == .flow {
            // 非共享情况下处理以下逻辑
            if change == .hideSelf, let hideSelf = userInfo as? Bool, hideSelf {
                // 隐藏自己时，小窗要先切换回自己，再隐藏小窗
                self.isSwitch = false
            } else if change == .hideNonVideoParticipants, let shouldHide = userInfo as? Bool, shouldHide {
                // 隐藏非视频参会者开启时的处理逻辑同上
                self.isSwitch = false
            }
        }
        if change == .showSpeakerOnMainScreen, let showSpeaker = userInfo as? Bool {
            self.isSwitch = showSpeaker
        }
        if change == .hideSelf {
            updateSpeechContents()
        }

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
}

private extension InMeetSceneManager.ContentMode {
    func speechFloatContentWithSwitch(_ isSwitch: Bool,
                                      hideMySelf: Bool,
                                      enableSelfASActiveSpeaker: Bool) -> SpeechFloatingContent {
        let speechContent: SpeechFloatingContent
        let mainContent: SpeechFloatingContent
        switch self {
        case .flow:
            speechContent = .local
        case .shareScreen, .follow, .whiteboard, .selfShareScreen, .webSpace:
            speechContent = (hideMySelf || !enableSelfASActiveSpeaker) ? .activeSpeakerWithoutLocal : .activeSpeaker
        }
        switch self {
        case .flow:
            mainContent = .activeSpeakerWithoutLocal
        case .shareScreen:
            mainContent = .shareScreen
        case .follow:
            mainContent = .follow
        case .whiteboard:
            mainContent = .whiteBoard
        case .selfShareScreen:
            mainContent = .selfShareScreen
        case .webSpace:
            mainContent = .webSpace
        }
        return isSwitch ? mainContent : speechContent
    }
}

extension SpeechSceneController: FloatingWindowTransitioning {
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

extension SpeechSceneController: InMeetSpeechFloatingVCDelegate {

    func speechFloatingDidShrunk(isShrunken: Bool) {
        InMeetSceneTracks.trackToggleVideoBar(videoBarFold: isShrunken,
                                              scene: .speech,
                                              isSharing: self.content.isShareContent,
                                              isSharer: self.floatingVC.viewModel.meeting.shareData.isSelfSharingContent)
    }

    func speechFloatingEndDrag(isShrunken: Bool) {
        InMeetSceneTracks.trackHaulVideoBar(videoBarFold: isShrunken,
                                            scene: .speech,
                                            isSharing: self.content.isShareContent,
                                            isSharer: self.floatingVC.viewModel.meeting.shareData.isSelfSharingContent)
    }
}

extension SpeechSceneController: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .enableSelfAsActiveSpeaker {
            Util.runInMainThread {
                self.enableSelfAsActiveSpeaker = isOn
            }
        }
    }
}
