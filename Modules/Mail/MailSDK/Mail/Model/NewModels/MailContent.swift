//
//  MailContent.swift
//  MailSDK
//
//  Created by majx on 2019/8/13.
//

import Foundation

struct MailContent {
    var from: MailAddress
    var to: [MailAddress]
    var cc: [MailAddress]
    var bcc: [MailAddress]
    var atContacts: [MailAddress]
    var subject: String
    var bodySummary: String
    var bodyHtml: String
    var subjectCover: MailSubjectCover?
    var attachments: [MailAttachment]
    var images: [MailImageInfo]
    var docsConfigs: [MailClientDocsPermissionConfig]
    var docsJsonConfigs: [[String: Any]]
    var priorityType: MailPriorityType
    var needReadReceipt: Bool

    init(from: MailAddress,
         to: [MailAddress],
         cc: [MailAddress],
         bcc: [MailAddress],
         atContacts: [MailAddress],
         subject: String,
         bodySummary: String,
         bodyHtml: String,
         subjectCover: MailSubjectCover?,
         attachments: [MailAttachment],
         images: [MailImageInfo],
         priorityType: MailPriorityType,
         needReadReceipt: Bool,
         docsConfigs: [MailClientDocsPermissionConfig]) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.atContacts = atContacts
        self.subject = subject
        self.bodySummary = bodySummary
        self.bodyHtml = bodyHtml
        self.subjectCover = subjectCover
        self.attachments = attachments
        self.images = images
        self.docsConfigs = docsConfigs
        self.docsJsonConfigs = docsConfigs.map { MailContent.getDocsJsonConfig(config: $0) }
        self.priorityType = priorityType
        self.needReadReceipt = needReadReceipt
    }

    static func getDocsJsonConfig(config: MailClientDocsPermissionConfig) -> [String: Any] {
        ["docUrl": config.docURL, "action": config.action.rawValue]
    }

    init(subject: String,
         bodySummary: String,
         bodyHtml: String,
         subjectCover: MailSubjectCover?,
         images: [MailImageInfo],
         docsConfigs: [MailClientDocsPermissionConfig]) {
        self.subject = subject
        self.bodySummary = bodySummary
        self.bodyHtml = bodyHtml
        self.images = images
        self.docsConfigs = docsConfigs
        self.subjectCover = subjectCover
        self.docsJsonConfigs = docsConfigs.map { MailContent.getDocsJsonConfig(config: $0) }

        self.from = MailAddress(name: "", address: "", larkID: "", tenantId: "", displayName: "", type: nil)
        self.to = []
        self.cc = []
        self.bcc = []
        self.atContacts = []
        self.attachments = []
        self.priorityType = .normal
        self.needReadReceipt = false
    }

    init(with clientDraft: MailClientDraft) {
        self.init(from: MailAddress(with: clientDraft.from),
                  to: clientDraft.to.map { MailAddress(with: $0) },
                  cc: clientDraft.cc.map { MailAddress(with: $0) },
                  bcc: clientDraft.bcc.map { MailAddress(with: $0) },
                  atContacts: clientDraft.bcc.map { MailAddress(with: $0) }, // vvlong_todo: 修改传入的值
                  subject: clientDraft.subject,
                  bodySummary: clientDraft.bodySummary,
                  bodyHtml: clientDraft.bodyHtml,
                  subjectCover: MailSubjectCover.decode(from: clientDraft.coverInfo),
                  attachments: clientDraft.attachments.map {MailAttachment(fileName: $0.fileName,
                                                                          fileKey: $0.fileToken,
                                                                          type: $0.type,
                                                                          fileSize: $0.fileSize, largeFilePermission: $0.largeFilePermission, expireTime: $0.expireTime,
                                                                          needConvertToLarge: $0.needConvertToLarge)
                  },
                  images: clientDraft.images.map { MailImageInfo.convertFromPBModel($0) },
                  priorityType: clientDraft.priorityType,
                  needReadReceipt: clientDraft.needReadReceipt,
                  docsConfigs: clientDraft.docsPermissions)
    }

    init(with clientMessage: MailClientMessage) {
        self.init(from: MailAddress(with: clientMessage.from),
                  to: clientMessage.to.map { MailAddress(with: $0) },
                  cc: clientMessage.cc.map { MailAddress(with: $0) },
                  bcc: clientMessage.bcc.map { MailAddress(with: $0) },
                  atContacts: clientMessage.bcc.map { MailAddress(with: $0) }, // vvlong_todo: 修改传入的值
                  subject: clientMessage.subject,
                  bodySummary: clientMessage.bodySummary,
                  bodyHtml: clientMessage.bodyHtml,
                  subjectCover: MailSubjectCover.decode(from: clientMessage.coverInfo),
                  attachments: clientMessage.attachments.map {MailAttachment(fileName: $0.fileName,
                                                                          fileKey: $0.fileToken,
                                                                          type: $0.type,
                                                                          fileSize: $0.fileSize, largeFilePermission: $0.largeFilePermission, expireTime: $0.expireTime,
                                                                          needConvertToLarge: $0.needConvertToLarge)
                  },
                  images: clientMessage.images.map { MailImageInfo.convertFromPBModel($0) },
                  priorityType: .normal,
                  needReadReceipt: false,
                  docsConfigs: [])
    }
}

