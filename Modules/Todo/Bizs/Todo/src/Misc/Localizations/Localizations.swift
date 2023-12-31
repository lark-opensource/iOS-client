//
//  Localizations.swift
//  Todo
//
//  Created by wangwanxin on 2022/2/16.
//

import LarkLocalizations
import RustPB

extension LarkLocalizations.Lang {

    /// 转成sdk需要类型
    var sdkLanguageType: Basic_V1_LanguageType {
        var languageType: Basic_V1_LanguageType = .enUs
        switch self {
        case .zh_CN:
            languageType = .zhCn
        case .ja_JP:
            languageType = .jaJp
        case .id_ID:
            languageType = .idID
        case .de_DE:
            languageType = .deDe
        case .es_ES:
            languageType = .esEs
        case .fr_FR:
            languageType = .frFr
        case .it_IT:
            languageType = .itIt
        case .pt_BR:
            languageType = .ptBr
        case .vi_VN:
            languageType = .viVn
        case .ru_RU:
            languageType = .ruRu
        case .hi_IN:
            languageType = .hiIn
        case .th_TH:
            languageType = .thTh
        case .ko_KR:
            languageType = .koKr
        case .zh_TW:
            languageType = .zhTw
        case .zh_HK:
            languageType = .zhHk
// TODO:
//        case .ms_MY:
//            languageType = .msMY
        default:
            languageType = .enUs
        }
        return languageType
    }
}
