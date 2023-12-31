//
//  ChatPinCardTopNoticeCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/8/9.
//

import Foundation
import LarkModel
import LarkMessageCore
import UniverseDesignIcon
import EENavigator
import LarkMessengerInterface
import RichLabel
import LarkUIKit
import LarkCore

protocol ChatPinCardTopNoticeCellViewModelDelegate: AnyObject {
    func getAvailableMaxWidth() -> CGFloat
    func getTargetVC() -> UIViewController?
    func menuShow()
    func menuHide()
}

final class ChatPinCardTopNoticeCellViewModel: ChatPinCardContainerCellAbility {

    private struct LabelProps {
        var attributedText: NSAttributedString?
        var numberOfLines: Int = 0
        var preferMaxLayoutWidth: CGFloat
        var outOfRangeText: NSAttributedString?
        var textLink: LKTextLink?
    }

    private lazy var linkParser: LKLinkParserImpl = {
        let linkParser = LKLinkParserImpl(linkAttributes: [
            .foregroundColor: UIColor.ud.primaryPri500,
            .font: UIFont.systemFont(ofSize: 14)
        ])
        return linkParser
    }()
    private lazy var textParser: LKTextParserImpl = {
        let textParser = LKTextParserImpl()
        return textParser
    }()
    private lazy var layoutEngine: LKTextLayoutEngineImpl = {
        let layoutEngine = LKTextLayoutEngineImpl()
        return layoutEngine
    }()

