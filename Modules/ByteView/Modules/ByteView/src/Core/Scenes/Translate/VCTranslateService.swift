//
//  VCTranslateService.swift
//  ByteView
//
//  Created by wulv on 2021/11/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewSetting
import ByteViewNetwork

protocol VCTranslateServiceDelegate: AnyObject {
    /// 手动翻译&自动翻译结果
    func didReceiveTranslationResult(translationInfos: [String: IMTranslationResult])
    /// 选词翻译结果
    func didReceiveTranslatioinContent(isSuccess: Bool, content: [String], language: String)
    /// 翻译配置变更，需要重新检测
    func needRedetect()
    /// 即将通知 rust 用户手动变更展示规则时调用
    func displayRuleWillChange(to rule: TranslateDisplayRule, messageID: String)
}

/// 会中 IM 翻译服务，直接与业务层交互的对象。
/// 内部负责整合 lark <-> VC <-> VC rust 之间的通信，并暴露翻译结果给外部业务层
class VCTranslateService {

    weak var delegate: VCTranslateServiceDelegate?

    private static let logger = Logger.chatMessage

    let provider: TranslationInfoProvider
    private let translationStore: IMTranslationStore
    private let queue = DispatchQueue(label: "lark.byteview.im.translation")
    private static let translationQueueKey = DispatchSpecificKey<Void>()

    var userId: String { meeting.userId }
    private let disposeBag = DisposeBag()
    var httpClient: HttpClient { meeting.httpClient }
    let meeting: InMeetMeeting

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.provider = TranslationInfoProvider(meeting: meeting)
        self.translationStore = IMTranslationStore(provider: self.provider)
        self.provider.addListener(self)
        meeting.push.translateResults.addObserver(self)
        Self.logger.info("Init translate service")
    }

    deinit {
        Self.logger.info("Deinit translate service")
    }

    private func clearCache() {
        queue.async { [weak self] in
            self?.translationStore.reset()
            self?.delegate?.needRedetect()
        }
    }

    func clearAll() {
        queue.async { [weak self] in
            self?.translationStore.clearAll()
        }
    }
}

// MARK: - Public
extension VCTranslateService {

    /// 可选翻译语言
    var availableLanguages: [TranslateLanguage] {
        provider.availableLanguages
    }

    var isVCAutoTranslationOn: Bool {
        provider.isVCAutoTranslationOn
    }

    func getIMTranslateInfo(by messageID: String) -> IMTranslationResult? {
        if DispatchQueue.getSpecific(key: Self.translationQueueKey) != nil {
            // 如果当前已经在 queue 中，可以安全访问 translationStore 内部数据结构
            return translationStore.translationResult(with: messageID)
        } else {
            // 否则同步到 queue 中访问 translationStore
            var result: IMTranslationResult?
            queue.sync {
                result = translationStore.translationResult(with: messageID)
            }
            return result
        }
    }

    /// 手动翻译消息, containerID: 讨论组中代表讨论组 ID，主会场或非讨论组代表会议 ID
    func translateMessage(containerID: String, messageID: String, language: String? = nil, role: Participant.MeetingRole) {
        queue.async { [weak self] in
            guard let self = self else { return }
            // 手动翻译需解锁 displayRule，重新使用全局设置的展示规则
            self.translationStore.unlockDisplayRule(with: messageID)
            let rule = self.translationStore.displayRule(with: messageID)
            let language = language ?? self.provider.targetLanguage
            Self.logger.info("Manually translate message \(messageID) to \(language) using rule \(rule), containerID: \(containerID)")
            self.translationStore.translateMessage(with: messageID)
            let context = TranslateContext(messageId: messageID, targetLanguage: language, displayRule: rule)
            let request = TranslateMessagesRequest(containerId: containerID, source: .manualTranslate, contexts: [context], role: role)
            self.httpClient.send(request) { result in
                if !result.isSuccess {
                    Self.logger.error("manual translate fail, messageID: \(messageID)")
                }
            }
        }
    }

