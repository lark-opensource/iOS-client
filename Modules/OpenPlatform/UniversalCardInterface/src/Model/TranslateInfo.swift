//
//  TranslateInfo.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation

public enum RenderType: String, Encodable {
    case renderOriginal = "renderOriginal" //不展示翻译效果
    case renderTranslation = "renderTranslation" //只展示译文
    case renderOriginalWithTranslation = "renderOriginalWithTranslation" //展示原文合译文
}

public struct TranslateInfo: Encodable, Equatable {
    public let localeLanguage: String
    public let translateLanguage: String
    public let renderType: RenderType
}
