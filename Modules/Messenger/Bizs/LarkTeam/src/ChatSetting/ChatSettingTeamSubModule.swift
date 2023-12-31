//
//  ChatSettingTeamSubModule.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2022/9/15.
//

import UIKit
import Foundation
import EENavigator
import LarkOpenChat
import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import LarkUIKit
import RxSwift
import RxCocoa
import RustPB
import LarkContainer
import LarkTag
import LarkCore
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import ThreadSafeDataStructure
import UniverseDesignActionPanel
import LarkNavigator

final class ChatSettingTeamSubModule: ChatSettingSubModule {
    private var teamAPI: TeamAPI?
    private var chatAPI: ChatAPI?
    private var navigator: EENavigator.Navigatable?

    private let disposeBag = DisposeBag()
    private var teams: [Team] = []
    private var chat: Chat?
    private var userId: String = ""

    override class func canInitialize(context: ChatSettingContext) -> Bool {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: TeamUserScope.userScopeCompatibleMode) // foregroundUser
        guard Feature.isTeamEnable(userID: userResolver.userID) else { return false }
        return true
    }

    override func canHandle(model: ChatSettingMetaModel) -> Bool {
        return model.chat.isAllowBinded
    }

    override func onInitialize() {
        do {
            try setup()
        } catch {}
    }

    private func setup() throws {
        let userResolver = self.userResolver
        self.userId = userResolver.userID
        self.teamAPI = try userResolver.resolve(assert: TeamAPI.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.navigator = userResolver.navigator
    }

    override var cellIdToTypeDic: [String: UITableViewCell.Type]? {
        [
            ChatInfoTeamHeaderCell.lu.reuseIdentifier: ChatInfoTeamHeaderCell.self,
            ChatInfoTeamItemCollection.lu.reuseIdentifier: ChatInfoTeamItemCollection.self
        ]
    }

    override func createItems(model: ChatSettingMetaModel) {
        super.createItems(model: model)
        chat = model.chat
        updateItem()
    }

    override func modelDidChange(model: ChatSettingMetaModel) {
        super.modelDidChange(model: model)
        if chat?.teamEntity.boundTeamsInfo != model.chat.teamEntity.boundTeamsInfo {
            chat = model.chat
            updateItem()
        } else {
            chat = model.chat
        }
    }

    func updateItem() {
        guard let chat = self.chat else { return }
        let teamsID = chat.teamEntity.boundTeamsInfo.compactMap { $0.teamID }
        guard chat.isTeamChat else {
            self.items = []
            self.context.reload?()
            TeamMemberViewModel.logger.error("teamlog/chatsetting/error. chatId: \(chat.id) teamsId: \(teamsID) teamChatTypes")
            return
        }
        TeamMemberViewModel.logger.info("teamlog/chatsetting/success. chatId: \(chat.id) teamsId: \(teamsID)")

        teamAPI?.getTeams(chatId: chat.id, teamIds: teamsID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.teams = res.teams.values.sorted(by: { res.teamsNameWeight[$0.id] ?? "" < res.teamsNameWeight[$1.id] ?? "" })
                self.items = self.getItems()
                self.context.reload?()
            }).disposed(by: self.disposeBag)
    }

    func getItems() -> [ChatSettingCellVMProtocol] {
        guard let chat = self.chat else { return [] }
        guard chat.isTeamChat && !self.teams.isEmpty else {
            return []
        }
        return [headerItem(chat: chat),
                teamItem(chat: chat)
        ].compactMap({ $0 })
    }
}

// MARK: item方法
extension ChatSettingTeamSubModule {
    func headerItem(chat: LarkModel.Chat) -> ChatSettingCellVMProtocol? {
        guard !teams.isEmpty else { return nil }
        return ChatInfoTeamHeaderCellModel(
            type: .unfastenTeamHeader,
            cellIdentifier: ChatInfoTeamHeaderCell.lu.reuseIdentifier,
            style: .none,
            title: BundleI18n.LarkTeam.Project_T_GroupLinkedTeam)
    }

