//
//  ThreadDetailRecallCellViewModel.swift
//  LarkThread
//
//  Created by shane on 2019/5/28.
//

import UIKit
import Foundation

import LarkModel
import RichLabel
import EENavigator
import AsyncComponent
import LarkMessageCore
import LarkMessageBase
import LarkUIKit
import LarkMessengerInterface
import LarkFeatureGating

private var callbackIcon = StaticColorizeIcon(icon: Resources.thread_detail_reedite)

final class ThreadDetailRecallCellViewModel: ThreadDetailCellViewModel, HasMessage {
    override public var identifier: String {
        return "recall"
    }

    /// 当前进入多选模式
    var inSelectMode: Bool = false {
        didSet {
            guard inSelectMode != oldValue else { return }
            calculateRenderer()
        }
    }

    /// 字体
    private var nameFont: UIFont { UIFont.ud.body1 }
    private var labelFont: UIFont { UIFont.ud.body2 }
    private var editButtonFont: UIFont { UIFont.ud.body1 }

    private var metaModel: ThreadDetailMetaModel
    var message: Message {
        return metaModel.message
    }

    private(set) var displayAttributeString: NSAttributedString = NSAttributedString(string: "")
    private(set) var displayNameRange: NSRange = NSRange(location: 0, length: 0)

    init(metaModel: ThreadDetailMetaModel, context: ThreadDetailContext) {
        self.metaModel = metaModel
        super.init(context: context, binder: ThreadDetailRecallCellComponentBinder(context: context))
        self.update(metaModel: metaModel)
        self.calculateRenderer()

        context.chatPageAPI?.inSelectMode
            .subscribe(onNext: { [weak self] (inSelectMode) in
                self?.inSelectMode = inSelectMode
            }).disposed(by: self.disposeBag)
    }

    private func getDisplyName(with chatter: Chatter?) -> String {
        let chat = metaModel.getChat()
        return chatter?.displayName(chatId: chat.id, chatType: chat.type, scene: .head) ?? ""
    }

