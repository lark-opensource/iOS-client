//
//  TeamActionServiceImpl.swift
//  LarkTeam
//
//  Created by chaishenghua on 2023/1/13.
//

import UIKit
import Foundation
import LarkMessengerInterface
import UniverseDesignDialog
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import LarkModel
import RxSwift
import LarkUIKit
import LarkContainer
import RustPB

class TeamActionServiceImpl: TeamActionService {
    let teamAPI: TeamAPI
    private let resolver: UserResolver

    init(teamAPI: TeamAPI,
         resolver: UserResolver) {
        self.teamAPI = teamAPI
        self.resolver = resolver
    }

    func joinTeamDialog(team: Basic_V1_Team, feedPreview: FeedPreview, on vc: UIViewController, isNewTeam: Bool, successCallBack: (() -> Void)?) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_AddToTeamName_Title(team.name))
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_AddToTeamNameAdd_Button) { [weak self] in
            guard let self = self else { return }
            TeamTracker.AddChatToTeamPopupClick(teamID: String(team.id), isNewTeam: isNewTeam)
            self.teamAPI.bindTeamChatRequest(teamId: team.id,
                                             chatId: Int64(feedPreview.id) ?? 0,
                                             teamChatType: .private,
                                             addMemberChat: false,
                                             isDiscoverable: !feedPreview.extraMeta.crossTenant)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                if let window = vc.currentWindow() {
                    UDToast.showSuccess(with: BundleI18n.LarkTeam.Project_T_AddedToTeamMobile_Toast, on: window)
                }
                successCallBack?()
            }, onError: { error in
                if let window = vc.currentWindow() {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Project_MV_UnableToAddTeamTittle, on: window, error: error)
                }
            })
        }
        vc.present(dialog, animated: true)
        TeamTracker.AddChatToTeamPopup()
    }

    func enableJoinTeam(feedPreview: FeedPreview) -> Bool {
        return Feature.isTeamEnable(userID: resolver.userID)
        && feedPreview.preview.chatData.chatType == .group
        && !feedPreview.preview.chatData.isCrypto && !feedPreview.preview.chatData.isPrivateMode && feedPreview.preview.chatData.oncallID.isEmpty && !feedPreview.preview.chatData.isFrozen
    }
}
