//
//  InterpreterLanguageInfo.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxDataSources

struct InterpreterLanguageInfo {
    let languageType: LanguageType
    let i18nText: String?
    let isSelected: Bool
}

struct InterpreterLanguagInfoSectionModel {
    var items: [InterpreterLanguageInfo]
}

extension InterpreterLanguagInfoSectionModel: SectionModelType {
    init(original: InterpreterLanguagInfoSectionModel, items: [InterpreterLanguageInfo]) {
        self = original
        self.items = items
    }
}
