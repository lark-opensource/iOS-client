//
//  OPBlockGuideInfoStatusHandler.swift
//  OPBlock
//
//  Created by chenziyi on 2021/10/25.
//

import Foundation
import OPSDK
import OPBlockInterface
import LarkOPInterface

struct GuideInfoStatusInfo {
    var isUsable: Bool
    var error: OPError?
}

class OPBlockGuideInfoStatusHandler {
    static func handle(status: OPBlockGuideInfoStatus, block_info: [String: Any]) -> GuideInfoStatusInfo {
        if status == .usable {
            return GuideInfoStatusInfo(isUsable: true, error: nil)
        } else {
            // 状态为不可用时再处理block_extension_tip字段
            guard let block_extension_tip = block_info["block_extension_tip"] as? [String: Any],
                  let content = block_extension_tip["content"] as? [String: Any] else {
                
                // content解析失败意味着找不到展示的错误信息，所以用兜底错误
                let data = GuideInfoStatusViewItem(imageType: .default_error,
                                                   displayMsg: BundleI18n.OPBlock.OpenPlatform_BlockGuide_PageNotFound,
                                                   button: nil)
                let error = OPBlockitMonitorCodeMountLaunchGuideInfo.check_guide_info_unknown.error()
                GuideInfoStatusViewItems.dataMap[error] = data
                return GuideInfoStatusInfo(isUsable: false, error: error)
            }

            let error = status.error
            let message = selectLanguage(fromContent: content)

            // 按钮文案，默认英文
            guard let buttons = block_extension_tip["buttons"] as? [String: Any],
                  let buttonContent = buttons["content"] as? [String: Any],
                  let schema = buttons["schema"] as? String else {
                status.register(display: message, button: nil)
                return GuideInfoStatusInfo(isUsable: false, error: error)
            }

            let title = selectLanguage(fromContent: buttonContent)
            let button = Button(title: title, schema: schema)

            status.register(display: message, button: button)

            return GuideInfoStatusInfo(isUsable: false, error: error)
        }
    }

    private static func selectLanguage(fromContent: [String: Any]) -> String {
        let lang = Locale.current.languageCode
        let message: String

        // 展示内容文案，默认英文
        if lang == "zh" {
            message = fromContent["zh_cn"] as? String ?? "The language type zh_cn is not supported"
        } else if lang == "ja" {
            message = fromContent["js_jp"] as? String ?? "The language type js_jp is not supported"
        } else {
            message = fromContent["en_us"] as? String ?? "The default language type en_us is not supported"
        }
        return message
    }
}
