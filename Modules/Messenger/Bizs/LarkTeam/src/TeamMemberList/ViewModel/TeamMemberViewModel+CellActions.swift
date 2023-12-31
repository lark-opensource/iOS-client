//
//  TeamMemberViewModel+CellActions.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/15.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkTag
import RxCocoa
import LarkModel
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import LarkListItem

// MARK: 左滑items组装及事件
extension TeamMemberViewModel {

    func getCellActionsItems(tapTask: @escaping () -> Void,
                                     indexPath: IndexPath) -> [UIContextualAction]? {
        guard scene != .transferOwner else { return nil }
        guard let item = getSlideItem(indexPath: indexPath) else { return nil }
        guard let team = team else { return nil }
        let isNotTeamOwnerForItem = !(item.memberMeta?.userRoles.isTeamOwner ?? false)
        // 前置条件：设置权限、转让团队所有者、删除。只有我是管理员才能对成员进行操作 + 不能操作owner + 不能操作自己
        guard team.isTeamManagerForMe, isNotTeamOwnerForItem, !isMeForItem(cellVM: item) else {
            return nil
        }
        let actions = [getDeleteAction(team: team, item: item, tapTask: tapTask),
                       getAssignTeamOwnerAction(team: team, item: item, tapTask: tapTask),
                       getRoleAction(team: team, item: item, tapTask: tapTask)]
            .compactMap({ $0 })
        return actions
    }

    private func getSlideItem(indexPath: IndexPath) -> TeamMemberCellVM? {
        guard canLeftSlide,
              let item = delegate?.getCellByIndexPath(indexPath)?.item as? TeamMemberCellVM else { return nil }
        return item
    }

    // 设置/移除角色
    private func getRoleAction(team: Team, item: TeamMemberCellVM, tapTask: @escaping () -> Void) -> UIContextualAction? {
        guard team.isTeamOwnerForMe, item.isChatter else {
            return nil
        }
        let isSetManager: Bool
        let roleTitle: String
        let isOnlyTeamMember = item.memberMeta?.userRoles.isOnlyTeamMember ?? true
        if isOnlyTeamMember {
            isSetManager = true
            roleTitle = BundleI18n.LarkTeam.Project_T_SetAsAdministratorRole
        } else {
            isSetManager = false
            roleTitle = BundleI18n.LarkTeam.Project_T_DisbandAdminRole
        }
        let roleAction = UIContextualAction(
            style: .destructive,
            title: roleTitle) { [weak self] (_, _, completionHandler) in
                tapTask()
                completionHandler(false)
                self?.showRoleAlert(isSetManager: isSetManager, item: item)
        }
        roleAction.backgroundColor = UIColor.ud.primaryContentDefault
        return roleAction
    }

    private func showRoleAlert(isSetManager: Bool, item: TeamMemberCellVM) {
        guard let vc = targetVC else { return }
        let dialog = UDDialog()
        let title = isSetManager ? BundleI18n.LarkTeam.Project_T_ConfirmToSetNameAsAdmin(item.realName) : BundleI18n.LarkTeam.Project_T_ConfirmToDisbandAdmin(item.realName)
        let content = isSetManager ? BundleI18n.LarkTeam.Project_T_AdminOwner : BundleI18n.LarkTeam.Project_T_FollowAdministratorSettings
        let buttonText = isSetManager ? BundleI18n.LarkTeam.Project_T_SetAdmin_Button : BundleI18n.LarkTeam.Project_T_RemoveButtonOverHere
        dialog.setTitle(text: title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.LarkTeam.Lark_Legacy_Cancel)
        dialog.addPrimaryButton(text: buttonText, dismissCompletion: { [weak self] in
            self?.setRole(isSetManager: isSetManager, role: .admin, chatterId: String(item.itemId))
        })
        navigator.present(dialog, from: vc)
    }

    private func setRole(isSetManager: Bool, role: TeamRoleType, chatterId: String) {

        let addChatterIds: [String]
        if isSetManager {
            addChatterIds = [chatterId]
        } else {
            addChatterIds = []
        }
        let deleteChatterIds: [String]
        if isSetManager {
            deleteChatterIds = []
        } else {
            deleteChatterIds = [chatterId]
        }
        teamAPI.patchTeamMembersRoleRequest(teamId: teamId,
                                            role: role,
                                            addChatterIds: addChatterIds,
                                            deleteChatterIds: deleteChatterIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let window = self.targetVC?.view.window {
                    let toast = isSetManager ? BundleI18n.LarkTeam.Project_T_RemovedFromThis : BundleI18n.LarkTeam.Project_T_AdminRemoveNow
                    UDToast.showTips(with: toast, on: window)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                if let window = self.targetVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }
            }).disposed(by: disposeBag)
    }

    // 删除团队成员
    private func getDeleteAction(team: Team, item: TeamMemberCellVM, tapTask: @escaping () -> Void) -> UIContextualAction? {
        // 权限大的角色 可以删除 权限小的成员
        guard team.userEntity.userRoles > (item.memberMeta?.userRoles ?? []) else {
            return nil
        }
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: BundleI18n.LarkTeam.Project_T_RemoveButton) { [weak self] (_, _, completionHandler) in
                tapTask()
                completionHandler(false)
                self?.delete(item: item)
        }
        deleteAction.backgroundColor = UIColor.ud.colorfulRed
        return deleteAction
    }

    private func delete(item: TeamMemberCellVM) {
        self.removeMembers([item], alertContent: BundleI18n.LarkTeam.Project_T_RemoveMember_Subtitle(1))
    }

    // 转让团队所有者身份
    private func getAssignTeamOwnerAction(team: Team, item: TeamMemberCellVM, tapTask: @escaping () -> Void) -> UIContextualAction? {
        guard team.isTeamOwnerForMe, item.isChatter else {
            return nil
        }
        // 设置为所有者人 item
        let assignTeamOwnerAction = UIContextualAction(
            style: .destructive,
            title: BundleI18n.LarkTeam.Project_T_TransferOwnershipButton) { [weak self] (_, _, completionHandler) in
                tapTask()
                completionHandler(false)
                self?.showTeamOwnerAlert(item: item)
        }
        assignTeamOwnerAction.backgroundColor = UIColor.ud.colorfulYellow
        return assignTeamOwnerAction
    }

    private func showTeamOwnerAlert(item: TeamMemberCellVM) {
        guard let vc = targetVC else { return }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_TransferTeamOwner)
        dialog.setContent(text: BundleI18n.LarkTeam.Project_MV_ToWhoSureTransferTeam(item.realName))
        dialog.addSecondaryButton(text: BundleI18n.LarkTeam.Lark_Legacy_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_ConfirmButton, dismissCompletion: { [weak self] in
            self?.setTeamOwner(newOwnerId: Int64(item.itemId) ?? 0)
        })
        navigator.present(dialog, from: vc)
    }

    private func setTeamOwner(newOwnerId: Int64) {
        teamAPI.patchTeamRequest(teamId: self.teamId,
                                 updateFiled: [.owner],
                                 name: nil,
                                 ownerId: newOwnerId,
                                 isDissolved: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let window = self.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkTeam.Project_T_OwnerAssigned_Toast, on: window)
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                if let window = self.targetVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }
            }).disposed(by: disposeBag)
    }
}
