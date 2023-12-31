//
//  Attachment.swift
//  Action
//
//  Created by tefeng liu on 2019/6/8.
//

import Foundation
import UniverseDesignColor
import UIKit

// MARK: AttachmentType
typealias MainAttachmentType = DriveFileType

/// 显示过期时间相关
protocol MailAttachmentExpiring {
    typealias MailAttachmentExpireDisplayInfo = (expireText: String, textColor: UIColor, expireDateType: ExpireDateType)

    var expireTime: Int64 { get }

    var expireDisplayInfo: MailAttachmentExpireDisplayInfo { get }
}

enum ExpireDateType: String {
    case none
    case normal
    case warning
    case expired
}

extension MailAttachmentExpiring {
    var expireDisplayInfo: MailAttachmentExpireDisplayInfo {
        let expireTime = Double(expireTime / 1000)
        let toExpireDays = Date().daysTo(dueDate: Date(timeIntervalSince1970: expireTime))

        let expireDateType: ExpireDateType
        let textColor: UIColor
        let expireText: String

        if expireTime == 0 {
            expireDateType = .none
            textColor = UIColor.ud.textPlaceholder
            expireText = ""
        } else {
            if let toExpireDays = toExpireDays {
                // 判断颜色
                // 判断过期时间
                if !FeatureManager.open(.largefileUploadOpt) && toExpireDays > 3 {
                    //超过3天过期，显示普通文本颜色
                    expireDateType = .normal
                    textColor = UIColor.ud.textPlaceholder
                } else if expireTime > Date().timeIntervalSince1970 {
                    //没过期的，显示warning颜色
                    expireDateType = .warning
                    textColor = UIColor.ud.functionWarningContentDefault
                } else {
                    //已过期，显示expired颜色
                    expireDateType = .expired
                    textColor = UIColor.ud.functionDangerContentDefault
                }

                // 判断文案
                if toExpireDays > 0 {
                    // 显示几天后过期的文案
                    expireText = BundleI18n.MailSDK.Mail_Attachments_DaysExpired(toExpireDays)
                } else if expireTime > Date().timeIntervalSince1970 {
                    // 当天准备过期的，显示当天过期文案
                    expireText = BundleI18n.MailSDK.Mail_Attachments_ExpiredToday
                } else {
                    // 已过期的，显示已过期
                    expireText = BundleI18n.MailSDK.Mail_Attachments_Expired
                }
            } else {
                MailLogger.error("toExpireDays is nil for \(expireTime)")
                expireDateType = .none
                textColor = UIColor.ud.textPlaceholder
                expireText = ""
            }
        }

        return (expireText, textColor, expireDateType)
    }
}

// MARK: MailSendAttachment
protocol MailAttachmentProtocol {
    associatedtype OriginalItem

    var displayName: String { get }
    var fileExtension: MainAttachmentType { get }
    var fileSize: Int { get }
    /// 关联的对象
    var attachObject: OriginalItem? { get }
    var largeFilePermission: MailClientAttachement.AttachmentPermission { get }
}

struct MailSendAttachment: MailAttachmentProtocol, MailAttachmentExpiring, Equatable {
    var displayName: String = ""
    var fileExtension: MainAttachmentType = .unknown
    var fileSize: Int = 0
    /// 上传成功后的fileToken
    var fileToken: String?

    /// 上传相关附件 ↓
    /// 文件信息
    var fileInfo: MailSendFileInfoProtocol?
    /// 外部设置
    var attachObject: Any?
    /// 用于判断是否同个对象，一般用文件名+时间戳
    var hashKey: String?
    var largeFilePermission: MailClientAttachement.AttachmentPermission
    var type: MailClientAttachement.AttachmentType
    var expireTime: Int64 = 0
    var needConvertToLarge: Bool = false
    var cachePath: String?
    var needReplaceToken: Bool = false
    var emlUploadTask: EmlUploadTask?

    static func fileIcon(with fileName: String) -> UIImage {
        return UIImage.fileLadderIcon(with: fileName)
    }

    static func fileLadderIcon(with fileName: String) -> UIImage {
        return UIImage.fileLadderIcon(with: fileName)
    }

    static func fileBgColor(with fileName: String, withSize size: CGSize) -> UIColor {
        return UIImage.fileBgColor(with: fileName, withSize: size)
    }

    static func genExpireTime() -> Int64 {
        return (Int64(Date().timeIntervalSince1970) + (60 * 60 * 24 * Const.attachExpireDay)) * 1000
    }

    init(displayName: String,
                fileExtension: MainAttachmentType,
                fileSize: Int,
                largeFilePermission: MailClientAttachement.AttachmentPermission = .tenantReadable,
                type: MailClientAttachement.AttachmentType) {
        self.displayName = displayName
        self.fileExtension = fileExtension
        self.fileSize = fileSize
        self.largeFilePermission = largeFilePermission
        self.type = type
    }
    
    

    func attachmentIcon() -> UIImage {
        return MailSendAttachment.fileIcon(with: displayName)
    }

    func attachmentBgColor(withSize size: CGSize) -> UIColor {
        return MailSendAttachment.fileBgColor(with: displayName, withSize: size)
    }

    static func == (lhs: MailSendAttachment, rhs: MailSendAttachment) -> Bool {
        if let aToken = lhs.fileToken, let bToken = rhs.fileToken, !aToken.isEmpty, !bToken.isEmpty {
            return aToken == bToken
        }
        if let a = lhs.hashKey, let b = rhs.hashKey {
            return a == b
        }
        return lhs.displayName == rhs.displayName
    }
}

extension MailClientAttachement: MailAttachmentExpiring {
    var fileType: String {
        return (fileName as NSString).pathExtension.lowercased() 
    }
}
