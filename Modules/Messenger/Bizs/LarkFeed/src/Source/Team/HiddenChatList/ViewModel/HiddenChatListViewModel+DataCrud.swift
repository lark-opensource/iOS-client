//
//  HiddenChatListViewModel+Data.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import RustPB
import LarkModel

extension HiddenChatListViewModel {
    func updateChats(chatItems: [Basic_V1_Item],
                     chatEntities: [Int: FeedPreview]) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.updateChats(chatItems: chatItems, chatEntities: chatEntities)
            if FeedSelectionEnable {
                self.dataSourceCache.updateChatSelected(self.dependency.getSelected())
            }
        }
        addTask(task)
    }

    func updateChatItems(_ chatItems: [RustPB.Basic_V1_Item]) {
        guard !chatItems.isEmpty else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.updateChatItems(chatItems)
        }
        addTask(task)
    }

    func removeChats(_ chatItemId: [Int]) {
        guard !chatItemId.isEmpty else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.removeChats(chatItemId)
        }
        addTask(task)
    }

    func removeAll() {
        let task = { [weak self] in
            guard let self = self else { return }
            guard !self.dataSourceCache.chatModels.isEmpty else { return }
            self.dataSourceCache.removeAllChats()
        }
        addTask(task)
    }

    func updateChatSelected(_ chatEntityId: String?) {
        guard FeedSelectionEnable else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.updateChatSelected(chatEntityId)
        }
        addTask(task)
    }

    func updateBadgeStyle() {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataSourceCache.updateBadgeStyle()
        }
        addTask(task)
    }

    func reload() {
        addTask({})
    }
}
