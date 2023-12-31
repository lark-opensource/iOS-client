//
//  LarkInterface+Search.swift
//  LarkContainer
//
//  Created by ChalrieSu on 2018/4/20.
//

import Foundation
import UIKit
import LarkModel
import EENavigator
import RxSwift
import LarkSDKInterface
import LarkMessageBase
import LarkNavigation

// 搜索的类型
public enum MessengerSearchInChatType: String, Codable {
    case message, file, doc, wiki, image, url
}

extension Chat.TypeEnum: Codable {}

// 群内消息搜索界面
public struct SearchInChatBody: CodablePlainBody {
    public static let pattern = "//client/search/chat"

    public let chatId: String
    public var isMeetingChat: Bool = false
    public var type: MessengerSearchInChatType?
    public var chatType: Chat.TypeEnum?

    public init (chatId: String, chatType: Chat.TypeEnum?, isMeetingChat: Bool = false) {
        self.chatId = chatId
        self.chatType = chatType
        self.isMeetingChat = isMeetingChat
    }

    public init (chatId: String, type: MessengerSearchInChatType? = nil, chatType: Chat.TypeEnum?, isMeetingChat: Bool = false) {
        self.type = type
        self.chatId = chatId
        self.chatType = chatType
        self.isMeetingChat = isMeetingChat
    }
}

/// 群内消息搜索独立type界面
public struct SearchInChatSingleBody: CodablePlainBody {
    public static let pattern = "//client/search/chat/single"

    public let chatId: String
    public var isMeetingChat: Bool = false
    public var type: MessengerSearchInChatType
    public var chatType: Chat.TypeEnum

    public init (chatId: String, type: MessengerSearchInChatType, chatType: Chat.TypeEnum, isMeetingChat: Bool = false) {
        self.type = type
        self.chatId = chatId
        self.isMeetingChat = isMeetingChat
        self.chatType = chatType
    }
}

public struct SearchInThreadBody: CodablePlainBody {
    public static let pattern = "//client/search/thread"
    public var type: MessengerSearchInChatType?

    public let chatId: String
    public var chatType: Chat.TypeEnum?

    public init (chatId: String, chatType: Chat.TypeEnum?) {
        self.chatId = chatId
        self.chatType = chatType
    }

    public init (chatId: String, chatType: Chat.TypeEnum?, type: MessengerSearchInChatType? = nil) {
        self.type = type
        self.chatType = chatType
        self.chatId = chatId
    }
}

// 进入大搜的入口分类
public enum SourceOfSearch: String {
    case im, calendar, workplace, docs, email, contact, wiki, pin, todo, moments // 底下的 Tab
    case videoChat
    case messageMenu // 消息长按进入大搜
    case todayWidget // 程序小组件
    case community // 帖子(Thread)
    case none

    public init(value: String) {
        switch value {
        case "message": self = .im
        case "drive": self = .docs
        case "videochat": self = .videoChat
        case "appcenter": self = .workplace
        case "msg_menu": self = .messageMenu
        case "calendar": self = .calendar
        case "email": self = .email
        case "contact": self = .contact
        case "wiki": self = .wiki
        case "pin": self = .pin
        case "todayWidget": self = .todayWidget
        case "community": self = .community
        case "todo": self = .todo
        case "moments": self = .moments
        default: self = .none
        }
    }
}

extension SourceOfSearch {
    public var formerName: String {
        switch self {
        case .im: return "message"
        case .docs: return "drive"
        case .videoChat: return "videochat"
        case .workplace: return "appcenter"
        case .messageMenu: return "msg_menu"
        default: return rawValue
        }
    }

    public var sourceKey: String {
        switch self {
        case .im: return "messenger"
        case .workplace: return "openplatform"
        case .contact: return "contacts"
        case .videoChat: return "video-conference-page"
        case .email: return "mail"
        case .wiki: return "space"
        default: return rawValue
        }
    }

    public var trackRepresentation: String {
        switch self {
        case .todayWidget, .community, .videoChat: return "none"
        case .messageMenu: return "chat"
        default: return rawValue
        }
    }
}