extension MailContent: Equatable {
    static func == (lhs: MailContent, rhs: MailContent) -> Bool {
        if lhs.from != rhs.from { return false }
        if lhs.to != rhs.to { return false }
        if lhs.cc != rhs.cc { return false }
        if lhs.bcc != rhs.bcc { return false }
        if lhs.atContacts != rhs.atContacts { return false }
        if lhs.subject != rhs.subject { return false }
        if lhs.attachments != rhs.attachments { return false }
        if lhs.subjectCover != rhs.subjectCover { return false }
        if lhs.priorityType != rhs.priorityType { return false }
        if lhs.needReadReceipt != rhs.needReadReceipt { return false }
        return true
    }
}

extension MailContent {
    func calculateMailSize(ignoreAttachment: Bool = false) -> Float {
        /// calculate string size
        ///
        /// 正文编码为quoted-printable（新版，推荐方式）
        /// M1: 正文中单个字节<128
        /// M2: 正文中单个字节>=128 （中文按UTF-8编码后再处理）
        /// E：添加HTML标记，2048字节
        /// P：图片占用字节数
        /// A：附件占用字节数
        /// 不重复加纯文本的算法， MailSize = ((M1 + M2 * 3 + E)  + (P + A) * 1.34
        /// 加上纯文本的算法，MailSize = ((M1 + M2 * 3) * 2 + E)  + (P + A) * 1.34

        /// address
//        var addressString = from.address
//        to.forEach { addressString += $0.address }
//        cc.forEach { addressString += $0.address }
//        bcc.forEach { addressString += $0.address }
//        let addressSize = Int64(addressString.utf8.count)

        /// mail subject + body html
//        var contentString = subject
//        contentString += bodyPlaintext
//        /// quoted printable encode
//        let estimateEncodeBytesCount = QuotedPrintable.estimateEncodeBytesCount(string:contentString)
//        /// html tag size estimate 2048
//        let contentSize: Int64 = (estimateEncodeBytesCount * 2) + 2048

        /// resource
        var attachmentsSize: Int64 = 0
        attachments.filter({ (item) -> Bool in
            let type = DriveFileType(rawValue: String(item.fileName.split(separator: ".").last ?? "").lowercased())
            return type?.isHarmful != true
        }).forEach {
            if $0.type != .large {
                attachmentsSize += $0.fileSize
            }
        }
        var imagesSize: Int64 = 0
        images.forEach { imagesSize += $0.dataSize }
        /// estimate base64 encode size

        var resourceSize = Float(attachmentsSize + imagesSize)
        if ignoreAttachment {
            resourceSize = Float(imagesSize)
        }
        /// all
//        let allSize = Float(addressSize) + Float(contentSize) + Float(resourceSize)

        /// mb size = allSize / 1024*1024
        /// 需求变化，移动端也需要计算正文大小
        let contentSize = Int64(bodyHtml.utf8.count)
        return (Float(contentSize) + resourceSize) / (1024 * 1024)
    }
}
