//
//  ChatTabTaskModule.swift
//  TodoMod
//
//  Created by baiyantao on 2022/12/1.
//

#if MessengerMod
import Foundation
import LarkOpenChat
import LarkModel
import EENavigator
import LKCommonsLogging
import UniverseDesignIcon
import LarkFoundation
import TangramService
import LarkSetting

public final class ChatTabTaskModule: ChatTabSubModule {
    static private let logger = Logger.log(ChatTabTaskModule.self, category: "Lark.ChatTabTaskModule")

    override public var type: ChatTabType {
        return .task
    }

    override public class func canInitialize(context: ChatTabContext) -> Bool {
        return true
    }

    override public func jumpTab(model: ChatJumpTabModel) {
        let dic = self.getPayloadDic(model.content.payloadJson)
        guard let urlStr = dic["url"] as? String else {
            Self.logger.error("chat tab init url json failed \(model.content.id))")
            return
        }
        guard let linkUrl = try? URL.forceCreateURL(string: urlStr).lf.toHttpUrl() else {
            Self.logger.error("chat tab transform to link url failed \(model.content.id))")
            return
        }
        userResolver.navigator.push(linkUrl, from: model.targetVC)
    }

    override public func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        return metaModel.content?.name ?? ""
    }

    override public func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        return .image(UDIcon.getIconByKey(.todoColorful, size: CGSize(width: 20, height: 20)))
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

    override public func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        var params: [AnyHashable: Any] = ["tab_type": "task_tab"]
        let dic = self.getPayloadDic(metaModel.content?.payloadJson)
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

    private func getPayloadDic(_ payloadJson: String?) -> [String: Any] {
        if let data = payloadJson?.data(using: .utf8),
           let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            return dic
        }
        return [:]
    }
}
#endif