public struct SearchMainBody: PlainBody {
    public static let pattern = "//client/search/main"

    public var scenes: [SearchSceneSection]?
    public var searchText: String?
    public var topPriorityScene: SearchSceneSection?
    public var sourceOfSearch: SourceOfSearch
    /*
     部分场景会出现在大搜内点击搜索结果，appLink还是跳大搜的情况，该情况不去拉起新的大搜，而只在大搜内跳转，
     此时：
        如果searchText不为空，则替换当前大搜的query，
        如果searchText为空，则根据shouldForceOverwriteQueryIfEmpty判断是否使用空query替换大搜query
     */
    public var shouldForceOverwriteQueryIfEmpty: Bool

    public init(scenes: [SearchSceneSection]? = nil,
                searchText: String? = nil,
                topPriorityScene: SearchSceneSection? = nil,
                sourceOfSearch: SourceOfSearch,
                shouldForceOverwriteQueryIfEmpty: Bool = false) {
        self.scenes = scenes
        self.searchText = searchText
        self.topPriorityScene = topPriorityScene
        self.sourceOfSearch = sourceOfSearch
        self.shouldForceOverwriteQueryIfEmpty = shouldForceOverwriteQueryIfEmpty
    }

    public init(scenes: [SearchSceneSection]? = nil,
                searchText: String? = nil,
                topPriorityScene: SearchSceneSection? = nil,
                searchTabName: String?,
                shouldForceOverwriteQueryIfEmpty: Bool = false) {
        self.scenes = scenes
        self.searchText = searchText
        self.topPriorityScene = topPriorityScene
        self.sourceOfSearch = SourceOfSearch(value: searchTabName ?? "none")
        self.shouldForceOverwriteQueryIfEmpty = shouldForceOverwriteQueryIfEmpty
    }
}

public struct SearchMainJumpBody: PlainBody {
    public static let pattern = "//clent/search/open"

    public var searchText: String?
    public var searchTabName: String?
    public var sourceOfSearch: SourceOfSearch

    public var jumpTab: SearchSectionAction
    public var appId: String
    public var appLinkSource: String
    /*
     部分场景会出现在大搜内点击搜索结果，appLink还是跳大搜的情况，该情况不去拉起新的大搜，而只在大搜内跳转，
     此时：
        如果searchText不为空，则替换当前大搜的query，
        如果searchText为空，则根据shouldForceOverwriteQueryIfEmpty判断是否使用空query替换大搜query
     */
    public var shouldForceOverwriteQueryIfEmpty: Bool
    public init(searchText: String? = nil,
                searchTabName: String?,
                jumpTab: SearchSectionAction,
                appId: String,
                appLinkSource: String,
                shouldForceOverwriteQueryIfEmpty: Bool = false) {
        self.searchText = searchText
        self.searchTabName = searchTabName
        self.jumpTab = jumpTab
        self.appId = appId
        self.appLinkSource = appLinkSource
        self.sourceOfSearch = SourceOfSearch(value: searchTabName ?? "none")
        self.shouldForceOverwriteQueryIfEmpty = shouldForceOverwriteQueryIfEmpty
    }
}

public struct SearchUserCalendarBody: PlainBody {
    public static let pattern = "//client/search/user/calendar"

    public var _url: URL {
        return URL(string: SearchUserCalendarBody.pattern) ?? .init(fileURLWithPath: "")
    }

    public var doTransfer: ((_ tansferUserName: String, _ tansferUserId: String) -> Void)?
    public let eventOrganizerId: String

    public init(eventOrganizerId: String,
                doTransfer: ((String, String) -> Void)? = nil) {
        self.doTransfer = doTransfer
        self.eventOrganizerId = eventOrganizerId
    }
}

public struct SearchGroupChatterPickerBody: PlainBody {
    public typealias SureCallBack = (_ controller: UIViewController, _ selectItems: [Chatter]) -> Void

    public static var pattern: String = "//client/search/chatter/picker"

    public let chatId: String
    public let selectedChatterIds: [String]

