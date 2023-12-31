//
//  TeamSetOpenGroupHandler.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2022/3/9.
//

import RxSwift
import Swinject
import Foundation
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignDialog
import UIKit
import UniverseDesignToast
import LarkNavigator

final class TeamSetOpenGroupHandler: UserTypedRouterHandler {
    private let disposeBag = DisposeBag()
    private var chatAPI: ChatAPI?
    private var teamAPI: TeamAPI?

    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamSetOpenGroupBody, req: EENavigator.Request, res: Response) throws {
        guard let page = req.from.fromViewController else { return }
        self.teamAPI = try userResolver.resolve(assert: TeamAPI.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)

        guard let teamAPI = teamAPI else { return }
        teamAPI.getTeams(chatId: String(body.chatId), teamIds: [body.teamId])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak page] res in
                guard let self = self, let page = page else { return }
                if let team = res.teams[body.teamId] {
                    self.handle(teamName: team.name, isTeamManager: team.isTeamManagerForMe, teamId: body.teamId, chatId: body.chatId, page: page)
                } else {
                    TeamMemberViewModel.logger.error("getTeamsByIds res had lost data: \(body.teamId), \( body.chatId)")
                }
            }).disposed(by: self.disposeBag)
        res.end(resource: EmptyResource())
    }

    private func handle(teamName: String, isTeamManager: Bool, teamId: Int64, chatId: Int64, page: UIViewController) {
        guard let chatAPI = chatAPI else { return }
        guard let localChat = chatAPI.getLocalChat(by: String(chatId)) else {
            // 最后弹窗引导用户设置公开群
            self.showOpenChatAlert(teamName: teamName, teamId: teamId, chatId: chatId, page: page)
            return
        }
        if !Feature.isTeamEnable(userID: self.userResolver.userID) {
            // 先判断当前操作人是否命中团队 FG，若未命中，则 toast 提示「暂不支持团队功能」
            if let window = page.view.window {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_UnableToSupport, on: window)
            }
            return
        }
        if !localChat.isAssociatedTeam {
            // 判断当前是否群组与团队关联，若不关联，则 toast 提示「本群已与该团队解除关联」
            if let window = page.view.window {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_DoneDoneGroup, on: window)
            }
            return
        }
        if localChat.isTeamOpenGroup(teamID: teamId) {
            // 判断是否是公开群类型，如果已经是公开群，则弹toast提示用户
            let dialog = UDDialog()
            dialog.setContent(text: BundleI18n.LarkTeam.Project_T_UnableToSetTitleAlreadyOpen_TEXT)
            dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_OkGotIt)
            navigator.present(dialog, from: page)
            return
        }
        if !(localChat.isGroupAdmin || localChat.ownerId == userResolver.userID) {
            // 判断是否为群干部身份，若不是群干部，则判断是否为团队干部
            if isTeamManager {
                // 如果为团队干部
                if localChat.addMemberPermission != .allMembers || localChat.messageVisibilitySetting != .allMessages {
                    // 再判断团队管理员身份+群权限
                    let dialog = UDDialog()
                    dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_CanNotSetAsOpen_Title(teamName))
                    dialog.setContent(text: BundleI18n.LarkTeam.Project_T_CanNotSetAsOpen_Text)
                    dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_OkGotIt)
                    navigator.present(dialog, from: page)
                    return
                }
            } else {
                // 再判断用户身份，如果不是群主/管理员，，则弹toast提示用户无权限
                if let window = page.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_YouAreRoleNo, on: window)
                }
                return
            }
        }
        if localChat.messageVisibilitySetting != .allMessages {
            // 然后判断chat的配置【历史消息是否可见】，如果不可见，需要弹窗引导用户打开历史消息可见的配置
            self.showMessageVisibilitAlert(teamId: teamId, chatId: chatId, page: page, successCallback: { [weak self, weak page] in
                if let page = page {
                    self?.showOpenChatAlert(teamName: teamName, teamId: teamId, chatId: chatId, page: page)
                }
            })
            return
        }
        // 最后弹窗引导用户设置公开群
        self.showOpenChatAlert(teamName: teamName, teamId: teamId, chatId: chatId, page: page)
    }

    private func showMessageVisibilitAlert(teamId: Int64, chatId: Int64, page: UIViewController, successCallback: @escaping () -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_NeedToSetMemberReadHistory_Title)
        dialog.setContent(text: BundleI18n.LarkTeam.Project_T_NeedToSetMemberReadHistory_Text)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_NeedToSetMemberReadHistory_ButtonOpen,
                         dismissCompletion: { [weak self, weak page] in
            if let page = page {
                self?.updateMessageVisibility(teamId: teamId, chatId: chatId, page: page, successCallback: successCallback)
            }
        })
        navigator.present(dialog, from: page)
    }

    private func updateMessageVisibility(teamId: Int64, chatId: Int64, page: UIViewController?, successCallback: @escaping () -> Void) {
        guard let chatAPI = chatAPI else { return }
        chatAPI.updateChat(chatId: String(chatId), messageVisibilitySetting: .allMessages)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                successCallback()
            }, onError: { [weak page] (error) in
            if let window = page?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_CantSetToast, on: window, error: error)
            }
        }).disposed(by: self.disposeBag)
    }

    private func showOpenChatAlert(teamName: String, teamId: Int64, chatId: Int64, page: UIViewController) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_SetGroupAsOpenConfirm_Title(teamName))
        dialog.setContent(text: BundleI18n.LarkTeam.Project_T_SetGroupAsOpenConfirm_Text)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_MakePublic_Button) { [weak self, weak page] in
            if let page = page {
                self?.setOpenChatRequest(teamId: teamId, chatId: chatId, page: page)
            }
        }
        navigator.present(dialog, from: page)
    }

    private func setOpenChatRequest(teamId: Int64, chatId: Int64, page: UIViewController?) {
        teamAPI?.patchTeamChatByIdRequest(teamId: teamId,
                                         chatId: chatId,
                                         teamChatType: .open,
                                         isDiscoverable: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak page] _ in
                if let window = page?.currentWindow() {
                    UDToast.showSuccess(with: BundleI18n.LarkTeam.Project_T_SettedToOpen_Toast, on: window)
                }
             }, onError: { [weak page] error in
                 if let window = page?.currentWindow() {
                     UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_CantSetToast, on: window, error: error)
                 }
             }).disposed(by: self.disposeBag)
    }
}
