//
//  MineMetric.swift
//  LarkMine
//
//  Created by zhenning on 2020/03/09.
//

import Foundation
import LKMetric

protocol MetricProtocol {
    var domain: MetricDomain { get }
    var type: MetricType { get }
    var id: MetricID { get }
}

extension MetricProtocol {
    var type: MetricType { .business }
}

// swiftlint:disable nesting
enum BusinessID {
    /// 设置项
    enum Settings {

        enum GenenalSetting: MetricID, MetricProtocol {
            var domain: MetricDomain {
                Root.translation
                .s(Translation.settings)
                .s(TranslationSettings.genenalSetting)
                 }
            var id: MetricID { rawValue }

            /// 翻译设置页面打开
            case openSetting = 1
            /// 翻译设置页面打开失败
            case openSettingFailed = 2
        }

        /// 目标语言设置
        enum TargetLanguageSetting: MetricID, MetricProtocol {
            var domain: MetricDomain {
                Root.translation
                .s(Translation.settings)
                .s(TranslationSettings.targetLanguageSetting)
                }
            var id: MetricID { rawValue }

            /// 打开目标翻译语言
            case openTargetLanguage = 1
            /// 打开目标翻译语言失败
            case openTargetLanguageFailed = 2
            /// 设置目标翻译语言
            case changeTargetLanguage = 3
            /// 设置目标翻译语言失败
            case changeTargetLanguageFailed = 4
        }

        /// 显示效果设置
        enum DisplayEffectSetting: MetricID, MetricProtocol {
            var domain: MetricDomain {
                Root.translation
                .s(Translation.settings)
                .s(TranslationSettings.displayEffectSetting)
                }
            var id: MetricID { rawValue }

            /// 设置目标翻译效果
            case setGlobalDisplayRule = 1
            /// 设置目标翻译语言失败
            case setGlobalDisplayRuleFailed = 2
            /// 设置特定语言翻译效果
            case setSpecificDisplayRule = 3
            /// 设置特定语言翻译效果失败
            case setSpecificDisplayRuleFailed = 4
            /// 打开设置特定语言翻译效果页面
            case openSpecificDisplayPage = 5
            /// 打开设置特定语言翻译效果页面失败
            case openSpecificDisplayPageFailed = 6
        }

        /// 自动翻译设置
        enum AutoTranslateSetting: MetricID, MetricProtocol {
            var domain: MetricDomain {
                Root.translation
                .s(Translation.settings)
                .s(TranslationSettings.autoTranslateSetting)
                }
            var id: MetricID { rawValue }

            /// 设置自动翻译全局开关
            case setGlobalAutoTranslateSwitch = 1
            /// 设置自动翻译全局开关失败
            case setGlobalAutoTranslateSwitchFailed = 2
            /// 设置自动翻译二级开关
            case setSecondaryAutoTranslateSwitch = 3
            /// 设置自动翻译二级开关失败
            case setSecondaryAutoTranslateSwitchFailed = 4
            /// 设置特定语言自动翻译
            case setSpecificAutoTranslateSwitch = 5
            /// 设置特定语言自动翻译失败
            case setSpecificAutoTranslateSwitchFailed = 6
            /// 打开特定语言自动翻译页面
            case openOpecificAutoTranslatePage = 7
            /// 打开特定语言自动翻译页面失败
            case openOpecificAutoTranslatePageFailed = 8
        }
    }
}
// swiftlint:enable nesting

final class MineMetric {

    func log(metric: MetricProtocol, params: [String: String]? = [:], error: Error? = nil) {
        if let params = params {
            LKMetric.log(domain: metric.domain, type: metric.type, id: metric.id, params: params, error: error)
        } else {
            LKMetric.log(domain: metric.domain, type: metric.type, id: metric.id, error: error)
        }
    }

}
