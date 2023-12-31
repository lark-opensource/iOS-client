//
//  RecalledContentViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/3/1.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import LarkCore
import EENavigator
import LarkUIKit
import LarkMessengerInterface

private var callbackIcon = StaticColorizeIcon(icon: Resources.callback)

protocol RecalledMessageCellViewModelActionAbility: AnyObject {
    func openProfile(chatterID: String, messageChannelID: String)
}

/// 撤回消息留痕优化，变成系统消息样式。
public final class RecalledContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: RecalledContentContext>: NewMessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "recalled"
    }

    /// 显示内容
    private(set) var attributedString = NSMutableAttributedString()

    /// @位置
    private(set) var atRange = NSRange(location: 0, length: 0)

    /// 字体
    private(set) var labelFont: UIFont = UIFont.ud.body0

    var preferMaxLayoutWidth: CGFloat {
        if self.context.scene == .newChat, message.showInThreadModeStyle {
            return self.metaModelDependency.getContentPreferMaxWidth(self.message)
        }
        return self.metaModelDependency.getContentPreferMaxWidth(self.message) - 2 * metaModelDependency.contentPadding
    }

    private var recallerIdentity: Message.RecallerIdentity = .unknownIdentity
    private var atElements: [NSRange: String] = [: ]
    private var config = RecallContentConfig()
    weak var recalledMessageActionDelegate: RecalledMessageCellViewModelActionAbility?

    public init(metaModel: M, metaModelDependency: D, context: C, config: RecallContentConfig? = nil) {
        if let config = config {
            self.config = config
        }
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context
        )
    }

    public override func initialize() {
        parseMessage(self.message)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        parseMessage(metaModel.message)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    @objc
    private func clickReeditButton(_ sender: UIButton) {
        context.reedit(self.message)
    }

    private func parseMessage(_ message: Message) {
        self.recallerIdentity = message.recallerIdentity
        self.generateLabelText(with: message.recaller)
        if self.config.isShowReedit {
            self.checkReedit(with: message)
        }
    }

    private func generateLabelText(with recaller: Chatter?) {
        let recallerId = config.showRecaller ? (recaller?.id ?? "") : ""
        var recalledText: String

        let groupOwnerName = recaller?.displayName(
            chatId: message.channel.id,
            chatType: .group,
            scene: .groupOwnerRecall
            ) ?? ""
        let atString = "@\(groupOwnerName)" as NSString

        if !recallerId.isEmpty {
            switch self.recallerIdentity {
            case .unknownIdentity:
                // 此消息已被%@（群主）%@撤回
                recalledText = String(
                    format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                    arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_GroupOwnerTag, atString])
            case .owner:
                // 此消息已被%@（群主）%@撤回
                recalledText = String(
                    format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                    arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_GroupOwnerTag, atString])
            case .administrator:
                // 此消息已被%@（管理员）%@撤回
                recalledText = String(
                    format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                    arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_Administrator, atString])
            case .groupAdmin:
                // 此消息已被群管理员 {{GroupAdministrator}} 撤回
                recalledText = BundleI18n.LarkMessageCore.Lark_Legacy_GroupAdminRecalledMsg(atString)
            case .enterpriseAdministrator:
                // 此消息已被%@（群主）%@撤回
                recalledText = String(
                    format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                    arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_GroupOwnerTag, atString])
            @unknown default:
                assert(false, "new value")
                // 此消息已被%@（群主）%@撤回
                recalledText = String(
                    format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                    arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_GroupOwnerTag, atString])
            }
        } else if recallerId.isEmpty, case .enterpriseAdministrator = self.recallerIdentity {
            // 此消息已被企业管理员撤回
            recalledText = BundleI18n.LarkMessageCore.Lark_IM_MessageRecalledByAdmin_Text
        } else {
            // 此消息已撤回
            recalledText = BundleI18n.LarkMessageCore.Lark_Legacy_MessageIsrecalled
        }

        let isFromMe = self.context.isMe(message.fromId, chat: metaModel.getChat())
        // 系统文字颜色
        let systemColor = context.getColor(for: .Message_SystemText_Foreground, type: isFromMe ? .mine : .other)
        let tempAttributeStr = NSMutableAttributedString(
            string: recalledText,
            attributes: LKLabel.lu.basicAttribute(foregroundColor: systemColor, font: labelFont)
        )

        // at属性
        var atAttributes: [NSAttributedString.Key: Any] = [.font: labelFont]
        if self.context.isMe(recallerId, chat: metaModel.getChat()) {
            atAttributes = LKLabel.lu.basicAttribute(
                foregroundColor: context.getColor(for: .Message_At_Foreground_Me, type: isFromMe ? .mine : .other),
                atMeBackground: context.getColor(for: .Message_At_Background_Me, type: isFromMe ? .mine : .other),
                font: labelFont
            )
        } else {
            atAttributes = LKLabel.lu.basicAttribute(
                foregroundColor: context.getColor(for: .Message_At_Foreground_InnerGroup, type: isFromMe ? .mine : .other),
                font: labelFont
            )
        }

        // 向文本上添加at属性
        let nsText = recalledText as NSString
        let atRange = nsText.range(of: atString as String)
        tempAttributeStr.addAttributes(atAttributes, range: atRange)
        self.atRange = atRange

        // 缓存住AtRange,供点击使用
        atElements[atRange] = recallerId

        self.attributedString = tempAttributeStr
    }

    private func checkReedit(with message: Message) {
        guard message.isReeditable else { return }

        let buttonTitleFont = UIFont.systemFont(ofSize: labelFont.pointSize, weight: .medium)

        let colorThemeType: Type = self.context.isMe(message.fromId, chat: metaModel.getChat()) ? .mine : .other
        let titleColor = self.context.getColor(for: .Message_Text_ActionDefault, type: colorThemeType)
        let icon = callbackIcon.get(textColor: titleColor, type: colorThemeType)
        /// icon在右，title在左
        let imageWidth = icon.size.width
        let titleWidth = BundleI18n.LarkMessageCore.Lark_Legacy_Reedit.lu.width(font: buttonTitleFont, height: labelFont.rowHeight)

        /// 当前方法在子线程执行，需要使用LKAsyncAttachment
        let attachment = LKAsyncAttachment(
            viewProvider: { [weak self] in
                guard let self = self else { return UIView() }

                let button = UIButton(type: .custom)
                button.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_Reedit, for: .normal)
                button.titleLabel?.font = buttonTitleFont
                button.setTitleColor(titleColor, for: .normal)
                button.setImage(icon, for: .normal)
                button.addTarget(self, action: #selector(self.clickReeditButton), for: .touchUpInside)
                button.sizeToFit()

                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: 0, right: imageWidth)
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth, bottom: 0, right: -titleWidth)

                return button
            },
            size: CGSize(width: titleWidth + imageWidth, height: labelFont.rowHeight)
        )

        attachment.fontDescent = labelFont.descender
        attachment.fontAscent = labelFont.ascender

        self.attributedString.append(NSAttributedString(string: " "))
        self.attributedString.append(
            NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: attachment]
            )
        )
    }
}

public struct RecallContentConfig {
    public var isShowReedit: Bool
    // 是否展示被谁撤回；话题转发卡片等场景不需要，因为有歧义
    public var showRecaller: Bool
    public init(
        isShowReedit: Bool = true,
        showRecaller: Bool = true
    ) {
        self.isShowReedit = isShowReedit
        self.showRecaller = showRecaller
    }
}

extension RecalledContentViewModel: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let userID = atElements[range], !userID.isEmpty else {
            return false
        }

        self.recalledMessageActionDelegate?.openProfile(chatterID: userID, messageChannelID: message.channel.id)
        return true
    }
}
