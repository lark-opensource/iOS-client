//
//  ChatTopNoticeServiceImp.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/11/8.
//
import Foundation
import LarkUIKit
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import LarkCore
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import LarkContainer
import ByteWebImage
import EENavigator
import LarkMessageBase
import LarkSetting
import LarkAlertController
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignActionPanel
import TangramService
import UIKit

public final class ChatTopNoticeServiceImp: ChatTopNoticeService, UserResolverWrapper {
    public let userResolver: UserResolver

    private static let logger = Logger.log(ChatTopNoticeServiceImp.self, category: "ChatTopNoticeServiceImp")
    @ScopedInjectedLazy var modelService: ModelService?
    @ScopedInjectedLazy var userActionService: TopNoticeUserActionService?
    @ScopedInjectedLazy var messageDynamicAuthorityService: MessageDynamicAuthorityService?
    private var debouncer: Debouncer = Debouncer()

    private let disposeBag = DisposeBag()
    private  var textAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        /// 设置富文本的内容以字符进行分割，防止内容中大量字母数字被解析成word过长而被省略，导致无法展示
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        return [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.ud.textTitle,
            .font: UIFont.systemFont(ofSize: 14),
            MessageInlineViewModel.iconColorKey: UIColor.ud.textTitle,
            MessageInlineViewModel.tagTypeKey: TagType.normal
        ]
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func createTopNoticeBannerWith(topNotice: ChatTopNotice,
                                           chatPush: BehaviorRelay<Chat>,
                                           fromVC: UIViewController?,
                                           closeHander: (() -> Void)?) -> UIView? {
        var view: UIView?
        let chatId = Int64(chatPush.value.id) ?? 0
        let chatterDic = topNotice.operator.chatChatters[chatPush.value.id]
        let pbOperator = chatterDic?.chatters.first?.value
        guard let pbOperator = pbOperator else {
            return nil
        }
        let operateChatter: Chatter? = try Chatter.transform(pb: pbOperator)
        guard let operateChatter = operateChatter else {
            assertionFailure("OperateChatterNotObtained")
            return nil
        }
        let messageID = String(topNotice.content.messageID)
        var message: Message?
        if !messageID.isEmpty {
            do {
                message = try Message.transform(entity: topNotice.content.entity,
                                                id: messageID,
                                                currentChatterID: userResolver.userID)
            } catch {
                Self.logger.error("get Message miss  messageID \(messageID)")
            }
        }
        /// 埋点相关
        let chat = chatPush.value
        let isTopNoticeOwner = userResolver.userID == operateChatter.id
        let isOnlyAdmin: Bool = chat.topNoticePermissionSetting == .onlyManager
        switch topNotice.content.type {
        case .announcementType:
            let pbSender = topNotice.content.entity.chatChatters[chatPush.value.id]?.chatters.first?.value
            var senderName: String = ""
            let senderId = String(topNotice.content.senderID) ?? ""
            let sender: Chatter? = try? Chatter.transformChatChatter(entity: topNotice.content.entity,
                                                                    chatID: chat.id,
                                                                    id: senderId)
            if let sender = sender {
                senderName = sender.displayName(chatId: chat.id,
                                                    chatType: chat.type,
                                                    scene: .reply)
            }
            let prefix = senderName.isEmpty ? "" : senderName + " : "
            let title = BundleI18n.LarkMessageCore.Lark_IMChatPin_PreviewGroupAnnouncement_Text + " " + topNotice.content.announcement.content
            let model = TopNoticeBannerModel(userResolver: self.userResolver,
                                             title: NSAttributedString(string: prefix + title, attributes: textAttributes),
                                             name: operateChatter.displayName(chatId: chat.id,
                                                                       chatType: chat.type,
                                                                       scene: .reply),
                                              type: .icon,
                                              fromChatter: operateChatter,
                                              placeholderImage: nil,
                                              closeCallBack: { [weak self, weak fromVC] _ in
                /// 这里需要用最新的chat，确保chat的权限
                self?.closeOrRemoveTopNotice(topNotice,
                                             chat: chatPush.value,
                                             fromVC: fromVC,
                                             trackerInfo: (message, isTopNoticeOwner),
                                             closeHander: closeHander)
            }, tapCallBack: { [weak self, weak fromVC] in
                self?.jumpToGroupAnnouncement(chatId, fromVC: fromVC)
                TopNoticeTracker.TopNoticeClick(chat, message, tapLocation: .content, isOnlyAdmin: isOnlyAdmin, isTopNoticeOwner: isTopNoticeOwner, topType: .announcement)
            }, fromUserClick: { [weak self, weak fromVC] (fromChatter) in
                self?.jumpToProfileFrom(fromChatter, fromVC: fromVC)
                TopNoticeTracker.TopNoticeClick(chat, message, tapLocation: .fromUser, isOnlyAdmin: isOnlyAdmin, isTopNoticeOwner: isTopNoticeOwner, topType: .announcement)
            })
            let topNoticeView = TopNoticeTextView()
            topNoticeView.model = model
            view = topNoticeView
            TopNoticeTracker.TopNoticeView(chatPush.value,
                                           message,
                                           isTopNoticeOwner: operateChatter.id == userResolver.userID, topType: .announcement)
        case .msgType:
            if let message = message {
                view = getTopNoticeViewWith(message,
                                            topNotice: topNotice,
                                            chat: chat,
                                            chatter: operateChatter,
                                            closeCallBack: { [weak self, weak fromVC] _ in
                    self?.closeOrRemoveTopNotice(topNotice,
                                                 chat: chatPush.value,
                                                 fromVC: fromVC,
                                                 trackerInfo: (message, isTopNoticeOwner),
                                                 closeHander: closeHander)
                }, tapCallBack: { [weak self, weak fromVC] in
                    self?.jumpToChat(chat: chatPush.value, message: message, fromVC: fromVC)
                    TopNoticeTracker.TopNoticeClick(chat, message, tapLocation: .content, isOnlyAdmin: isOnlyAdmin, isTopNoticeOwner: isTopNoticeOwner, topType: .message)
                }, fromUserClick: { [weak self, weak fromVC] (fromChatter) in
                    self?.jumpToProfileFrom(fromChatter, fromVC: fromVC)
                    TopNoticeTracker.TopNoticeClick(chat, message, tapLocation: .fromUser, isOnlyAdmin: isOnlyAdmin, isTopNoticeOwner: isTopNoticeOwner, topType: .message)
                })
            }
            TopNoticeTracker.TopNoticeView(chatPush.value,
                                           message,
                                           isTopNoticeOwner: operateChatter.id == userResolver.userID, topType: .message)
        case .unknown:
            break
        @unknown default:
            break
        }
        return view
    }

