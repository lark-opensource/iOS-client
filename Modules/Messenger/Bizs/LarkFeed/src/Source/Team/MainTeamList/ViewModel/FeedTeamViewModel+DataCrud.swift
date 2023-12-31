//
//  FeedTeamViewModel+Data.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import RustPB
import LarkModel

extension FeedTeamViewModel {

    func updateTeams(teamItems: [Basic_V1_Item],
                     teamEntities: [Int: Basic_V1_Team],
                     dataFrom: DataFrom) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = dataFrom
            self.dataSourceCache.updateTeams(
                teamItems: teamItems,
                teamEntities: teamEntities)
        }
        self.addTask(task)
    }

    func updateTeamEntities(_ teamEntities: [Int: Basic_V1_Team]) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = .pushTeams
            self.dataSourceCache.updateTeamEntities(teamEntities)
        }
        self.addTask(task)
    }

    func removeTeams(_ teamItemIds: [Int],
                     dataFrom: DataFrom) {
        guard !teamItemIds.isEmpty else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = dataFrom
            self.dataSourceCache.removeTeams(teamItemIds)
        }
        addTask(task)
    }

    func removeAllTeams() {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = .pushExpired
            self.dataSourceCache.removeAllTeams()
        }
        addTask(task)
    }

    func updateChats(chatItems: [Int: [RustPB.Basic_V1_Item]],
                     chatEntities: [Int: FeedPreview],
                     dataFrom: DataFrom) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = dataFrom
            self.dataSourceCache.updateChats(
                chatItems: chatItems,
                chatEntities: chatEntities)
            if FeedSelectionEnable {
                self.dataSourceCache.updateChatSelected(self.dependency.getSelected())
            }
        }
        addTask(task)
    }

    func updateChatItems(_ chatItems: [Basic_V1_Item],
                     dataFrom: DataFrom) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = dataFrom
            self.dataSourceCache.updateChatItems(chatItems)
        }
        addTask(task)
    }

    func removeChats(_ chatItems: [Basic_V1_Item]) {
        guard !chatItems.isEmpty else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = .pushItemsRemoveFeed
            self.dataSourceCache.removeChats(chatItems)
        }
        addTask(task)
    }

    func updateTeamExpanded(_ teamItemId: Int, isExpanded: Bool, section: Int?) {
        let task = { [weak self] in
            guard let self = self else { return }
            if let index = section {
                self.dataSourceCache.dataFrom = .expand
                self.dataSourceCache.renderType = .reloadSection(section: index)
            }
            self.dataSourceCache.updateTeamExpanded(teamItemId, isExpanded: isExpanded)
        }
        addTask(task)
    }

    func updateChatSelected(_ chatEntityId: String?) {
        guard FeedSelectionEnable else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = .selected
            self.dataSourceCache.updateChatSelected(chatEntityId)
        }
        addTask(task)
    }

    func updateBadgeStyle() {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.dataFrom = .pushStyle
            self.dataSourceCache.updateBadgeStyle()
        }
        addTask(task)
    }

    func reload() {
        addTask({
            self.dataSourceCache.dataFrom = .reload
        })
    }
}
