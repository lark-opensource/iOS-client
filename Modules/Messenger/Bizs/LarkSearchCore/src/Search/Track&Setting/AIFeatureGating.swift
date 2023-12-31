//
//  AIFeatureGating.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/2/26.
//

import Foundation
import LarkFeatureGating
import LarkContainer
import LarkSetting

/**
 此类汇集了AI模块的所有FG，并且提供 DEBUG 环境 mock FG的功能
 */
public enum AIFeatureGating: String, CaseIterable {

    /// 是否开启Smart Compose 功能，此FG在LarkMine的Setting模块有引用，为避免不必要的依赖，LarkMine中直接引用的LarkFeatureGating
    case smartCompose = "suite.ai.smart_compose.mobile.enabled"

    case eewQueryMenu = "abbreviation.chat.menu.enable" // 是否在消息menu对实体词高亮
    /// 实体词卡片是否展开
    case eewCardExpand = "ai.abbr.mobile_card_expand"
    /// 实体词卡片是否启用V2接口
    case eewCardV2 = "ai.abbr.mobile.card_v2"

    /// 是否开启智能纠错
    case smartCorrect = "ai.smartcorrect.message"

    case lingoHighlightOnKeyboard = "lingo.imeditor.recall"
    // 翻译
    /// 是否启用翻译反馈
    case translateFeedback = "message.translation.feedback"
    /// 是否启用网页翻译
    case webTranslate = "translate.webpage.enable.ios"
    /// 是否启用划词翻译
    case selectTranslate = "lark.ai.select_translate"
    /// 是否启动翻译目标语言优化
    case optimizeTargetLanuage = "lark.ai.optimize_translate_trglanguage"
    /// 是否支持多层合并转发消息翻译
    case multiLayerTranslate = "lark.ai.support_multi_layer_translation"

    /// IM消息翻译体验优化
    case translationOptimization = "ai.translate.message.optimization"

    /// 控制语音消息是否有翻译功能
    case audioMessageTranslation = "ai.translate.message.audio"

    /// IM消息翻译体验优化切换语言功能
    case translationOptimizationSwitchLanguage = "ai.translate.message.optimization.switch.language"

    case eewInDoc = "ai.abbreviation.docs"
    case eewInMinutes = "byteview.vc.minutes.lingo"
    case enableTranslate = "suite_translation"
    case translateSettingV2 = "translate.settings.v2.enable"
    case translateCard = "messagecard.translate.support"
    case translateCardForce = "messagecard.translate.force_enable_translate"
    public var isEnabled: Bool {
        #if DEBUG
        switch self {
        default:
            return true
        }
        #else
        return Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: rawValue))
        #endif
    }
    public func isUserEnabled(userResolver: UserResolver) -> Bool {
        return userResolver.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: rawValue))
    }
}

extension AIFeatureGating {
    var description: String {
        switch self {
        case .smartCompose:
            return "是否开启智能补全"
        case .eewQueryMenu:
            return "是否在消息menu对实体词高亮"
        case .eewCardExpand:
            return "实体词卡片是否展开"
        case .eewCardV2:
            return "实体词卡片是否启用V2接口"
        case .smartCorrect:
            return "是否开启智能纠错"
        case .lingoHighlightOnKeyboard:
            return "lingo highlight enable in im inputView"
        case .translateFeedback:
            return "是否启用翻译反馈"
        case .webTranslate:
            return "是否启用网页翻译"
        case .selectTranslate:
            return "是否启用划词翻译"
        case .optimizeTargetLanuage:
            return "翻译目标语言优化"
        case .multiLayerTranslate:
            return "合并转发消息支持多层翻译"
        case .translationOptimization:
            return "IM消息翻译体验优化"
        case .audioMessageTranslation:
            return "控制语音消息是否有翻译功能"
        case .translationOptimizationSwitchLanguage:
            return "IM消息翻译体验优化切换语言功能"
        case .eewInDoc:
            return "enterprise entiry word in doc enable"
        case .enableTranslate:
            return "control translate"
        case .translateSettingV2:
            return "translate setting v2 enable"
        case .translateCard:
            return "message Card can translate"
        case .translateCardForce:
            return "message Card force translate"
        case .eewInMinutes:
            return "enterprise entiry word in minutes enable"
        }
    }
}
