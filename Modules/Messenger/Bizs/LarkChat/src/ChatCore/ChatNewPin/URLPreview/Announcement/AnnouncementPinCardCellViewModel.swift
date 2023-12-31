//
//  AnnouncementPinCardCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/24.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import LarkOpenChat
import RustPB
import LarkModel
import DynamicURLComponent
import LarkCore

public final class AnnouncementPinCardCellViewModel: URLPreviewBasePinCardCellViewModel {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .announcementPin
    }

    public override class var reuseIdentifier: String? {
        return "AnnouncementPinCardCellViewModel"
    }

    private let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                                              .foregroundColor: UIColor.ud.textTitle]
    private let title = BundleI18n.LarkChat.Lark_Groups_Announcement
    private let limitedToNumberOfLines: Int = 0

    public override func getActionItems() -> [ChatPinActionItemType] {
        return [.commonType(.stickToTop),
                .commonType(.unSticktoTop),
                .commonType(.unPin)]
    }

    private let iconSize: CGFloat = 16

    public override func getIconConfig() -> ChatPinIconConfig? {
        let icon = UDIcon.getIconByKey(.announceFilled, size: CGSize(width: iconSize, height: iconSize)).ud.withTintColor(UIColor.ud.orange)
        let iconResource = ChatPinIconResource.image(.just(icon))
        return ChatPinIconConfig(iconResource: iconResource, size: CGSize(width: iconSize, height: iconSize))
    }

    public override var showCardFooter: Bool {
        return false
    }

    public override var entity: URLPreviewEntity? {
        return (self.metaModel?.pin.payload as? AnnouncementChatPinPayload)?.urlPreviewEntity
    }

    public override func createTitleView() -> UILabel {
        let label = UILabel(frame: .zero)
        label.attributedText = NSAttributedString(string: title, attributes: attributes)
        label.numberOfLines = limitedToNumberOfLines
        return label
    }

    public override func updateTitletView(_ view: UILabel) {
        view.attributedText = NSAttributedString(string: title, attributes: attributes)
        view.gestureRecognizers?.forEach({ view.removeGestureRecognizer($0) })
        view.isUserInteractionEnabled = true
        _ = view.lu.addTapGestureRecognizer(action: #selector(onClickTitle), target: self)
    }

    @objc
    private func onClickTitle() {
        guard let metaModel = self.metaModel,
              let payload = metaModel.pin.payload as? AnnouncementChatPinPayload,
              let targetVC = self.targetVC else {
            return
        }
        AnnouncementChatPinConfig.onClick(useOpendoc: payload.useOpendoc,
                                          pinURL: payload.url,
                                          cardURL: nil,
                                          targetVC: targetVC,
                                          chat: metaModel.chat,
                                          userResolver: self.context.userResolver,
                                          pinId: metaModel.pin.id)
    }

    private var titleAvailableMaxWidth: CGFloat {
        return self.context.headerAvailableMaxWidth - iconSize
    }

    public override func getTitleSize() -> CGSize {
        let attrStr = NSAttributedString(string: title, attributes: attributes)
        let titleSize = attrStr.componentTextSize(for: CGSize(width: titleAvailableMaxWidth, height: .infinity), limitedToNumberOfLines: limitedToNumberOfLines)
        return CGSize(width: titleAvailableMaxWidth, height: titleSize.height)
    }

    public override func onCardTapped(cardURL: Basic_V1_URL?) {
        guard let metaModel = self.metaModel,
              let payload = metaModel.pin.payload as? AnnouncementChatPinPayload,
              let targetVC = self.targetVC else {
            return
        }
        AnnouncementChatPinConfig.onClick(useOpendoc: payload.useOpendoc,
                                          pinURL: payload.url,
                                          cardURL: cardURL,
                                          targetVC: targetVC,
                                          chat: metaModel.chat,
                                          userResolver: self.context.userResolver,
                                          pinId: metaModel.pin.id)
        IMTracker.Chat.Sidebar.Click.open(metaModel.chat, topId: metaModel.pin.id, messageId: nil, type: .announcement)
    }
}
