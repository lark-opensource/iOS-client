//
// Created by liujianlong on 2022/8/30.
//

import UIKit
import RxSwift
import RxRelay
import ByteViewNetwork
import ByteViewUI

class InMeetASVideoContentVM {
    let meeting: InMeetMeeting
    let context: InMeetViewContext

    var asFlavor: ASGridVMFlavor {
        get {
            localGridSelector.value
        }
        set {
            localGridSelector.accept(newValue)
        }
    }

    private let localGridSelector: BehaviorRelay<ASGridVMFlavor>
    let gridCellViewModel: Observable<InMeetGridCellViewModel>
    let sceneMode: InMeetSceneManager.SceneMode
    enum ASGridVMFlavor: Equatable {
        case local
        case activeSpeaker
        case activeSpeakerExcludeLocal
    }

    init(meeting: InMeetMeeting,
         context: InMeetViewContext,
         asFlavor: ASGridVMFlavor,
         gridViewModel: InMeetGridViewModel,
         sceneMode: InMeetSceneManager.SceneMode) {
        self.meeting = meeting
        self.context = context
        self.sceneMode = sceneMode
        self.localGridSelector = BehaviorRelay(value: asFlavor)
        self.gridCellViewModel = self.localGridSelector
            .distinctUntilChanged()
            .flatMapLatest { flavor -> Observable<InMeetGridCellViewModel> in
                switch flavor {
                case .local:
                    if let vm = gridViewModel.localGridCellViewModel {
                        return .just(vm)
                    } else {
                        return .empty()
                    }
                case .activeSpeaker:
                    return gridViewModel.singleGridViewModel(asIncludeLocal: true)
                case .activeSpeakerExcludeLocal:
                    return gridViewModel.singleGridViewModel(asIncludeLocal: false)
                }
            }
            .distinctUntilChanged()
    }
}

class InMeetASVideoContentVC: VMViewController<InMeetASVideoContentVM> {

    lazy var videoView: SingleVideoParticipantView = {
        let videoView: SingleVideoParticipantView
        if viewModel.sceneMode == .thumbnailRow {
            videoView = SingleVideoParticipantView(isZoomEnabled: false, cornerRadius: 0.0, fromSource: .thumbnailContentVC)
        } else {
            videoView = SingleVideoParticipantView(isZoomEnabled: false, cornerRadius: 0.0, fromSource: .speechContentVC)
        }
        return videoView
    }()

    var didTapUserName: ((Participant) -> Void)?

    let disposeBag = DisposeBag()
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = UIColor.clear
        setupVideoView()
    }

    override func bindViewModel() {
        self.bindVideoView2()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard Display.pad else { return }
        // width未撑满时，需要加圆角
        if videoView.frame.width < VCScene.bounds.width {
            videoView.cornerRadius = 8.0
            videoView.userInfoView.canSpecilizeBottomLeftRadius = true
            videoView.userInfoView.setNeedsLayout()
        } else {
            videoView.cornerRadius = 0.0
            videoView.userInfoView.canSpecilizeBottomLeftRadius = false
            videoView.userInfoView.setNeedsLayout()
        }
    }

    var bottomBarGuide: UILayoutGuide {
        self.loadViewIfNeeded()
        return videoView.bottomBarLayoutGuide
    }

    var topBarGuide: UILayoutGuide {
        self.loadViewIfNeeded()
        return videoView.topBarLayoutGuide
    }

    private func setupVideoView() {
        self.view.addSubview(videoView)
        videoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        videoView.didTapUserName = { [weak self] participant in
            self?.didTapUserName?(participant)
        }

        videoView.didTapRemoveFocus = { [weak self] in
            self?.removeFocus()
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.videoView.isLandscapeMode = newContext.layoutType.isPhoneLandscape
    }

    private func bindVideoView2() {
        viewModel.gridCellViewModel
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] cellVM in
                    self?.videoView.bind(viewModel: cellVM, layoutType: "full_screen")
                    self?.updateRemoveFocusVisible()
                    self?.updateVideoViewLayout(isShare: cellVM.type == .share)
                })
                .disposed(by: self.disposeBag)
        viewModel.context.addListener(self, for: .containerLayoutStyle)
        viewModel.meeting.addMyselfListener(self)
        viewModel.meeting.data.addListener(self)
    }

    private func updateRemoveFocusVisible() {
        // 本人是主持人 && 当前视图为焦点视频 && 非沉浸态，则展示“移除焦点视频”按钮
        if viewModel.meeting.myself.isHost
            && videoView.cellViewModel?.isFocused == true
            && viewModel.context.meetingLayoutStyle != .fullscreen {
            videoView.shouldShowRomoveFocusButton = true
        } else {
            videoView.shouldShowRomoveFocusButton = false
        }
    }

    private func updateVideoViewLayout(isShare: Bool) {
        if Display.pad, !isShare {
            videoView.snp.remakeConstraints { (make) in
                make.width.equalToSuperview().priority(.veryHigh)
                make.width.lessThanOrEqualToSuperview()
                make.height.equalToSuperview().priority(.veryHigh)
                make.height.lessThanOrEqualToSuperview()
                make.height.equalTo(videoView.snp.width).multipliedBy(9.0 / 16.0)
                make.center.equalToSuperview()
            }
        } else {
            videoView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    private func removeFocus() {
        ByteViewDialog.Builder()
            .id(.focusVideo)
            .title(I18n.View_G_UnfocusVideoForPop)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_MV_ConfirmButtonTwo)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                let request = HostManageRequest(action: .setSpotLight, meetingId: self.viewModel.meeting.meetingId)
                self.viewModel.meeting.httpClient.send(request) { result in
                    Logger.participant.info("remove focus video, err: \(result.error)")
                }
                ParticipantTracks.trackFocusVideo(withdraw: true, location: "focus_video")
            })
            .show()
    }
}

extension InMeetASVideoContentVC: InMeetViewChangeListener, MyselfListener, InMeetDataListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .containerLayoutStyle {
            updateRemoveFocusVisible()
        }
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        if myself.isHost != oldValue?.isHost {
            updateRemoveFocusVisible()
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if inMeetingInfo.focusingUser != oldValue?.focusingUser {
            updateRemoveFocusVisible()
        }
    }
}
