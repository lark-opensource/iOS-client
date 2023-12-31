//
//  UnknownPinCardCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/7/4.
//

import Foundation
import LarkOpenChat
import RustPB
import UniverseDesignIcon
import UniverseDesignColor

public final class UnknownPinCardCellViewModel: ChatPinCardCellViewModel,
                                                ChatPinCardActionProvider, ChatPinCardRenderAbility {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .unknown
    }

    public class var reuseIdentifier: String? {
        return "UnknownPinCardCellViewModel"
    }

    public override class func canInitialize(context: ChatPinCardContext) -> Bool {
        return true
    }

    private var metaModel: ChatPinCardCellMetaModel?

    public override func modelDidChange(model: ChatPinCardCellMetaModel) {
        self.metaModel = model
    }

    public func getActionItems() -> [ChatPinActionItemType] {
        return [.commonType(.unPin)]
    }

    private let limitedToNumberOfLines: Int = 0
    private let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                                                  .foregroundColor: UIColor.ud.textTitle]
    private let contentAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                    .foregroundColor: UIColor.ud.textTitle]
    private var titleText: String {
        if let unknownPayload = self.metaModel?.pin.payload as? UnknownChatPinPayload {
            return unknownPayload.title.isEmpty ? BundleI18n.LarkChat.Lark_IM_CurrentVersionDontSupportPinnedType_Text : unknownPayload.title
        }
        return BundleI18n.LarkChat.Lark_IM_CurrentVersionDontSupportPinnedType_Text
    }
    private let contentText: String = BundleI18n.LarkChat.Lark_IM_CurrentVersionDontSupportPinnedType_Text
    private let iconSize: CGFloat = 16

    public func getIconConfig() -> ChatPinIconConfig? {
        let iconResourceSize = CGSize(width: iconSize, height: iconSize)
        let defaultIcon = UDIcon.getIconByKey(.maybeFilled, size: iconResourceSize).ud.withTintColor(UIColor.ud.colorfulNeutral)
        guard let unknownPayload = self.metaModel?.pin.payload as? UnknownChatPinPayload else {
            let iconResource = ChatPinIconResource.image(.just(defaultIcon))
            return ChatPinIconConfig(iconResource: iconResource, size: iconResourceSize)
        }
        let iconResource = URLPreviewPinIconTransformer.transform(unknownPayload.icon,
                                                                  iconSize: iconResourceSize,
                                                                  defaultIcon: defaultIcon,
                                                                  placeholder: defaultIcon)
        return ChatPinIconConfig(iconResource: iconResource, size: iconResourceSize)
    }

    public func createTitleView() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = limitedToNumberOfLines
        return label
    }

    public func updateTitletView(_ view: UILabel) {
        view.attributedText = NSAttributedString(string: self.titleText, attributes: titleAttributes)
    }

    private var titleAvailableMaxWidth: CGFloat {
        return self.context.headerAvailableMaxWidth - iconSize
    }

    public func getTitleSize() -> CGSize {
        let attrStr = NSAttributedString(string: self.titleText, attributes: titleAttributes)
        let titileSize = attrStr.componentTextSize(for: CGSize(width: titleAvailableMaxWidth, height: .infinity), limitedToNumberOfLines: limitedToNumberOfLines)
        return CGSize(width: titleAvailableMaxWidth, height: titileSize.height)
    }

    public func createContentView() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = limitedToNumberOfLines
        return label
    }

    public func updateContentView(_ view: UILabel) {
        view.attributedText = NSAttributedString(string: self.contentText, attributes: contentAttributes)
    }

    public func getContentSize() -> CGSize {
        let attrStr = NSAttributedString(string: self.contentText, attributes: contentAttributes)
        let titileSize = attrStr.componentTextSize(for: CGSize(width: self.context.contentAvailableMaxWidth, height: .infinity), limitedToNumberOfLines: limitedToNumberOfLines)
        return CGSize(width: self.context.contentAvailableMaxWidth, height: titileSize.height)
    }
}
