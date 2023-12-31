//
//  UnknownPinSummaryCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/7/4.
//

import Foundation
import LarkOpenChat
import RustPB
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift
import RxCocoa

public final class UnknownPinSummaryCellViewModel: ChatPinSummaryCellViewModel {

    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .unknown
    }

    public override class func canInitialize(context: ChatPinSummaryContext) -> Bool {
        return true
    }

    private var metaModel: ChatPinSummaryCellMetaModel?

    public override func modelDidChange(model: ChatPinSummaryCellMetaModel) {
        self.metaModel = model
    }

    public override func getSummaryInfo() -> (attributedTitle: NSAttributedString, iconConfig: ChatPinIconConfig?) {
        let iconSize = CGSize(width: 16, height: 16)
        let defaultIcon = UDIcon.getIconByKey(.maybeFilled, size: iconSize).ud.withTintColor(UIColor.ud.colorfulNeutral)
        guard let unknownPayload = self.metaModel?.pin.payload as? UnknownChatPinPayload else {
            return (NSAttributedString(string: ""), ChatPinIconConfig(iconResource: .image(.just(defaultIcon))))
        }
        let title = unknownPayload.title.isEmpty ? BundleI18n.LarkChat.Lark_IM_CurrentVersionDontSupportPinnedType_Text : unknownPayload.title
        return (NSAttributedString(string: title, attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                      .foregroundColor: UIColor.ud.textTitle]),
                ChatPinIconConfig(iconResource: URLPreviewPinIconTransformer.transform(unknownPayload.icon,
                                                                                       iconSize: iconSize,
                                                                                       defaultIcon: defaultIcon,
                                                                                       placeholder: defaultIcon)))
    }

}
