//
//  TranslateLanguageProxy.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/6/8.
//

import Foundation
import LarkModel

public protocol TranslateLanguageProxy: AnyObject {
    var targetLanguage: String { get }

    var isEmailAutoTranslateOn: Bool { get }

    var trgLanguages: [(String, TargetLanguageConfig)] { get }

    var srcLanguagesConfig: [String: SourceLanguageConfig] { get }

    var globalDisplayRule: DisplayRule? { get }

    var disableLanguages: [String] { get }

    /// 对指定语言是否进行自动翻译
    /// - Parameter src: 源语言 lan code
    func shouldAutoTranslateFor(src: String) -> Bool

    func displayRuleFor(src: String) -> DisplayRule?
}
