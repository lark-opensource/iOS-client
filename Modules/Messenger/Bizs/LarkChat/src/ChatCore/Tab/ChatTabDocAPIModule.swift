//
//  ChatTabDocAPIModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2021/12/20.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel
import LarkContainer
import EENavigator
import RustPB
import LKCommonsLogging
import LarkFeatureGating
import LarkMessengerInterface
import LarkUIKit
import LarkRichTextCore
import UniverseDesignIcon

final public class ChatTabDocAPIModule: ChatTabSubModule {
    static private let FromValue: String = "chat_tabs_docPreview"
    static private let logger = Logger.log(ChatTabDocAPIModule.self, category: "Lark.MessengerAssembly")
    @ScopedInjectedLazy private var docSDKAPI: ChatDocDependency?
    override public var type: ChatTabType {
        return .doc
    }

    override public class func canInitialize(context: ChatTabContext) -> Bool {
        return true
    }

    private func getPayloadDic(_ payloadJson: String?) -> [String: Any] {
        if let data = payloadJson?.data(using: .utf8),
           let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return dic
        }
        return [:]
    }

    override public func jumpTab(model: ChatJumpTabModel) {
        let dic = self.getPayloadDic(model.content.payloadJson)
        guard let url = dic["url"] as? String,
              let docURL = URL(string: url) else {
                  Self.logger.error("chat tab init doc json failed \(model.content.id))")
            return
        }
        navigator.push(docURL.append(name: "from", value: "top_doc_tab"), context: ["showTemporary": false], from: model.targetVC)
    }

    override public func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
        guard let content = metaModel.content else { return nil }
        return ChatTabManageItem(
            name: self.getTabTitle(metaModel),
            tabId: content.id,
            canBeDeleted: true,
            canEdit: true,
            canBeSorted: true,
            imageResource: self.getImageResource(metaModel)
        )
    }

    override public func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        return metaModel.content?.name ?? ""
    }

    override public func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        if let typeStr = self.getPayloadDic(metaModel.content?.payloadJson)["docType"] as? String,
           let typeRawValue = Int(typeStr),
           let docType = RustPB.Basic_V1_Doc.TypeEnum(rawValue: typeRawValue) {
            return .image(LarkRichTextCoreUtils.docIconColorful(docType: docType, fileName: ""))
        }
        return .image(UDIcon.getIconByKey(.fileDocColorful, size: CGSize(width: 20, height: 20)))
    }

    override public func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        var params: [AnyHashable: Any] = ["tab_type": "single_doc_tab"]
        let dic = self.getPayloadDic(metaModel.content?.payloadJson)
        if let urlStr = dic["url"] as? String,
           let url = URL(string: urlStr) {
            params["file_id"] = self.docSDKAPI?.isSupportURLType(url: url).2
        }
        var isOapiTab: Bool = false
        if let source = dic["source"] as? String, source == "OAPI" {
            isOapiTab = true
            if let appId = dic["app_id"] as? Int {
                params["app_id"] = "\(appId)"
            }
        }
        params["is_oapi_tab"] = "\(isOapiTab)"
        return params
    }

    override public func getFirstScreenParams(_ metaModels: [ChatTabMetaModel]) -> [AnyHashable: Any] {
        let docTabCount = metaModels.count
        return ["doc_page_count": docTabCount]
    }

    override public func beginAddTab(metaModel: ChatAddTabMetaModel) {
        guard let from = (try? self.context.resolver.resolve(assert: ChatOpenService.self))?.chatVC(),
            let chatOpenTabService = try? self.context.resolver.resolve(assert: ChatOpenTabService.self)
        else { return }
        let presentParam = PresentParam(
            wrap: LkNavigationController.self,
            from: from,
            prepare: {
                $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            }
        )

        self.docSDKAPI?.presentTabSendDocController(
            chat: metaModel.chat,
            title: BundleI18n.LarkChat.Lark_Groups_AddTabsTitle,
            presentParam: presentParam,
            chatOpenTabService: chatOpenTabService
        )
    }
}
