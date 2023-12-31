//
//  PushTranslateLanguageNotice.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 翻译来源
/// - Basic_V1_TranslateSource
public enum TranslateSource: Int, Hashable {
    case unknown // = 0

    ///手动翻译
    case manualTranslate // = 1

    ///自动翻译
    case autoTranslate // = 2
}

public enum TranslateDisplayRule: Int, Hashable {
    case unknown // = 0

    /// 不展示翻译效果，即不翻译
    case noTranslation // = 1

    /// 只展示译文
    case onlyTranslation // = 2

    /// 展示译文与原文
    case withOriginal // = 3
}

/// Videoconference_V1_VCTranslateInfo.VCTranslateDisplayArea
public enum TranslateDisplayArea: Int, Hashable {

    /// 聊天框
    case chatbox = 1

    /// 气泡
    case popup // = 2
}

/// Im_V1_LanguagesConfiguration
public struct TranslateLanguagesConfiguration: Equatable {
    public init(rule: TranslateDisplayRule) {
        self.rule = rule
    }

    public var rule: TranslateDisplayRule
}
