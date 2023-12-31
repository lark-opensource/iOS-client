//
//  TeamSettingViewModel+Data.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/16.
//

import UIKit
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

// cellViewModel 组装的扩展
extension TeamSettingViewModel {
    func startToObserve() {
        let teamId = team.id
        // 根据id拉取team列表
        getTeamMembers()

        pushTeams
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                if let team = push.teams[teamId] {
                    self.team = team
                    self.fireRefresh()
                    self.getTeamMembers()
                }
            }).disposed(by: self.disposeBag)

        pushItems
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                if response.action == .delete {
                    for item in response.items {
                        if item.entityType == .team && item.id == teamId {
                            DispatchQueue.main.async {
                                self.targetVC?.closeWith(animated: true)
                            }
                            break
                        }
                    }
                }
            }).disposed(by: disposeBag)
    }

    func fireRefresh() {
        self.items = self.structureItems()
        self._reloadData.onNext(())
    }

    func structureItems() -> TeamSectionDatasource {
        let sections = [
            self.getTeamInfoSection(),
            self.getTeamEventsSection(),
            self.getTeamActionSection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }

    private func getTeamInfoSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            getTeamInfoCellItem(),
            getTeamMemberItem()
        ].compactMap({ $0 }))
    }

    private func getTeamEventsSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            getTeamEvents()
        ].compactMap({ $0 }))
    }

    private func getTeamActionSection() -> TeamSectionModel {
        return TeamSectionModel(items: [
            getTeamLeaveItem(),
            getTeamDisbandItem()
        ].compactMap({ $0 }))
    }

    // 团队信息
    private func getTeamInfoCellItem() -> TeamCellViewModelProtocol? {
        let editText = NSAttributedString(string: BundleI18n.LarkTeam.Project_MV_EditTeamInfo, attributes: [.foregroundColor: UIColor.ud.textLinkNormal])
        let subTitle: NSAttributedString = team.isTeamManagerForMe && team.description_p.isEmpty ? editText : NSAttributedString(string: team.description_p)
        return TeamInfoCellViewModel(type: .groupMode,
                                     cellIdentifier: TeamInfoCell.lu.reuseIdentifier,
                                     style: .half,
                                     isShowLeftAvatar: true,
                                     isShowDescription: true,
                                     isShowArrow: true,
                                     title: team.name,
                                     subTitle: subTitle,
                                     leftAvatarKey: team.avatarKey,
                                     avatarId: String(team.id)) { [weak self] _ in
            guard let self = self, let targetVC = self.targetVC else { return }
            self.trackEditInfoClick()
            let body = TeamInfoBody(team: self.team)
            self.navigator.push(body: body, from: targetVC)
        }
    }

    // 团队成员
    private func getTeamMemberItem() -> TeamCellViewModelProtocol? {
        let teamID = team.id
        return TeamMemberCellViewModel(type: .member,
                                       cellIdentifier: TeamMemberCell.lu.reuseIdentifier,
                                       style: .full,
                                       title: BundleI18n.LarkTeam.Project_T_SubtitleTeamMembers,
                                       descriptionText: "",
                                       memberList: memberList,
                                       isShowMember: true,
                                       isShowAddButton: true,
                                       isShowDeleteButton: team.isTeamManagerForMe && memberList.count > 1,
                                       countText: String(team.memberCount),
                                       tapHandler: { [weak self] _ in
            self?.trackTeamMember(teamID: String(teamID))
            self?.openTeamMembesrPage(isRemove: false)
        },
                                       addNewMember: { [weak self] _ in
            self?.trackTeamMember(teamID: String(teamID))
            self?.trackAddMemberClick()
            self?.openAddTeamMemberPicker()
        },
                                       deleteMember: { [weak self] _ in
            self?.trackTeamMember(teamID: String(teamID))
            self?.trackRemoveMemberClick()
            self?.openTeamMembesrPage(isRemove: true)
        },
                                       selectedMember: { _ in })
    }

    // 退出团队
    private func getTeamLeaveItem() -> TeamCellViewModelProtocol? {
        return TeamTapCellViewModel(type: .leaveTeam,
                             cellIdentifier: TeamTapCell.lu.reuseIdentifier,
                             style: .full,
                             attributedText: NSAttributedString(string: BundleI18n.LarkTeam.Project_T_ExitTeamNow,
                                                                attributes: [.foregroundColor: UIColor.ud.colorfulRed,
                                                                             .font: UIFont.systemFont(ofSize: 16)
                                                                ])) { [weak self] _ in
            self?.trackExistTeamButtonClick()
            self?.trackExistView()
            self?.existTeam()
        }
    }

    // 解散团队
    private func getTeamDisbandItem() -> TeamCellViewModelProtocol? {
        guard team.isTeamOwnerForMe else { return nil }
        return TeamTapCellViewModel(type: .disbandTeam,
                               cellIdentifier: TeamTapCell.lu.reuseIdentifier,
                               style: .full,
                               attributedText: NSAttributedString(string: BundleI18n.LarkTeam.Project_T_DisbandTeamButton,
                                                                  attributes: [.foregroundColor: UIColor.ud.colorfulRed,
                                                                               .font: UIFont.systemFont(ofSize: 16)
                                                                  ])) { [weak self] _ in
            self?.trackDisbandTeamButtonClick()
            self?.trackDisbandView()
            self?.disbandTeam()
        }
    }

    // 团队动态
    private func getTeamEvents() -> TeamCellViewModelProtocol? {
        trackTeamEvent(teamID: String(self.team.id))
        return TeamDescriptionCellViewModel(type: .teamEvent,
                                                    cellIdentifier: TeamDescriptionCell.lu.reuseIdentifier,
                                                    style: .full,
                                                    title: BundleI18n.LarkTeam.Project_T_Updates_Title,
                                                    description: "") { [weak self] _ in
            guard let self = self, let targetVC = self.targetVC else { return }
            let body = TeamEventBody(teamID: self.team.id)
            self.navigator.push(body: body, from: targetVC)
        }
    }

    func getTeamMembers() {
        let getTeamMembersOB = teamAPI.getTeamMembers(
            teamId: team.id,
            limit: teamMembersMaxCount,
            nextOffset: nil)

        getTeamMembersOB
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                var memberList = result.teamMemberInfos.compactMap { member -> TeamMemberHorizItem? in
                    let key: String
                    if member.metaType == .chat {
                        key = member.chatInfo.chat.avatarKey
                    } else if member.metaType == .chatter {
                        key = member.chatterInfo.chatter.avatarKey
                    } else {
                        return nil
                    }
                    return TeamMemberHorizItem(memberId: String(member.memberID), avatarKey: key, order: member.orderedWeight)
                }
                memberList.sort(by: {
                    ($0.order < $1.order)
                })
                self.memberList = memberList
                self.fireRefresh()
            }).disposed(by: disposeBag)
    }
}
