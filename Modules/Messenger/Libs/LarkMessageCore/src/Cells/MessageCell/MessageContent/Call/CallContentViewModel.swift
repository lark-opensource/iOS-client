//
//  CallContentViewModel.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/18.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import RichLabel
import EENavigator
import LarkUIKit
import LarkMessengerInterface

public final class CallContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: CallContentContext>: MessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "call"
    }

    /// 显示内容
    private(set) var attributedString = NSMutableAttributedString()
    /// @位置
    private(set) var atRange = NSRange(location: 0, length: 0)
    private(set) var callText = NSMutableAttributedString()

    public var isMe: Bool {
        guard let content = self.message.content as? SystemContent,
            let fromChatter = content.triggerUser else { return false }
        return context.isMe(fromChatter.id, chat: metaModel.getChat())
    }

    var preferMaxLayoutWidth: CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(self.message) - 2 * metaModelDependency.contentPadding
    }
    let labelFont = UIFont.ud.title4

    @objc
    private func callContacts(_ sender: UIButton) {
        guard let content = self.message.content as? SystemContent,
            let chatter = isMe ? content.callee : content.triggerUser else { return }
        self.context.callContacts(chatter.id)
        /// isMe = true ? 重拨 ：回拨
        if isMe {
            CallContentTracker.chatCallPhoneClickRecall()
        } else {
            CallContentTracker.chatCallPhoneClickCallback()
        }
    }

    /// 拨号/回拨消息不会变化
    public override func shouldUpdate(_ new: Message) -> Bool {
        return false
    }

    /// self在init之后，有机会在CallContentComponentBinder调用update之前准备好vm的属性
    public override func initialize() {
        self.getCallTextAndAtRange(message: self.message)
        self.getAttributedString(message: self.message)
    }

    private func getCallTextAndAtRange(message: Message) {
        guard let content = message.content as? SystemContent else {
            self.atRange = NSRange(location: 0, length: 0)
            self.callText = NSMutableAttributedString()
            return
        }

        // 基本的at文本
        let calleeName = "@\(content.callee?.displayName ?? "")" as NSString
        let callText = BundleI18n.LarkMessageCore.Lark_Legacy_SystemMessageCheckPhone(calleeName)
        let colorThemeType: Type = isMe ? .mine : .other
        let tempAttributeStr = NSMutableAttributedString(
            string: callText,
            attributes: LKLabel.lu.basicAttribute(
                foregroundColor: context.getColor(for: .Message_SystemText_Foreground, type: colorThemeType),
                font: labelFont
            )
        )
        // at属性
        var atAttributes: [NSAttributedString.Key: Any] = [:]
        if self.context.isMe(content.callee?.id ?? "", chat: metaModel.getChat()) {
            atAttributes = LKLabel.lu.basicAttribute(
                foregroundColor: context.getColor(for: .Message_At_Foreground_Me, type: .mine),
                atMeBackground: context.getColor(for: .Message_At_Background_Me, type: .mine),
                font: labelFont
            )
        } else {
            atAttributes = LKLabel.lu.basicAttribute(
                foregroundColor: context.getColor(for: .Message_At_Foreground_InnerGroup, type: .mine),
                atMeBackground: context.getColor(for: .Message_At_Background_InnerGroup, type: .mine),
                font: labelFont
            )
        }

        // 向文本上添加at属性
        let nsText = callText as NSString
        self.atRange = nsText.range(of: calleeName as String)
        tempAttributeStr.addAttributes(atAttributes, range: self.atRange)

        self.callText = tempAttributeStr
    }

    private func getAttributedString(message: Message) {

        let resultAttributedString = self.callText
        // 添加空格
        resultAttributedString.append(NSAttributedString(string: "  "))

        let origintitle = self.isMe ?
            BundleI18n.LarkMessageCore.Lark_Legacy_SystemMessageCall :
            BundleI18n.LarkMessageCore.Lark_Legacy_CallBackPhone

        let image = Resources.callback.withRenderingMode(.alwaysTemplate)
        let labelFont = self.labelFont
        /// 计算出来的准确的原始宽度
        let originTitleWidth = origintitle.lu.width(font: labelFont, height: labelFont.rowHeight)
        /// 修正width：在特殊case下，系统返回的宽度误差，导致触发了超出裁剪的逻辑
        let fixTitleWidth = self.fixLabelWidth(font: labelFont, width: originTitleWidth)
        /// 当前方法在子线程执行，需要使用LKAsyncAttachment
        let attachmentColor = context.getColor(
            for: .Message_Text_ActionDefault,
            type: isMe ? .mine : .other
        )
        let attachment = LKAsyncAttachment(
            viewProvider: { [weak self] in
                guard let `self` = self else { return UIView() }
                /// 拨号按钮
                let button = UIButton(type: .custom)
                button.setTitle(origintitle, for: .normal)
                button.titleLabel?.font = labelFont
                button.setTitleColor(attachmentColor, for: .normal)
                button.contentMode = .left
                button.addTarget(self, action: #selector(self.callContacts(_:)), for: .touchUpInside)
                button.setImage(image, for: .normal)
                button.setImage(image, for: .highlighted)
                button.tintColor = attachmentColor
                button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
                button.titleEdgeInsets = UIEdgeInsets(
                    top: 0,
                    left: -image.size.width,
                    bottom: 0,
                    right: image.size.width
                )
                button.imageEdgeInsets = UIEdgeInsets(
                    top: 0,
                    left: originTitleWidth,
                    bottom: 0,
                    right: -originTitleWidth
                )
                return button
            },
            size: CGSize(width: fixTitleWidth + image.size.width, height: labelFont.rowHeight)
        )
        attachment.fontDescent = self.labelFont.descender
        attachment.fontAscent = self.labelFont.ascender
        resultAttributedString.append(
            NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: attachment]
            )
        )

        self.attributedString = resultAttributedString
    }

    /// 修正width：在特殊case下，系统返回的宽度误差，导致触发了超出裁剪的逻辑
    private func fixLabelWidth(font: UIFont, width: CGFloat) -> CGFloat {
        /// 得到字体的宽度
        let fontWidth: CGFloat = font.rowHeight
        /// 修正基数，我们以2为基数
        let fixNum: Int = 2
        let widthUnit: CGFloat = fontWidth / CGFloat(fixNum)
        return ceil(width / widthUnit) * widthUnit
    }
}

extension CallContentViewModel: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let content = self.message.content as? SystemContent, let chatter = content.callee else { return true }
        if self.atRange.contains(range.location) && !chatter.id.isEmpty {
            let body = PersonCardBody(chatterId: chatter.id,
                                      chatId: metaModel.getChat().id,
                                      source: .chat)
            if Display.phone {
                context.navigator(type: .push, body: body, params: nil)
            } else {
                context.navigator(
                    type: .present,
                    body: body,
                    params: NavigatorParams(wrap: LkNavigationController.self, prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    }))
            }
            return false
        }
        return true
    }
}
