//
//  TeamMemberViewModel+RustAPI.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/15.
//

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

// MARK: 列表数据接口
extension TeamMemberViewModel {
    func bind(teamId: Int64) {
        // 更新team
        pushTeams
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (pushTeams) in
                guard let self = self else { return }
                if let team = pushTeams.teams[teamId] {
                    self.team = team
                }
        }).disposed(by: disposeBag)

        teamAPI.getTeamsFromLocalAndServer(teamIds: [teamId])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                if let team = res.teams[teamId] {
                    self.team = team
                } else {
                    TeamMemberViewModel.logger.error("teamlog/getTeamsFromLocalAndServerByIds res had lost data")
                }
            }).disposed(by: disposeBag)

        // 获取列表数据
        pushTeamMembers
            .filter { $0.teamID == teamId }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.handleDataFromPush(result: response)
                if self.isInSearch {
                    if let key = self.filterKey {
                        self.statusBehavior.onNext(.viewStatus(self.searchDatas.isEmpty ? .searchNoResult(key) : .display))
                    } else {
                        self.statusBehavior.onNext(.viewStatus(self.searchDatas.isEmpty ? .empty : .display))
                    }
                } else {
                    self.statusBehavior.onNext(.viewStatus(self.datas.isEmpty ? .empty : .display))
                }
            }).disposed(by: disposeBag)

        pushItems
            .observeOn(schedulerType)
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

    func getTeamMembers(isFirst: Bool) -> Observable<[TeamMemberItem]> {
        switch scene {
        case .normal:
            return teamAPI.getTeamMembers(
                teamId: teamId,
                limit: TeamConfig.teamMemberPageCount,
                nextOffset: nextOffset)
            .observeOn(schedulerType)
            .map { [weak self] (result) -> [TeamMemberItem] in
                guard let self = self else { return [] }
                if !self.isInSearch {
                    self.nextOffset = result.nextOffset
                    self.hasMore = result.hasMore_p
                }
                self.shouldShowTipView = result.forbiddenBySecurity
                return self.addChatter(isFirst: isFirst, result: result.teamMemberInfos)
            }
        case .transferOwner:
            return teamAPI.getTeamChatter(
                teamId: teamId,
                limit: TeamConfig.teamMemberPageCount,
                nextOffset: nextOffset)
            .observeOn(schedulerType)
            .map { [weak self] (result) -> [TeamMemberItem] in
                guard let self = self else { return [] }
                if !self.isInSearch {
                    self.nextOffset = result.nextOffset
                    self.hasMore = result.hasMore_p
                }
                self.shouldShowTipView = result.forbiddenBySecurity
                // 转让需要过滤掉自己
                let members = result.teamMemberInfos.filter({ [weak self] teamMember in
                    String(teamMember.chatterInfo.chatterID) != self?.currentUserId
                })
                return self.addChatter(isFirst: isFirst, result: members)
            }
        }
    }

    func getSearchTeamMembers(id: String) -> Observable<[TeamMemberItem]> {
        let scene: Im_V1_SearchTeamMembersRequest.Scene
        if isTransferTeam {
            scene = .transferTeam
        } else {
            scene = .teamMember
        }
        return teamAPI.searchTeamMember(scene: scene,
                                        teamID: String(teamId),
                                        key: filterKey ?? "",
                                        offset: self.searchNextOffset,
                                        limit: Int32(10))
        .observeOn(schedulerType)
        .filter { [weak self] _ in
            id == self?.searchID
        }
        .map { [weak self] (response) -> [TeamMemberItem] in
            guard let self = self else { return [] }
            var response = response
            self.searchNextOffset = response.nextOffset
            self.searchHasMore = response.hasMore_p
            if case .transferTeam = scene {
                response.teamMemberInfos = response.teamMemberInfos.filter { memberInfo in
                    if memberInfo.metaType == .chatter {
                        return String(memberInfo.chatterInfo.chatterID) != self.currentUserId
                    }
                    return true
                }
            }
            return self.addSerachChatter(result: response)
        }
    }
}
