//
//  ChatSettingLabelSubModule.swift
//  LarkFeedPlugin
//
//  Created by aslan on 2022/4/19.
//
//  label item in chat setting page

import Foundation
import EENavigator
import LarkOpenChat
import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import LarkUIKit
import RxSwift
import LarkFeatureGating
import UIKit
import RustPB
import LarkContainer
import LarkFeed

final class ChatSettingLabelSubModule: ChatSettingSubModule {
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
        [ChatSettingLabelCell.lu.reuseIdentifier: ChatSettingLabelCell.self]
    }

    override func canHandle(model: ChatSettingMetaModel) -> Bool {
        guard Feed.Feature.labelEnabled else { return false }
        guard !model.chat.isCrypto else { return false }
        return true
    }

    func structItems(chat: Chat) -> [ChatSettingCellVMProtocol] {
        let items = [
            feedLabelItem(chat: chat)
        ].compactMap({ $0 })
        return items
    }

    /// 群标签
    func feedLabelItem(chat: Chat) -> ChatSettingCellVMProtocol? {
        let labels = chat.feedLabels.map { label in
            return label.name
        }
        let chatId = chat.id
        let title = BundleI18n.LarkFeedPlugin.Lark_Core_LabelTab_Title
        FeedPluginTracker.log.info("feedlog/label/chatSetting. count: \(labels.count)")
        return ChatSettingLabelModel(
            type: .feedLabel,
            cellIdentifier: ChatSettingLabelCell.lu.reuseIdentifier,
            style: .auto,
            title: title,
            labels: labels) { [weak self] _ in // 一期不支持显示机器人个数
            guard let entityId = Int64(chatId) else {
                return
            }
            self?.didTapSettingLabelItem(entityId: entityId, chat: chat)
        }
    }

    private func didTapSettingLabelItem(entityId: Int64, chat: Chat) {
        guard let vc = self.context.currentVC else { return }
        let body = AddItemInToLabelBody(feedId: entityId, infoCallback: { (mode, _) in
            switch mode {
            case .create:
                LabelTrack.trackChatSettingLabelClick(isEdit: false, chat: chat)
            case .edit:
                LabelTrack.trackChatSettingLabelClick(isEdit: true, chat: chat)
            }
        })
        userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: vc,
            prepare: { $0.modalPresentationStyle = .formSheet })
    }
}
