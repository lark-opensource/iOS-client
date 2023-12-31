//
//  Basic_V1_Message+Translate.swift
//  LarkModel
//
//  Created by MJXin on 2022/7/11.
//

import Foundation
import RustPB

/// 是否可翻译的卡片类型
/// v1 版卡片不支持翻译
/// 除指定卡片类型外,其余不在需求范围内的卡片不支持翻译
public extension Basic_V1_Message {
    func isTranslatableMessageCardType() -> Bool {
        let content = content.cardContent
        return type == .card && content.cardVersion >= 2 && content.type == .text
    }
}

public extension Message {
    func isTranslatableMessageCardType() -> Bool {
        guard let content = content as? CardContent else {
            return false
        }
        return type == .card && content.version >= 2 && content.type == .text
    }
}
