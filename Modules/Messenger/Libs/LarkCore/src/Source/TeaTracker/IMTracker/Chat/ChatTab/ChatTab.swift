//
//  ChatTab.swift
//  LarkCore
//
//  Created by zhaojiachen on 2022/4/24.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel

public extension IMTracker.Chat {
    struct TabManagement {}
}

public extension IMTracker.Chat.TabManagement {
    static func View(_ chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_VIEW,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

public extension IMTracker.Chat.TabManagement {
    struct Click {
        public static func ReOrder(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "tab_drag",
                                              "target": "im_chat_doc_page_manage_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabDelete(_ chat: Chat, tabId: Int64) {
            var params: [AnyHashable: Any] = ["click": "tab_delete",
                                              "target": "none",
                                              "tab_id": tabId]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabNameChange(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "tab_name_change",
                                              "target": "none"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabLinkChange(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "tab_link_change",
                                              "target": "none"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabAdd(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "tab_add",
                                              "target": "im_chat_doc_page_add_view",
                                              "location": "tab_more"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabClick(_ chat: Chat, params: [AnyHashable: Any]) {
            var md5AllowList: [String] = []
            var params = params
            params += ["target": "none",
                       "click": "single_tab"]
            if params["file_id"] != nil {
                md5AllowList = ["file_id"]
            } else {
                params["file_id"] = "NA"
            }
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_MANAGE_CLICK,
                                  params: params,
                                  md5AllowList: md5AllowList,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat {
    struct DocPageAdd {}
}

public extension IMTracker.Chat.DocPageAdd {
    static func View(_ chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_ADD_VIEW,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

public extension IMTracker.Chat.DocPageAdd {
    struct Click {
        public static func LinkAdd(_ chat: Chat, params: [AnyHashable: Any]) {
            var params = params
            params += ["click": "link_add",
                       "target": "none"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_ADD_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabSave(_ chat: Chat, params: [AnyHashable: Any]) {
            var params = params
            params += ["target": "none",
                       "click": "tab_save"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_ADD_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat {
    struct DocList {}
}
