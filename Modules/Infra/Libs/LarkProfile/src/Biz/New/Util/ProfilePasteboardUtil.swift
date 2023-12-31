//
//  ProfilePasteboardUtil.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/2/16.
//

import Foundation
import UIKit
import LarkEMM
import LarkSensitivityControl

struct ProfilePasteboardUtil {

    /// 个人信息剪贴板复制统一接入PSDA管控
    /// - Parameter text: 复制内容
    /// - Returns: 是否复制成功
    static func pasteboardPersonalItemInfo(text: String) -> Bool {
        do {
            let config = PasteboardConfig(token: Token("LARK-PSDA-profile_person_info_item_content_long_press_copy"))
            try SCPasteboard.generalUnsafe(config).string = text
            return true
        } catch {
            // 业务兜底逻辑
            return false
        }
    }
}
