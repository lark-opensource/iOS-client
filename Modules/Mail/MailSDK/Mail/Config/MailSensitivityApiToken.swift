//
//  MailSensitivityApiToken.swift
//  MailSDK
//
//  Created by Ender on 2023/5/17.
//

import Foundation

enum MailSensitivityApiToken {
    // 注意token需要走申请流程：https://thrones.bytedance.net/security-and-compliance/data-collect/api-control 
    /// 读信页复制邮件地址
    static let readMailCopyAddress = "LARK-PSDA-mail_message_copy_address"
    /// 已读统计详情页复制邮件地址
    static let readStatCopyAddress = "LARK-PSDA-mail_readstat_copy_address"
    static let aiChatModeCopy = "LARK-PSDA-mail_chatmode_copy_content"
    /// 读信保存动图
    static let saveImageForAsset = "LARK-PSDA-mail_read_save_image_for_asset"
    /// 读信保存图片
    static let saveImageCreationRequestForAsset = "LARK-PSDA-mail_read_save_image_creation_request"
    /// 读信编辑保存动图
    static let editImageSaveForAsset = "LARK-PSDA-mail_read_edit_image_save_for_asset"
    /// 读信编辑保存图片
    static let editImageSaveCreationRequestForAsset = "LARK-PSDA-mail_read_edit_image_save_creation_request"
    /// 写信添加图片
    static let addImage = "LARK-PSDA-mail_compose_add_image"
    /// 写信添加视频
    static let addVideo = "LARK-PSDA-mail_compose_add_video"
}
