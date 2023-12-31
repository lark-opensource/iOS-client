//
//  WebinarStageSceneController.swift
//  ByteView
//
//  Created by liujianlong on 2023/3/3.
//

import UIKit
import SnapKit
import RxSwift
import ByteViewNetwork
import ByteViewSetting

final class WebinarStageSceneController: BaseSceneController {

    override var childVCForOrientation: InMeetOrderedViewController? {
        InMeetOrderedViewController(orientation: .flow, self.stageVC)
    }

    private var meetingLayoutStyle: MeetingLayoutStyle {
        didSet {
            guard self.meetingLayoutStyle != oldValue else {
                return
            }
            self.flowAndStageVC?.meetingLayoutStyle = meetingLayoutStyle
            self.updateStageViewGuide()
        }
    }

    private var hasHostCohostAuthority: Bool = false {
        didSet {
            guard self.hasHostCohostAuthority != oldValue else {
                return
            }
            updateCanSwitchScene()
        }
    }

    private var isMobileLandscapeMode: Bool = false {
        didSet {
            guard self.isMobileLandscapeMode != oldValue else {
                return
            }
            self.updateStageViewGuide()
        }
    }

    private var canSwitchScene: Bool = true {
        didSet {
            guard self.canSwitchScene != oldValue else {
                return
            }
            UIView.performWithoutAnimation {
                self.updateStageViewGuide()
                self.view.layoutIfNeeded()
            }
        }
    }

    private let disposeBag = DisposeBag()

    private let flowTopBarGuide = UILayoutGuide()
    private let topBarExtendOverlayGuideHelper = UILayoutGuide()

    private var flowAndStageVC: InMeetFlowAndStageViewController?
    private let gridViewModel: InMeetGridViewModel
    private let stageVC: WebinarStageVC

