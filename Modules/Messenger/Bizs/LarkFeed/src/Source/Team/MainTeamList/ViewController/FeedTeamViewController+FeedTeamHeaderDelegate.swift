//
//  FeedTeamViewController+FeedTeamSectionHeaderDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/16.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import LarkNavigator
import EENavigator
import RustPB
import LarkAccountInterface
import LarkMessengerInterface
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignActionPanel

extension FeedTeamViewController: FeedTeamSectionHeaderDelegate {
    func expandAction(_ header: FeedTeamSectionHeader, team: FeedTeamItemViewModel) {
        let index = self.viewModel.teamUIModel.getTeamIndex(teamItem: team.teamItem)
        self.viewModel.updateTeamExpanded(Int(team.teamItem.id), isExpanded: !team.isExpanded, section: index)
        if !team.isExpanded, team.chatModels.isEmpty {
            // 即将展开
            DispatchQueue.main.asyncAfter(deadline: .now() + TeamHeaderCons.delaySecond) {
                self.viewModel.fetchMissedChats([Int(team.teamItem.id)], dataFrom: .fetchMissedChatsForExpandTeam)
            }
        }
        FeedTracker.Team.Click.Team(teamId: String(team.teamEntity.id), isFold: team.isExpanded)
    }

    func handleAction(_ action: FilterGroupAction) {
        switch action {
        case .firstLevel(_): break
        case .secondLevel(let subFilter):
            guard subFilter.type == .team else { return }
            if case .threeBarMode(let teamId) = getSwitchModeModule() {
                var teamItem = Basic_V1_Item()
                teamItem.id = Int64(teamId)
                guard let team = self.viewModel.teamUIModel.getTeam(teamItem: teamItem),
                      let header = self.tableView.headerView(forSection: 0) as? FeedTeamSectionHeader else { return }
                moreAction(header, team: team)
            }
        }
    }

    func moreAction(_ header: FeedTeamSectionHeader, team: FeedTeamItemViewModel) {
        tryShowSheet(header: header, team: team, from: self.parent ?? self)
    }

