//
//  MailAttachmentsListCellViewModel.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/23.
//

import Foundation
import RxSwift
import RustPB
import LarkLocalizations
import LarkFoundation
import LarkExtensions
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkFeatureGating
import UniverseDesignTheme

class MailAttachmentsListCellViewModel {
    var fileName: String?
    var fileToken: String?
    var fileSize: Int64?
    var createdTime: Int64?
    var status: MailLargeAttachmentStatus = .default
    var isMountPointExplorer: Bool = false
    var mailMessageBizID: String?
    var mailThreadID: String?
    var mailSmtpID: String?
    var fileType: String?
    var infoListType: MailLargeAttachmentInfoListType = .fileInfo// 文件夹类型还是普通附件
//    var fileID = Int64
    var createdTimeStr: String?
    var isFlagged: Bool = false
    var desc: String? // 文件描述： 文件大小 + 创建时间
    var isDraft: Bool

    init(with attachmentInfo: MailLargeAttachmentInfo) {
        fileName = attachmentInfo.fileName
        fileToken = attachmentInfo.fileToken
        fileSize = attachmentInfo.fileSize
        createdTime = attachmentInfo.createdTime
        status = attachmentInfo.status
        infoListType = attachmentInfo.infoListType
        isMountPointExplorer = attachmentInfo.isMountPointExplorer
        mailMessageBizID = attachmentInfo.mailMessageBizID
        mailThreadID = attachmentInfo.mailThreadBizID
        mailSmtpID = attachmentInfo.mailSmtpID
        isDraft = attachmentInfo.isDraft
        if let createdTime = createdTime {
            createdTimeStr = ProviderManager.default.timeFormatProvider?.mailLargeAttachmentTimeFormat(createdTime) ?? ""
        }
        if let fileSize = fileSize {
            desc = FileSizeHelper.memoryFormat(UInt64(fileSize)) + " ｜ " + (createdTimeStr ?? "")
        }
        if let fileName = fileName {
            fileType = String(fileName.split(separator: ".").last ?? "")
        }
    }
}
