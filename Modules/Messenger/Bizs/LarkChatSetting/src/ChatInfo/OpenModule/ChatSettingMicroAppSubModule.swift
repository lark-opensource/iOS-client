//
//  ChatSettingMicroAppSubModule.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/8/29.
//

import UIKit
import Foundation
import LarkModel
import EENavigator
import LarkOpenChat
import LarkOPInterface
import LarkBoxSetting

// 群机器人Module，通过chatSetting open能力注入
final class ChatSettingMicroAppSubModule: ChatSettingSubModule {
    override func createItems(model: ChatSettingMetaModel) {
        super.createItems(model: model)
        self.items = structItems(chat: model.chat)
    }

    override func modelDidChange(model: ChatSettingMetaModel) {
        super.modelDidChange(model: model)
        self.items = structItems(chat: model.chat)
    }

    override class func canInitialize(context: ChatSettingContext) -> Bool {
        return true
    }

    override var cellIdToTypeDic: [String: UITableViewCell.Type]? {
        [ChatInfoBotCell.lu.reuseIdentifier: ChatInfoBotCell.self]
    }

    override func canHandle(model: ChatSettingMetaModel) -> Bool {
        guard !BoxSetting.isBoxOff() else { return false }
        guard model.chat.type != .p2P, !model.chat.isCrypto, !model.chat.isPrivateMode else { return false }
        return true
    }

    func structItems(chat: Chat) -> [CommonCellItemProtocol] {
        let items = [
            groupBotItem(chat: chat)             // 群机器人
        ].compactMap({ $0 })
        return items
    }

    /// 群机器人
    func groupBotItem(chat: Chat) -> CommonCellItemProtocol? {
        if chat.isCrossWithKa || chat.isFrozen {
            return nil
        }
        let chatId = chat.id
        let isCrossTenant = chat.isCrossTenant
        return ChatInfoBotModel(
            type: .groupBot,
            cellIdentifier: ChatInfoBotCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_Legacy_BOTs,
            chatBotCount: 0) { [weak self] hasBot in // 一期不支持显示机器人个数
            guard let self, let vc = self.context.currentVC else {
                assertionFailure("missing targetVC")
                return
            }
            let body = ChatGroupBotBody(chatId: chatId, isCrossTenant: isCrossTenant, hasBot: hasBot)
            self.userResolver.navigator.push(
                body: body,
                from: vc
            )
        }
    }
}
