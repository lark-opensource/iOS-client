//
//  URLPreviewPinSummaryCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RxCocoa
import LarkOpenChat
import LKCommonsLogging
import ByteWebImage
import RustPB
import LarkModel
import EENavigator
import TangramService
import LarkMessengerInterface
import LarkContainer

public final class URLPreviewPinSummaryCellViewModel: ChatPinSummaryCellViewModel {
    private static let logger = Logger.log(URLPreviewPinSummaryCellViewModel.self, category: "Module.IM.ChatPin")

    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .urlPin
    }

    public override class func canInitialize(context: ChatPinSummaryContext) -> Bool {
        return true
    }

    private var metaModel: ChatPinSummaryCellMetaModel?
    @ScopedInjectedLazy private var auditService: ChatSecurityAuditService?

    public override func modelDidChange(model: ChatPinSummaryCellMetaModel) {
        self.metaModel = model
    }

    public override func getSummaryInfo() -> (attributedTitle: NSAttributedString, iconConfig: ChatPinIconConfig?) {
        let iconSize = CGSize(width: 16, height: 16)
        let defaultIcon = UDIcon.getIconByKey(.globalLinkOutlined, size: iconSize).ud.withTintColor(UIColor.ud.B500)
        guard let urlPreviewPayload = self.metaModel?.pin.payload as? URLPreviewChatPinPayload else {
            return (NSAttributedString(string: ""), ChatPinIconConfig(iconResource: .image(.just(defaultIcon))))
        }

        return (NSAttributedString(string: urlPreviewPayload.displayTitle, attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                                 .foregroundColor: UIColor.ud.textTitle]),
                ChatPinIconConfig(iconResource: URLPreviewPinIconTransformer.transform(urlPreviewPayload.displayIcon,
                                                                                       iconSize: iconSize,
                                                                                       defaultIcon: defaultIcon,
                                                                                       placeholder: defaultIcon),
                                  cornerRadius: 2))
    }

    public override func onClick() {
        guard let metaModel = self.metaModel,
              let urlPreviewPayload = metaModel.pin.payload as? URLPreviewChatPinPayload,
              let chatVC = (try? self.context.userResolver.resolve(assert: ChatOpenService.self))?.chatVC() else {
            return
        }
        self.auditService?.auditEvent(.chatPin(type: .clickOpenUrl(chatId: metaModel.chat.id,
                                                                   pinId: metaModel.pin.id)),
                                      isSecretChat: false)
        if !urlPreviewPayload.url.isEmpty,
           let url = try? URL.forceCreateURL(string: urlPreviewPayload.url) {
            if let httpUrl = url.lf.toHttpUrl() {
                self.context.nav.open(httpUrl, from: chatVC)
            } else {
                self.context.nav.open(url, from: chatVC)
            }
        } else {
            Self.logger.error("chatPinCardTrace [URLPreview] url create failed chat: \(metaModel.chat.id) pinId: \(metaModel.pin.id)")
        }
    }
}
