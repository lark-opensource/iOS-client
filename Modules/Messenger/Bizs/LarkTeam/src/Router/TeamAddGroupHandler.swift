//
//  TeamBindGroupHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/25.
//

import UIKit
import RxSwift
import Swinject
import Foundation
import EENavigator
import LarkBizAvatar
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import LarkUIKit
import LarkTab
import LarkNavigator

final class TeamBindGroupHandler: UserTypedRouterHandler {
    private var disposeBag = DisposeBag()
    private var teamAPI: TeamAPI?

    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamBindGroupBody, req: EENavigator.Request, res: Response) throws {
        let userResolver = self.userResolver
        let teamId = body.teamId
        self.teamAPI = try userResolver.resolve(assert: TeamAPI.self)
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        var pickerBody = TeamChatterPickerBody()
        pickerBody.selectStyle = .single(style: .callbackWithReset)
        pickerBody.title = BundleI18n.LarkTeam.Project_MV_AddGroupsTitle
        pickerBody.searchPlaceholder = BundleI18n.LarkTeam.Project_T_SearchGroupsIJoined
        pickerBody.usePickerTitleView = false
        pickerBody.supportSelectGroup = true
        pickerBody.supportSelectOrganization = false
        pickerBody.supportSelectChatter = false
        pickerBody.supportUnfoldSelected = false
        pickerBody.customLeftBarButtonItem = body.customLeftBarButtonItem
        pickerBody.hideRightNaviBarItem = true
        pickerBody.includeShieldGroup = true
        pickerBody.cancelCallback = {
            body.completionHandler?(nil)
        }
        // 移动端的话添加群组只支持用户管理的群组(普通群、话题群、会议群、部门群、公开群)；暂不支持：外部群、密聊群 、家校群)
        pickerBody.checkChatDeniedReasonForDisabledPick = { chatType in
            if chatType.isCrypto || chatType.isPrivateMode {
                return true
            }
            return false
        }
        pickerBody.checkChatDeniedReasonForWillSelected = { (chatType, targetVC) in
            if chatType.isCrypto || chatType.isPrivateMode {
                UDToast.showTips(with: BundleI18n.LarkTeam.Project_MV_UnableToSelectExternalGroups, on: targetVC.view)
                return false
            }
            if let chat = chatAPI.getLocalChat(by: chatType.selectedInfoId) {
                if chat.teamEntity.teams[teamId] != nil {
                    UDToast.showTips(with: BundleI18n.LarkTeam.Project_MV_GroupHasLinkedTeam, on: targetVC.view)
                    return false
                }
            }
            return true
        }
        pickerBody.selectedCallback = { [weak self] controller, contactPickerResult in
            guard let self = self, let controller = controller else {
                TeamMemberViewModel.logger.error("teamlog/ChatterPickerBody selectedCallback controller is nil ")
                return
            }

            guard let chatInfo = contactPickerResult.chatInfos.first, let chatId = Int64(chatInfo.id) else {
                TeamMemberViewModel.logger.error("teamlog/ChatterPickerBody selectedCallback contactPickerResult chatInfo is nil ")
                return
            }
            self.showDialog(teamId: teamId, chatId: chatId, chatName: chatInfo.name, isDiscoverable: !(chatInfo.crossTenant ?? false), currentVC: controller, completionHandler: body.completionHandler)
        }
        res.redirect(body: pickerBody)
    }
}

extension TeamBindGroupHandler {
    func showDialog(teamId: Int64, chatId: Int64, chatName: String, isDiscoverable: Bool, currentVC: UIViewController?, completionHandler: TeamBindGroupBody.CompletionHandler?) {
        guard let currentVC = currentVC else { return }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_ConfirmThisMany(chatName), alignment: .center)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_MV_ButtonsAddHere,
                         dismissCompletion: { [weak self, weak currentVC] in
            guard let self = self, let currentVC = currentVC else { return }
            TeamTracker.trackAddGroupClick(addChatCnt: 1)
            self.bindTeamChatRequest(teamId: teamId, chatId: chatId, isDiscoverable: isDiscoverable, currentVC: currentVC, completionHandler: { _ in
                completionHandler?(String(chatId))
            })
        })
        navigator.present(dialog, from: currentVC)
        TeamTracker.trackAddGroupShow()
    }

    private func bindTeamChatRequest(teamId: Int64, chatId: Int64, isDiscoverable: Bool, currentVC: UIViewController?, completionHandler: TeamBindGroupBody.CompletionHandler?) {
        teamAPI?.bindTeamChatRequest(teamId: teamId,
                                    chatId: chatId,
                                    teamChatType: .private,
                                    addMemberChat: false,
                                    isDiscoverable: isDiscoverable)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak currentVC] _ in
           if let window = currentVC?.currentWindow() {
               UDToast.showSuccess(with: BundleI18n.LarkTeam.Project_T_GroupAdded_Toast, on: window)
           }
           TeamTracker.trackBindTeamChat(teamId: String(teamId), chatId: String(chatId))
           currentVC?.dismiss(animated: true, completion: nil)
           completionHandler?(String(chatId))
        }, onError: { error in
           if let apiError = error.underlyingError as? APIError {
               switch apiError.type {
               case .willOverflowAfterAddMember, .willOverflowAfterBindChat:
                   TeamTracker.trackTeamCreateFailPopupView()
               default:
                   break
               }
           }
           if let window = currentVC?.currentWindow() {
               UDToast.showFailure(with: BundleI18n.LarkTeam.Project_MV_UnableToAddTeamTittle, on: window, error: error)
           }
        }).disposed(by: self.disposeBag)
    }
}
