//
//  TeamSettingViewModel+Actions.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/16.
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
import UIKit

extension TeamSettingViewModel {
    // 退出团队
    func existTeam() {
        guard let targetVC = self.targetVC else { return }
        let userId = Int64(currentUserId) ?? 0
        let teamId = self.team.id
        let isTeamOwner = team.isTeamOwnerForMe
        let defaultChatId = String(team.defaultChatID)
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_LeaveTeam)
        // 根据不同身份配置不同的alert文案
        let onlyOwnerInTeam = team.memberCount == 1 && isTeamOwner
        let ownerContentText = onlyOwnerInTeam ? BundleI18n.LarkTeam.Project_MV_OnlyYouLeftHa :
            BundleI18n.LarkTeam.Project_T_LeaveAsTeamOwner_Subtitle
        let contentText = isTeamOwner ? ownerContentText :
            BundleI18n.LarkTeam.Project_T_OnceYouExited
        let ownerButtonText = onlyOwnerInTeam ? BundleI18n.LarkTeam.Project_T_LeaveAndDelete : BundleI18n.LarkTeam.Project_MV_TransferOwnershipButton
        let buttonText = isTeamOwner ? ownerButtonText : BundleI18n.LarkTeam.Project_T_LeaveButton
        dialog.setContent(text: contentText)
        dialog.addCancelButton(dismissCompletion: { [weak self] in
            self?.trackExistCancel()
        })
        dialog.addDestructiveButton(text: buttonText,
                                    dismissCompletion: { [weak self] in
            guard let self = self else { return }
            if !isTeamOwner {
                // 如果不是团队所有者，直接走退出逻辑
                self.trackExist()
                self.deleteTeamMember(teamId: teamId, chatterIds: [userId])
                return
            }
            if onlyOwnerInTeam {
                // 如果团队里只有一个人时（即团队所有者），走解散逻辑
                self.trackExitAndLeave()
                self.disbandTeam(teamId: teamId)
                return
            }
            // 当是团队所有人且团队成员大于1个人时，走转让逻辑和删除团队成员（自己）的逻辑
            self.trackTransfer()
            self.trackImTransferTeamOwnerView()
            let body: TeamMemberListBody
            if Feature.teamSearchEnable(userID: self.currentUserId) {
                body = TeamMemberListBody(teamId: teamId,
                                          mode: .normal,
                                          navItemType: .noneItem,
                                          isTransferTeam: true,
                                          scene: .transferOwner) { [weak self ] chatterId, name, teamMemberPage in
                    self?.transferOwner(chatterId: chatterId, name: name, teamMemberPage: teamMemberPage, userId: userId)
                }
            } else {
                body = TeamMemberListBody(teamId: teamId,
                                          mode: .normal,
                                          navItemType: .noneItem,
                                          isTransferTeam: true,
                                          scene: .normal)
            }
            if let vc = self.targetVC {
                self.navigator.push(body: body, from: vc)
            }
        })
        navigator.present(dialog, from: targetVC)
    }

    private func transferOwner(chatterId: String, name: String, teamMemberPage: UIViewController, userId: Int64) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_TransferTeamOwner)
        dialog.setContent(text: BundleI18n.LarkTeam.Project_MV_ToWhoSureTransferTeam(name))
        dialog.addCancelButton(dismissCompletion: { [weak self] in
            self?.trackTransferClick()
        })
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_MV_LeaveAndTransferButton,
                                dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.teamAPI.deleteTeamMemberRequest(teamId: self.team.id,
                                                 chatterIds: [userId],
                                                 chatIds: [],
                                                 newOwnerId: Int64(chatterId) ?? 0)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                self?.trackTransferClick(newOwnerId: chatterId)
                _ = res
                if let window = self?.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkTeam.Lark_Legacy_ChangeOwnerSuccess, on: window)
                }
                // 成功后退出当前页面并退出设置页
                self?.targetVC?.dismiss(animated: true, completion: nil)
            }, onError: { error in
                if let window = self.targetVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }
            }).disposed(by: self.disposeBag)
        })
        navigator.present(dialog, from: teamMemberPage)
    }

    // 删除团队成员
    private func deleteTeamMember(teamId: Int64,
                                  chatterIds: [Int64]) {
        self.teamAPI.deleteTeamMemberRequest(teamId: teamId,
                                             chatterIds: chatterIds,
                                             chatIds: [],
                                             newOwnerId: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.targetVC?.closeWith(animated: true)
            }, onError: { [weak self] error in
                if let window = self?.targetVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    // 解散团队
    func disbandTeam() {
        guard let targetVC = self.targetVC else { return }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_SureToDisbandNameNow(team.name))
        dialog.setContent(text: BundleI18n.LarkTeam.Project_T_GroupsUnderThisTeam)
        dialog.addCancelButton(dismissCompletion: { [weak self] in
            self?.trackDisbandCancel()
        })
        let teamId = self.team.id
        dialog.addDestructiveButton(text: BundleI18n.LarkTeam.Project_T_DisbandTeamButton,
                                    dismissCompletion: { [weak self] in
                            guard let self = self else { return }
                            self.trackDisbandClick()
                            self.disbandTeam(teamId: teamId)
        })
        navigator.present(dialog, from: targetVC)
    }

    // 调用解散团队接口
    private func disbandTeam(teamId: Int64) {
        self.teamAPI.patchTeamRequest(teamId: teamId,
                                      updateFiled: [.isDissolved],
                                      name: nil,
                                      ownerId: nil,
                                      isDissolved: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                _ = res
                if let window = self?.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkTeam.Lark_Group_DisbandedButton, on: window)
                }
                self?.targetVC?.closeWith(animated: true)
            }, onError: { [weak self] error in
                if let window = self?.targetVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    // 打开团队成员页面
    func openTeamMembesrPage(isRemove: Bool) {
        guard let targetVC = self.targetVC else { return }
        let displayMode: TeamMemberMode = isRemove ? .multiRemoveTeamMember : .normal
        let navItemType: TeamMemberNavItemType = isRemove ? .removeItem : .moreItem
        let body = TeamMemberListBody(teamId: team.id,
                                      mode: displayMode,
                                      navItemType: navItemType,
                                      isTransferTeam: false,
                                      scene: .normal)
        navigator.push(body: body, from: targetVC)
    }

    // 打开Picker页面，添加团队成员
    func openAddTeamMemberPicker() {
        guard let targetVC = self.targetVC else { return }
        guard team.isAllowAddTeamMember else {
            UDToast.showTips(with: BundleI18n.LarkTeam.Project_T_OnlyOwnerAndTheOther, on: targetVC.view)
            return
        }
        let body = TeamAddMemberBody(teamId: team.id,
                                     forceSelectedChatterIds: [team.ownerID])
        navigator.present(
            body: body,
            from: targetVC,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }
}