    func tryShowSheet(header: FeedTeamSectionHeader, team: FeedTeamItemViewModel, from: UIViewController) {
        let queryMuteAtAll = viewModel.muteActionSetting.secondryTeam
        let queryAtAll = viewModel.atAllSetting.secondryTeam
        if queryMuteAtAll || queryAtAll {
            viewModel.dependency.getBatchFeedsActionState(teamID: team.teamEntity.id,
                                                    queryMuteAtAll: queryAtAll)
            .timeout(.milliseconds(viewModel.atAllSetting.timeout), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] response in
                    guard let self = self else { return }
                    let showMute = response.feedCount > 0
                    let isMute = response.hasUnmuteFeeds_p
                    var showAtAll = false
                    var muteAtAll = false
                    switch response.muteAtAllType {
                    case .unknown, .shouldNotDisplay: break
                    case .displayMuteAtAll:
                        showAtAll = true
                        muteAtAll = true
                    case .displayRemindAtAll:
                        showAtAll = true
                        muteAtAll = false
                    @unknown default: break
                    }
                    self.showSheet(header: header, team: team, from: from, showMute: showMute, isMute: isMute, showAtAll: showAtAll, muteAtAll: muteAtAll)
                }, onError: { [weak self] _ in
                    guard let self = self else { return }
                    self.showSheet(header: header, team: team, from: from, showMute: false, isMute: false, showAtAll: false, muteAtAll: false)
                }).disposed(by: disposeBag)
        } else {
            showSheet(header: header, team: team, from: from, showMute: false, isMute: false, showAtAll: false, muteAtAll: false)
        }
    }

    func showSheet(header: FeedTeamSectionHeader,
                           team: FeedTeamItemViewModel,
                           from: UIViewController,
                           showMute: Bool,
                           isMute: Bool,
                           showAtAll: Bool,
                           muteAtAll: Bool) {
        let teamId = String(team.teamEntity.id)
        FeedTracker.Team.Click.MoreTeam(teamId: teamId)
        FeedTracker.Team.MoreView(teamId: teamId)
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let teamEntity = team.teamEntity
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.viewModel.frozenDataQueue(.popoverForTeam)
        }
        actionSheet.dismissCallback = { [weak self] in
            if Display.pad {
                self?.viewModel.resumeDataQueue(.popoverForTeam)
                self?.fullReload()
            }
        }

        actionSheet.setTitle(teamEntity.name)
        let teamSettingTask = { [weak self] in
            if Display.pad {
                self?.navigator.push(body: TeamSettingBody(team: teamEntity),
                                     from: from)
            } else {
                self?.navigator.present(body: TeamSettingBody(team: teamEntity),
                                        wrap: LkNavigationController.self,
                                        from: from,
                                        prepare: {
                    $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                })
            }
            FeedTracker.Team.Click.TeamSetting(teamId: teamId)
        }
        FeedDebug.executeTask {
            actionSheet.addDefaultItem(text: "copy team", action: { [weak self] in
                guard let self = self else { return }
                self.handleDebugEvent(team: team)
            })
        }

        if viewModel.clearBadgeActionSetting.secondryTeam,
           let unreadCount = team.unreadCount, unreadCount > 0 {
            actionSheet.addDefaultItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Button, action: { [weak self, weak header] in
                guard let self = self, let header = header else { return }
                FeedTracker.Team.Click.BatchClearTeamBadge(teamId: teamId, unreadCount: team.unreadCount ?? 0, muteUnreadCount: team.muteUnreadCount ?? 0)
                self.showClearBagdeSheet(teamID: teamEntity.id, header: header, team: team)
            })
        }

        if showMute {
            let text: String
            if isMute {
                text = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_Mute_Button
            } else {
                text = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_Unmute_Button
            }
            actionSheet.addDefaultItem(text: text, action: { [weak self, weak header] in
                guard let self = self, let header = header else { return }
                FeedTracker.Team.Click.BatchMuteTeamFeeds(teamId: String(teamEntity.id), mute: isMute)
                self.showMuteSheet(teamID: teamEntity.id, header: header, isMute: isMute)
            })
        }

        if showAtAll {
            let text: String
            if muteAtAll {
                text = BundleI18n.LarkFeed.Lark_IM_MuteTagAllMentions_Button
            } else {
                text = BundleI18n.LarkFeed.Lark_IM_UnmuteTagAllMentions_Button
            }
            actionSheet.addDefaultItem(text: text, action: { [weak self, weak header] in
                guard let self = self, let header = header else { return }
                self.showAtAllSheet(teamID: teamEntity.id, header: header, muteAtAll: muteAtAll)
                FeedTracker.Team.Click.FirstOpenAtAll(teamId: String(teamEntity.id), openAtAll: muteAtAll)
            })
        }

        actionSheet.addDefaultItem(text: BundleI18n.LarkTeam.Project_T_ManageYourTeams, action: teamSettingTask)

        let isAllowAddTeamMember = team.teamEntity.isAllowAddTeamMember
        let isAllowAddTeamChat = team.teamEntity.isAllowAddTeamChat

        let addMembersText = BundleI18n.LarkFeed.Project_T_AddMembersOptions
        let addMemberTask = {
            if isAllowAddTeamMember {
                self.viewModel.dependency.openAddTeamMemberPicker(teamId: teamEntity.id,
                                                                  defaultChatID: teamEntity.defaultChatID,
                                                                  ownerID: teamEntity.ownerID)
                FeedTracker.Team.Click.AddUser(teamId: teamId)
            } else {
                UDToast.showTips(with: BundleI18n.LarkTeam.Project_T_OnlyOwnerAndTheOther, on: from.view)
            }
        }
        let addMembersItem = UDActionSheetItem(title: addMembersText, titleColor: getColor(isAllowAddTeamMember), style: .default, isEnable: true, action: addMemberTask)
        actionSheet.addItem(addMembersItem)

        let createTeamGroupText = BundleI18n.LarkTeam.Project_T_AddNewGroup_MobileMenuItem
        let createTeamGroupTask = {
            if isAllowAddTeamChat {
                self.viewModel.dependency.createTeamGroup(teamId: teamEntity.id,
                                                          ownerID: teamEntity.ownerID,
                                                          defaultChatId: teamEntity.defaultChatID,
                                                          memberCount: teamEntity.memberCount,
                                                          allowCreate: true,
                                                          isAllowAddTeamPrivateChat: team.teamEntity.isAllowAddTeamPrivateChat)
                FeedTracker.Team.Click.CreateChat(teamId: teamId)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_OnlyOwnerOtherAddGroup, on: from.view)
            }
        }
        let createTeamGroupItem = UDActionSheetItem(title: createTeamGroupText, titleColor: getColor(isAllowAddTeamChat), style: .default, isEnable: true, action: createTeamGroupTask)
        actionSheet.addItem(createTeamGroupItem)

        let addTeamGroupText = BundleI18n.LarkTeam.Project_T_AddExistingGroup_MobileMenuItem
        var addTeamGroupTask = {
            if isAllowAddTeamChat {
                self.viewModel.dependency.addTeamGroup(teamId: teamEntity.id,
                                                       teamName: teamEntity.name,
                                                       isAllowAddTeamPrivateChat: team.teamEntity.isAllowAddTeamPrivateChat)
                FeedTracker.Team.Click.AddChat(teamId: teamId)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_OnlyOwnerOtherAddGroup, on: from.view)
            }
        }
        let addTeamGroupItem = UDActionSheetItem(title: addTeamGroupText, titleColor: getColor(isAllowAddTeamChat), style: .default, isEnable: true, action: addTeamGroupTask)
        actionSheet.addItem(addTeamGroupItem)

        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Project_T_CancelButton)
        navigator.present(actionSheet, from: from)
    }

    private func getColor(_ enabled: Bool) -> UIColor {
        return enabled ? UIColor.ud.textTitle : UIColor.ud.textLinkDisabled
    }

    enum TeamHeaderCons {
        static let delaySecond: CGFloat = 0.25
    }
}