    init?(container: InMeetViewContainer,
          content: InMeetSceneManager.ContentMode,
          meeting: InMeetMeeting,
          stageInfo: WebinarStageInfo,
          gridViewModel: InMeetGridViewModel,
          activeSpeaker: InMeetActiveSpeakerViewModel) {
        guard let webinarManager = meeting.webinarManager else {
            return nil
        }
        self.meetingLayoutStyle = container.meetingLayoutStyle
        self.gridViewModel = gridViewModel
        self.stageVC = WebinarStageVC(meeting: meeting,
                                      container: container,
                                      webinarManager: webinarManager,
                                      stageInfo: stageInfo,
                                      gridViewModel: gridViewModel,
                                      activeSpeaker: activeSpeaker)
        self.hasHostCohostAuthority = meeting.setting.hasCohostAuthority
        super.init(container: container, content: content)

        meeting.shareData.addListener(self, fireImmediately: true)
        meeting.setting.addListener(self, for: .hasCohostAuthority)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(stageVC.view)
        self.view.addLayoutGuide(flowTopBarGuide)
        self.view.addLayoutGuide(topBarExtendOverlayGuideHelper)

        self.topBarExtendOverlayGuideHelper.snp.remakeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.height.equalTo(self.containerTopBarExtendGuide)
        }
        self.flowTopBarGuide.snp.remakeConstraints { make in
            make.edges.equalTo(self.containerTopBarExtendGuide)
        }
        updateStageViewGuide()
    }

    override func onMount(container: InMeetViewContainer) {
        super.onMount(container: container)

        container.addMeetLayoutStyleListener(self)
        container.context.addListener(self, for: [.containerDidLayout])
        container.addMeetSceneModeListener(self)

        self.updateCanSwitchScene()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.isMobileLandscapeMode = Display.phone && self.view.bounds.width > self.view.bounds.height
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard Display.phone else {
            return
        }
        coordinator.animate { _ in
            self.isMobileLandscapeMode = size.width > size.height
        }
    }

    private func updateCanSwitchScene() {
        self.canSwitchScene = !self.gridViewModel.isWebinarAttendee && (self.stageVC.webinarStageInfo.allowGuestsChangeView || self.hasHostCohostAuthority)
    }

    private func updateStageViewGuide() {
        guard self.isViewLoaded else {
            return
        }
        if isMobileLandscapeMode && canSwitchScene {
            if self.flowAndStageVC == nil,
               let shareComponent = self.container?.shareComponent {
                self.stageVC.willMove(toParent: nil)
                self.stageVC.view.removeFromSuperview()
                self.stageVC.removeFromParent()
                let flowAndStageVC = shareComponent.makeLandscapeVC(gridViewModel: gridViewModel, stageVC: stageVC)
                self.flowAndStageVC = flowAndStageVC
                self.addChild(flowAndStageVC)
                self.view.addSubview(flowAndStageVC.view)
                flowAndStageVC.didMove(toParent: self)
                flowAndStageVC.sceneContent = .shareScreen
                flowAndStageVC.meetingLayoutStyle = self.meetingLayoutStyle
                self.flowAndStageVC?.setupExternalContainerGuides(topBarGuide: self.containerTopBarExtendGuide,
                                                                  bottomBarGuide: self.containerBottomBarGuide)
                if self.view.bounds.width < self.view.bounds.height {
                    flowAndStageVC.view.frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.height, height: self.view.bounds.width))
                }
            }

            self.flowAndStageVC?.setupExternalContainerGuides(topBarGuide: self.containerTopBarExtendGuide,
                                                              bottomBarGuide: self.containerBottomBarGuide)
            self.flowAndStageVC?.view.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                if meetingLayoutStyle.isOverlayFullScreen {
                    if content.isShareContent && Display.pad {
                        make.top.equalTo(self.topBarExtendOverlayGuideHelper.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                    make.bottom.equalToSuperview()
                } else if isMobileLandscapeMode {
                    make.top.bottom.equalToSuperview()
                } else {
                    make.top.equalTo(containerTopBarExtendGuide.snp.bottom)
                    make.bottom.equalTo(containerBottomBarGuide.snp.top)
                }
            }
        } else {
            if let flowAndStageVC = self.flowAndStageVC {
                flowAndStageVC.willMove(toParent: nil)
                flowAndStageVC.view.removeFromSuperview()
                flowAndStageVC.removeFromParent()
                self.flowAndStageVC = nil

                self.addChild(self.stageVC)
                self.view.addSubview(stageVC.view)
                stageVC.didMove(toParent: self)

            }
            self.stageVC.bottomBarLayoutGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.containerBottomBarGuide)
            }
            self.stageVC.view.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                if meetingLayoutStyle.isOverlayFullScreen {
                    if content.isShareContent && Display.pad {
                        make.top.equalTo(self.topBarExtendOverlayGuideHelper.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                    make.bottom.equalToSuperview()
                } else if isMobileLandscapeMode {
                    make.top.bottom.equalToSuperview()
                } else {
                    make.top.equalTo(containerTopBarExtendGuide.snp.bottom)
                    make.bottom.equalTo(containerBottomBarGuide.snp.top)
                }
            }
        }
    }

}

extension WebinarStageSceneController: MeetingSceneModeListener, InMeetShareDataListener {
    func containerDidChangeWebinarStageInfo(container: InMeetViewContainer, webinarStageInfo: WebinarStageInfo?) {
        assert(Thread.isMainThread)
        guard let stageInfo = webinarStageInfo else {
            return
        }
        self.stageVC.webinarStageInfo = stageInfo
        updateCanSwitchScene()
    }

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        Util.runInMainThread {
            self.stageVC.shareScene = newScene
        }
    }
}

extension WebinarStageSceneController: MeetingLayoutStyleListener {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
    }
}

extension WebinarStageSceneController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .containerDidLayout:
            self.flowAndStageVC?.handleTopBottomGuideChanged()
        default:
            break
        }
    }
}

extension WebinarStageSceneController: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority {
            Util.runInMainThread {
                self.hasHostCohostAuthority = isOn
            }
        }
    }
}
