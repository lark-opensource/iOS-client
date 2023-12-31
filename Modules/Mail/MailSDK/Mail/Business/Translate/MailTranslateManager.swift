//
//  MailTranslateManager.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/6/2.
//

import Foundation
import LarkLocalizations
import RxSwift
import LarkModel
import LarkFeatureGating

// swiftlint:disable line_length
struct MailTranslateLanguage {
    static let unknown = "unknown"
    static let not_support = "not_support"
    static let not_lang = "not_lang"

    static var en: MailTranslateLanguage {
        return MailTranslateLanguage(lanCode: "en",
                                     displayName: BundleI18n.MailSDK.Mail_Translations_English,
                                     sheetDisplayName: BundleI18n.MailSDK.Mail_Translations_English)
    }
    static var auto: MailTranslateLanguage {
        return MailTranslateLanguage(lanCode: "auto",
                                     displayName: BundleI18n.MailSDK.Mail_Translations_Auto,
                                     sheetDisplayName: BundleI18n.MailSDK.Mail_Translations_Autodetected)
    }

    let lanCode: String
    let displayName: String
    let sheetDisplayName: String
}

class MailTranslateManager {
    lazy var targetLanguages: [MailTranslateLanguage] = {
        return translateLanguageProvider?.trgLanguages.map({
            MailTranslateLanguage(lanCode: $0.0,
                                  displayName: $0.1.language,
                                  sheetDisplayName: $0.1.language)
            }) ?? []
    }()

    typealias ResultLanguageItem = (sourceLan: MailTranslateLanguage, targetLan: MailTranslateLanguage, msg: TranslateMessage, isBodyClipped: Bool)

    private var translateResult = [String: ResultLanguageItem]()

    lazy var disableLanguages: [String] = translateLanguageProvider?.disableLanguages ?? []

    private let disposeBag = DisposeBag()
    private let imageService: MailImageService
    private let accountContext: MailAccountContext

    private var translateLanguageProvider: TranslateLanguageProxy?

    init(translateLanguageProvider: TranslateLanguageProxy?, accountContext: MailAccountContext) {
        self.accountContext = accountContext
        self.imageService = accountContext.imageService
        self.translateLanguageProvider = translateLanguageProvider
    }

    var isAutoTranslateOn: Bool {
        return translateLanguageProvider?.isEmailAutoTranslateOn == true
    }

    func shouldAutoTranslate(src: String) -> Bool {
        let traditionalCHCodes = ["zh-Hant", "zh-HK", "zh-MO", "zh-TW"]
        if traditionalCHCodes.contains(src) {
            // 繁体翻译接口返回 zh-Hant，主端接口使用 zh-TW，需要特殊处理，不然繁体不会命中翻译
            // 繁体只要有一个命中，就返回TRUE
            let lanCode = traditionalCHCodes.first(where: { translateLanguageProvider?.shouldAutoTranslateFor(src: $0) == true })
            if let lanCode = lanCode {
                MailLogger.info("shouldAutoTranslate input: \(src), match: \(lanCode)")
                return true
            }
        }
        return translateLanguageProvider?.shouldAutoTranslateFor(src: src) == true
    }

    func displayRuleFor(src: String) -> DisplayRule? {
        let traditionalCHCodes = ["zh-Hant", "zh-HK", "zh-MO", "zh-TW"]
        if traditionalCHCodes.contains(src) {
            // 繁体翻译接口返回 zh-Hant，主端接口使用 zh-TW，需要特殊处理，不然繁体不会选中对应的规则
            for code in traditionalCHCodes {
                if let rule = translateLanguageProvider?.displayRuleFor(src: code) {
                    MailLogger.info("shouldAutoTranslate display rule input: \(src), match: \(code), rule: \(rule)")
                    return rule
                }
            }
        }
        return translateLanguageProvider?.displayRuleFor(src: src)
            ?? translateLanguageProvider?.globalDisplayRule
    }

    var targetLanFromSetting: MailTranslateLanguage {
        let lanCode = translateLanguageProvider?.targetLanguage ?? (LanguageManager.currentLanguage.languageCode ?? "")
        if let translateLan = targetLanguages.first(where: { $0.lanCode == lanCode }) {
            return translateLan
        } else {
            return .en
        }
    }

