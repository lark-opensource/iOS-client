//
//  ChatFeedCardDigestVM.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/5/19.
//

import Foundation
import UIKit
import LarkOpenFeed
import LarkFeedBase
import LarkModel
import RustPB
import UniverseDesignColor
import LarkEmotion

final class ChatFeedCardDigestVM: FeedCardDigestVM {
    // VM 数据
    var digestContent: FeedCardDigestVMType

    // 表明组件类别
    var type: FeedCardComponentType {
        return .digest
    }
    let helper: FeedDigestInfoHelper
    let hasDraft: Bool
    let supportHideByEvent: Bool

    // 在子线程生成view data
    required init(feedPreview: FeedPreview, helper: FeedDigestInfoHelper) {
        self.hasDraft = !feedPreview.uiMeta.draft.content.isEmpty
        self.helper = helper
        self.digestContent = .attributedText(helper.generateDigestContent(selectedStatus: false))
        // 单聊下如果 reactions 超一屏, 则摘要需要隐藏
        self.supportHideByEvent = feedPreview.preview.chatData.chatType == .p2P
    }

    func update(selectedStatus: Bool) {
        guard hasDraft else { return }
        self.digestContent = .attributedText(helper.generateDigestContent(selectedStatus: selectedStatus))
    }

    func subscribedEventTypes() -> [FeedCardEventType] {
        return [.selected]
    }

    func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        if case .selected(let selected) = value {
            guard hasDraft else { return }
            self.digestContent = .attributedText(helper.generateDigestContent(selectedStatus: selected))
        }
    }
}
