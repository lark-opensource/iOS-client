//
//  MailSecurityAudit.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2022/9/8.
//

import Foundation
import LarkSecurityAudit
import RustPB
import RxSwift

private typealias AuditEvent = LarkSecurityAudit.Event

enum MailAuditEventType {

    enum AuditCopyContentType: String {
        case RichText
    }

    /// 切换到公共邮箱
    case switchToSharedMail(name: String, sender: String)
    /// 点击读信URL
    case readMailClickURL(mailInfo: AuditMailInfo, urlString: String)
    /// 分享drive附件，TODO: 还需要添加会话相关字段
    case driveFileShareToChat(mailInfo: AuditMailInfo, isLarge: Bool, fileInfo: DriveAttachmentInfo, shareInfo: AuditShareAttachmentInfo, origin: String)
    /// 下载Drive文件
    case driveFileDownload(mailInfo: AuditMailInfo, isLarge: Bool, fileInfo: DriveAttachmentInfo, origin: String)
    /// 第三方app打开
    case driveFileOpenViaApp(mailInfo: AuditMailInfo, isLarge: Bool, appID: String, isSuccess: Bool, fileInfo: DriveAttachmentInfo, origin: String)
    /// 复制读信内容
    case copyMailContent(mailInfo: AuditMailInfo, copyContentTypes: Set<AuditCopyContentType>)
    case largeAttachmentDelete(mailInfo: AuditMailInfo, fileID: String, fileSize: Int, fileName: String)
    
    case emlAsAttachment(mailInfo: AuditMailInfo, fileId: String, fileSize: Int)

    var operation: SecurityEvent_OperationType {
        switch self {
        case .switchToSharedMail:
            return .operationEmailLogin
        case .readMailClickURL:
            return .operationEmailUrlclick
        case .driveFileShareToChat:
            return .operationEmailShareFile
        case .driveFileDownload:
            return .operationEmailDownloadFile
        case .driveFileOpenViaApp:
            return .operationEmailLocalOpen
        case .copyMailContent:
            return .operationEmailCopy
        case .emlAsAttachment:
            return .operationEmailEmlAsAttachment
        case .largeAttachmentDelete:
            return .operationEmailDelBigFile
        }
    }
}

struct AuditShareAttachmentInfo {
    /// 用 ; 分割
    let chatTypes: String
    /// 用 ; 分割
    let chatNames: String
    /// 用 ; 分割
    let chatIDs: String
    /// true or false
    let hasExternal: String

    static func fromForwardItems(_ items: [MailForwardItemParam]) -> AuditShareAttachmentInfo {
        var chatTypes = ""
        var chatNames = ""
        var chatIDs = ""
        var hasExternal = false
        // 用 ; 分割多个值
        let seperateBlock: ((Bool, String) -> String) = { isFirst, val in
            return isFirst ? val : ";\(val)"
        }
        for item in items {
            chatTypes.append(seperateBlock(chatTypes.isEmpty, item.type))
            chatNames.append(seperateBlock(chatNames.isEmpty, item.name))
            chatIDs.append(seperateBlock(chatIDs.isEmpty, item.chatID))

            if !hasExternal && item.isCrossTenant {
                /// 只要有一个外部，就算外部
                hasExternal = true
            }
        }
        return AuditShareAttachmentInfo(chatTypes: chatTypes, chatNames: chatNames, chatIDs: chatIDs, hasExternal: hasExternal ? "true" : "false")
    }
}

struct AuditMailInfo {
    let smtpMessageID: String
    let subject: String
    let sender: String
    let ownerID: String?
    let isEML: Bool

    func toLogDict(userID: String) -> [String: String] {
        let mailOwner: String
        if (ownerID != nil && ownerID != userID) || isEML {
            // 不是我的分享邮件 或者是 EML，不打mailOwner
            mailOwner = ""
        } else {
            mailOwner = Store.settingData.currentAccount.value?.accountAddress ?? ""
        }
        return ["messageID": smtpMessageID, "mailSubject": subject, "mailOwner": mailOwner]
    }
}

/// 接入安全审计SDK，https://bytedance.feishu.cn/wiki/wikcnbcnrztW2R9ZyXJvayjPLjf
final class MailSecurityAudit {
    private let user: User
    private let securityAudit: SecurityAudit
    private let disposeBag = DisposeBag()

    init(user: User) {
        self.user = user
        self.securityAudit = SecurityAudit()
    }

    private func getEvent(_ type: MailAuditEventType) -> AuditEvent {
        var event = AuditEvent()
        let userID = user.userID
        // 操作者
        var op = OperatorEntity()
        op.type = .entityUserID
        op.value = userID
        event.operator = op
        // 操作对象
        var obj = SecurityEvent_ObjectEntity()
        obj.type = .entityUserID
        // 生成uuid避免后端入库去重，因为后端通过 事件名 + 操作者 + 操作对象 +  接收者 + 时间(s) 去重
        obj.value = "\(MailTracker.getCurrentTime())"
        event.objects = [obj]

        event.module = .moduleApp
        event.operation = type.operation
        event.tenantID = user.tenantID
        return event
    }

