//
//  DocsInfo+Translate.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/6.
//

import Foundation

extension DocsInfo {
    // 翻译功能上下文，包括翻译语言设置与埋点信息
    public struct TranslationContext {
        /// 参考文档内容与用户设置的目标翻译语言, ch, en, jp, ...
        public var targetLanguage: String
        // 目标翻译语言的文案，当前语言对应的目标语言的文案
        public var targetLanguageTitle: String
        /// 文档内容主要语言
        public var contentSourceLanguage: String?
        /// 用户主要语言
        public var userMainLanguage: String?
        /// 用户设置的默认翻译语言
        public var defaultTargetLanguage: String?

        public init(targetLanguage: String, targetLanguageTitle: String) {
            self.targetLanguage = targetLanguage
            self.targetLanguageTitle = targetLanguageTitle
        }
    }
}
