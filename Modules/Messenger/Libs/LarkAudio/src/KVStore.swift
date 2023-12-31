//
//  KVStore.swift
//  LarkAudio
//
//  Created by 李晨 on 2020/10/28.
//

import Foundation
import LarkLocalizations
import LarkStorage

extension Lang: KVNonOptionalValue {}
extension Lang {
    /// 自动识别语种枚举，方便组件内数据传递
    public static let un_AUTO = Lang(rawValue: "UN_AUTO")
}

extension RecognizeLanguageManager.RecognizeType: KVNonOptionalValue {}

struct KVStore {
    static private var store = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("Audio"))
    static private let recognitionLanguageKey = KVKey<Lang>("recognition.language", default: .dynamic({
        if LanguageManager.currentLanguage == .zh_CN {
            return .zh_CN
        } else {
            return .en_US
        }
    }))

    /// 存储当前语音识别语言
    @KVConfig(key: recognitionLanguageKey, store: store)
    static var recognitionLanguage: Lang

    static private let recognitionTypeKey = KVKey(
        "recognition.type",
        default: RecognizeLanguageManager.RecognizeType.audio
    )
    /// 存储当前语音面板类型
    @KVConfig(key: recognitionTypeKey, store: store)
    static var recognitionType: RecognizeLanguageManager.RecognizeType

    static private let recognitionI18nKey = KVKey(
        "recognition.i18n",
        default: {
            switch RecognizeLanguageManager.shared.recognitionLanguage {
            case .zh_CN:
                return BundleI18n.LarkAudio.Lark_Chat_AudioToChinese
            default:
                return BundleI18n.LarkAudio.Lark_Chat_AudioToEnglish
            }
        }()
    )

    /// 存储当前语音识别语言的 i18n 文案
    @KVConfig(key: recognitionI18nKey, store: store)
    static var recognitionI18n: String
}
