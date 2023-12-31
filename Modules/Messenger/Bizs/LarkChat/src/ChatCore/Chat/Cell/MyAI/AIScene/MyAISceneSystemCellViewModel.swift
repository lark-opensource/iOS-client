//
//  MyAISceneSystemCellViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2023/10/26.
//

import Foundation
import LarkModel
import LarkCore
import LarkMessageBase

/// 场景系统消息和新话题系统消息样式一样，这里直接复用即可
final class MyAISceneSystemCellViewModel: MyAIToolSystemCellViewModel<ChatContext>, HasMessage, HasCellConfig {
    var cellConfig: ChatCellConfig = ChatCellConfig()

    override public var identifier: String {
        return "myAI-scene-system"
    }

    /// 不显示插件、只显示title
    override var displayable: Bool { return false }
    override var displayTopic: Bool { return true }

    /// 避免卡顿，减少刷新逻辑
    override func listenAIExtensionConfig() {}

    /// 文本内容处理和SystemCellViewModel保持一致
    override var centerText: String {
        guard let systemContent = self.message.content as? SystemContent else { return "" }
        // 只有纯文本，没有@、点击事件，和新话题系统消息行为保持一致
        return LarkCoreUtils.parseSystemContent(systemContent, chatterForegroundColor: UIColor.clear, onLinkTap: nil).text
    }
}
