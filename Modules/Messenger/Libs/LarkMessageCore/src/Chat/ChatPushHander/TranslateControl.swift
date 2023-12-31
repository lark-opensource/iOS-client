//
//  PushHandler+Translate.swift
//  LarkMessageCore
//
//  Created by MJXin on 2022/7/11.
//

import Foundation
import RustPB
import LarkModel
import LarkFeatureGating
import LarkSearchCore

// 消息卡片翻译控制 majiaxin.jx
// 同一个 FG 其他封装位置: LarkMessageBase: MessageCellViewModel
public final class TranslateControl {
    /// 是否可翻译的消息卡片类型
    public static func isTranslatableMessageCardType(_ message: Message) -> Bool {
        guard message.isTranslatableMessageCardType(), let content = message.content as? CardContent else { return false }
        guard LarkFeatureGating.shared.getFeatureBoolValue(for: .messageCardTranslate) else { return false }
        return content.enableTrabslate || LarkFeatureGating.shared.getFeatureBoolValue(for: .messageCardForceTranslate)
    }
    /// 是否可翻译的消息卡片类型
    public static func isTranslatableMessageCardType(_ message: Basic_V1_Message) -> Bool {
        guard message.isTranslatableMessageCardType() else { return false }
        guard LarkFeatureGating.shared.getFeatureBoolValue(for: .messageCardTranslate) else { return false }
        return message.content.cardContent.extraInfo.customConfig.enableTranslate
            || LarkFeatureGating.shared.getFeatureBoolValue(for: .messageCardForceTranslate)
    }
    /// 是否是可翻译的语音类型
    public static func isTranslatableAudioMessage(_ message: Message) -> Bool {
        guard message.type == .audio else { return false }
        guard AIFeatureGating.audioMessageTranslation.isEnabled else { return false }
        guard let audioContent = message.content as? AudioContent else { return false }
        return !audioContent.hideVoice2Text
    }

    public static func isTranslatableAudioMessage(_ message: Basic_V1_Message) -> Bool {
        guard message.type == .audio else { return false }
        guard AIFeatureGating.audioMessageTranslation.isEnabled else { return false }
        return !message.content.hideVoice2Text
    }
}
