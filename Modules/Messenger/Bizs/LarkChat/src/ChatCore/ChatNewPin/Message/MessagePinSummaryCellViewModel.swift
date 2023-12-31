//
//  MessagePinSummaryCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import RxSwift
import RxCocoa
import LarkOpenChat
import LKCommonsLogging
import RustPB
import LarkModel
import EENavigator
import LarkContainer
import LarkMessengerInterface
import UniverseDesignIcon

public final class MessagePinSummaryCellViewModel: ChatPinSummaryCellViewModel {

    @ScopedInjectedLazy private var topNoticeService: ChatTopNoticeService?

    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .messagePin
    }

    public override class func canInitialize(context: ChatPinSummaryContext) -> Bool {
        return true
    }

    private var metaModel: ChatPinSummaryCellMetaModel?

    public override func modelDidChange(model: ChatPinSummaryCellMetaModel) {
        self.metaModel = model
    }

    public override func getSummaryInfo() -> (attributedTitle: NSAttributedString, iconConfig: ChatPinIconConfig?) {
        guard let metaModel = metaModel,
              let messagePayload = metaModel.pin.payload as? MessageChatPinPayload,
              let message = messagePayload.message,
              MessagePinUtils.checkVisible(message: message, chat: metaModel.chat) else {
            let notVisibleText: String
            if (metaModel?.pin.payload as? MessageChatPinPayload)?.message?.isDeleted ?? false {
                notVisibleText = BundleI18n.LarkChat.Lark_IM_PinnedMessageDeleted_Text
            } else {
                notVisibleText = BundleI18n.LarkChat.Lark_IM_SuperApp_PinnedItemNotVisible_Text
            }
            let messageNotVisibleAttrText = NSAttributedString(
                string: notVisibleText,
                attributes: [.font: UIFont.systemFont(ofSize: 14),
                             .foregroundColor: UIColor.ud.textTitle]
            )
            return (messageNotVisibleAttrText, nil)
        }

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                         .foregroundColor: UIColor.ud.textTitle]
        let messageSummerize = NSMutableAttributedString(string: "", attributes: attributes)
        if let senderName = message.fromChatter?.displayName(chatId: metaModel.chat.id,
                                                             chatType: metaModel.chat.type,
                                                             scene: .reply),
           !senderName.isEmpty {
            messageSummerize.append(NSAttributedString(string: senderName + " : ", attributes: attributes))
        }
        ///  这里暂时对齐置顶消息摘要
        if let summerizeAttrStr = self.topNoticeService?.getTopNoticeMessageSummerize(message, customAttributes: attributes) {
            messageSummerize.append(summerizeAttrStr)
        }
        switch message.type {
        case .text, .post:
            if message.isMultiEdited {
                messageSummerize.append(NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_EditMessage_Edited_Label,
                                                           attributes: [.font: UIFont.systemFont(ofSize: 12),
                                                                        .foregroundColor: UIColor.ud.textCaption]))
            }
        default:
            break
        }
        return (messageSummerize,
                ChatPinIconConfig(iconResource: .resource(resource: .avatar(key: message.fromChatter?.avatarKey ?? "",
                                                                            entityID: message.fromChatter?.id ?? "",
                                                                            params: .init(sizeType: .size(16))),
                                                          config: ChatPinIconResource.ImageConfig(tintColor: nil, placeholder: nil)),
                                  cornerRadius: 8))
    }

    public override func onClick() {
        guard let metaModel = self.metaModel,
              let message = (metaModel.pin.payload as? MessageChatPinPayload)?.message,
              let chatVC = (try? self.context.userResolver.resolve(assert: ChatOpenService.self))?.chatVC() else {
            return
        }
        MessagePinUtils.onClick(
            message: message,
            chat: metaModel.chat,
            pinID: metaModel.pin.id,
            navigator: self.context.userResolver.navigator,
            targetVC: chatVC,
            auditService: try? self.context.userResolver.resolve(assert: ChatSecurityAuditService.self)
        )
    }
}