    private func getDrawer(dic: [String: String]) -> SecurityEvent_CommonDrawer {
        var drawer = SecurityEvent_CommonDrawer()
        var renderItems: [SecurityEvent_RenderItem] = []
        for item in dic {
            var renderItem = SecurityEvent_RenderItem()
            renderItem.key = item.key
            renderItem.value = item.value
            renderItem.renderTypeValue = .plainText
            renderItems.append(renderItem)
        }
        drawer.itemList = renderItems.sorted(by: { $0.key < $1.key })
        return drawer
    }

    private func dictFromFileInfo(_ fileInfo: DriveAttachmentInfo, isLarge: Bool) -> [String: String] {
        var dict = [String: String]()
        dict["fileID"] = fileInfo.token
        dict["fileSize"] = FileSizeHelper.memoryFormat(fileInfo.size, useAbbrByte: true, spaceBeforeUnit: true)
        dict["fileName"] = fileInfo.name
        dict["isLargeFile"] = isLarge ? "true" : "false"
        return dict
    }
    
    private func dictFromShareInfo(_ info: AuditShareAttachmentInfo) -> [String: String] {
        var dict = [String: String]()
        dict["chatType"] = info.chatTypes
        dict["chatName"] = info.chatNames
        dict["chatID"] = info.chatIDs
        dict["externalChat"] = info.hasExternal
        return dict
    }

    func audit(type: MailAuditEventType) {
        guard Store.settingData.currentAccount.value?.mailSetting.userType != .tripartiteClient,
              Store.settingData.currentAccount.value?.isFreeBindUser == false
        else {
            MailLogger.info("MailAudit tripartiteClient and freeBind account don't audit")
            return
        }
        var dict = [String: String]()
        switch type {
        case .switchToSharedMail(let name, let address):
            dict["shareAccountName"] = name
            dict["shareAccountAddress"] = address
        case .driveFileDownload(let mailInfo, let isLarge, let fileInfo, let origin):
            dict.merge(other: mailInfo.toLogDict(userID: user.userID))
            dict.merge(other: dictFromFileInfo(fileInfo, isLarge: isLarge))
            dict.merge(other: ["origin": origin])
        case .readMailClickURL(let mailInfo, let urlString):
            dict.merge(other: mailInfo.toLogDict(userID: user.userID))
            dict["url"] = urlString
        case .driveFileShareToChat(let mailInfo, let isLarge, let fileInfo, let shareInfo, let origin):
            dict.merge(other: mailInfo.toLogDict(userID: user.userID))
            dict.merge(other: dictFromFileInfo(fileInfo, isLarge: isLarge))
            dict.merge(other: dictFromShareInfo(shareInfo))
            dict.merge(other: ["origin": origin])
        case .driveFileOpenViaApp(let mailInfo, let isLarge, let appID, let isSuccess, let fileInfo, let origin):
            dict.merge(other: mailInfo.toLogDict(userID: user.userID))
            dict.merge(other: dictFromFileInfo(fileInfo, isLarge: isLarge))
            dict.merge(other: ["appID": appID, "OpResult": isSuccess ? "success" : "fail"])
            dict.merge(other: ["origin": origin])
        case .copyMailContent(let mailInfo, let copyContentTypes):
            dict.merge(other: mailInfo.toLogDict(userID: user.userID))
            let contentType: String = copyContentTypes.reduce("") { res, type in
                var res = res
                if res.count == 0 {
                    res.append(type.rawValue)
                } else {
                    res.append(",\(type.rawValue)")
                }
                return res
            }
            dict["copyContentType"] = contentType
        case .emlAsAttachment(let mailInfo, let fileId, let fileSize):
            dict.merge(other: mailInfo.toLogDict(userID: user.userID))
            dict.merge(other: ["fileID": fileId, "fileSize": FileSizeHelper.memoryFormat(UInt64(fileSize), useAbbrByte: true, spaceBeforeUnit: true)])
        case .largeAttachmentDelete(let mailInfo, let fileID, let fileSize, let fileName):
            dict.merge(other: mailInfo.toLogDict(userID: user.userID))
            dict.merge(other: ["fileID": fileID,
                               "fileSize": FileSizeHelper.memoryFormat(UInt64(fileSize), useAbbrByte: true, spaceBeforeUnit: true),
                               "fileName": fileName])
        }

        let commonDrawer = getDrawer(dic: dict)
        var event = getEvent(type)
        event.extend.commonDrawer = commonDrawer

        let logString = commonDrawer.itemList.reduce("") { partialResult, item in
            return partialResult + ",\(item.key): \(item.value)"
        }
        securityAudit.auditEvent(event)
    }
}