    func teamItem(chat: LarkModel.Chat) -> ChatSettingCellVMProtocol {
        var chatInfoTeamCells: [ChatInfoTeamItem] = []
        for team in teams {
            let subTitle: String
            if chat.isTeamOpenGroup(teamID: team.id) {
                subTitle = BundleI18n.LarkTeam.Project_T_GroupSettings_PublicToTeam_Text
            } else if chat.isTeamPrivateGroup(teamID: team.id) {
                subTitle = BundleI18n.LarkTeam.Project_T_GroupSettings_PrivateToTeam_Text
            } else {
                subTitle = ""
            }
            chatInfoTeamCells.append(ChatInfoTeamItem(
                type: .unfastenTeamItem,
                title: team.name,
                subTitle: subTitle,
                entityIdForAvatar: String(team.id),
                avatarKey: team.avatarKey,
                showSubTitle: !subTitle.isEmpty,
                showMore: chat.isAllowUnbindTeam(team, userId: userId),
                chatId: chat.id,
                unbindHandler: { [weak self] _ in
                    self?.showTeamUnbindAlert(chat: chat, team: team)
                },
                tapHandler: { [weak self] (_, cell: UIView) in
                    guard let self = self else { return }
                    if Feature.teamChatPrivacy(userID: self.userId) {
                        self.showNewTeamChatActionSheet(cell: cell, chat: chat, team: team)
                    } else {
                        self.showTeamChatActionSheet(cell: cell, chat: chat, team: team)
                    }
                }))
        }
        return ChatInfoTeamItemsCellModel(type: .unfastenTeamItem,
                                          cellIdentifier: ChatInfoTeamItemCollection.lu.reuseIdentifier,
                                          style: .none,
                                          teamCells: chatInfoTeamCells)
    }
}

// MARK: - 解绑逻辑
extension ChatSettingTeamSubModule {
    private func showTeamChatActionSheet(cell: UIView, chat: LarkModel.Chat, team: Team) {
        guard let vc = self.context.currentVC else { return }
        let popSource = UDActionSheetSource(sourceView: cell,
                                           sourceRect: cell.bounds,
                                           arrowDirection: .up)
        let sheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))
        let isAllowSetOpenGroup = (chat.isHasGroupAuthorized(userId: userId) || team.isTeamManagerForMe) && chat.isTeamPrivateGroup(teamID: team.id)
        if isAllowSetOpenGroup {
            let teamName = team.name
            let teamId = team.id
            let chatId = Int64(chat.id) ?? 0
            if chat.isCrossTenant {
                let actionSheetItem = UDActionSheetItem(title: BundleI18n.LarkTeam.Project_T_OpenToTeam,
                                                        titleColor: UIColor.ud.textDisabled,
                                                        action: { [weak vc] in
                    guard let page = vc else { return }
                    UDToast.showWarning(with: BundleI18n.LarkTeam.Project_T_ExternalGroupCannotBePublic_hover, on: page.view)
                })
                sheet.addItem(actionSheetItem)
            } else {
                sheet.addDefaultItem(text: BundleI18n.LarkTeam.Project_T_OpenToTeam) { [weak self, weak vc] in
                    guard let self = self, let page = vc else { return }
                    self.setOpenChat(teamName: teamName, teamId: teamId, chatId: chatId, page: page, chat: chat, team: team)
                }
            }
        }
        if chat.isAllowUnbindTeam(team, userId: userId) {
            sheet.addDestructiveItem(text: BundleI18n.LarkTeam.Project_MV_UnlinkButton) { [weak self] in
                self?.showTeamUnbindAlert(chat: chat, team: team)
            }
        }
        sheet.setCancelItem(text: BundleI18n.LarkTeam.Lark_Legacy_Cancel)
        self.navigator?.present(sheet, from: vc)
    }

    private func showNewTeamChatActionSheet(cell: UIView, chat: LarkModel.Chat, team: Team) {
        guard let vc = self.context.currentVC else { return }
        let popSource = UDActionSheetSource(sourceView: cell,
                                           sourceRect: cell.bounds,
                                           arrowDirection: .up)
        let sheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))
        let ownerAuthority = (chat.isHasGroupAuthorized(userId: userId) || team.isTeamManagerForMe)
        if ownerAuthority {
            sheet.addDefaultItem(text: BundleI18n.LarkTeam.Project_T_GroupSettings_PrivacySettings_Button) { [weak self, weak vc] in
                guard let self = self, let page = vc else { return }
                let messageVisibility: Bool
                if case .allMessages = chat.messageVisibilitySetting {
                    messageVisibility = true
                } else {
                    messageVisibility = false
                }
                let body = TeamGroupPrivacyBody(teamId: team.id,
                                                chatId: chat.id,
                                                teamName: team.name,
                                                isMessageVisible: chat.isTeamOpenGroup(teamID: team.id),
                                                ownerAuthority: ownerAuthority,
                                                isCrossTenant: chat.isCrossTenant,
                                                discoverable: chat.isTeamDiscoverableGroup(teamID: team.id),
                                                messageVisibility: messageVisibility)
                self.navigator?.push(body: body, from: page)
            }
        }

        if chat.isAllowUnbindTeam(team, userId: userId) {
            sheet.addDestructiveItem(text: BundleI18n.LarkTeam.Project_MV_UnlinkButton) { [weak self] in
                self?.showTeamUnbindAlert(chat: chat, team: team)
            }
        }
        sheet.setCancelItem(text: BundleI18n.LarkTeam.Lark_Legacy_Cancel)
        self.navigator?.present(sheet, from: vc)
    }

    private func showTeamUnbindAlert(chat: LarkModel.Chat, team: Team) {
        guard let vc = self.context.currentVC else { return }
        imGroupManageClickTrack(clickType: "unbundling", target: "im_group_unbundling_view", chat: chat)
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_ToastSureToUnlink)
        dialog.setContent(text: BundleI18n.LarkTeam.Project_MV_TeamGroupUnlinkRelation)
        dialog.addCancelButton(dismissCompletion: { [weak self] in
            self?.imGroupUnbundlingCancelTrack(chat: chat, team: team)
        })
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_MV_UnlinkButton) { [weak self] in
            self?.unbindTeamChatRequest(chat: chat, team: team)
        }
        self.navigator?.present(dialog, from: vc)
     }

    private func unbindTeamChatRequest(chat: LarkModel.Chat, team: Team) {
        self.imGroupUnbundlingClickTrack(chat: chat, team: team)
        self.teamAPI?.unbindTeamChatRequest(teamId: team.id, chatId: Int64(chat.id) ?? 0)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let window = self.context.currentVC?.currentWindow() {
                    UDToast.showTips(with: BundleI18n.LarkTeam.Project_T_UnlinkDone_Toast, on: window)
                }
             }, onError: { [weak self] error in
                 if let window = self?.context.currentVC?.currentWindow() {
                     UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_CantSetToast,
                                         on: window,
                                         error: error)
                 }
             }).disposed(by: self.disposeBag)
    }
}

