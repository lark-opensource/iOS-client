//
//  ParticipantsViewModel+Router.swift
//  ByteView
//
//  Created by wulv on 2022/9/29.
//

import Foundation
import LarkSegmentedView

extension Router {
    func startParticipants(meeting: InMeetMeeting, resolver: InMeetViewModelResolver, autoScrollToLobby: ParticipantsViewController.ScrollToLobbyList = .none) {
        let viewModel = ParticipantsViewModel(resolver: resolver)
        let inMeetVC = InMeetParticipantsViewController(viewModel: viewModel)
        inMeetVC.autoScrollToLobby = autoScrollToLobby == .normal
        let vcs: [JXSegmentedListContainerViewListDelegate]
        if viewModel.isWebinar {
            let attendeeVC = AttendeeParticipantsViewController(viewModel: viewModel)
            attendeeVC.autoScrollToLobby = autoScrollToLobby == .attendee
            vcs = [inMeetVC, attendeeVC]
        } else {
            let suggestionVC = SuggestionParticipantsViewController(viewModel: viewModel)
            vcs = [inMeetVC, suggestionVC]
        }
        let vc = ParticipantsViewController(subViewControllers: vcs, autoScrollToLobby: autoScrollToLobby)
        vc.viewModel = viewModel
        presentDynamicModal(vc,
                            regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                            compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
    }
}
