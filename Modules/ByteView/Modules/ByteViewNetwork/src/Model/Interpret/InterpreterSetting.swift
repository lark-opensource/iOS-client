//
//  InterpreterSetting.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 传译员配置
/// - Videoconference_V1_InterpreterSetting
public struct InterpreterSetting: Equatable, Codable {
    public init(firstLanguage: LanguageType, secondLanguage: LanguageType, confirmStatus: ConfirmStatus?,
                interpretingLanguage: LanguageType, confirmInterpretationTime: Int64, interpreterSetTime: Int64) {
        self.firstLanguage = firstLanguage
        self.secondLanguage = secondLanguage
        self.confirmStatus = confirmStatus
        self.interpretingLanguage = interpretingLanguage
        self.confirmInterpretationTime = confirmInterpretationTime
        self.interpreterSetTime = interpreterSetTime
    }

    public var firstLanguage: LanguageType
    public var secondLanguage: LanguageType

    /// 传译员确认状态
    public var confirmStatus: ConfirmStatus?

    /// 正在翻译的目标语言
    public var interpretingLanguage: LanguageType

    /// 确认传译员身份时间，秒级，用于客户端排序
    public var confirmInterpretationTime: Int64

    /// 主持人设定用户为传译员的时间
    public var interpreterSetTime: Int64

    public init() {
        self.init(firstLanguage: .init(languageType: "", despI18NKey: "", iconStr: ""),
                  secondLanguage: .init(languageType: "", despI18NKey: "", iconStr: ""),
                  confirmStatus: .reserve,
                  interpretingLanguage: .init(languageType: "", despI18NKey: "", iconStr: ""),
                  confirmInterpretationTime: 0, interpreterSetTime: 0)
    }

    public enum ConfirmStatus: Int, Hashable, Codable {
        /// 保留数据，身份不生效
        case reserve // = 0
        case waitConfirm // = 1
        case confirmed // = 2
    }

    /// 同声传译相关, Videoconference_V1_LanguageType
    public struct LanguageType: Equatable, Codable {
        /// 唯一标示一种语言和语言频道
        public var languageType: String
        public var despI18NKey: String
        public var iconStr: String

        public init(languageType: String, despI18NKey: String, iconStr: String) {
            self.languageType = languageType
            self.despI18NKey = despI18NKey
            self.iconStr = iconStr
        }
    }
}

extension InterpreterSetting.LanguageType: CustomStringConvertible {
    public var description: String {
        String(indent: "Lang",
               "type: \(languageType)",
               "desp: \(despI18NKey)",
               "icon: \(iconStr)"
        )
    }
}

extension InterpreterSetting: CustomStringConvertible {
    public var description: String {
        String(
            indent: "InterpreterSetting",
            "firstLanguage: \(firstLanguage)",
            "secondLanguage: \(secondLanguage)",
            "confirmStatus: \(confirmStatus)",
            "interpretingLanguage: \(interpretingLanguage)",
            "confirmTime: \(confirmInterpretationTime)",
            "interpreterSetTime: \(interpreterSetTime)"
        )
    }
}
