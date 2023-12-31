//
//  SingleVideoViewController.swift
//  ByteView
//
//  Created by LUNNER on 2020/4/1.
//

import UIKit
import RxSwift
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork

protocol SingleVideoVCDelegate: AnyObject {
    func didTapMoreSelection(cellVM: InMeetGridCellViewModel, sourceView: UIView, isSingleVideoEnabled: Bool)
    func didTapUserName(participant: Participant)
    func didHideSingleVideo()
}

class SingleVideoViewController: VMViewController<SingleVideoViewModel>, UIGestureRecognizerDelegate {

    let disposeBag = DisposeBag()
    let topBar = SingleVideoNavigationBar()

    var isSingleVideoEnabled: Bool {
        viewModel.gridCellViewModel.participant.value.status == .onTheCall
    }

    // 包裹流、topGradientView内容等 一级视图
    lazy var contentView = UIView()

    lazy var videoView = SingleVideoParticipantView(isZoomEnabled: true, cornerRadius: 0.0, fromSource: .singleVideoVC)

    weak var delegate: SingleVideoVCDelegate?

    override func setupViews() {
        isNavigationBarHidden = true
        setupContentView()
        setupVideoView()

        view.addSubview(topBar)
        topBar.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction))
        tap.numberOfTapsRequired = 2
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    private var isLayoutCalibrated = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isLayoutCalibrated = false
        viewModel.gridCellViewModel.context.fullScreenDetector?.registerInterruptWhiteListView(self.view)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.gridCellViewModel.context.fullScreenDetector?.unregisterInterruptWhiteListView(self.view)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let layout = self.view.window?.safeAreaLayoutGuide, !isLayoutCalibrated {
            isLayoutCalibrated = true
            topBar.resetSafeAreaLayoutGuide(layout)
        }
    }

    override func bindViewModel() {
        bindVideoView2()
        bindNavigationBar2()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    @objc
    func panAction(gesture: UISwipeGestureRecognizer) {
        let point = gesture.location(in: self.view)

        if gesture.state == .ended, point.x < 30 {
            self.didClickSingleBack()
        }
    }

    @objc private func tapGestureAction() {
        delegate?.didHideSingleVideo()
        ParticipantTracks.trackFullScreen(click: "double_click_exit_fullscreen")
    }

    private func setupContentView() {
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    private func setupVideoView() {
        contentView.addSubview(videoView)
        videoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        videoView.didTapUserName = { [weak self] participant in
            self?.delegate?.didTapUserName(participant: participant)
        }
    }

    private func bindVideoView2() {
        self.videoView.bind(viewModel: viewModel.gridCellViewModel, layoutType: "full_screen")

        viewModel.gridCellViewModel.isRemoved
            .filter({ $0 })
            .take(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self,
                      let prevCellVM = self.videoView.cellViewModel,
                      case .onTheCall = prevCellVM.participant.value.status else {
                    return
                }
                // "隐藏本人视图"导致的remove，不需要toast
                if !prevCellVM.isMe {
                    let meetingId = self.viewModel.gridCellViewModel.meeting.meetingId
                    let participantService = self.viewModel.gridCellViewModel.meeting.httpClient.participantService
                    participantService.participantInfo(pid: prevCellVM.participant.value.participantId, meetingId: meetingId) { ap in
                        Toast.show(I18n.View_M_NameLeftTheMeeting(ap.name))
                    }
                }
                self.delegate?.didHideSingleVideo()
            })
            .disposed(by: self.disposeBag)
    }

    private func bindNavigationBar2() {
        let isMe = viewModel.gridCellViewModel.isMe
        viewModel.gridCellViewModel.participant
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] participant in
                guard let self = self else { return }
                if !isMe || Util.isiOSAppOnMacSystem {
                    self.topBar.cameraButton.isHidden = true
                } else {
                    self.topBar.cameraButton.isHidden = participant.settings.isCameraMutedOrUnavailable
                }
                self.topBar.backButton.isHidden = false
                self.topBar.moreButton.isHidden = false
                self.updateStatusEmojiInfo(statusEmojiInfo: participant.settings.conditionEmojiInfo)
            })
            .disposed(by: disposeBag)

        topBar.backButton.addTarget(self, action: #selector(didClickSingleBack), for: .touchUpInside)
        topBar.cameraButton.addTarget(self, action: #selector(didClickSingleCamera), for: .touchUpInside)
        topBar.moreButton.addTarget(self, action: #selector(didClickSingleMore2), for: .touchUpInside)
    }

    @objc private func didClickSingleBack() {
        delegate?.didHideSingleVideo()
        ParticipantTracks.trackFullScreen(click: "exit_fullscreen")
    }

    @objc private func didClickSingleCamera() {
        viewModel.gridCellViewModel.meeting.camera.switchCamera()
    }

    @objc private func didClickSingleMore2() {
        delegate?.didTapMoreSelection(cellVM: viewModel.gridCellViewModel,
                                      sourceView: topBar.moreButton,
                                      isSingleVideoEnabled: isSingleVideoEnabled)
    }

    private var startInsets = UIEdgeInsets.zero
    private var startAvatarSize = CGSize.zero
    func show(startFrame: CGRect, avatarSize: CGSize, duration: TimeInterval, alongsideTransition: (() -> Void)? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let sv = self.view.superview else {
            return
        }
        startAvatarSize = avatarSize
        startInsets = UIEdgeInsets(top: startFrame.minY - sv.bounds.minY,
                                   left: startFrame.minX - sv.bounds.minX,
                                   bottom: sv.bounds.maxY - startFrame.maxY,
                                   right: sv.bounds.maxX - startFrame.maxX)
        view.snp.remakeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(startInsets)
        }
        sv.layoutIfNeeded()
        self.topBar.alpha = 0
        sv.isHidden = false
        UIView.animate(withDuration: duration, animations: {
            self.topBar.alpha = 1
            self.view.snp.updateConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets.zero)
            }
            alongsideTransition?()
            sv.layoutIfNeeded()
        }, completion: completion)
    }

    func hide(duration: TimeInterval, alongsideTransition: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        guard self.view.superview != nil else {
            completion?(true)
            return
        }
        self.topBar.alpha = 0
        let sv = self.view.superview
        UIView.animate(withDuration: duration, animations: {
            self.view.snp.updateConstraints { (maker) in
                maker.edges.equalToSuperview().inset(self.startInsets)
            }
            self.videoView.userInfoView.snp.remakeConstraints { (make) in
                make.bottom.left.right.equalToSuperview()
            }
            alongsideTransition?()
            sv?.layoutIfNeeded()
        }, completion: completion)
    }

    func updateSystemCallingInfo(mobileCallingStatus: ParticipantSettings.MobileCallingStatus?) {
        if mobileCallingStatus == .busy && !viewModel.gridCellViewModel.isMe {
            videoView.systemCallingStatusView.isHidden = false
        } else {
            videoView.systemCallingStatusView.isHidden = true
        }
    }

    func updateStatusEmojiInfo(statusEmojiInfo: ParticipantSettings.ConditionEmojiInfo?) {
        videoView.updateStatusEmojiInfo(statusEmojiInfo: statusEmojiInfo)
    }

    @objc func dismissManipulator() {
        AlignPopoverManager.shared.dismiss(animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let view = touch.view
        if view is UIButton {
            return false
        }
        return true
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged {
            self.dismissManipulator()
        }
        self.videoView.isLandscapeMode = newContext.layoutType.isPhoneLandscape
    }
}
