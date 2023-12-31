//
//  TeamMemberViewModel+DataHandle.swift
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

// MARK: 数据处理
extension TeamMemberViewModel {
    // 解析返回数据
    func addChatter(isFirst: Bool, result: [Basic_V1_TeamMemberInfo]) -> [TeamMemberCellVM] {
        var items = result.compactMap { wrapper(member: $0) }
        if isFirst {
            items.sort(by: { $0.order < $1.order })
            reSort(items)
            self.datas = items
        } else {
            guard let items = merge(currentData: self.datas, appendData: items) as? [TeamMemberCellVM] else {
                return items
            }
            self.datas = items
        }
        return items
    }

    func addSerachChatter(result: RustPB.Im_V1_SearchTeamMembersResponse) -> [TeamMemberCellVM] {
        let items = self.searchDatas + result.teamMemberInfos.compactMap { searchWrapper(member: $0, joinedChats: result.joinedChats) }
        guard let items = items as? [TeamMemberCellVM] else { return [] }
        reSortSearchResult(items)
        self.searchDatas = items
        return items
    }

    func updateSearchResult(currentData: [TeamMemberItem], newData: [TeamMemberItem]) -> [TeamMemberItem] {
        guard var currentItems = currentData as? [TeamMemberCellVM] else { return currentData }
        newData.forEach { item in
            guard let item = item as? TeamMemberCellVM else { return }
            if let index = getSearchIndex(item.itemId), index < currentItems.count {
                let description = currentItems[index].itemDescription
                currentItems[index] = item
                currentItems[index].itemDescription = description
            }
        }
        currentItems.sort(by: { $0.order < $1.order })
        reSortSearchResult(currentItems)
        return currentItems
    }

    func addOrUpdateChatter(_ result: PushTeamMembers) {
        let items = result.teamMemberInfos.compactMap { wrapper(member: $0) }
        self.datas = merge(currentData: self.datas, appendData: items)
        // 如果在搜索状态下，还需要更新搜索列表
        if isInSearch {
            let items = result.teamMemberInfos.compactMap { wrapper(member: $0) }
            self.searchDatas = updateSearchResult(currentData: self.searchDatas, newData: items)
        }
    }

    func handleDataFromPush(result: PushTeamMembers) {
        switch result.type {
        case .addChatter: addOrUpdateChatter(result)
        case .deleteChatter: removeMember(ids: result.teamMemberInfos.map { String($0.memberID) })
        case .updateChatter: addOrUpdateChatter(result)
        @unknown default:
            break
        }
    }

    func removeMember(ids: [String]) {
        if isInSearch {
            guard var newItems = self.searchDatas as? [TeamMemberCellVM] else { return }
            ids.compactMap({ getSearchIndex($0) }).sorted(by: { $0 > $1 }).forEach { index in
                if index < newItems.count {
                    newItems.remove(at: index)
                }
            }
            reSortSearchResult(newItems)
            self.searchDatas = newItems
        }
        guard var newItems = self.datas as? [TeamMemberCellVM] else { return }
        ids.compactMap({ getIndex($0) }).sorted(by: { $0 > $1 }).forEach { index in
            newItems.remove(at: index)
        }
        newItems.sort(by: { $0.order < $1.order })
        reSort(newItems)
        self.datas = newItems
    }