    func update(metaModel: ThreadDetailMetaModel) {
        self.metaModel = metaModel
        var title = ""
        var displyName = ""
        var displayNameLocation = 0

        switch message.recallerIdentity {
        case .unknownIdentity:
            displyName = getDisplyName(with: self.message.fromChatter)
            title = BundleI18n.LarkThread.Lark_Chat_TopicReplyRecallTip(displyName)

            let tmpStr = BundleI18n.LarkThread.Lark_Chat_TopicReplyRecallTip("{}")
            displayNameLocation = tmpStr.indexDistance(of: "{}")
        case .owner:
            displyName = getDisplyName(with: self.message.recaller)
            title = BundleI18n.LarkThread.Lark_Chat_TopicAdminReplyRecallTip(displyName)

            let tmpStr = BundleI18n.LarkThread.Lark_Chat_TopicAdminReplyRecallTip("{}")
            displayNameLocation = tmpStr.indexDistance(of: "{}")
        case .administrator:
            displyName = getDisplyName(with: self.message.recaller)
            title = BundleI18n.LarkThread.Lark_Chat_SystemAdminReplyRecallTip(displyName)

            let tmpStr = BundleI18n.LarkThread.Lark_Chat_SystemAdminReplyRecallTip("{}")
            displayNameLocation = tmpStr.indexDistance(of: "{}")
        case .groupAdmin:
            displyName = getDisplyName(with: self.message.recaller)
            title = BundleI18n.LarkThread.Lark_Legacy_GroupAdminRecalledMsg(displyName)

            let tmpStr = BundleI18n.LarkThread.Lark_Legacy_GroupAdminRecalledMsg("{}")
            displayNameLocation = tmpStr.indexDistance(of: "{}")
        case .enterpriseAdministrator:
            title = BundleI18n.LarkThread.Lark_IM_ReplyRecalledByAdmin_Text
        @unknown default:
            assert(false, "new value")
            displyName = getDisplyName(with: self.message.fromChatter)
            title = BundleI18n.LarkThread.Lark_Chat_TopicReplyRecallTip(displyName)

            let tmpStr = BundleI18n.LarkThread.Lark_Chat_TopicReplyRecallTip("{}")
            displayNameLocation = tmpStr.indexDistance(of: "{}")
        }

        self.displayNameRange = NSRange(location: displayNameLocation, length: (displyName as NSString).length)

        let isMe = context.isMe(message.fromId, chat: metaModel.getChat())
        let attributedText = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: labelFont,
                .foregroundColor: context.getColor(for: .Message_SystemText_Foreground, type: isMe ? .mine : .other)
            ]
        )
        attributedText.addAttributes(
            [.font: nameFont],
            range: displayNameRange
        )

        if let reediteAttributeString = checkReedit(with: message) {
            attributedText.append(reediteAttributeString)
        }

        self.displayAttributeString = attributedText

        super.calculateRenderer()
    }

    private func checkReedit(with message: Message) -> NSAttributedString? {
        guard message.isReeditable else { return nil }

        let buttonTitleFont = editButtonFont

        /// icon在右，title在左
        let imageWidth = Resources.thread_detail_reedite.size.width
        let titleWidth = BundleI18n.LarkThread.Lark_Legacy_Reedit.lu.width(font: buttonTitleFont, height: CGFloat.greatestFiniteMagnitude)

        let colorThemeType: Type = self.context.isMe(message.fromId, chat: metaModel.getChat()) ? .mine : .other
        let titleColor = context.getColor(for: .Message_Text_ActionDefault, type: colorThemeType)
        let icon = callbackIcon.get(textColor: titleColor, type: colorThemeType)

        /// 当前方法在子线程执行，需要使用LKAsyncAttachment
        let attachment = LKAsyncAttachment(
            viewProvider: { [weak self] in
                guard let self = self else { return UIView() }

                let button = UIButton(type: .custom)
                button.accessibilityIdentifier = "reedit_button"
                button.setTitle(BundleI18n.LarkThread.Lark_Legacy_Reedit, for: .normal)
                button.titleLabel?.font = buttonTitleFont
                button.setTitleColor(titleColor, for: .normal)
                button.setTitleColor(UIColor.ud.N700, for: .highlighted)
                button.setImage(icon, for: .normal)
                button.setImage(icon, for: .highlighted)
                button.addTarget(self, action: #selector(self.clickReeditButton), for: .touchUpInside)
                button.sizeToFit()

                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: 0, right: imageWidth)
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth, bottom: 0, right: -titleWidth)

                return button
            },
            size: CGSize(width: titleWidth + imageWidth, height: buttonTitleFont.rowHeight)
        )

        attachment.fontDescent = labelFont.descender
        attachment.fontAscent = labelFont.ascender

        let attributedString = NSMutableAttributedString(string: " ", attributes: nil)
        attributedString.append(
            NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: attachment]
            )
        )

        return attributedString
    }

    @objc
    private func clickReeditButton(_ sender: UIButton) {
        context.reedit(self.message)
    }

    private func onTap() {

        guard let targetVC = context.pageAPI else { return }
        /// 撤回消息的 有两种 自己与圈主 需要禁止点击prfile
        var userId = ""
        var isAnonymous = false

        if let recaller = message.recaller {
            userId = recaller.id
            isAnonymous = recaller.isAnonymous
        } else {
            userId = message.fromId
            isAnonymous = message.fromChatter?.isAnonymous ?? false
        }
        // 用户ID为空 或者 是匿名直接返回
        if userId.isEmpty || isAnonymous {
            return
        }
        let chatId = message.channel.id
        let body = PersonCardBody(chatterId: userId,
                                  chatId: chatId,
                                  source: .chat)
        context.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }
}

extension ThreadDetailRecallCellViewModel: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        self.onTap()
        return false
    }
}

final class ThreadDetailRecallCellComponentBinder: ComponentBinder<ThreadDetailContext> {
    private let style = ASComponentStyle()
    private let props = ThreadDetailRecallCellComponent.Props()
    private lazy var _component: ThreadDetailRecallCellComponent = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<ThreadDetailContext> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadDetailRecallCellViewModel else {
            assertionFailure()
            return
        }
        props.displayAttributeString = vm.displayAttributeString
        props.displayNameRange = vm.displayNameRange
        props.delegate = vm
        // 多选
        props.inSelectMode = vm.inSelectMode

        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: ThreadDetailContext? = nil) {
        _component = ThreadDetailRecallCellComponent(
            props: props,
            style: style,
            context: context
        )
    }
}

fileprivate extension StringProtocol {
    func indexDistance(of string: Self) -> Int {
        guard let index = range(of: string)?.lowerBound else { return 0 }
        return distance(from: startIndex, to: index)
    }
}