    /// 消息自动翻译检测, 包含送翻策略
    func detectAutoTranslateMessage(messageId: String, displayArea: TranslateDisplayArea) {
        queue.async { [weak self] in
            guard let self = self, self.translationStore.shouldAutoTranslateMessage(with: messageId) else { return }
            Self.logger.info("Detect auto translation message \(messageId), language \(self.provider.targetLanguage), rule \(self.provider.translationDisplayRule), isAutoTranslate: \(self.provider.isVCAutoTranslationOn)")
            self.translationStore.translateMessage(with: messageId)
            let request = SetMessageAutoDetectStateRequest(isAutoTranslate: self.provider.isVCAutoTranslationOn, targetLanguage: self.provider.targetLanguage, displayRule: self.provider.translationDisplayRule, displayArea: displayArea, messageIds: [messageId])
            self.httpClient.send(request) { result in
                if !result.isSuccess {
                    Self.logger.error("Detect translate fail, messageID: \(messageId)")
                }
            }
        }
    }

    /// 手动变更消息展示规则
    func changeDisplayRule(messageId: String, displayRule: TranslateDisplayRule) {
        queue.async { [weak self] in
            guard let self = self else { return }
            Self.logger.info("Change display rule to \(displayRule)")
            self.translationStore.changeDisplayRule(with: messageId, to: displayRule)
            self.delegate?.displayRuleWillChange(to: displayRule, messageID: messageId)
            let request = SetMessageTranslateDisplayRuleRequest(messageId: messageId, displayRule: displayRule)
            self.httpClient.send(request, options: .retry(3, owner: self)) { result in
                if !result.isSuccess {
                    Self.logger.error("Change translate rule fail, messageID: \(messageId)")
                }
            }
        }
    }

    /// 选词翻译
    func translateContent(content: [String], languageKey: String? = nil) {
        let targetLanguage: String = languageKey ?? provider.targetLanguage
        let displayName = provider.availableLanguages.first { $0.key == targetLanguage }?.name ?? targetLanguage
        Self.logger.info("Translate content to \(languageKey)")
        let request = TranslateWebXMLRequest(srcContents: content, srcLanguage: "auto", targetLanguage: targetLanguage)
        httpClient.getResponse(request) { [weak self] result in
            switch result {
            case .success(let response):
                self?.delegate?.didReceiveTranslatioinContent(isSuccess: true, content: response.targetContents, language: displayName)
            case .failure:
                self?.delegate?.didReceiveTranslatioinContent(isSuccess: false, content: [], language: displayName)
                Self.logger.error("content translate fail")
            }
        }
    }
}

// MARK: - TranslationInfoProvider Delegate
extension VCTranslateService: TranslationInfoProviderDelegate {
    func translationLanguageDidChange(language: String) {
        Self.logger.info("Received the push of language change: new value = \(language), old value = \(provider.targetLanguage)")
        clearCache()
    }

    func translationDisplayRuleDidChange(rule: TranslateDisplayRule) {
        Self.logger.info("Received the push of display rule change: new value = \(rule), old value = \(provider.translationDisplayRule)")
        clearCache()
    }

    func autoTranslationSwitchDidChange(isOn: Bool) {
        Self.logger.info("Received the push of auto translation change: new value = \(isOn), old value = \(provider.isVCAutoTranslationOn)")
        clearCache()
    }
}

// MARK: - 翻译结果
extension VCTranslateService: TranslateResultsPushObserver {
    func didReceiveTranslateResults(_ infos: [TranslateInfo]) {
        queue.async { [weak self] in
            guard let self = self else { return }

            var hasNewInfo: Bool = false
            infos.forEach { info in
                guard info.messageType == .text else {
                    Self.logger.error("translate push unsupport type: \(info.messageType), messageID: \(info.messageID)")
                    return
                }
                if self.translationStore.didReceiveTranslationInfo(info) {
                    hasNewInfo = true
                }
            }
            if hasNewInfo {
                self.delegate?.didReceiveTranslationResult(translationInfos: self.translationStore.translationInfos)
            }
        }
    }
}

extension VCTranslateServiceDelegate {
    func didReceiveTranslationResult(translationInfos: [String: IMTranslationResult]) {}
    func didReceiveTranslatioinContent(isSuccess: Bool, content: [String], language: String) {}
    func needRedetect() {}
    func displayRuleWillChange(to rule: TranslateDisplayRule, messageID: String) {}
}
