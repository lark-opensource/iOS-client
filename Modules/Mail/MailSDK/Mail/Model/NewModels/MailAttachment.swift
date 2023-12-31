//
//  MailAttachment.swift
//  MailSDK
//
//  Created by majx on 2019/8/13.
//

import Foundation
import LarkAppConfig

struct MailAttachment {
    var fileName: String
    var fileKey: String
    var type: MailClientAttachement.AttachmentType
    var fileSize: Int64
    var largeFilePermission: MailClientAttachement.AttachmentPermission
    var jsonDic: [String: Any] {
        ["name": fileName, "token": fileKey, "size": fileSize, "type": type.rawValue]
    }
    var expireTime: Int64
    var needConvertToLarge: Bool
    var needReplaceToken: Bool = false
}

extension MailAttachment {
    func toPBModel() -> MailClientAttachement {
        var clientAttachement = MailClientAttachement()
        clientAttachement.fileName = fileName
        clientAttachement.fileToken = fileKey
        clientAttachement.fileSize = fileSize
        clientAttachement.fileURL = ""
        clientAttachement.largeFilePermission = largeFilePermission
        clientAttachement.type = type
        clientAttachement.expireTime = expireTime
        clientAttachement.needConvertToLarge = needConvertToLarge
        // gen largefileUrl
        if type == .large {
            let domain =  ConfigurationManager.shared.settings
            if expireTime > 0 || FeatureManager.open(.largeAttachmentManage,
                                                     openInMailClient: false) {
                if let biffDomain = MailEditorLoader.getBffDomain(domain: domain)?.first,
                    !biffDomain.isEmpty {
                    clientAttachement.largeFileURL = "https://\(biffDomain)/mail/page/attachment?token=\(fileKey)"
                } else {
                    MailLogger.error("[attachmentUrl] can't get bffDomain")
                }
            } else {
                if let homeDomain = MailEditorLoader.getHomeDomain(domain: domain)?.first,
                    !homeDomain.isEmpty {
                    clientAttachement.largeFileURL = "https://\(homeDomain)/file/\(fileKey)"
                } else {
                    MailLogger.error("[attachmentUrl] can't get homeDomain")
                }
            }
        }
        return clientAttachement
    }
}

extension MailAttachment: Equatable {
    static func == (lhs: MailAttachment, rhs: MailAttachment) -> Bool {
        if lhs.fileName != rhs.fileName { return false }
        if lhs.fileKey != rhs.fileKey { return false }
        if lhs.type != rhs.type { return false }
        if lhs.fileSize != rhs.fileSize { return false }
        if lhs.largeFilePermission != rhs.largeFilePermission { return false }
        if lhs.expireTime != rhs.expireTime { return false }
        if lhs.needConvertToLarge != rhs.needConvertToLarge { return false }
        return true
    }
}
