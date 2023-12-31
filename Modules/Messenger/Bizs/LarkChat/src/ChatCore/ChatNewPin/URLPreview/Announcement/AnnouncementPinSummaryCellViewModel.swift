//
//  AnnouncementPinSummaryCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/24.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import LarkOpenChat
import RustPB

public final class AnnouncementPinSummaryCellViewModel: ChatPinSummaryCellViewModel {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .announcementPin
    }

    public override class func canInitialize(context: ChatPinSummaryContext) -> Bool {
        return true
    }

    private var metaModel: ChatPinSummaryCellMetaModel?

    public override func modelDidChange(model: ChatPinSummaryCellMetaModel) {
        self.metaModel = model
    }

    public override func getSummaryInfo() -> (attributedTitle: NSAttributedString, iconConfig: ChatPinIconConfig?) {
        let icon = UDIcon.getIconByKey(.announceFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.orange)
        var title: String = BundleI18n.LarkChat.Lark_Groups_Announcement
        if let payload = metaModel?.pin.payload as? AnnouncementChatPinPayload,
           let content = payload.announcementPBModel?.content,
           !content.isEmpty {
            title = BundleI18n.LarkChat.Lark_IM_SuperApp_AnnouncementPin_Text(content)
        }
        return (NSAttributedString(string: title, attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                               .foregroundColor: UIColor.ud.textTitle]),
                ChatPinIconConfig(iconResource: .image(.just(icon))))
    }

    public override func onClick() {
        guard let metaModel = self.metaModel,
              let payload = metaModel.pin.payload as? AnnouncementChatPinPayload,
              let chatVC = (try? self.context.userResolver.resolve(assert: ChatOpenService.self))?.chatVC() else {
            return
        }
        AnnouncementChatPinConfig.onClick(useOpendoc: payload.useOpendoc,
                                          pinURL: payload.url,
                                          cardURL: nil,
                                          targetVC: chatVC,
                                          chat: metaModel.chat,
                                          userResolver: self.context.userResolver,
                                          pinId: metaModel.pin.id)
    }
}
