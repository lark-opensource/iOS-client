//
//  ChatLinkPage.swift
//  LarkCore
//
//  Created by zhaojiachen on 2023/11/3.
//

import Foundation
import LKCommonsTracker
import LarkModel
import RustPB

public extension IMTracker.Chat {
    struct ChatLinkPage {

        public enum BarType: String {
            case createGroup = "create_group"
            case joinGroup = "join_group"
            case openGroup = "open_group"
        }

        private static var urlHashKey: String {
            return "hash_u"
        }

        private static var urlIDKey: String {
            return "url_id"
        }

        public static func View(_ chatID: String?, url: URL, barType: BarType, urlMetaID: Int?) {
            var params: [AnyHashable: Any] = ["show_type": barType.rawValue,
                                              urlHashKey: url.absoluteString]
            if let urlMetaID = urlMetaID {
                params[urlIDKey] = urlMetaID
            }
            if let chatID = chatID {
                params["chat_id"] = chatID
            }
            if let bizType = getBizType(url) {
                params["biz_type"] = bizType
            }
            Tracker.post(TeaEvent("im_group_plugin_view",
                                  params: params,
                                  md5AllowList: [urlHashKey]))
        }

        public static func Click(_ chatID: String?, url: URL, barType: BarType, urlMetaID: Int?) {
            var params: [AnyHashable: Any] = ["click": barType.rawValue,
                                              urlHashKey: url.absoluteString]
            if let urlMetaID = urlMetaID {
                params[urlIDKey] = urlMetaID
            }
            if let chatID = chatID {
                params["chat_id"] = chatID
            }
            if let bizType = getBizType(url) {
                params["biz_type"] = bizType
            }
            Tracker.post(TeaEvent("im_group_plugin_click",
                                  params: params,
                                  md5AllowList: [urlHashKey]))
        }

        private static func getBizType(_ url: URL) -> String? {
            if let host = url.host, let hostURL = URL(string: host) {
                var bizTypeURL = hostURL
                let pathComponents = url.pathComponents.prefix(2)
                pathComponents.forEach { bizTypeURL = bizTypeURL.appendingPathComponent($0) }
                let bizTypeStr = bizTypeURL.absoluteString
                return bizTypeStr
            }
            return nil
        }
    }
}
