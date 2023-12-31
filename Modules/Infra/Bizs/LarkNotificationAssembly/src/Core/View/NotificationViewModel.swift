//
//  NotificationViewModel.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/12/14.
//

import Foundation
import NotificationUserInfo
import LarkLocalizations
import LarkAccountInterface
import LarkContainer
import UniverseDesignColor
import LarkRustClient
import LKCommonsLogging

typealias ReplyTracker = NotificationTracker.QuickReply
typealias i18N = BundleI18n.LarkNotificationAssembly

final class NotificationViewModel {

    let logger = Logger.log(NotificationViewModel.self, category: "LarkNotificationAssembly")

    let userInfo: UserInfo
    let currentUserId: String

    private lazy var rustAPI: NotificationRustAPI = {
        NotificationRustAPI()
    }()

    private var rustService: RustService?

    /// userResolver: 当前登录用户的
    init(userInfo: UserInfo, currentUserId: String) {
        self.userInfo = userInfo
        self.currentUserId = currentUserId
        if let extra = self.userInfo.nseExtra, let userId = extra.userId {
            let type: UserScopeType = self.currentUserId == userId ? .foreground : .background
            let userResolver = try? Container.shared.getUserResolver(userID: extra.userId, type: type)
            self.rustService = try? userResolver?.resolve(type: RustService.self)
        }
    }

    var isShowDetail: Bool {
        guard let extra = self.userInfo.nseExtra else {
            return false
        }
        return extra.isShowDetail
    }

    var title: String {
        guard let extra = self.userInfo.nseExtra else {
            return LanguageManager.bundleDisplayName
        }
        let placeholderName = "--"
        /// 不展示详情
        if !extra.isShowDetail {
            return placeholderName
        }
        if !extra.groupName.isEmpty {
            return extra.groupName
        }
        return !extra.senderName.isEmpty ? extra.senderName : placeholderName
    }

    var subTitle: String {
        guard let extra = self.userInfo.nseExtra,
              let userId = extra.userId else {
            return ""
        }
        if !extra.tenantName.isEmpty {
            return extra.tenantName
        }
        guard let userResolver = try? Container.shared.getUserResolver(userID: self.currentUserId, type: .foreground) else {
             return ""
         }
         guard let passportService = try? userResolver.resolver.resolve(type: PassportService.self) else {
             return ""
         }
         let user = passportService.getUser(userId)
         return user?.tenant.tenantName ?? ""
    }

    var switchTenantTitle: String {
        return i18N.Lark_MessageNotifications_FromOtherAccounts_SwitchAccount_Button
    }

    var closeDialogTitle: String {
        return i18N.Lark_MessageNotifications_FromOtherAccounts_Exit_Desc
    }

    var closeButtonTitle: String {
        return i18N.Lark_MessageNotifications_FromOtherAccounts_Exit_Button
    }

    var editButtonTitle: String {
        return i18N.Lark_MessageNotifications_FromOtherAccounts_ExitStay_Button
    }

    var imageURL: URL? {
        guard let url = self.userInfo.nseExtra?.imageUrl else {
            return nil
        }
        return URL(string: url)
    }

    var placeHolderImage: UIImage {
        return BundleResources.LarkNotificationAssembly.placeholder_avatar
    }

    var noteText: String {
        return i18N.Lark_MessageNotifications_FromOtherAccounts_SwitchAccountToView_Text
    }
    
    var isNoteTextHidden: Bool {
        return self.isShowDetail
    }

    var nameLabelIsHidden: Bool {
        guard let extra = self.userInfo.nseExtra else {
            return true
        }
        return extra.groupName.isEmpty
    }

    var senderName: String {
        return self.userInfo.nseExtra?.senderName ?? ""
    }

    var content: String {
        return self.userInfo.alert?.body ?? ""
    }

    var contentLabelColor: UIColor {
        guard let extra = self.userInfo.nseExtra else {
            return UDColor.textTitle
        }
        if extra.isRecall {
            return UDColor.textCaption
        }
        return UDColor.textTitle
    }

    var urgentIconIsHidden: Bool {
        guard let extra = self.userInfo.nseExtra else {
            return true
        }
        return !extra.isUrgent
    }
    
    var replySuccessToast: String {
        return i18N.Lark_MessageNotifications_FromOtherAccounts_MessageSent_Toast
    }
    
    var replyFailToast: String {
        return i18N.Lark_MessageNotifications_FromOtherAccounts_UnableTosend_Toast
    }

    func sendReplyMessage(text: String, completionHandler: ((_ success: Bool) -> Void)? = nil) {
        guard let extra = self.userInfo.nseExtra else {
            self.logger.error("extra is nil")
            return
        }
        guard let messageId = extra.messageID, let chatId = extra.chatId else {
            self.logger.error("messageId or chatId is nil")
            return
        }
        self.rustAPI.sendReplyMessage(text, 
                                      rustService: rustService,
                                      userId: extra.userId,
                                      messageID: String(messageId),
                                      chatID: String(chatId)) { [weak self] success in
            guard let `self` = self else { return }
            completionHandler?(success)
            if success {
                ReplyTracker.clickSend(msgId: String(messageId),
                                       userId: extra.userId ?? "",
                                       ifCrossTenant: extra.userId != self.currentUserId,
                                       isRemote: extra.isRemote)
            }
        }
    }

    func sendReaction(_ key: String, completionHandler: ((_ success: Bool) -> Void)? = nil) {
        guard let extra = self.userInfo.nseExtra else {
            self.logger.error("extra is nil")
            return
        }
        guard let messageId = extra.messageID else {
            self.logger.error("messageId is nil")
            return
        }
        self.rustAPI.sendReaction(key, rustService: rustService, userId: extra.userId, messageID: String(messageId)) { [weak self] success in
            guard let `self` = self else { return }
            completionHandler?(success)
            if success {
                ReplyTracker.clickSend(msgId: String(messageId),
                                       userId: extra.userId ?? "",
                                       ifCrossTenant: extra.userId != self.currentUserId,
                                       isRemote: extra.isRemote)
            }
        }
    }

    func sendReadMessage() {
        guard let extra = self.userInfo.nseExtra else {
            self.logger.error("extra is nil")
            return
        }
        guard let messageId = extra.messageID, let chatId = extra.chatId else {
            self.logger.error("messageId or chatId is nil")
            return
        }
        self.rustAPI.sendReadMessage(String(messageId), rustService: rustService, userId: extra.userId, chatID: String(chatId))
    }
}
