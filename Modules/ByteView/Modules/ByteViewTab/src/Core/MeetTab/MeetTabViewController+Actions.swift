//
//  MeetTabViewController+Actions.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Action
import ByteViewCommon
import ByteViewTracker

extension MeetTabViewController {

    func bindViewActions() {
        for type in headerView.buttons {
            switch type {
            case .newMeeting:
                headerView.actions[type] = viewModel.getNewMeetingAction(from: self)
            case .joinMeeting:
                headerView.actions[type] = viewModel.getJoinMeetingAction(from: self)
            case .schedule:
                headerView.actions[type] = viewModel.scheduleMeetingAction
            case .localShare:
                headerView.actions[type] = viewModel.getLocalShareAction(from: self)
            case .minutes:
                let minutesAction = CocoaAction(workFactory: { [weak self] _ in
                    guard let self = self else { return .empty() }
                    VCTracker.post(name: .vc_meeting_tab, params: [.action_name: "lark_minutes"])
                    MeetTabTracks.trackMeetTabOperation(.clickLarkMinutes)
                    self.router?.gotoMinutesHome(from: self, isFromTab: false)
                    return .empty()
                })
                headerView.actions[type] = minutesAction
            case .phoneCall:
                headerView.actions[type] = CocoaAction(workFactory: { [weak self] _ in
                    self?.showKeypadViewController()
                    return .empty()
                })
            case .webinarSchedule:
                headerView.actions[type] = viewModel.webinarScheduleMeetingAction
            }
        }
    }

    private func showKeypadViewController() {
        if self.headerView.isShowGuideView {
            let vc = EnterpriseKeyPadCloseViewController(viewModel: self.viewModel.tabViewModel)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = EnterpriseKeyPadViewController(viewModel: EnterpriseKeyPadViewModel(viewModel: self.viewModel.tabViewModel))
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
