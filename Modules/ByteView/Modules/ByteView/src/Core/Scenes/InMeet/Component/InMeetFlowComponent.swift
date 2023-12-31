//
//  InMeetFlowComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import RxSwift

/// 宫格流
final class InMeetFlowComponent: InMeetViewComponent {
    private let meeting: InMeetMeeting
    private let viewModel: InMeetViewModel
    private let context: InMeetViewContext
    weak var container: InMeetViewContainer?

    private let gridViewModel: InMeetGridViewModel
    private let reorderFloatGuideToken: MeetingLayoutGuideToken

    static var isNewLayoutEnabled: Bool {
        return Display.phone && !InMeetOrientationToolComponent.isPhoneLandscapeMode
    }

    private var flowVC: InMeetFlowViewControllerV2?
    func getOrCreateFlowVC() -> InMeetFlowViewControllerV2 {
        if self.flowVC != nil {
            return self.flowVC!
        }
        self.flowVC = InMeetFlowViewControllerV2(viewModel: gridViewModel)
        self.flowVC?.container = container
        self.flowVC?.delegate = self
        return self.flowVC!
    }

    private lazy var reorderTagView = {
        let view = GridReorderTagView()
        view.isHidden = true
        return view
    }()

    let bag = DisposeBag()

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.viewModel = viewModel
        self.context = viewModel.viewContext
        self.container = container
        self.gridViewModel = viewModel.resolver.resolve(InMeetGridViewModel.self)!
        self.reorderFloatGuideToken = container.layoutContainer.requestOrderedLayoutGuide(topAnchor: .topShareBar, bottomAnchor: .bottomShareBar, insets: 8.0)
        container.addContent(reorderTagView, level: .gridReorderTag)
        self.context.addListener(self, for: [.contentScene, .sketchMenu, .whiteboardMenu])
        self.bindReorderTag()
        self.gridViewModel.showCustomOrderGuide()
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .flow
    }

    func setupConstraints(container: InMeetViewContainer) {
        remakeTagConstraints()
    }
}

extension InMeetFlowComponent: InMeetFlowViewControllerDelegate {
    func flowDidShowSingleVideo(pid: ByteviewUser, from: UIView, avatarView: UIView) {
        container?.singleVideoComponent?.showSingleVideo(pid: pid, from: from, avatarView: avatarView)
    }

    func flowDidHideSingleVideo() {
        container?.singleVideoComponent?.hideSingleVideo()
    }
}


extension InMeetViewContainer {
    var flowComponent: InMeetFlowComponent? {
        component(by: .flow) as? InMeetFlowComponent
    }
}


extension InMeetFlowComponent {
    func didTapUserName(participant: Participant) {
        guard gridViewModel.browserUserProfileEnable,
              !participant.isLarkGuest else {
            return
        }
        if let userId = participant.participantId.larkUserId {
            MeetingTracks.trackDidTapUserProfile()
            ParticipantTracks.trackParticipantAction(.userInformation,
                                                     isFromGridView: true,
                                                     isSharing: self.meeting.shareData.isSharingContent)
            InMeetUserProfileAction.show(userId: userId, meeting: self.meeting)
        }
    }

    func makeContentVC(asFlavor: InMeetASVideoContentVM.ASGridVMFlavor = .activeSpeakerExcludeLocal,
                       sceneMode: InMeetSceneManager.SceneMode) -> InMeetASVideoContentVC {
        let vm = InMeetASVideoContentVM(meeting: meeting,
                                        context: context,
                                        asFlavor: asFlavor,
                                        gridViewModel: self.gridViewModel,
                                        sceneMode: sceneMode)
        let vc = InMeetASVideoContentVC(viewModel: vm)
        vc.didTapUserName = { [weak self] participant in
            self?.didTapUserName(participant: participant)
        }
        return vc
    }

    func makeSpeechFloatingVC() -> InMeetSpeechFloatingViewController {
        let speechFloatingVM = InMeetSpeechViewModel(resolver: self.viewModel.resolver)
        let vc = InMeetSpeechFloatingViewController(viewModel: speechFloatingVM)
        vc.didTapUserName = { [weak self] participant in
            self?.didTapUserName(participant: participant)
        }
        return vc
    }
}

extension InMeetFlowComponent: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if [.contentScene, .sketchMenu, .whiteboardMenu].contains(change) {
            remakeTagConstraints()
        }
    }

    private func bindReorderTag() {
        gridViewModel.showReorderTagRelay
            .asDriver()
            .map { !$0 }
            .drive(reorderTagView.rx.isHidden)
            .disposed(by: bag)

        reorderTagView.syncButton.addTarget(self, action: #selector(sync), for: .touchUpInside)
        reorderTagView.abandonButton.addTarget(self, action: #selector(abandon), for: .touchUpInside)
    }

    @objc private func sync() {
        InMeetSceneTracks.trackToggleReorder(confirm: true)
        gridViewModel.syncReorder()
        Toast.show(I18n.View_G_VideoOrderUpdated)
    }

    @objc private func abandon() {
        InMeetSceneTracks.trackToggleReorder(confirm: false)
        gridViewModel.undoReorder()
    }

    private func remakeTagConstraints() {
        Util.runInMainThread {
            guard self.container != nil else { return }
            self.reorderTagView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview().offset(8)
                make.height.equalTo(40)
                make.top.equalTo(self.reorderFloatGuideToken.layoutGuide)
            }
        }
    }
}
