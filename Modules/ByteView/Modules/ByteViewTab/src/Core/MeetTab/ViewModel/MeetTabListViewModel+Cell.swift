//
//  MeetTabListViewModel+Cell.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import RxSwift
import ByteViewCommon
import ByteViewNetwork

extension MeetTabListViewModel {

    func historyToAll(_ elements: [TabListItem], users: [ParticipantUserInfo] = []) -> [MeetTabCellViewModel] {
        return elements.compactMap { element -> MeetTabCellViewModel? in
            let user = users.first(where: { $0.id == element.historyAbbrInfo.interacterUserID })
            if element.meetingStatus == .meetingOnTheCall {
                return MeetTabOngoingCellViewModel(viewModel: self.tabViewModel, vcInfo: element, user: user)
            } else {
                return MeetTabHistoryCellViewModel(viewModel: self.tabViewModel, vcInfo: element, user: user)
            }
        }
    }

    func upcomingToAll(_ elements: [TabUpcomingInstance]) -> [MeetTabCellViewModel] {
        return elements.enumerated().compactMap { index, element -> MeetTabCellViewModel? in
            return MeetTabUpcomingCellViewModel(viewModel: self.tabViewModel, index: index, instance: element)
        }
    }
}
