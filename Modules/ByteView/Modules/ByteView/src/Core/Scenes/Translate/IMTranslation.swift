//
//  IMTranslation.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/11/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

/// 轻量化的翻译结果，与VM层对接
struct IMTranslationResult: Equatable {
    /// 翻译结果的展示规则
    let rule: TranslateDisplayRule
    /// 翻译结果文本
    let content: MessageRichText
    /// 翻译类型(手动/自动）
    let source: TranslateSource
}

class IMTranslation {

    /// 当前这条消息所处的翻译阶段
    enum Stage {
        case normal
        case translating
        case translated
        case failed
    }

    let messageID: String
    var stage: Stage = .normal
    var displayRule: TranslateDisplayRule = .noTranslation
    var isRuleLocked = false
    var content: MessageRichText?
    var source: TranslateSource = .unknown

    var result: IMTranslationResult? {
        if let content = content {
            return IMTranslationResult(rule: displayRule, content: content, source: source)
        } else {
            return nil
        }
    }

    init(messageID: String) {
        self.messageID = messageID
    }

    var shouldAutoTranslate: Bool {
        // 1. 已经送翻，并且翻译结果（如果有）未报错的不需要重复发送
        if [.translating, .translated].contains(stage) {
            return false
        }
        // 2. 手动锁定过样式为不翻译的，无论全局翻译语言还是展示规则变更，都不用再次送翻
        if isRuleLocked && displayRule == .noTranslation {
            return false
        }
        return true
    }

    func lockDisplayRule(to rule: TranslateDisplayRule) {
        isRuleLocked = true
        displayRule = rule
    }

    func unlockDisplayRule() {
        isRuleLocked = false
    }

    func resetStage() {
        // 删除缓存时不改变已缓存项的锁定显示样式，也不清除翻译结果，仅把状态改变，以便可以重新送翻
        stage = .normal
    }
}

class IMTranslationStore {
    // messageID: translation
    var translations: [String: IMTranslation] = [:]
    private let provider: TranslationInfoProvider
    private static let logger = Logger.chatMessage

    var translationInfos: [String: IMTranslationResult] {
        return translations.compactMapValues { $0.result }
    }

    init(provider: TranslationInfoProvider) {
        self.provider = provider
    }

    func shouldAutoTranslateMessage(with messageID: String) -> Bool {
        translations[messageID]?.shouldAutoTranslate ?? true
    }

    func translationResult(with messageID: String) -> IMTranslationResult? {
        translations[messageID]?.result
    }

    func unlockDisplayRule(with messageID: String) {
        translations[messageID]?.unlockDisplayRule()
    }

    func displayRule(with messageID: String) -> TranslateDisplayRule {
        // 优先查有无锁定样式，没有的话使用全局设置的样式
        if let translation = translations[messageID], translation.isRuleLocked {
            return translation.displayRule
        } else {
            return provider.translationDisplayRule
        }
    }

    func translateMessage(with messageID: String) {
        // 替换翻译对象，但要保留原有锁定规则（如果有）
        if let oldTranslation = translations[messageID] {
            oldTranslation.stage = .translating
        } else {
            let translation = IMTranslation(messageID: messageID)
            translation.stage = .translating
            translations[messageID] = translation
        }
    }

    func changeDisplayRule(with messageID: String, to displayRule: TranslateDisplayRule) {
        translations[messageID]?.lockDisplayRule(to: displayRule)
    }

    func didReceiveTranslationInfo(_ info: TranslateInfo) -> Bool {
        switch info.errCode {
        case .unknown:
            return handleTranlationSuccess(info)
        default:
            return handleTranslationFailure(info)
        }
    }

    func reset() {
        translations.forEach { $0.value.resetStage() }
    }

    func clearAll() {
        translations.removeAll()
    }

    private func handleTranlationSuccess(_ info: TranslateInfo) -> Bool {
        // 客户端无需记录翻译请求并尝试过滤过期推送，rust会保证
        guard let translation = translations[info.messageID] else {
            return false
        }

        translation.stage = .translated
        if info.displayRule == .noTranslation {
            translation.content = nil
            translation.displayRule = .noTranslation
            translation.source = .unknown
        } else {
            guard let textContent = info.textContent else {
                Self.logger.info("Ignore wrong formatted message, expected textFormatString.")
                return false
            }
            translation.content = textContent.content
            translation.displayRule = info.displayRule
            translation.source = info.translateSource
        }

        return true
    }

    private func handleTranslationFailure(_ info: TranslateInfo) -> Bool {
        Self.logger.error("translate push error: \(info.errCode), messageID: \(info.messageID)")
        guard let translation = translations[info.messageID] else { return false }
        switch info.errCode {
        case .internalError, .timeout:
            translation.stage = .failed
        case .sameLanguage:
            // 这里清空 content 的原因：如果收到了 sameLanguage 的错误码，说明消息源语言和翻译语言相同，应该恢复成原文
            translation.content = nil
            translation.stage = .translated
            // 只有这种情况表明页面需要重新刷新
            return true
        case .unsupportedLanguage, .unsupportedMessageType:
            translation.stage = .translated
        default:
            assertionFailure("undefined error case")
        }
        return false
    }
}

private extension TranslateSource {
    var isAutoTranslate: Bool {
        self == .autoTranslate
    }
}
