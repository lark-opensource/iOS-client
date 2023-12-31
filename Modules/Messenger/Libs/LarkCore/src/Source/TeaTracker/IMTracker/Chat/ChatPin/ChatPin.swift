//
//  Sidebar.swift
//  LarkCore
//
//  Created by zhaojiachen on 2023/6/19.
//

import Foundation
import LKCommonsTracker
import LarkModel
import RustPB

public extension IMTracker.Chat {
    struct Sidebar {}
}

public enum IMTrackerChatPinType: String {
    case unknown = ""
    case message
    case url
    case pinList = "pin_list"

    case announcement

    public init(type: RustPB.Im_V1_UniversalChatPin.TypeEnum) {
        switch type {
        case .messagePin:
            self = .message
        case .urlPin:
            self = .url
        case .announcementPin:
            self = .announcement
        case .unknown:
            self = .unknown
        @unknown default:
            self = .unknown
        }
    }
}

public extension IMTracker.Chat.Sidebar {
    static func View(_ chat: Chat) {
        Tracker.post(TeaEvent("im_chat_sidebar_view",
                              params: ["scene": "top"],
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

public extension IMTracker.Chat.Sidebar {
    struct Click {
        public static func addTop(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "add_top",
                                              "target": "none",
                                              "scene": "top"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func open(_ chat: Chat, topId: Int64?, messageId: String?, type: IMTrackerChatPinType) {
            var params: [AnyHashable: Any] = ["click": "open",
                                              "target": "none",
                                              "top_type": type.rawValue,
                                              "scene": "top"]
            if let topId = topId {
                params["top_id"] = "\(topId)"
            }
            if let messageId = messageId {
                params["msg_id"] = messageId
            }
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func copyLink(_ chat: Chat, topId: Int64) {
            let params: [AnyHashable: Any] = ["click": "copy_link",
                                              "target": "none",
                                              "scene": "top",
                                              "top_id": "\(topId)",
                                              "top_type": IMTrackerChatPinType.url.rawValue,
                                              "location": "more"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func edit(_ chat: Chat, topId: Int64) {
            let params: [AnyHashable: Any] = ["click": "edit",
                                              "target": "none",
                                              "scene": "top",
                                              "top_id": "\(topId)",
                                              "top_type": IMTrackerChatPinType.url.rawValue,
                                              "location": "more"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func remove(_ chat: Chat, topId: Int64?, messageId: String?, topType: IMTrackerChatPinType) {
            var params: [AnyHashable: Any] = ["click": "remove",
                                              "target": "none",
                                              "scene": "top",
                                              "top_type": topType.rawValue,
                                              "location": "more"]
            if let topId = topId {
                params["top_id"] = "\(topId)"
            }
            if let messageId = messageId {
                params["msg_id"] = messageId
            }
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func viewInChat(_ chat: Chat, topId: Int64?, messageId: String?, topType: IMTrackerChatPinType) {
            var params: [AnyHashable: Any] = ["click": "view_in_chat",
                                              "target": "none",
                                              "scene": "top",
                                              "top_type": topType.rawValue,
                                              "location": "more"]
            if let topId = topId {
                params["top_id"] = "\(topId)"
            }
            if let messageId = messageId {
                params["msg_id"] = messageId
            }
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func more(_ chat: Chat, topId: Int64?, messageId: String?, type: IMTrackerChatPinType) {
            var params: [AnyHashable: Any] = ["click": "more",
                                              "target": "none",
                                              "scene": "top",
                                              "top_type": type.rawValue]
            if let topId = topId {
                params["top_id"] = "\(topId)"
            }
            if let messageId = messageId {
                params["msg_id"] = messageId
            }
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func close(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "close",
                                              "target": "none",
                                              "scene": "top"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func moveToTop(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "move_to_top"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func cancelmMoveToTop(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "cancel_move_to_top"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func drag(_ chat: Chat, topId: Int64, topType: IMTrackerChatPinType, sourcePos: Int, targetPos: Int, isTop: Bool) {
            let params: [AnyHashable: Any] = ["click": "drag",
                                              "top_id": "\(topId)",
                                              "top_type": topType.rawValue,
                                              "is_fix": isTop ? "true" : "false",
                                              "source_position": "\(sourcePos)",
                                              "target_position": "\(targetPos)"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func closeOnboarding(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "close_onboarding"]
            Tracker.post(TeaEvent("im_chat_sidebar_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat.Sidebar {
    struct TopCard {
        public static func View(_ chat: Chat, topList: [(Int64, IMTrackerChatPinType)]) {
            Tracker.post(TeaEvent("im_chat_sidebar_topcard_view",
                                  params: ["top_list": topList.map { ["top_id": $0.0, "top_type": $0.1.rawValue] }],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat.Sidebar {
    struct Confirm {
        public static func replace(_ chat: Chat) {
            Tracker.post(TeaEvent("im_chat_sidebar_confirm_click",
                                  params: ["click": "replace"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func cancelFix(_ chat: Chat) {
            Tracker.post(TeaEvent("im_chat_sidebar_confirm_click",
                                  params: ["click": "cancel_fix"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat {
    struct AddTop {}
}

public extension IMTracker.Chat.AddTop {
    static func View(_ chat: Chat) {
        Tracker.post(TeaEvent("im_chat_add_top_view",
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

public extension IMTracker.Chat.AddTop {
    struct Click {
        public static func cancel(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "cancel",
                                              "target": "none"]
            Tracker.post(TeaEvent("im_chat_add_top_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func search(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "search",
                                              "target": "none"]
            Tracker.post(TeaEvent("im_chat_add_top_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func select(_ chat: Chat, fromSearch: Bool) {
            let params: [AnyHashable: Any] = ["click": "select",
                                              "add_source": fromSearch ? "search" : "default",
                                              "target": "none"]
            Tracker.post(TeaEvent("im_chat_add_top_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func edit(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "edit",
                                              "target": "none"]
            Tracker.post(TeaEvent("im_chat_add_top_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func add(_ chat: Chat, fromSearch: Bool, addNum: Int, searchDoc: Bool, isEdit: Bool) {
            var params: [AnyHashable: Any] = ["click": "add",
                                              "is_edit": isEdit ? "true" : "false",
                                              "add_num": "\(addNum)",
                                              "target": "none"]
            if searchDoc {
                params["add_source"] = fromSearch ? "search" : "default"
            }
            Tracker.post(TeaEvent("im_chat_add_top_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat {
    struct Top {}
}

public extension IMTracker.Chat.Top {
    struct Click {
        public static func top(_ chat: Chat, topId: Int64?, type: IMTrackerChatPinType) {
            var params: [AnyHashable: Any] = ["click": "top",
                                              "target": "none",
                                              "top_type": type.rawValue]
            if let topId = topId {
                params["top_id"] = "\(topId)"
            }
            Tracker.post(TeaEvent("im_chat_top_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func more(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "more",
                                              "target": "none"]
            Tracker.post(TeaEvent("im_chat_top_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat.Top {
    struct Onboarding {
        public static func View(_ chat: Chat, isFromInfo: Bool) {
            let params: [AnyHashable: Any] = ["open_source": isFromInfo ? "info" : "default"]
            Tracker.post(TeaEvent("im_chat_top_onboarding_view",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public struct Click {
            public static func KnowDetails(_ chat: Chat, isFromInfo: Bool) {
                let params: [AnyHashable: Any] = ["click": "know_details",
                                                  "open_source": isFromInfo ? "info" : "default"]
                Tracker.post(TeaEvent("im_chat_top_onboarding_click",
                                      params: params,
                                      bizSceneModels: [IMTracker.Transform.chat(chat)]))
            }
        }
    }
}