    func translate(threadId: String?, ownerUserID: String?, mail: MailMessageItem, targetLan: MailTranslateLanguage, isAuto: Bool, completion: ((TranslateMessage?, Error?) -> Void)?) {
        let msgId = mail.message.id
        let sourceLan = MailTranslateLanguage.auto
        let languages: [String]
        if let data = mail.message.languageIdentifier.data(using: .utf8), let lans = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
            languages = lans
        } else {
            languages = []
        }

        var showOriginalText = false
        var displayRule: DisplayRule?
        if let lan = languages.first,
           let srcDisplayRule = displayRuleFor(src: lan) {
            displayRule = srcDisplayRule
        } else {
            displayRule = translateLanguageProvider?.globalDisplayRule
        }
        showOriginalText = displayRule == .withOriginal
        Store.fetcher?.translateMessage(msgId: msgId,
                                       threadId: threadId,
                                       ownerUserID: ownerUserID,
                                       isBodyClipped: mail.message.isBodyClipped,
                                       sourceLan: sourceLan.lanCode,
                                       targetLan: targetLan.lanCode,
                                       showOriginalText: showOriginalText,
                                       languages: languages,
                                       ignoredLanguages: isAuto ? disableLanguages : [],
                                       needTranslatedSubject: true)
            .subscribe(onNext: { [weak self] (msgs) in
                if var msg = msgs.first, !(msg.translatedSubject.isEmpty && msg.translatedBody.isEmpty && msg.translatedBodyPlainText.isEmpty) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let self = self else { return }
                        msg.translatedBody = MailMessageListTemplateRender.preprocessHtml(
                            msg.translatedBody,
                            messageID: msg.messageId,
                            messageItem: mail,
                            isFromChat: false,
                            sharedService: self.accountContext.sharedServices)
                        DispatchQueue.main.async { [weak self] in
                            self?.translateResult[msgId] = (sourceLan, targetLan, msg, mail.message.isBodyClipped)
                            completion?(msgs.first, nil)
                        }
                    }

                } else {
                    completion?(msgs.first, nil)
                }
                }, onError: { (error) in
                    completion?(nil, error)
            }).disposed(by: disposeBag)
    }

    func getUpdateTranslationJSCall(msgId: String,
                                    isTranslation: Bool,
                                    subject: String,
                                    messageSubject: String,
                                    summary: String,
                                    translatedBody: String,
                                    isBodyClipped: Bool,
                                    sourceLan: MailTranslateLanguage? = nil,
                                    targetLan: MailTranslateLanguage? = nil,
                                    showOriginalText: Bool) -> String? {
        let resultItem = translateResult[msgId]
        func escapeJSON(_ s: String) -> String {
            // line breaks need to be escaped before encoding
            // cuz \n will be escaped to \\n when encoding
            return s.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: "\t", with: "")
                .replacingOccurrences(of: "'", with: "\\'")
        }
        return "window.updateTranslation('\(msgId)', \(isTranslation), '\(escapeJSON(subject))', '\(escapeJSON(messageSubject.htmlEncoded))', '\(escapeJSON(summary))', '\(escapeJSON(isBodyClipped ? "<!--\(translatedBody)-->" : translatedBody))', '\(targetLan?.displayName ?? (resultItem?.targetLan.displayName) ?? "")', \(isTranslation && !showOriginalText))"
    }

    typealias TranslatedJSResult = (jsCallString: String?, translatedSubject: String?, showOriginalText: Bool)
    func getPreTranslateResultJSCall(msgId: String, isTranslation: Bool) -> TranslatedJSResult {
        guard let resultItem = translateResult[msgId] else { return (nil, nil, false) }
        let jsCall = getUpdateTranslationJSCall(msgId: msgId, isTranslation: isTranslation,
                                                subject: resultItem.msg.translatedSubject,
                                                messageSubject: resultItem.msg.translatedSubject,
                                                summary: resultItem.msg.translatedBodyPlainText, translatedBody: resultItem.msg.translatedBody,
                                                isBodyClipped: resultItem.isBodyClipped, sourceLan: resultItem.sourceLan,
                                                targetLan: resultItem.targetLan, showOriginalText: resultItem.msg.showOriginalText)
        let translatedSubject = resultItem.msg.translatedSubject
        return (jsCall, translatedSubject, resultItem.msg.showOriginalText)
    }

    func resultItem(for msgId: String) -> ResultLanguageItem? {
        return translateResult[msgId]
    }
}
// swiftlint:enable line_length