// MARK: 清理badge
extension FeedTeamViewController {
    private func showClearBagdeSheet(teamID: Int64, header: FeedTeamSectionHeader, team: FeedTeamItemViewModel) {
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.viewModel.frozenDataQueue(.popoverForTeam)
            actionSheet.dismissCallback = { [weak self] in
                guard let self = self else { return }
                self.viewModel.resumeDataQueue(.popoverForTeam)
            }
        }
        actionSheet.setTitle(BundleI18n.LarkFeed.Lark_Core_DismissAllMultipleChats_Title)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Ignore_Button, action: { [weak self] in
            FeedTracker.Team.Click.BatchClearTeamBadgeConfirm(filterType: .team, unreadCount: team.unreadCount ?? 0, muteUnreadCount: team.muteUnreadCount ?? 0)
            self?.clearBadgeRequest(teamID: teamID)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Cancel_Button)
        navigator.present(actionSheet, from: self)
    }

    private func clearBadgeRequest(teamID: Int64) {
        let taskID = UUID().uuidString
        self.viewModel.dependency.feedGuideDependency.didShowGuide(key: GuideKey.feedClearBadgeGuide.rawValue)
        self.viewModel.dependency.batchClearBadgeService.addTaskID(taskID: taskID)
        self.viewModel.dependency.clearTeamBadge(teamID: teamID, taskID: taskID)
    }
}

// MARK: 批量免打扰
extension FeedTeamViewController {
    private func showMuteSheet(teamID: Int64, header: FeedTeamSectionHeader, isMute: Bool) {
        let title: String
        let confirmText: String
        if isMute {
            title = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Title
            confirmText = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Mute_Button
        } else {
            title = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmUnmute_Title
            confirmText = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmUnmute_Unmute_Button
        }
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.viewModel.frozenDataQueue(.popoverForTeam)
            actionSheet.dismissCallback = { [weak self] in
                guard let self = self else { return }
                self.viewModel.resumeDataQueue(.popoverForTeam)
            }
        }
        actionSheet.setTitle(title)
        actionSheet.addDestructiveItem(text: confirmText, action: { [weak self] in
            guard let self = self else { return }
            FeedTracker.Team.Click.BatchMuteTeamFeedsConfirm(mute: isMute)
            self.muteRequest(teamID: teamID, mute: isMute)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Cancel_Button)
        navigator.present(actionSheet, from: self)
    }

    private func muteRequest(teamID: Int64, mute: Bool) {
        let taskID = UUID().uuidString
        self.viewModel.dependency.batchMuteFeedCardsService.addTaskID(taskID: taskID, mute: mute)
        self.viewModel.dependency.setBatchFeedsState(teamID: teamID, taskID: taskID, action: mute ? .mute : .remind)
    }
}

