//
//  PreviewImageConfig.swift
//  OPPlugin
//
//  Created by ByteDance on 2023/10/31.
//

import Foundation
import LarkSetting
import LKCommonsLogging

public struct PreviewImageConfig {
    static let logger = Logger.oplog(PreviewImageConfig.self, category: "PreviewImageConfig")

    static func settingsConfig() -> OPPreviewImageConfig {
        var resultConfig = OPPreviewImageConfig.default
        do {
            let config: [String: Any] = try SettingManager.shared.setting(with: .make(userKeyLiteral: "preview_image_config"))
            if let enableLarkPhotoPreview = config["enable_lark_photo_preview"] as? Bool,
                let ignoreCipherCheck = config["ignore_cipher_check"] as? Bool {
                resultConfig = OPPreviewImageConfig(enableLarkPhotoPreview: enableLarkPhotoPreview, ignoreCipherCheck: ignoreCipherCheck)
            }
        } catch {}
        logger.info("previewImage resultConfig: \(resultConfig)")
        return resultConfig
    }
}

struct OPPreviewImageConfig {

    /// 是否使用主端图片预览器
    var enableLarkPhotoPreview: Bool

    /// 主端图片预览器是否忽略移动文件加密下的检查（即允许保存图片）
    var ignoreCipherCheck: Bool

    /// 默认配置
    static let `default` = OPPreviewImageConfig(enableLarkPhotoPreview: true, ignoreCipherCheck: false)
}
