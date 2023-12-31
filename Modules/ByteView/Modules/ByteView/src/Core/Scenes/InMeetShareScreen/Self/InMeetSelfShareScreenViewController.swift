//
//  InMeetSelfShareScreenViewController.swift
//  ByteView
//
//  Created by Prontera on 2021/3/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ReplayKit
import ByteViewTracker
import UniverseDesignIcon
import ByteViewUI

class InMeetSelfShareScreenViewController: VMViewController<InMeetSelfShareScreenViewModel> {

    private let disposeBag = DisposeBag()

    private var reconnectComponent: InMeetReconnectComponent?
    private var pickerView: UIView?
    private var isWebinarStageScene: Bool = false {
        didSet {
            guard self.isWebinarStageScene != oldValue else {
                return
            }
            stopSharingView.isWebinarStage = isWebinarStageScene
        }
    }

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var stopSharingView: InMeetSelfStopSharingScreenView = {
        let view = InMeetSelfStopSharingScreenView(frame: .zero)
        return view
    }()

    private lazy var startSharingView: InMeetSelfStartSharingScreenView = {
        let view = InMeetSelfStartSharingScreenView(frame: .zero)
        return view
    }()

    private let topEmptyView = UIView()
    private let bottomEmptyView = UIView()
    private var meetingLayoutStyle: MeetingLayoutStyle = .tiled
    private var lastDisplayStatus: (layoutStyle: MeetingLayoutStyle, isLandscape: Bool) = (.tiled, VCScene.isLandscape)

