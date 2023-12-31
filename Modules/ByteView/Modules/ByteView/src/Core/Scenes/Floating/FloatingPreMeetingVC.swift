//
//  FloatingPreMeetingVC.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/8.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import Action
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI
import ByteViewMeeting
import ByteViewRtcBridge

class FloatingPreMeetVM {
    var avatarInfo: Driver<AvatarInfo>
    var topic: Driver<String>
    var meetingStatus: Driver<String>
    var overlayStatus: Driver<String>

    var isCameraMuted: Bool {
        get { isCameraMutedRelay.value }
        set {
            isCameraMutedRelay.accept(newValue)
        }
    }
    var isCameraMutedObservable: Observable<Bool> { isCameraMutedRelay.asObservable() }
    private let isCameraMutedRelay: BehaviorRelay<Bool>
    var meetingID: String?
    let disposeBag = DisposeBag()
    let session: MeetingSession
    let service: MeetingBasicService

    init(session: MeetingSession,
         service: MeetingBasicService,
         avatarInfo: Driver<AvatarInfo>,
         topic: Driver<String> = .just(""),
         meetingStatus: Driver<String> = .just(""),
         overlayStatus: Driver<String> = .just(""),
         isCameraMutedRelay: BehaviorRelay<Bool> = BehaviorRelay(value: true),
         meetingID: String? = nil) {
        self.session = session
        self.service = service
        self.avatarInfo = avatarInfo
        self.topic = topic
        self.meetingStatus = meetingStatus
        self.overlayStatus = overlayStatus
        self.isCameraMutedRelay = isCameraMutedRelay
        self.meetingID = meetingID
    }
}

/// 会前小窗，包括：
/// 1v1 calling & ringing
/// 多人会议 ringing
/// Lobby 等候室
class FloatingPreMeetingVC: VMViewController<FloatingPreMeetVM> {

    enum Style: Equatable {
        case `default`
        case large
    }

    private lazy var floatingView = FloatingSkeletonView()
    private lazy var participantView = FloatingParticipantView()
    private lazy var floatingMaskView = FloatingMaskView()

    var camera: PreviewCameraManager?

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func viewLayoutContextWillChange(to layoutContext: VCLayoutContext) {
        view.window?.clipsToBounds = true
    }

    override func viewLayoutContextDidChanged() {
        self.view.window?.clipsToBounds = false
    }

    override func setupViews() {
        self.view.applyFloatingBGAndBorder()
        floatingView.contentView = participantView
        floatingView.overlayView = floatingMaskView
        view.addSubview(floatingView)
        floatingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        setUpCamera()
    }

    private func setUpCamera() {
        if camera != nil {
            participantView.isMe = true
            let streamRenderView = participantView.streamRenderView
            if Display.pad {
                streamRenderView.renderMode = .renderModeFit
            } else {
                streamRenderView.renderMode = .renderModeHidden
            }
            streamRenderView.setStreamKey(.local)
            streamRenderView.bindMeetingSetting(viewModel.service.setting)
        }
    }

    override func bindViewModel() {
        viewModel.avatarInfo
            .drive(onNext: { [weak self] in
                self?.participantView.avatar.setAvatarInfo($0)
            })
            .disposed(by: rx.disposeBag)

        viewModel.topic
            .drive(onNext: { [weak self] in
//                self?.miniVideoView.name = $0
                self?.floatingView.userInfoView.isHidden = $0.isEmpty
                self?.participantView.isUserInfoVisible = !$0.isEmpty
                self?.floatingView.userInfoView.userInfoStatus = ParticipantUserInfoStatus(hasRoleTag: false,
                                                                                           meetingRole: .participant,
                                                                                           isSharing: false,
                                                                                           isFocusing: false,
                                                                                           isMute: false,
                                                                                           isLarkGuest: false,
                                                                                           name: $0,
                                                                                           attributedName: nil,
                                                                                           isRinging: false,
                                                                                           isMe: false,
                                                                                           rtcNetworkStatus: nil,
                                                                                           audioMode: .internet,
                                                                                           is1v1: false,
                                                                                           conditionEmoji: nil,
                                                                                           meetingSource: nil,
                                                                                           isRoomConnected: false,
                                                                                           isLocalRecord: false)
            })
            .disposed(by: rx.disposeBag)

        viewModel.meetingStatus
            .drive(onNext: { [weak self] meetingStatus in
                guard let self = self else {
                    return
                }
                self.participantView.avatarDesc = meetingStatus
            })
            .disposed(by: rx.disposeBag)

        viewModel.overlayStatus
            .drive(onNext: { [weak self] overlayStatus in
                guard let self = self else {
                    return
                }
                self.floatingMaskView.infoStatus = overlayStatus
            })
            .disposed(by: rx.disposeBag)
    }
}
