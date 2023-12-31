//
//  MeetingDetailParticipantHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import ByteViewNetwork

class MeetingDetailParticipantHeaderComponent: MeetingDetailHeaderComponent {

    static let countOfParticipantsInCell = 6

    lazy var previewView: ParticipantsPreviewView = {
        let previewView = ParticipantsPreviewView(frame: .zero,
                                                  cellRadius: 12,
                                                  cellSpacing: 2,
                                                  countOfParticipantsInCell: Self.countOfParticipantsInCell,
                                                  font: UIFont.systemFont(ofSize: 10, weight: .medium))
        previewView.delegate = self
        return previewView
    }()

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.participantAbbrInfos.addObserver(self)
    }

    override func updateLayout() {
        super.updateLayout()
        viewModel?.resetParticipantsPopover(view: previewView)
    }

    override func updateViews() {
        super.updateViews()
        guard let viewModel = viewModel, let participants = viewModel.participantAbbrInfos.value, !participants.isEmpty else { return }

        let maxAvatarCount = min(Self.countOfParticipantsInCell, participants.count)
        let requestedParticipants = Array(participants[0..<maxAvatarCount])
        Logger.ui.debug("update participants preview view: participants.count = \(participants.count), actual requested count: \(requestedParticipants.count), meetingID = \(viewModel.meetingID)")
        viewModel.httpClient.participantService.participantInfo(pids: requestedParticipants, meetingId: viewModel.meetingID) { [weak self] avatars in
            Logger.ui.debug("get participants avatars success: count = \(avatars.count), meetingID = \(viewModel.meetingID)")
            self?.previewView.updateParticipants(avatars, totalCount: participants.count)
        }
    }
}

extension MeetingDetailParticipantHeaderComponent: MeetingDetailParticipantAbbrInfoObserver {
    func didReceive(data: [ParticipantAbbrInfo]) {
        updateViews()
    }
}

extension MeetingDetailParticipantHeaderComponent: ParticipantsPreviewViewDelegate {
    func didTapParticipantsPreviewView(_ preview: ParticipantsPreviewView) {
        guard let commonInfo = viewModel?.commonInfo.value else { return }
        MeetTabTracks.trackMeetTabDetailOperation(.clickUserGroup, isOngoing: commonInfo.meetingStatus == .meetingOnTheCall, isCall: commonInfo.meetingType == .call)
        viewModel?.handleParticipantsTapped(view: preview)
    }
}

extension ParticipantUserInfo: AvatarProvider {}
