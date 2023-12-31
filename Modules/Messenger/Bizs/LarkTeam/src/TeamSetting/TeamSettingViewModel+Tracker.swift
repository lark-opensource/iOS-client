//
//  TeamSettingViewModel+Tracker.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/15.
//

import Foundation
import RxSwift
import RxCocoa
import LarkCore
import LarkUIKit
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface

extension TeamSettingViewModel {
    func trackExistView() {
        TeamTracker.trackFeedTeamExitView(isTeamOwner: team.isTeamOwnerForMe)
    }

    func trackTransfer() {
        TeamTracker.trackFeedTeamExitClick(click: "transfer_team_owner_and_exit",
                                           target: "feed_transfer_team_owner_view")
    }

    func trackExitAndLeave() {
        TeamTracker.trackFeedTeamExitClick(click: "delete_and_exit",
                                           target: "none")
    }

    func trackExist() {
        TeamTracker.trackFeedTeamExitClick(click: "exit",
                                           target: "none")
    }

    func trackExistCancel() {
        TeamTracker.trackFeedTeamExitClick(click: "cancel",
                                           target: "none")
    }

    func trackTransferClick(newOwnerId: String) {
        TeamTracker.trackImTransferTeamOwnerClick(click: "transfer_team_owner_and_exit",
                                                  target: "none",
                                                  newOwnerId: newOwnerId)

    }

    func trackTransferClick() {
        TeamTracker.trackImTransferTeamOwnerClick(click: "cancel",
                                                  target: "none")
    }

    func trackDisbandView() {
        TeamTracker.trackImTeamDeleteView()
    }

    func trackDisbandClick() {
        TeamTracker.trackImTeamDeleteClick(click: "delete", target: "none")
    }

    func trackDisbandCancel() {
        TeamTracker.trackImTeamDeleteClick(click: "cancel", target: "none")
    }

    func trackView() {
        TeamTracker.trackImTeamSettingView()
    }

    func trackEditInfoClick() {
        TeamTracker.trackImTeamSettingClick(click: "edit", target: "im_team_info_edit_view")
    }

    func trackAddMemberClick() {
        TeamTracker.trackImTeamSettingClick(click: "add_team_member", target: "none")
    }

    func trackRemoveMemberClick() {
        TeamTracker.trackImTeamSettingClick(click: "remove_team_member", target: "none")
    }

    func trackDisbandTeamButtonClick() {
        TeamTracker.trackImTeamSettingClick(click: "delete", target: "im_team_delete_view")
    }

    func trackExistTeamButtonClick() {
        TeamTracker.trackImTeamSettingClick(click: "exit_team", target: "im_team_exit_view")
    }

    func trackManageTeamClick() {
        TeamTracker.trackImTeamSettingClick(click: "authority_management", target: "im_team_authority_management_view")
    }

    func trackExit() {
        let addMemberPermission = self.team.setting.addMemberPermission
        let addMemberToggle = addMemberPermission == .allMembers ? "open" : "close"
        let addTeamChatPermission = self.team.setting.addTeamChatPermission
        let addGroupToggle = addTeamChatPermission == .allMembers ? "open" : "close"
        TeamTracker.trackImTeamSettingClick(click: "exit",
                                            target: "none",
                                            isMemberChanged: initMemberCount != self.team.memberCount,
                                            isAddGroupToggleChanged: initAddGroupHash != addTeamChatPermission.hashValue,
                                            addGroupToggle: addGroupToggle,
                                            isAddMemberToggleChanged: initAddMemberHash != addMemberPermission.hashValue,
                                            addMemberToggle: addMemberToggle)
    }

    func trackImTransferTeamOwnerView() {
        TeamTracker.trackImTransferTeamOwnerView()
    }

    func trackTeamEvent(teamID: String) {
        TeamTracker.trackTeamSettingClick(teamID: teamID, click: "update")
    }

    func trackTeamMember(teamID: String) {
        TeamTracker.trackTeamSettingClick(teamID: teamID, click: "member")
    }
}
