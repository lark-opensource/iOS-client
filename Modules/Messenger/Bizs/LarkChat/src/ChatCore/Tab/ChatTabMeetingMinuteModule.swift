//
//  ChatTabMeetingMinuteModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/6.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel
import LarkContainer
import EENavigator
import LKCommonsLogging
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkSDKInterface
import UniverseDesignIcon
import RustPB
import LarkCore

final public class ChatTabMeetingMinuteModule: ChatTabSubModule {
    @ScopedInjectedLazy private var docSDKAPI: ChatDocDependency?
    static private let logger = Logger.log(ChatTabMeetingMinuteModule.self, category: "Lark.MessengerAssembly")

    override public var type: ChatTabType {
        return .meetingMinute
    }

    override public class func canInitialize(context: ChatTabContext) -> Bool {
        return true
    }

    override public func checkVisible(metaModel: ChatTabMetaModel) -> Bool {
        if metaModel.chat.isMeeting { return true }
        return self.getURL(metaModel.content?.payloadJson ?? "") != nil
    }

    private func getURL(_ payloadJson: String) -> URL? {
        guard let data = payloadJson.data(using: .utf8),
              let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let url = dic["url"] as? String,
              let meetingURL = URL(string: url) else {
            return nil
        }
        return meetingURL
    }

    override public func jumpTab(model: ChatJumpTabModel) {
        if let meetingURL = getURL(model.content.payloadJson) {
            navigator.push(meetingURL, from: model.targetVC)
            return
        }
        Self.logger.error("content do not contain meetingURL")
    }

    override public func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        return BundleI18n.Calendar.Calendar_MeetingNotes_MeetingNotes
    }

    override public func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        return .image(UDIcon.getIconByKey(.noteColorful, size: CGSize(width: 20, height: 20)))
    }

    override public func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
        guard let content = metaModel.content else { return nil }
        return ChatTabManageItem(
          name: self.getTabTitle(metaModel),
          tabId: content.id,
          canBeDeleted: !metaModel.chat.isMeeting,
          canEdit: false,
          canBeSorted: true,
          imageResource: self.getImageResource(metaModel)
        )
    }

    override public func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        var params: [AnyHashable: Any] = ["tab_type": "meeting_tab", "is_oapi_tab": "false"]
        if let url = self.getURL(metaModel.content?.payloadJson ?? "") {
            params["file_id"] = self.docSDKAPI?.isSupportURLType(url: url).2
        }
        return params
    }
}