    private lazy var backButton: UIButton = {
        let btn = UIButton()
        btn.isExclusiveTouch = true
        btn.addInteraction(type: .highlight)
        return btn
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        VCTracker.post(name: .vc_client_signal_info,
                              params: [.action_name: "req_onthecall"],
                              platforms: [.plane])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        super.viewDidFirstAppear(animated)
        // box投屏和会中主动共享屏幕是一个页面，但是埋点只需要box投屏才需要
        if viewModel.isBoxSharing {
            VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: "display"])
            MeetingTracksV2.trackDisplayOnTheCallPage(false, isSharing: viewModel.context.meetingContent.isShareContent,
                                                      meeting: viewModel.meeting)
        }
    }

    override func setupViews() {
        super.setupViews()

        view.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff

        view.addSubview(topEmptyView)
        view.addSubview(contentView)
        view.addSubview(bottomEmptyView)

        topEmptyView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            if self.viewModel.isBoxSharing {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide)
            }
            if currentLayoutContext.layoutType.isPhoneLandscape {
                make.top.greaterThanOrEqualToSuperview().offset(15.0 + (meetingLayoutStyle == .tiled ? 44.0 : 0))
            }
            make.height.greaterThanOrEqualTo(1)
        }

        bottomEmptyView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            if self.viewModel.isBoxSharing {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            }
            make.height.equalTo(topEmptyView)
        }

        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(24)
            make.top.equalTo(topEmptyView.snp.bottom)
            make.bottom.equalTo(bottomEmptyView.snp.top)
        }

        if viewModel.isBoxSharing {
            setUpPickerView()
            viewModel.showShareScreenAlert()
            setUpBackButton()
        } else {
            if viewModel.mySharingScreenRelay.value {
                setUpStopSharingView()
            } else {
                setUpStartSharingView()
            }
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        viewModel.audioSwitchOnRelay
            .distinctUntilChanged()
            .bind(to: stopSharingView.switchView.rx.isOn)
            .disposed(by: disposeBag)

        viewModel.audioSwitchOnRelay
            .distinctUntilChanged()
            .bind(to: startSharingView.switchView.rx.isOn)
            .disposed(by: disposeBag)

        stopSharingView.switchView.rx.isOn
            .bind(to: viewModel.audioSwitchOnRelay)
            .disposed(by: disposeBag)

        stopSharingView.stopSharingButton.rx.action = viewModel.stopSharingAction

        viewModel.shareScreenTitle
            .drive(onNext: { [weak self] shareScreenTitle in
                self?.stopSharingView.shareScreenLabel.attributedText = NSAttributedString(string: shareScreenTitle, config: .h2)
                self?.stopSharingView.shareScreenLabel.textAlignment = .center
            })
            .disposed(by: disposeBag)

        viewModel.stopSharingScreenTitle
            .drive(onNext: { [weak self] stopSharingScreenTitle in
                let title = NSAttributedString(string: stopSharingScreenTitle,
                                               config: .body,
                                               lineBreakMode: .byTruncatingTail,
                                               textColor: UIColor.ud.primaryOnPrimaryFill)
                self?.stopSharingView.stopSharingButton.setAttributedTitle(title, for: .normal)
            })
            .disposed(by: disposeBag)

        if viewModel.isShareScreenMeetingRelay.value {
            viewModel.meeting.shareData.addListener(self)

            startSharingView.switchView.rx.isOn
                .bind(to: viewModel.audioSwitchOnRelay)
                .disposed(by: disposeBag)
            startSharingView.startSharingButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    VCTracker.post(name: .vc_meeting_sharescreen_click, params: [.click: "start_sharing"])
                    self.viewModel.showShareScreenAlert()
                })
                .disposed(by: disposeBag)
        }

        if viewModel.isBoxSharing {
            self.reconnectComponent = InMeetReconnectComponent(container: self, meeting: viewModel.meeting)
        }
    }

    private func clearViews() {
        stopSharingView.removeFromSuperview()
        stopSharingView.snp.removeConstraints()

        startSharingView.removeFromSuperview()
        startSharingView.snp.removeConstraints()
    }

    private func updateLeftButton(isSharing: Bool) {
        let icon: UDIconType = isSharing ? .leftOutlined : .closeOutlined
        backButton.setImage(UDIcon.getIconByKey(icon, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        backButton.setImage(UDIcon.getIconByKey(icon, iconColor: .ud.iconN1.withAlphaComponent(0.5), size: CGSize(width: 24, height: 24)), for: .highlighted)
        backButton.rx.action = viewModel.leftButtonAction
    }

    private func setUpStartSharingView() {
        contentView.addSubview(startSharingView)
        startSharingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func setUpStopSharingView() {
        contentView.addSubview(stopSharingView)
        stopSharingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func setUpPickerView() {
        if InMeetSelfShareScreenViewModel.isPickerViewAvailable, #available(iOS 12.0, *) {
            _ = ReplayKitFixer.fixOnce
            let pickerView = ShareScreenSncWrapper.createRPSystemBroadcastPickerView(for: .shareToRoom)
            if #available(iOS 12.2, *) {
                pickerView?.preferredExtension = self.viewModel.broadcastExtensionId
            }
            pickerView?.showsMicrophoneButton = false
            self.pickerView = pickerView
        }
    }

    private func setUpBackButton() {
        view.addSubview(backButton)
        backButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(2)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            maker.size.equalTo(CGSize(width: 44, height: 36))
        }
    }

    override var shouldAutorotate: Bool {
        false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.updateLayout()
    }

    private func updateLayout() {
        self.loadViewIfNeeded()
        let newMeetingLayoutStyle = self.meetingLayoutStyle
        let newIsLandscape = view.isLandscape
        let storedDisplayStatus = self.lastDisplayStatus

        guard Display.phone, (storedDisplayStatus.layoutStyle != newMeetingLayoutStyle || storedDisplayStatus.isLandscape != newIsLandscape) else {
            return // nothing to update
        }
        self.lastDisplayStatus = (newMeetingLayoutStyle, newIsLandscape)
        let topOffset = 15.0 + (newMeetingLayoutStyle == .tiled ? 44.0 : 0)

        stopSharingView.updateWithOrientation(newIsLandscape)

        topEmptyView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            if self.viewModel.isBoxSharing {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide)
            }
            if currentLayoutContext.layoutType.isPhoneLandscape {
                make.top.greaterThanOrEqualToSuperview().offset(topOffset)
            }
            make.height.greaterThanOrEqualTo(1)
        }

        bottomEmptyView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            if self.viewModel.isBoxSharing {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            }
            make.height.equalTo(topEmptyView)
        }
    }
}

extension InMeetSelfShareScreenViewController: InMeetShareDataListener {

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if [.selfSharingScreen, .none].contains(newScene.shareSceneType)
            || [.selfSharingScreen, .none].contains(oldScene.shareSceneType) {
            Util.runInMainThread {
                let isSharing = self.viewModel.meeting.shareData.isMySharingScreen
                self.clearViews()
                if isSharing {
                    self.setUpStopSharingView()
                } else {
                    self.setUpStartSharingView()
                }
                self.updateLeftButton(isSharing: isSharing)
            }
        }
    }

}

extension InMeetSelfShareScreenViewController: MeetingLayoutStyleListener {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
        self.updateLayout()
    }
}

extension InMeetSelfShareScreenViewController: MeetingSceneModeListener {
    func containerDidChangeSceneMode(container: InMeetViewContainer, sceneMode: InMeetSceneManager.SceneMode) {
        self.isWebinarStageScene = sceneMode == .webinarStage
    }
}