// MARK: - 设置公开群逻辑
extension ChatSettingTeamSubModule {
    private func setOpenChat(teamName: String, teamId: Int64, chatId: Int64, page: UIViewController, chat: LarkModel.Chat, team: Team) {
        // 判断是否为群干部身份，若不是群干部，则判断是否为团队干部,如果为团队干部
        if !chat.isHasGroupAuthorized(userId: userId), team.isTeamManagerForMe, chat.addMemberPermission != .allMembers || chat.messageVisibilitySetting != .allMessages {
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_CanNotSetAsOpen_Title(teamName))
            dialog.setContent(text: BundleI18n.LarkTeam.Project_T_CanNotSetAsOpen_Text)
            dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_OkGotIt)
            self.navigator?.present(dialog, from: page)
            return
        }
        guard chat.messageVisibilitySetting == .allMessages else {
            // 然后判断chat的配置【历史消息是否可见】，如果不可见，需要弹窗引导用户打开历史消息可见的配置
            showMessageVisibilitAlert(teamId: teamId, chatId: chatId, page: page, successCallback: { [weak self, weak page] in
                if let page = page {
                    self?.showOpenChatAlert(teamName: teamName, teamId: teamId, chatId: chatId, page: page)
                }
            })
            return
        }
        showOpenChatAlert(teamName: teamName, teamId: teamId, chatId: chatId, page: page)
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
        self.navigator?.present(dialog, from: page)
    }

    private func updateMessageVisibility(teamId: Int64, chatId: Int64, page: UIViewController?, successCallback: @escaping () -> Void) {
        chatAPI?.updateChat(chatId: String(chatId), messageVisibilitySetting: .allMessages)
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
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_ThisIsSetButton) { [weak self, weak page] in
            if let page = page {
                self?.setOpenChatRequest(teamId: teamId, chatId: chatId, page: page)
            }
        }
        self.navigator?.present(dialog, from: page)
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
                     UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_CantSetToast, on: window, error: error.transformToAPIError())
                 }
             }).disposed(by: self.disposeBag)
    }
}

// MARK: Tracker
extension ChatSettingTeamSubModule {
    private func imGroupUnbundlingCancelTrack(chat: LarkModel.Chat, team: Team) {
        TeamTracker.imGroupUnbundlingClickTrack(click: "cancel",
                                                          chatID: chat.id,
                                                          teamID: "\(team.id)",
                                                          target: "none")
    }

    private func imGroupUnbundlingClickTrack(chat: LarkModel.Chat, team: Team) {
        TeamTracker.imGroupUnbundlingClickTrack(click: "unbundling",
                                                          chatID: chat.id,
                                                          teamID: "\(team.id)",
                                                          target: "none")
    }

    func imGroupManageClickTrack(clickType: String, target: String = "none", chat: LarkModel.Chat) {
        TeamTracker.imGroupManageClick(
            chat: chat,
            myUserId: userId,
            isOwner: chat.isGroupOwner(userId: userId),
            isAdmin: chat.isGroupAdmin,
            clickType: clickType,
            extra: ["target": target])
    }
}
