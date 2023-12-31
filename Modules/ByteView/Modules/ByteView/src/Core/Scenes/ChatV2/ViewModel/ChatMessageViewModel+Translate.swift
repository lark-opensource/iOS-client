//
//  ChatMessageViewModel+Translate.swift
//  ByteView
//
//  Created by wulv on 2021/11/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting

extension ChatMessageViewModel {

    var translationLanguages: [TranslateLanguage] {
        translateService.availableLanguages
    }

    /** 自动翻译 */
    func detectAutoTranslate(_ cellModel: ChatMessageCellModel) {
        translateService.detectAutoTranslateMessage(messageId: cellModel.id, displayArea: .chatbox)
    }

    func updateMessageTranslation(_ cellModel: ChatMessageCellModel) {
        cellModel.updateTranslation(translateService.getIMTranslateInfo(by: cellModel.id))
    }

    /** 手动翻译 */
    func translateMessage(with messageID: String, languageKey: String) {
        let role = self.meeting.myself.meetingRole
        translateService.translateMessage(containerID: meeting.data.meetingIdForRequest, messageID: messageID, language: languageKey, role: role)
    }

    /** 划词翻译 */
    func translateText(_ text: [String], languageKey: String) {
        translateService.translateContent(content: text, languageKey: languageKey)
    }

    /** 翻译样式更改 */
    func changeDisplayRule(_ rule: TranslateDisplayRule, forMessage messageID: String) {
        translateService.changeDisplayRule(messageId: messageID, displayRule: rule)
    }
}

extension ChatMessageViewModel: VCTranslateServiceDelegate {
    func didReceiveTranslationResult(translationInfos: [String: IMTranslationResult]) {
        guard !translationInfos.isEmpty else { return }
        let sources = translationInfos.mapValues { $0.source }

        Util.runInMainThread {
            self.listeners.forEach { $0.translationResultDidChange(sources: sources) }
        }
    }

    func didReceiveTranslatioinContent(isSuccess: Bool, content: [String], language: String) {
        triggerTranslatioinContentRelay.accept((isSuccess, content, language))
    }

    func needRedetect() {
        Util.runInMainThread {
            self.listeners.forEach { $0.translationInfoDidChange() }
        }
    }

    func displayRuleWillChange(to rule: TranslateDisplayRule, messageID: String) {
        // 点击“查看原文”或“收起译文”时，显示原文逻辑
        Util.runInMainThread {
            if rule == .noTranslation, let index = self.messagesStore.messageIndex(for: messageID) {
                let message = self.messagesStore.message(at: index)
                message?.updateTranslation(nil)
                // 译文->原文，翻译方式 sources 传空
                self.listeners.forEach { $0.translationResultDidChange(sources: [:]) }
            }
        }
    }
}
