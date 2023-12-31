//
//  misc.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/9.
//

import Foundation
import RustPB

extension Search_V1_Scene.TypeEnum {
    public func protobufName() -> String {
        switch self {
        case .unknown: return "UNKNOWN"
        case .atUsers: return "AT_USERS"
        case .addChatChatters: return "ADD_CHAT_CHATTERS"
        case .transmitMessages: return "TRANSMIT_MESSAGES"
        case .smartSearch: return "SMART_SEARCH"
        case .searchMessages: return "SEARCH_MESSAGES"
        case .searchChats: return "SEARCH_CHATS"
        case .searchChatters: return "SEARCH_CHATTERS"
        case .searchUsers: return "SEARCH_USERS"
        case .searchInChat: return "SEARCH_IN_CHAT"
        case .searchChatterInEmail: return "SEARCH_CHATTER_IN_EMAIL"
        case .searchMemberInEmail: return "SEARCH_MEMBER_IN_EMAIL"
        case .searchDoc: return "SEARCH_DOC"
        case .searchEmailMessages: return "SEARCH_EMAIL_MESSAGES"
        case .searchDocsInDialogScene: return "SEARCH_DOCS_IN_DIALOG_SCENE"
        case .searchInCalendarScene: return "SEARCH_IN_CALENDAR_SCENE"
        case .searchHadChatHistoryScene: return "SEARCH_HAD_CHAT_HISTORY_SCENE"
        case .searchMessageInChatScene: return "SEARCH_MESSAGE_IN_CHAT_SCENE"
        case .searchFileInChatScene: return "SEARCH_FILE_IN_CHAT_SCENE"
        case .searchDocsInChatScene: return "SEARCH_DOCS_IN_CHAT_SCENE"
        case .getFileInChatScene: return "GET_FILE_IN_CHAT_SCENE"
        case .getDocsInChatScene: return "GET_DOCS_IN_CHAT_SCENE"
        case .searchBoxScene: return "SEARCH_BOX_SCENE"
        case .searchOncallScene: return "SEARCH_ONCALL_SCENE"
        case .searchMessageCount: return "SEARCH_MESSAGE_COUNT"
        case .searchThreadScene: return "SEARCH_THREAD_SCENE"
        case .searchChatMentionScene: return "SEARCH_CHAT_MENTION_SCENE"
        case .searchOpenAppScene: return "SEARCH_OPEN_APP_SCENE"
        case .largeGroupSearchScene: return "LARGE_GROUP_SEARCH_SCENE"
        case .largeGroupReadScene: return "LARGE_GROUP_READ_SCENE"
        case .searchLinkScene: return "SEARCH_LINK_SCENE"
        case .searchFileScene: return "SEARCH_FILE_SCENE"
        case .searchExternalScene: return "SEARCH_EXTERNAL_SCENE"
        case .searchWikiScene: return "SEARCH_WIKI_SCENE"
        case .searchWikiInChatScene: return "SEARCH_WIKI_IN_CHAT_SCENE"
        case .advancedSearchFilterScene: return "ADVANCED_SEARCH_FILTER_SCENE"
        case .searchCalendarEventScene: return "SEARCH_CALENDAR_EVENT_SCENE"
        case .searchChatsInAdvanceScene: return "SEARCH_CHATS_IN_ADVANCE_SCENE"
        case .searchChattersInAdvanceScene: return "SEARCH_CHATTERS_IN_ADVANCE_SCENE"
        case .searchDepartmentScene: return "SEARCH_DEPARTMENT_SCENE"
        case .searchPinMsgScene: return "SEARCH_PIN_MSG_SCENE"
        case .searchPanoTagScene: return "SEARCH_PANO_TAG_SCENE"
        case .searchPanoViewScene: return "SEARCH_PANO_VIEW_SCENE"
        case .searchSlashCommandScene: return "SEARCH_SLASH_COMMAND_SCENE"
        case .searchOpenSearchScene: return "SEARCH_OPEN_SEARCH_SCENE"
        case .searchDocsWikiInChatScene: return "SEARCH_DOCS_WIKI_IN_CHAT_SCENE"
        case .pullDocsWikiInChatScene: return "PULL_DOCS_WIKI_IN_CHAT_SCENE"
        @unknown default: break
        }
        return String(describing: self)
    }
}

extension Search_V1_SearchChatMeta {
    public var userCountWithBackup: Int32 { return userCount > 0 ? userCount : memberCount }
    public var userCountText: String {
        if userCount > 0 { return "(\(userCount))" }
        if memberCount > 0 { return "(\(memberCount))" }
        return ""
    }
    public var userCountTextMayBeInvisible: String {
        return ""
    }
    public var isUserCountVisible: Bool {
        return true
    }
}

extension Search_V2_ChatMeta {
    public var userCountWithBackup: Int32 { userCount }
    public var userCountText: String {
        if userCount > 0 { return "(\(userCount))" }
        // if memberCount > 0 { return "(\(memberCount))" }
        return ""
    }
    public var userCountTextMayBeInvisible: String {
        if !userCountInvisible {
            return "(\(userCountWithBackup))"
        } else {
            return ""
        }
    }
    public var isUserCountVisible: Bool {
        return !userCountInvisible
    }
}

extension Bool {
    public var searchStatValue: String { self ? "True" : "False" }
}