    // 批量删除事件
    func removeMembers(_ selectedItems: [TeamMemberItem], alertContent: String) {
        guard let vc = self.targetVC else { return }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_RemoveGroupMembers)
        dialog.setContent(text: alertContent)
        dialog.addCancelButton()
        var chatterIds: [String] = []
        var chatIds: [String] = []
        selectedItems.forEach { item in
            if item.isChatter {
                chatterIds.append(item.itemId)
            } else {
                chatIds.append(item.itemId)
            }
        }
        dialog.addDestructiveButton(text: BundleI18n.LarkTeam.Project_T_RemoveMember_PopupButton,
                                    dismissCompletion: { [weak self] in
            self?.removeMembers(chatterIds: chatterIds, chatIds: chatIds)
        })
        navigator.present(dialog, from: vc)
    }

    func removeMembers(chatterIds: [String], chatIds: [String]) {
        teamAPI.deleteTeamMemberRequest(teamId: self.teamId,
                                        chatterIds: chatterIds.compactMap({ Int64($0) }),
                                        chatIds: chatIds.compactMap({ Int64($0) }),
                                        newOwnerId: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let window = self.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkTeam.Project_T_MemberRemoved_Toast, on: window)
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                if let window = self.targetVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }
            }).disposed(by: disposeBag)
    }

    func merge(currentData: [TeamMemberItem], appendData: [TeamMemberItem]) -> [TeamMemberItem] {
        guard var currentItems = currentData as? [TeamMemberCellVM] else { return currentData }
        appendData.forEach { item in
            guard let item = item as? TeamMemberCellVM else { return }
            if let index = getIndex(item.itemId), index < currentItems.count {
                currentItems[index] = item
            } else {
                currentItems.append(item)
            }
        }
        currentItems.sort(by: { $0.order < $1.order })
        reSort(currentItems)
        return currentItems
    }

    /// 包装成 TeamMemberCellVM
    private func wrapper(member: Basic_V1_TeamMemberInfo) -> TeamMemberCellVM? {
        var item = TeamMemberCellVM(memberID: member.memberID,
                                    chatInfo: member.chatInfo,
                                    chatterInfo: member.chatterInfo,
                                    orderedWeight: member.orderedWeight,
                                    metaType: member.metaType,
                                    itemCellClass: TeamMemberListCell.self,
                                    userResolver: userResolver)
        guard !item.itemName.isEmpty else { return nil }
        // 多选模式下：移除团队成员的判断条件
        if let team = self.team {
            let meRole = team.userEntity.userRoles
            let itemRole = item.memberMeta?.userRoles ?? []
            if meRole < itemRole || meRole == itemRole {
                item.isSelectedable = false
            }
        }
        // 添加群成员的判断条件
        return item
    }

    private func searchWrapper(member: Basic_V1_SearchTeamMemberInfo,
                               joinedChats: [Int64: Basic_V1_Chat]) -> TeamMemberCellVM? {
        let metaType: Basic_V1_TeamMemberInfo.MetaType
        switch member.metaType {
        case .chat:
            metaType = .chat
        case .chatter:
            metaType = .chatter
        case .unknown:
            metaType = .unknown
        @unknown default:
            metaType = .unknown
        }
        var names: String = BundleI18n.LarkTeam.Project_T_GroupNameFrom
        for i in 0 ..< member.joinedChatIds.count {
            if let chat = joinedChats[member.joinedChatIds[i]] {
                names.append(chat.name)
                if i != member.joinedChatIds.count - 1 {
                    names.append(BundleI18n.LarkTeam.Project_T_GroupNameComma)
                }
            }
        }
        let item = TeamMemberCellVM(memberID: member.memberID,
                                    chatInfo: member.chatInfo,
                                    chatterInfo: member.chatterInfo,
                                    metaType: metaType,
                                    itemDescription: member.joinedChatIds.isEmpty ? nil : names,
                                    itemCellClass: TeamMemberListCell.self,
                                    userResolver: userResolver)
        return item
    }
}

// MARK: 排序
extension TeamMemberViewModel {
    private func reSort(_ items: [TeamMemberItem]) {
        indexMap.removeAll()
        for (i, item) in items.enumerated() {
            indexMap[item.itemId] = i
        }
    }

    private func reSortSearchResult(_ items: [TeamMemberItem]) {
        searchIndexMap.removeAll()
        for (i, item) in items.enumerated() {
            searchIndexMap[item.itemId] = i
        }
    }

    private func getIndex(_ id: String) -> Int? {
        return indexMap[id]
    }

    private func getSearchIndex(_ id: String) -> Int? {
        return searchIndexMap[id]
    }
}
