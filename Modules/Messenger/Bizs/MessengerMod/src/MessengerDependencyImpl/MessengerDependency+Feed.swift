//
//  MessengerMockDependency+Feed.swift
//  LarkMessenger
//
//  Created by 袁平 on 2020/6/28.
//

import Foundation
import EENavigator
import LarkFeed
import LarkContainer
import RxSwift
import Swinject
import LarkMinimumMode
import LarkInteraction
#if LarkCore
import LarkCore
import CryptoKit
import LarkBaseKeyboard
#endif

public final class FeedDependencyImpl: FeedDependency {
    @ScopedInjectedLazy private var minimumModeInterface: MinimumModeInterface?

    public let userResolver: UserResolver

    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    // MARK: LarkCore
    /// chat 支持的 item 类型
    public var supportTypes: [DropItemType] {
        var supportTypes: [DropItemType] = []
        #if LarkCore
        supportTypes = ChatInteractionKit.supportTypes
        #endif
        return supportTypes
    }

    /// 展示草稿
    public func getDraftFromLarkCoreModel(content: String) -> String {
        #if LarkCore
        if let text = TextDraftModel.getContentPreviewFromDraft(content) {
            return text
        } else {
            /// 有标题优先展示标题
            let model = PostDraftModel.parse(content)
            var text = model.title
            if text.isEmpty {
                text = RichTextTransformKit.transformDraftToText(content: model.content) ?? ""
            }
            return text
        }
        #endif
        return ""
    }

    /// 设置临时的 DropItems
    public func setDropItemsFromLarkCoreModel(chatID: String, items: [DropItemValue]) {
        #if LarkCore
        ChatInteractionKit.setDropItems(chatID: chatID, items: items)
        #endif
    }

    // MARK: LarkMinimumMode
    /// 展示切换至基本功能模式提示(内部会去判断是否需要执行展示逻辑) show：具体的展示逻辑
    public func showMinimumModeChangeTip(show: () -> Void) {
        self.minimumModeInterface?.showMinimumModeChangeTip(show: show)
    }
}
