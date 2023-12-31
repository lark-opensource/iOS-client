//
//  TranslationDomain.swift
//  LKMetric
//
//  Created by zhenning on 2020/3/9.
//

import Foundation

// MARK: - Translation Level 2
public enum Translation: Int32, MetricDomainEnum {
    case unknown = 0
    /// 设置项
    case settings = 1
}

// MARK: - Translation Level 3
public enum TranslationSettings: Int32, MetricDomainEnum {
    case unknown = 0
    /// 设置项总况
    case genenalSetting = 1
    /// 目标语言设置
    case targetLanguageSetting = 2
    /// 显示效果设置
    case displayEffectSetting = 3
    /// 自动翻译设置
    case autoTranslateSetting = 4
}
