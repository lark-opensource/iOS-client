//
//  ContactPasteboard.swift
//  LarkContact
//
//  Created by Yuri on 2023/2/15.
//

import Foundation
import LarkEMM
import LarkSensitivityControl

class ContactPasteboard {
    /// 敏感API: 联系人模块 粘贴板 PSDA key https://thrones.bytedance.net/security-and-compliance/data-collect/api-control
    static let CONTACTPASTEBOARDPSDAKEY = "LARK-PSDA-contact_paste_data"
    static func writeToPasteboard(string: String, shouldImmunity: Bool? = false) -> Bool {
        do {
            var config = PasteboardConfig(token: Token(CONTACTPASTEBOARDPSDAKEY))
            config.shouldImmunity = shouldImmunity
            try SCPasteboard.generalUnsafe(config).string = string
            return true
        } catch {
            // 复制失败兜底逻辑
            return false
        }
    }
}