    private var contentSize: CGSize = .zero
    private var operaterSize: CGSize = .zero
    private var iconSize: CGSize = .zero
    var iconHasCorner: Bool = false
    private var operaterProps: LabelProps?
    private var contentProps: LabelProps?
    private let contentAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                    .foregroundColor: UIColor.ud.textTitle]

    private let nav: Navigatable
    private let topNoticeService: ChatTopNoticeService?
    private let currentChatterId: String
    private weak var delegate: ChatPinCardTopNoticeCellViewModelDelegate?
    let fromChat: Chat
    let topNoticeModel: ChatPinTopNoticeModel

    init(topNoticeModel: ChatPinTopNoticeModel,
         currentChatterId: String,
         fromChat: Chat,
         topNoticeService: ChatTopNoticeService?,
         nav: Navigatable,
         delegate: ChatPinCardTopNoticeCellViewModelDelegate?) {
        self.topNoticeModel = topNoticeModel
        self.topNoticeService = topNoticeService
        self.currentChatterId = currentChatterId
        self.fromChat = fromChat
        self.nav = nav
        self.delegate = delegate
    }

    func getCellHeight() -> CGFloat {
        let availableMaxWidth = self.delegate?.getAvailableMaxWidth() ?? .zero
        let preferredMaxLayoutWidth = availableMaxWidth - ChatTopNoticeCardCollectionViewCell.UIConfig.contentMargin * 2 - ChatPinListCardBaseCell.ContainerUIConfig.horizontalMargin * 2
        self.layoutIcon()
        self.layoutContent(preferredMaxLayoutWidth: preferredMaxLayoutWidth)
        self.layoutOperater(preferredMaxLayoutWidth: preferredMaxLayoutWidth)
        return calculateLayoutResult().cellHeight
    }

    func calculateLayoutResult() -> (layoutResult: ChatPinCardContainerCellLayoutManager.LayoutResult, cellHeight: CGFloat) {
        return ChatPinCardContainerCellLayoutManager.calculate(
            iconSize: self.iconSize,
            titleSize: .zero,
            contentSize: self.contentSize,
            pinChatterSize: self.operaterSize
        )
    }

    func update(contentLabel: LKLabel, operaterLable: LKLabel) {

        func update(label: LKLabel, props: LabelProps) {
            label.attributedText = props.attributedText
            label.numberOfLines = props.numberOfLines
            label.preferredMaxLayoutWidth = props.preferMaxLayoutWidth
            label.outOfRangeText = props.outOfRangeText
            label.removeLKTextLink()
            if let textLink = props.textLink {
                label.addLKTextLink(link: textLink)
            }
        }

        if let contentProps = self.contentProps {
            update(label: contentLabel, props: contentProps)
        }
        if let operaterProps = self.operaterProps {
            update(label: operaterLable, props: operaterProps)
        }
    }

    func jumpChat() {
        guard let message = topNoticeModel.message,
              let targetVC = delegate?.getTargetVC() else { return }
        let body = ChatControllerByChatBody(chat: fromChat,
                                            position: message.position,
                                            messageId: message.id)
        self.nav.push(body: body, from: targetVC)
    }

    func jumpAnnouncement() {
        guard let targetVC = delegate?.getTargetVC() else { return }
        let body = ChatAnnouncementBody(chatId: fromChat.id)
        self.nav.push(body: body, from: targetVC)
    }

    func handleMore(_ sourceView: UIView) {
        guard let targetVC = delegate?.getTargetVC() else {
            return
        }

        let pinType: IMTrackerChatPinType
        switch topNoticeModel.pbModel.content.type {
        case .announcementType:
            pinType = .announcement
        case .msgType:
            pinType = .message
        case .unknown:
            pinType = .unknown
        @unknown default:
            pinType = .unknown
        }

        var menuItemInfos: [FloatMenuItemInfo] = []
        if case .msgType = topNoticeModel.pbModel.content.type {
            menuItemInfos.append(
                FloatMenuItemInfo(
                    icon: UDIcon.getIconByKey(.viewinchatOutlined, size: CGSize(width: 20, height: 20)),
                    title: BundleI18n.LarkChat.Lark_IM_GroupChatUnclipMessage_ViewInChat_Button,
                    acionFunc: { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.jumpChat()
                        IMTracker.Chat.Sidebar.Click.viewInChat(self.fromChat, topId: nil, messageId: self.topNoticeModel.message?.id, topType: pinType)
                    }
                )
            )
        }
        menuItemInfos.append(
            FloatMenuItemInfo(
                icon: UDIcon.getIconByKey(.unpinOutlined, size: CGSize(width: 20, height: 20)),
                title: BundleI18n.LarkChat.Lark_IM_NewPin_Remove_Button,
                acionFunc: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    let isTopNoticeOwner = (self.currentChatterId == self.topNoticeModel.pbOperator.id)
                    self.topNoticeService?.closeOrRemoveTopNotice(
                        self.topNoticeModel.pbModel,
                        chat: self.fromChat,
                        fromVC: self.delegate?.getTargetVC(),
                        trackerInfo: (self.topNoticeModel.message, isTopNoticeOwner),
                        closeHander: nil
                    )
                    IMTracker.Chat.Sidebar.Click.remove(self.fromChat, topId: nil, messageId: self.topNoticeModel.message?.id, topType: pinType)
                }
            )
        )
        let menuVC = FloatMenuOperationController(pointView: sourceView,
                                                  bgMaskColor: UIColor.clear,
                                                  menuShadowType: .s5Down,
                                                  items: menuItemInfos)
        menuVC.modalPresentationStyle = .overFullScreen
        menuVC.animationBegin = { [weak self] in self?.delegate?.menuShow() }
        menuVC.animationEnd = { [weak self] in self?.delegate?.menuHide() }
        self.nav.present(menuVC, from: targetVC, animated: false)
        IMTracker.Chat.Sidebar.Click.more(fromChat, topId: nil, messageId: self.topNoticeModel.message?.id, type: pinType)
    }

    func onClickContent() {
        switch topNoticeModel.pbModel.content.type {
        case .announcementType:
            IMTracker.Chat.Sidebar.Click.open(fromChat, topId: nil, messageId: topNoticeModel.message?.id, type: .announcement)
            self.jumpAnnouncement()
        case .msgType:
            IMTracker.Chat.Sidebar.Click.open(fromChat, topId: nil, messageId: topNoticeModel.message?.id, type: .message)
            self.jumpChat()
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    func onClickIcon() {
        switch topNoticeModel.pbModel.content.type {
        case .announcementType:
            self.jumpAnnouncement()
        case .msgType:
            self.jumpToProfile(topNoticeModel.message?.fromChatter)
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func calculateSize(props: LabelProps) -> CGSize {
        textParser.originAttrString = props.attributedText
        textParser.parse()

        linkParser.textLinkList = []
        if let textLink = props.textLink {
            linkParser.textLinkList = [textLink]
        }
        linkParser.originAttrString = textParser.renderAttrString
        linkParser.parse()

        layoutEngine.outOfRangeText = props.outOfRangeText
        layoutEngine.numberOfLines = props.numberOfLines
        layoutEngine.attributedText = linkParser.renderAttrString
        layoutEngine.preferMaxWidth = props.preferMaxLayoutWidth
        let height = layoutEngine.layout(size: CGSize(width: props.preferMaxLayoutWidth, height: CGFloat.infinity)).height
        return CGSize(width: props.preferMaxLayoutWidth, height: height)
    }

    private func layoutContent(preferredMaxLayoutWidth: CGFloat) {
        var attr: NSAttributedString?
        switch topNoticeModel.pbModel.content.type {
        case .announcementType:
            let summerize = BundleI18n.LarkChat.Lark_IMChatPin_PreviewGroupAnnouncement_Text + " " + topNoticeModel.pbModel.content.announcement.content
            attr = NSAttributedString(string: summerize, attributes: self.contentAttributes)
        case .msgType:
            guard let message = topNoticeModel.message else {
                break
            }
            let summerizeAttrStr = self.topNoticeService?.getTopNoticeMessageSummerize(message, customAttributes: self.contentAttributes) ?? NSAttributedString(string: "")
            let messageSummerize = NSMutableAttributedString(attributedString: summerizeAttrStr)
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
            attr = messageSummerize
        case .unknown:
            break
        @unknown default:
            break
        }

        let contentProps = LabelProps(
            attributedText: attr,
            numberOfLines: 10,
            preferMaxLayoutWidth: preferredMaxLayoutWidth,
            outOfRangeText: NSAttributedString(string: "\u{2026}", attributes: self.contentAttributes),
            textLink: nil
        )
        self.contentSize = calculateSize(props: contentProps)
        self.contentProps = contentProps
    }

    private func layoutIcon() {
        switch topNoticeModel.pbModel.content.type {
        case .announcementType:
            if topNoticeModel.announcementSender != nil {
                iconHasCorner = true
                iconSize = ChatTopNoticeCardCollectionViewCell.UIConfig.avatarSize
            } else {
                iconHasCorner = false
                iconSize = ChatTopNoticeCardCollectionViewCell.UIConfig.announcementSize
            }
        case .msgType:
            iconHasCorner = true
            iconSize = ChatTopNoticeCardCollectionViewCell.UIConfig.avatarSize
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func layoutOperater(preferredMaxLayoutWidth: CGFloat) {
        let name = topNoticeModel.pbOperator.displayName(
            chatId: fromChat.id,
            chatType: fromChat.type,
            scene: .reply
        )
        let text = BundleI18n.LarkChat.__Lark_IM_NewPin_PinnedBy_Text as NSString
        let operaterFont = UIFont.systemFont(ofSize: 14)
        let startRange = text.range(of: "{{name}}")
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textPlaceholder,
            .font: operaterFont
        ]
        /// 如果匹配不到{{name}},使用降级策略
        if startRange.location == NSNotFound {
            let operaterProps = LabelProps(
                attributedText: NSAttributedString(string: BundleI18n.LarkChat.Lark_IM_NewPin_PinnedBy_Text(name), attributes: attributes),
                numberOfLines: 0,
                preferMaxLayoutWidth: preferredMaxLayoutWidth,
                outOfRangeText: nil,
                textLink: nil
            )
            self.operaterSize = calculateSize(props: operaterProps)
            self.operaterProps = operaterProps
            return
        }
        let muAttr = NSMutableAttributedString(string: BundleI18n.LarkChat.Lark_IM_NewPin_PinnedBy_Text(name),
                                               attributes: attributes)
        let nameRange = NSRange(location: startRange.location, length: (name as NSString).length)
        muAttr.addAttributes([.foregroundColor: UIColor.ud.primaryPri500], range: nameRange)
        var link = LKTextLink(range: nameRange,
                              type: .link,
                              attributes: [.foregroundColor: UIColor.ud.primaryPri500],
                              activeAttributes: [.foregroundColor: UIColor.ud.primaryPri500])
        let pbOperator = topNoticeModel.pbOperator
        link.linkTapBlock = { [weak self] (_, _) in
            self?.jumpToProfile(pbOperator)
        }

        let operaterProps = LabelProps(
            attributedText: muAttr,
            numberOfLines: 0,
            preferMaxLayoutWidth: preferredMaxLayoutWidth,
            outOfRangeText: nil,
            textLink: link
        )
        self.operaterSize = calculateSize(props: operaterProps)
        self.operaterProps = operaterProps
    }

    private func jumpToProfile(_ chatter: Chatter?) {
        guard let chatter = chatter,
              !chatter.isAnonymous,
              let targetVC = delegate?.getTargetVC() else {
            return
        }
        let body = PersonCardBody(chatterId: chatter.id)
        self.nav.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

}