    func jumpToChat(chat: Chat, message: Message, fromVC: UIViewController?) {
        /// 防止连续点击-> 0.25 这里使用 weak fromVC， 不能影响原有的生命逻辑
        debouncer.debounce(indentify: "topMsg_banner", duration: 0.25) { [weak fromVC, weak self] in
            guard let fromVC = fromVC else {
                return
            }
            if chat.chatMode == .threadV2 {
                let body = ThreadDetailByIDBody(threadId: message.id, loadType: .root)
                self?.navigator.push(body: body, from: fromVC)
            } else {
                let body = ChatControllerByChatBody(chat: chat,
                                                    position: message.position,
                                                    messageId: message.id)
                self?.navigator.push(body: body, from: fromVC)
            }
        }
    }

    func jumpToGroupAnnouncement(_ chatId: Int64, fromVC: UIViewController?) {
        guard let fromVC = fromVC else {
            return
        }
        let body = ChatAnnouncementBody(chatId: String(chatId))
        self.navigator.push(body: body, from: fromVC)
    }

    func jumpToProfileFrom(_ chatter: Chatter?, fromVC: UIViewController?) {
        guard let fromVC = fromVC, let chatter = chatter else {
            return
        }
        let body = PersonCardBody(chatterId: chatter.id)
        self.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: fromVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    public func getTopNoticeMessageSummerize(_ message: Message,
                                             customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        var messageSummerize = NSMutableAttributedString(string: self.modelService?.messageSummerize(message) ?? "")
        messageSummerize.addAttributes(customAttributes, range: NSRange(location: 0, length: messageSummerize.length))
        switch message.type {
        case .text:
            if let textContent = message.content as? TextContent {
                let textDocsVM = TextDocsViewModel(userResolver: self.userResolver,
                                                   richText: textContent.richText,
                                                   docEntity: textContent.docEntity,
                                                   hangPoint: message.urlPreviewHangPointMap)
                let parseRichText = textDocsVM.parseRichText(
                    checkIsMe: nil,
                    needNewLine: false,
                    iconColor: UIColor.ud.textTitle,
                    customAttributes: customAttributes,
                    urlPreviewProvider: { elementID, _ in
                        let inlinePreviewVM = MessageInlineViewModel()
                        return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: customAttributes)
                    })
                messageSummerize = NSMutableAttributedString(string: "")
                let contentTitle: NSMutableAttributedString = parseRichText.attriubuteText
                if message.isCleaned {
                    var cleanedTextAttributes = customAttributes
                    cleanedTextAttributes[.foregroundColor] = UIColor.ud.textCaption
                    contentTitle.addAttributes(cleanedTextAttributes, range: NSRange(location: 0, length: contentTitle.length))
                } else {
                    contentTitle.addAttributes(customAttributes, range: NSRange(location: 0, length: contentTitle.length))
                }
                messageSummerize.append(contentTitle)
            }
        case .post:
            if let postContent = message.content as? PostContent {
                if postContent.isUntitledPost {
                    let fixRichText = postContent.richText.lc.convertText(tags: [.img, .media])
                    let textDocsVM = TextDocsViewModel(userResolver: self.userResolver,
                                                       richText: fixRichText,
                                                       docEntity: postContent.docEntity,
                                                       hangPoint: message.urlPreviewHangPointMap)
                    let parseRichText = textDocsVM.parseRichText(
                        checkIsMe: nil,
                        needNewLine: false,
                        iconColor: UIColor.ud.textTitle,
                        customAttributes: customAttributes,
                        urlPreviewProvider: { elementID, _ in
                            let inlinePreviewVM = MessageInlineViewModel()
                            return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: customAttributes)
                        }
                    )
                    let contentTitle: NSMutableAttributedString = parseRichText.attriubuteText
                    messageSummerize = NSMutableAttributedString(string: "")
                    messageSummerize.append(contentTitle)
                    messageSummerize.addAttributes(customAttributes, range: NSRange(location: 0, length: messageSummerize.length))
                } else {
                    messageSummerize = NSMutableAttributedString(string: postContent.title)
                    messageSummerize.addAttributes(customAttributes, range: NSRange(location: 0, length: messageSummerize.length))
                }
            }
        case .calendar, .generalCalendar, .shareCalendarEvent:
            if messageSummerize.string.isEmpty {
                messageSummerize = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Calendar_Push_EventNoName,
                                                             attributes: customAttributes)
            }
        case .todo:
            /// 删除尾部的空格
            var attrStr = NSAttributedString(attributedString: messageSummerize)
            attrStr = attrStr.lf.trimmedAttributedString(set: .whitespacesAndNewlines, position: .trail)
            messageSummerize = NSMutableAttributedString(attributedString: attrStr)
        case .card:
            if let content = message.content as? CardContent {
                if content.type != .vote, !content.header.title.isEmpty {
                    messageSummerize = NSMutableAttributedString(string: content.header.title,
                                                                 attributes: customAttributes)
                }
            }
        case .mergeForward:
            if let content = message.content as? MergeForwardContent, content.isFromPrivateTopic {
                messageSummerize = NSMutableAttributedString(string: MergeForwardPostCardTool.getTitleFromContent(content),
                                                             attributes: customAttributes)
            }
        default:
            break
        }
        return messageSummerize
    }

    /// 这里banner的生成规则 统一回复
    func getTopNoticeViewWith(_ message: Message,
                              topNotice: ChatTopNotice,
                              chat: Chat,
                              chatter: Chatter,
                              closeCallBack: ((UIButton?) -> Void)?,
                              tapCallBack: (() -> Void)?,
                              fromUserClick: ((Chatter?) -> Void)?) -> UIView? {
        let iconColor = UIColor.ud.textTitle
        var authorName: String
        let authorFullname: String
        var messageSummerize: NSMutableAttributedString
        var view: TopNoticeBaseBannerView = TopNoticeTextView()
        /// 发送人姓名的显示逻辑「群昵称>备注名>姓名(别名)」
        if let senderName = message.fromChatter?.displayName(chatId: chat.id,
                                                             chatType: chat.type,
                                                             scene: .reply),
           !senderName.isEmpty {
            authorFullname = senderName + " : "
            messageSummerize = NSMutableAttributedString(string: authorFullname)
            messageSummerize.append(self.getTopNoticeMessageSummerize(message, customAttributes: textAttributes))
        } else {
            authorFullname = ""
            messageSummerize = NSMutableAttributedString(attributedString: self.getTopNoticeMessageSummerize(message, customAttributes: textAttributes))
        }
        messageSummerize.addAttributes(textAttributes, range: NSRange(location: 0, length: messageSummerize.length))
        let model = TopNoticeBannerModel(userResolver: self.userResolver,
                                         title: messageSummerize,
                                         name: chatter.displayName(chatId: chat.id,
                                                                   chatType: chat.type,
                                                                   scene: .reply),
                                         type: .icon,
                                         fromChatter: chatter,
                                         placeholderImage: nil,
                                         closeCallBack: closeCallBack,
                                         tapCallBack: tapCallBack,
                                         fromUserClick: fromUserClick)
        switch message.type {
        case .text, .post:
            if message.isMultiEdited {
                var multiEditedTagAttributes = textAttributes
                multiEditedTagAttributes[.font] = UIFont.systemFont(ofSize: 12)
                multiEditedTagAttributes[.foregroundColor] = UIColor.ud.textCaption
                messageSummerize.append(.init(string: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_Edited_Label,
                                              attributes: multiEditedTagAttributes))
            }
            model.title = messageSummerize
        /// 表情类型
        case .sticker:
            if let content = message.content as? StickerContent {
                model.type = .sticker(key: content.key, stickerSetID: content.stickerSetID)
            }
            view = TopNoticeImageVideoView(messageDynamicAuthorityService: self.messageDynamicAuthorityService)
        /// 图片类型
        case .image:
            if let content = message.content as? ImageContent {
                let imageSet = ImageItemSet.transform(imageSet: content.image)
                let key = imageSet.generateImageMessageKey(forceOrigin: false)
                let placeholder = imageSet.inlinePreview
                model.placeholderImage = placeholder
                model.type = .key(imagekey: key, isVideo: false, authorityMessage: message, anonymousId: chat.anonymousId)
            }
            view = TopNoticeImageVideoView(messageDynamicAuthorityService: self.messageDynamicAuthorityService)
        /// 媒体类型
        case .media:
            if let content = message.content as? MediaContent {
                let imageSet = ImageItemSet.transform(imageSet: content.image)
                let key = imageSet.generateVideoMessageKey(forceOrigin: false)
                let placeholder = imageSet.inlinePreview
                model.placeholderImage = placeholder
                model.type = .key(imagekey: key, isVideo: true, authorityMessage: message, anonymousId: chat.anonymousId)
            }
            view = TopNoticeImageVideoView(messageDynamicAuthorityService: self.messageDynamicAuthorityService)
        case .calendar, .generalCalendar, .shareCalendarEvent:
            if self.modelService?.messageSummerize(message).isEmpty ?? true {
                model.title = NSAttributedString(string: authorFullname + BundleI18n.LarkMessageCore.Calendar_Push_EventNoName,
                                                 attributes: textAttributes)
            }
        case .videoChat:
            model.type = .icon
            view = TopNoticeTextView()
        case .card:
            if let content = message.content as? CardContent, content.type == .vote {
                model.type = .icon
            }
            view = TopNoticeTextView()
        /// 其他类型
        case .file, .folder, .audio, .hongbao, .email, .location, .shareUserCard, .shareGroupChat:
            model.type = .icon
        @unknown default:
            model.type = .icon
        }
        view.model = model
        return view
    }

    /// 关闭或者撤销置顶
    /// 这里是关闭或者撤销置顶的逻辑，如果当前用户有权限撤销 则撤销，没有权限则关闭
    /// 用户是否有权限撤销 1 群设置 只有管理员或者群主 2 群设置 所有人 是否是自己发送的消息
    public func closeOrRemoveTopNotice(_ topNotice: ChatTopNotice,
                                       chat: Chat,
                                       fromVC: UIViewController?,
                                       trackerInfo: (Message?, Bool),
                                       closeHander: (() -> Void)?) {
        let topType: TopNoticeTracker.TopType
        switch topNotice.content.type {
        case .announcementType:
            topType = .announcement
        case .msgType:
            topType = .message
        case .unknown:
            assertionFailure("unSupported type")
            topType = .message
        @unknown default:
            assertionFailure("unSupported type")
            topType = .message
        }
        let isOnlyAdmin: Bool = chat.topNoticePermissionSetting == .onlyManager
        TopNoticeTracker.TopNoticeClick(chat, trackerInfo.0, tapLocation: .close, isOnlyAdmin: isOnlyAdmin, isTopNoticeOwner: trackerInfo.1, topType: topType)
        /// 所有人有权限 1. message的fromChatter.id == userID 2. 管理员
        /// 管理员有权限 2. 管理员
        guard let chatID = Int64(chat.id),
              let fromVC = fromVC else {
            assertionFailure("类型转换出现异常")
            return
        }
        let messageID: Int64? = topNotice.content.type == .msgType ? Int64(topNotice.content.messageID) : nil

        let p2pRemoveTopNotice = { [weak self, weak fromVC] in
            guard let self = self, let fromVC = fromVC else {
                return
            }
            TopNoticeTracker.TopNoticeCancelAlertView(chat, trackerInfo.0, isTopNoticeOwner: trackerInfo.1)
            self.userActionService?.patchChatTopNoticeWithChatID(chatID,
                                                                 type: .remove, senderId: nil,
                                                                 messageId: messageID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    TopNoticeTracker.TopNoticeDidRemove(chat, trackerInfo.0, isTopNoticeOwner: trackerInfo.1, action: .p2pRemove)
                }, onError: { [weak fromVC] error in
                    if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = fromVC?.view {
                        UDToast.showFailure(with: error.displayMessage, on: view)
                    }
                    Self.logger.error("patchChatTopNoticeWithChatID remove \(messageID)", error: error)
                }).disposed(by: self.disposeBag)
            }
        let groupRemoveTopNotice = {[weak self, weak fromVC] in
            guard let self = self, let fromVC = fromVC else {
                return
            }
            TopNoticeTracker.TopNoticeCancelAlertView(chat, trackerInfo.0, isTopNoticeOwner: trackerInfo.1)
            self.userActionService?.patchChatTopNoticeWithChatID(chatID, type: .remove, senderId: nil, messageId: messageID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    closeHander?()
                    TopNoticeTracker.TopNoticeDidRemove(chat, trackerInfo.0, isTopNoticeOwner: trackerInfo.1, action: .remove)
                }, onError: { [weak fromVC] error in
                    if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = fromVC?.view {
                        UDToast.showFailure(with: error.displayMessage, on: view)
                    }
                    Self.logger.error("patchChatTopNoticeWithChatID remove \(messageID)", error: error)
                }).disposed(by: self.disposeBag)
        }
        let groupCloseTopNotice = {[weak self, weak fromVC] in
            guard let self = self, let fromVC = fromVC else {
                return
            }
            TopNoticeTracker.TopNoticeCancelAlertView(chat, trackerInfo.0, isTopNoticeOwner: trackerInfo.1)
            self.userActionService?.patchChatTopNoticeWithChatID(chatID,
                                                                type: .close, senderId: nil,
                                                                messageId: messageID)
                .observeOn(MainScheduler.instance).subscribe(onNext: { _ in
                closeHander?()
                    TopNoticeTracker.TopNoticeDidRemove(chat, trackerInfo.0, isTopNoticeOwner: trackerInfo.1, action: .close)
            }, onError: { [weak fromVC] error in
                if let error = error.underlyingError as? APIError, !error.displayMessage.isEmpty, let view = fromVC?.view {
                    UDToast.showFailure(with: error.displayMessage, on: view)
                }
                Self.logger.error("patchChatTopNoticeWithChatID close \(messageID)", error: error)
            }).disposed(by: self.disposeBag)
        }

        if chat.type == .p2P {
            // 单聊模式不存在权限问题,直接关
            p2pRemoveTopNotice()
        } else if canRemoveTopNotice(topNotice, chat: chat) {
            if Display.phone {
                let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
                actionsheet.setTitle(BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Title)
                actionsheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_OnlyForMe, action: groupCloseTopNotice)
                actionsheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_ForAllMembers, action: groupRemoveTopNotice)
                actionsheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Cancel)
                self.navigator.present(actionsheet, from: fromVC)
            } else {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Title)
                alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_OnlyForMe, dismissCompletion: groupCloseTopNotice)
                alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_ForAllMembers, dismissCompletion: groupRemoveTopNotice)
                alertController.addCancelButton()
                self.navigator.present(alertController, from: fromVC)
            }
        } else {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Title)
            alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_OnlyUnclipSelfClip_PopUpTitle)
            alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Cancel, dismissCompletion: nil)
            alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_GroupChatUnclipMessage_Confirm, dismissCompletion: groupCloseTopNotice)
            self.navigator.present(alertController, from: fromVC)
        }
    }

    /// 是有权限移除置顶消息
    public func canRemoveTopNotice(_ topNotice: ChatTopNotice, chat: Chat) -> Bool {
        if chat.type == .p2P {
            return true
        }
        return ChatPinPermissionUtils.checkTopNoticePermission(chat: chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg)
    }

    public func canTopNotice(chat: Chat) -> Bool {
        self.canTopNotice(chat: chat, currentChatterId: self.userResolver.userID)
    }

    private func canTopNotice(chat: Chat, currentChatterId: String) -> Bool {
        if chat.type == .p2P {
            return true
        }
        return ChatPinPermissionUtils.checkTopNoticePermission(chat: chat, userID: currentChatterId, featureGatingService: self.userResolver.fg)
    }

    public func topNoticeActionMenu(_ message: Message,
                                    chat: Chat,
                                    currentTopNotice: ChatTopNotice?,
                                    currentUserId: String) -> TopNoticeMenuType? {
        /// 当前Chat界面支持置顶(FG开关)
        guard isSupportTopNoticeChat(chat) else {
            return nil
        }
        /// 假消息或者系统消息不支持置顶/取消置顶
        if message.localStatus != .success || message.type == .system {
            return nil
        }

        /// 用户有权限置顶
        if canTopNotice(chat: chat, currentChatterId: currentUserId) {
            return hasPermissionTopNoticeActionMenu(message, chat: chat, currentTopNotice: currentTopNotice)
        } else {
            return noPermissionTopNoticeActionMenu(message, chat: chat, currentTopNotice: currentTopNotice)
        }
    }

    func noPermissionTopNoticeActionMenu(_ message: Message,
                                    chat: Chat,
                                    currentTopNotice: ChatTopNotice?) -> TopNoticeMenuType? {

        guard let topNotice = currentTopNotice, !topNotice.closed else {
            return nil
        }

        if topNotice.content.type == .announcementType,
           let content = message.content as? PostContent,
           content.isGroupAnnouncement {
            return .cancelTopMessage
        }

        if topNotice.content.type == .msgType,
           String(topNotice.content.messageID) == message.id {
            return .cancelTopMessage
        }

        return nil
    }

    func hasPermissionTopNoticeActionMenu(_ message: Message,
                                    chat: Chat,
                                    currentTopNotice: ChatTopNotice?) -> TopNoticeMenuType? {

        guard let topNotice = currentTopNotice else {
            return .topMessage
        }

        if topNotice.content.type == .announcementType,
           let content = message.content as? PostContent,
           content.isGroupAnnouncement {
            return .cancelTopMessage
        }

        if topNotice.content.type == .msgType,
           String(topNotice.content.messageID) == message.id {
            return .cancelTopMessage
        }

        return .topMessage
    }

    /// 用户有权限的情况下，每条消息都是可以置顶的
    /// 只有以下情况出现撤销置顶  当前消息 == 置顶消息 && 用户有权限取消置顶

    public func topNoticeActionMenu(_ message: Message, chat: Chat, currentTopNotice: ChatTopNotice?) -> TopNoticeMenuType? {
        return self.topNoticeActionMenu(message, chat: chat, currentTopNotice: currentTopNotice, currentUserId: self.userResolver.userID)
    }

    public func isSupportTopNoticeChat(_ chat: Chat) -> Bool {
        if chat.isPrivateMode { return false }
        return true
    }
}