    public var confirm: SureCallBack?
    public var cancel: (() -> Void)?
    public let forceMultiSelect: Bool

    public let title: String

    public init(title: String,
                chatId: String,
                forceMultiSelect: Bool = false,
                selectedChatterIds: [String]) {
        self.title = title
        self.chatId = chatId
        self.forceMultiSelect = forceMultiSelect
        self.selectedChatterIds = selectedChatterIds
    }
}

/// 卡片消息用的选人组件
public struct SearchChatterPickerBody: PlainBody {

    public static var pattern: String = "//client/chatter/select/card"

    public let chatID: String
    public var navibarTitle: String = ""
    public var chatterIDs: [String] = []
    public var preSelectIDs: [String]?
    // 是否支持搜索
    public var searchEnabled: Bool = true
    // 当chatterIDs为空时，是否使用chatID拉取chatterIDs兜底展示
    public var showChatChatters: Bool = true
    public var isMulti: Bool = false
    // 是否为半屏popup
    public var isPopup: Bool = false
    public var selectChatterCallback: (([Chatter]) -> Void)?

    public init(
        chatID: String,
        chatterIDs: [String] = [],
        selectChatterCallback: (([Chatter]) -> Void)?
    ) {
        self.init(chatID: chatID,
                  navibarTitle: "",
                  chatterIDs: chatterIDs,
                  searchEnabled: true,
                  showChatChatters: true,
                  selectChatterCallback: selectChatterCallback)
    }

    public init(
        chatID: String,
        navibarTitle: String = "",
        chatterIDs: [String] = [],
        preSelectIDs: [String]? = nil,
        searchEnabled: Bool = true,
        showChatChatters: Bool = true,
        isMulti: Bool = false,
        isPopup: Bool = false,
        selectChatterCallback: (([Chatter]) -> Void)?
    ) {
        self.chatID = chatID
        self.navibarTitle = navibarTitle
        self.chatterIDs = chatterIDs
        self.preSelectIDs = preSelectIDs
        self.searchEnabled = searchEnabled
        self.showChatChatters = showChatChatters
        self.isMulti = isMulti
        self.isPopup = isPopup
        self.selectChatterCallback = selectChatterCallback
    }
}

// 搜索时间段选择页面
public struct SearchDateFilterBody: PlainBody {
    public typealias SureCallBack = (_ controller: UIViewController, _ startDate: Date?, _ endDate: Date?) -> Void

    public static var pattern: String = "//client/search/filter/date"

    public let startDate: Date?
    public let endDate: Date?
    public let enableSelectFuture: Bool
    public var confirm: SureCallBack?
    public var fromView: UIView?

    // 关闭选中未来后，endDate不能比当前时间晚
    public init(startDate: Date?, endDate: Date?, enableSelectFuture: Bool = false) {
        self.enableSelectFuture = enableSelectFuture
        self.startDate = startDate
        if !enableSelectFuture {
            if let _endDate = endDate, _endDate < Date() {
                self.endDate = endDate
            } else {
                self.endDate = Date()
            }
        } else {
            self.endDate = endDate
        }
    }
}

//pad上搜索入口跳转
public struct SearchOnPadJumpBody: PlainBody {
    public static var pattern = "//client/search/onpad"

    public var searchEnterModel: SearchEnterModel
    public init(searchEnterModel: SearchEnterModel) {
        self.searchEnterModel = searchEnterModel
    }
}

public protocol ChatDocSpaceTabDelegate: AnyObject {
    func jumpToChat(messagePosition: Int32)
    /// 容器 VC 顶部视图高度
    var contentTopMargin: CGFloat { get }
}

//搜索-消息跳转的消息详情页，往「x」按钮的submodule 透传来源
public protocol ChatCloseDetailLeftItemService: AnyObject {
    var source: SpecificSourceFromWhere? { get }
}

public final class DefaultChatCloseDetailLeftItemService: ChatCloseDetailLeftItemService {
    public init() {}
    public var source: SpecificSourceFromWhere? { return nil }
}