// MARK: 批量打开/关闭 at all
extension FeedTeamViewController {
    private func showAtAllSheet(teamID: Int64, header: FeedTeamSectionHeader, muteAtAll: Bool) {
        let title: String
        let confirmText: String
        if muteAtAll {
            title = BundleI18n.LarkFeed.Lark_IM_MuteAllMentionsInAllChats_Title
            confirmText = BundleI18n.LarkFeed.Lark_IM_MuteAllMentionsInAllChats_Mute_Button
        } else {
            title = BundleI18n.LarkFeed.Lark_IM_UnmuteAllMentionsInAllChats_Title
            confirmText = BundleI18n.LarkFeed.Lark_IM_UnmuteAllMentionsInAllChats_Unmute_Button
        }
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.viewModel.frozenDataQueue(.popoverForTeam)
            actionSheet.dismissCallback = { [weak self] in
                guard let self = self else { return }
                self.viewModel.resumeDataQueue(.popoverForTeam)
            }
        }
        actionSheet.setTitle(title)
        actionSheet.addDestructiveItem(text: confirmText, action: { [weak self] in
            guard let self = self else { return }
            self.atAllRequest(teamID: teamID, muteAtAll: muteAtAll)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Cancel_Button)
        navigator.present(actionSheet, from: self)
        FeedTracker.GroupAction.ConfirmView(openAtAll: muteAtAll, type: FilterGroupAction.secondLevel(.init(type: .team, tabId: String(teamID))))
    }

    private func atAllRequest(teamID: Int64, muteAtAll: Bool) {
        let taskID = UUID().uuidString
        self.viewModel.dependency.setBatchFeedsState(teamID: teamID, taskID: taskID, action: muteAtAll ? .muteAtAll : .remindAtAll)
        FeedTracker.GroupAction.Click.ConfirmOpenAtAll(openAtAll: muteAtAll, type: FilterGroupAction.secondLevel(.init(type: .team, tabId: String(teamID))))
    }
}

extension FeedTeamViewController {
    func showActionSheet(team: FeedTeamItemViewModel) {
        let teamId = String(team.teamEntity.id)
        FeedTracker.Team.Click.MoreTeam(teamId: teamId)
        FeedTracker.Team.MoreView(teamId: teamId)
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad)
        let teamEntity = team.teamEntity
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(teamEntity.name)
        let isAllowAddTeamChat = team.teamEntity.isAllowAddTeamChat
        let createTeamGroupText = BundleI18n.LarkFeed.Project_T_TitleCreateGroups
        let createTeamGroupTask = {
            if isAllowAddTeamChat {
                self.viewModel.dependency.createTeamGroup(teamId: teamEntity.id,
                                                          ownerID: teamEntity.ownerID,
                                                          defaultChatId: teamEntity.defaultChatID,
                                                          memberCount: teamEntity.memberCount,
                                                          allowCreate: true,
                                                          isAllowAddTeamPrivateChat: team.teamEntity.isAllowAddTeamPrivateChat)
                FeedTracker.Team.Click.CreateChat(teamId: teamId)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_OnlyOwnerOtherAddGroup, on: self.view)
            }
        }
        let createTeamGroupItem = UDActionSheetItem(title: createTeamGroupText, titleColor: getColor(isAllowAddTeamChat), style: .default, isEnable: true, action: createTeamGroupTask)
        actionSheet.addItem(createTeamGroupItem)

        let addTeamGroupText = BundleI18n.LarkTeam.Project_T_AddGroupsOptions
        var addTeamGroupTask = {
            if isAllowAddTeamChat {
                self.viewModel.dependency.addTeamGroup(teamId: teamEntity.id,
                                                       teamName: teamEntity.name,
                                                       isAllowAddTeamPrivateChat: team.teamEntity.isAllowAddTeamPrivateChat)
                FeedTracker.Team.Click.AddChat(teamId: teamId)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_OnlyOwnerOtherAddGroup, on: self.view)
            }
        }
        let addTeamGroupItem = UDActionSheetItem(title: addTeamGroupText, titleColor: getColor(isAllowAddTeamChat), style: .default, isEnable: true, action: addTeamGroupTask)
        actionSheet.addItem(addTeamGroupItem)

        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Project_T_CancelButton)
        navigator.present(actionSheet, from: self)
    }
}
