//
//  MailClientTemplateDownloadState.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/2/23.
//

import Foundation

enum MailClientTemplateDownloadState: String {
    /// ready，可以直接打开，不显示下载和关闭按钮，支持用户点击附件打开
    case ready = "0"
    /// 需要下载，显示下载按钮
    case needDownload = "1"
    /// 正在下载，显示进度和关闭按钮
    case downloading = "2"
}
