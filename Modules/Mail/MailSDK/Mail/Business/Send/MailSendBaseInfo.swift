//
//  MailSendBaseInfo.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2019/12/24.
//

import Foundation

enum MailSendAction {
    case new
    case reply
    case replyAll
    case forward
    case draft
    case messagedraft
    case outOfOffice
    case fromAddress
    case sendToChat_Reply
    case sendToChat_Forward
    case share
    case reEdit
    case fromAIChat //ai场景对话
    
    var isReply: Bool {
        switch self {
        case .reply, .replyAll, .reply:
            return true
        default:
            return false
        }
    }
    
    var isForward: Bool {
        switch self {
        case .forward, .sendToChat_Forward:
            return true
        default:
            return false
        }
    }
}

struct MailSendStatInfo {
    /// 那个入口拉起的mailSend
    enum From {
        case routerPullUp
        case threadListCreate
        case threadList // 弃用
        case threadListDraft
        case messageAddress
        case messageReply
        case messageReplyAll
        case messageForward
        case messageDraftClick
        case messageOutboxEdit
        /// 点击at联系人，没有找到当前联系人，弹起写信页
        case messageHandleAt
        case msgReEdit
        case search // 保留用 暂时没有使用场景
        case chatSideBar
        case chat // 未发送的草稿进行分享
        case notification
        case outOfOffice
        case sendSig // 从签名的url中跳转
        case emlAsAttachment
        case attachmentManager // 附件管理列表
        case feedMessageList
    }

    let from: From

    // 三言两语说不清 @liutefeng
    let newCoreEventLabelItem: String
    var emlAsAttachmentInfos: [EmlAsAttachmentInfo] = [] //需要转附件的messageId
}
struct EmlAsAttachmentInfo {
    let subject: String
    let bizId: String
    var fileSize: Int64?
}

struct MailSendBaseInfo {
    var threadID: String?
    let messageID: String?
    var permissionCode: MailPermissionCode? {
        return mailItem?.code
    }
    var chatID: String?
    let currentLabelId: String
    let statInfo: MailSendStatInfo
    var mailItem: MailItem?
    var sendToAddress: String?
    var toAddress: String?
    var ccAddress: String?
    var bccAddress: String?
    var subject: String?
    var body: String?
    var fileBannedInfos: [String: FileBannedInfo]? // 附件封禁状态

    init(threadID: String?,
         messageID: String?,
         chatID: String?,
         currentLabelId: String,
         statInfo: MailSendStatInfo,
         mailItem: MailItem?,
         sendToAddress: String?,
         fileBannedInfos: [String: FileBannedInfo]?) {
        self.threadID = threadID
        self.messageID = messageID
        self.chatID = chatID
        self.currentLabelId = currentLabelId
        self.statInfo = statInfo
        self.mailItem = mailItem
        self.sendToAddress = sendToAddress?.replacingOccurrences(of: "mailto:", with: "")
        self.fileBannedInfos = fileBannedInfos
        parseMailTo()
    }

    mutating func parseMailTo() {
        guard let sendToAddress = sendToAddress, let url = URL(string: sendToAddress) else { return }
        toAddress = url.path
        let components = URLComponents(string: sendToAddress)
        components?.queryItems?.forEach({ (item) in
            switch item.name {
            case "subject":
                if let subject = item.value {
                    self.subject = subject
                }
            case "body":
                if let body = item.value {
                    self.body = body
                }
            default:
                ()
            }
        })
    }

    var currentAccount: MailAccount?

    /// 是否是发表人
    func isShareThreadOwner() -> Bool {
        if permissionCode == .owner {
            return true
        }
        return false
    }

    func isSharedAccount() -> Bool {
        return self.currentAccount?.isShared ?? false
    }

    var sharedAccountId: String? {
        return self.currentAccount?.mailAccountID
    }
}

extension MailSendAction {
    func getDraftAction() -> DraftAction {
        var draftAction: DraftAction = .reply
        switch self {
        case .new, .fromAddress, .fromAIChat:
            draftAction = .compose
        case .reply:
            draftAction = .reply
        case .replyAll:
            draftAction = .replyAll
        case .forward:
            draftAction = .forward
        default:
            ()
        }
        return draftAction
    }
}

extension DraftAction {
    func getSendAction() -> MailSendAction {
        var sendAction: MailSendAction
        switch self {
        case .reply:
            sendAction = .reply
        case .compose:
            sendAction = .new
        case .replyAll:
            sendAction = .replyAll
        case .forward:
            sendAction = .forward
        @unknown default:
            sendAction = .reply
        }
        return sendAction
    }
}
