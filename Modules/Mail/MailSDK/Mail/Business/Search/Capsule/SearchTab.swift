//
//  SearchTab.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
import ServerPB
import UniverseDesignIcon

//enum SearchTab: Identifiable, Hashable {
//    case main
//    case message, doc, wiki, chatter, chat, app, calendar, email
//    case oncall
//    case topic, thread
//    case pano(label: String)
//    enum RequestPageMod {
//        case normal // 正常翻页
//        case noPage // 不翻页，相当于只有1页
//    }
//    struct RequestParam {
//        var pageSize: Int32
//        var mod: RequestPageMod
//    }
//    struct OpenSearch {
//        var id: String
//        var label: String
//        var icon: String?
//        var resultType: ServerPB_Usearch_SearchTab.ResultType
//        var filters: [SearchFilter]
//        var bizKey: ServerPB_Usearch_SearchTab.BizKey?
//        var requestParam: RequestParam?
//    }
//    case open(OpenSearch)
//
//    var title: String {
//        switch self {
//        case .main:     return "main"
//        case .app:      return "app"
//        case .message:  return ""
//        case .doc:      return ""
//        case .oncall:   return ""
//        case .wiki:     return ""
//        case .chatter:  return ""
//        case .chat:     return ""
//        case .calendar: return ""
//        case .topic:    return ""
//        case .thread:   return ""
//        case .email:    return "邮箱"
//        case .open(let v): return v.label
//        case .pano(label: let v): return v
//        }
//    }
//
//    var icon: UIImage? {
//        switch self {
//        case .app: return UDIcon.tabAppColorful
//        case .message: return UDIcon.tabChatColorful
//        case .doc, .wiki: return UDIcon.tabDriveColorful
//        case .chatter: return UDIcon.tabContactsColorful
//        case .chat: return UDIcon.tabGroupColorful
//        case .calendar: return UDIcon.tabCalendarColorful
//        case .email: return UDIcon.tabMailColorful
//        case .oncall: return UDIcon.helpdeskColorful
//        default:
//            return nil
//        }
//    }
//
////    init?(_ tab: SearchMainTabService.Tab) {
////        func getGeneralFilters(tab: SearchMainTabService.Tab) -> [SearchFilter] {
////            return tab.platformCustomFilters.map { (info) -> SearchFilter? in
////                switch info.filterType {
////                case .userFilter:
////                    return .general(.user(info, []))
////                case .timeFilter:
////                    return .general(.date(info, nil))
////                case .searchableFilter, .predefineEnumFilter:
////                    switch info.optionMode {
////                    case .single: return .general(.single(info, nil))
////                    case .multiple: return .general(.multiple(info, []))
////                    @unknown default:
////                        return nil
////                    }
////                case .calendarFilter:
////                    return .general(.calendar(info, []))
////                case .userChatFilter:
////                    return .general(.userChat(info, []))
////                case .mailUser:
////                    return .general(.mailUser(info, []))
////                case .inputTextFilter:
////                    return .general(.inputTextFilter(info, []))
////                @unknown default:
////                    return nil
////                }
////            }.compactMap({ $0 })
////        }
////        switch tab.type {
////        case .messageTab: self = .message
////        case .docsTab: self = .doc
////        case .wikiTab: self = .wiki
////        case .chatTab: self = .chat
////        case .calendarTab: self = .calendar
////        case .appTab: self = .app
////        case .chatterTab: self = .chatter
////        case .openSearchTab:
////            var requestParam: RequestParam?
////            if tab.hasParams, tab.params.hasPageSize, tab.params.hasMode {
////                let pageSize = tab.params.pageSize > 0 ? tab.params.pageSize : 15
////                switch tab.params.mode {
////                case .normal: requestParam = RequestParam(pageSize: pageSize, mod: .normal)
////                case .noPage: requestParam = RequestParam(pageSize: pageSize, mod: .noPage)
////                case .unknown: requestParam = nil
////                @unknown default:
////                    requestParam = nil
////                    assertionFailure("@unknown case")
////                }
////            }
////            self = .open(.init(id: tab.appID,
////                               label: tab.label,
////                               icon: tab.hasIconURL ? tab.iconURL : nil,
////                               resultType: tab.resultType,
////                               filters: getGeneralFilters(tab: tab),
////                               bizKey: tab.bizKey,
////                               requestParam: requestParam))
////        case .emailTab: self = .email
////        case .panoTab: self = .pano(label: tab.label)
////        case .helpdeskTab: self = .oncall
////        // NOTE: 除了不知道的，格式尽量保留，哪怕UI暂时没适配.., 这样可以转换回传set数据
////        // UI适配用另一个supported参数控制
////        case .unknownTab, .smartSearchTab:
////            fallthrough // use unknown default setting to fix warning
////        @unknown default:
////        return nil
////        }
////    }
////    func cast() -> SearchMainTabService.Tab? {
////        switch self {
////        case .message: return .init(type: .messageTab, label: self.title)
////        case .doc: return .init(type: .docsTab, label: self.title)
////        case .wiki: return .init(type: .wikiTab, label: self.title)
////        case .chatter: return .init(type: .chatterTab, label: self.title)
////        case .chat: return .init(type: .chatTab, label: self.title)
////        case .app: return .init(type: .appTab, label: self.title)
////        case .calendar: return .init(type: .calendarTab, label: self.title)
////        case .oncall: return .init(type: .helpdeskTab, label: self.title)
////        case .email: return .init(type: .emailTab, label: self.title)
////        case .pano(let label): return .init(type: .panoTab, label: label)
////        case .open(let v):
////            var tab = SearchMainTabService.Tab()
////            tab.type = .openSearchTab
////            tab.appID = v.id
////            if let icon = v.icon { tab.iconURL = icon }
////            tab.label = v.label
////            return tab
////        // TODO: oncall: tabs需要支持，否则对应的Tab是调不动的..
////        case .topic, .thread, .main:
////            return nil
////        }
////    }
//    static func defaultTypes() -> [SearchTab] {
//        var childTypes: [SearchTab] = [.main]
//
//        childTypes.append(.message)
//        childTypes.append(.doc)
//        childTypes.append(.wiki)
//        childTypes.append(.email)
//        childTypes.append(.app)
//        childTypes.append(.chatter)
//        childTypes.append(.chat)
//        childTypes.append(.calendar)
//        childTypes.append(.oncall)
//        return childTypes
//    }
//
//    /// 用于判断去重的关键字段
//    enum Identity: Hashable {
//        case main
//        case message, doc, wiki, chatter, chat, app, calendar
//        case oncall
//        case topic, thread
//        case email, pano
//        case open(id: String)
//    }
//    var id: Identity {
//        switch self {
//        case .main: return .main
//        case .message: return .message
//        case .doc: return .doc
//        case .wiki: return .wiki
//        case .chatter: return .chatter
//        case .chat: return .chat
//        case .app: return .app
//        case .calendar: return .calendar
//        case .oncall: return .oncall
//        case .topic: return .topic
//        case .thread: return .thread
//        case .email: return .email
//        case .pano: return .pano
//        case .open(let v): return .open(id: v.id)
//        }
//    }
//    var isOpenSearchCalendar: Bool {
//        if case .open(let openSearch) = self, openSearch.bizKey == .calendar {
//            return true
//        } else {
//            return false
//        }
//    }
//
//    var isOpenSearchEmail: Bool {
//        if case .open(let openSearch) = self, openSearch.bizKey == .email {
//            return true
//        } else {
//            return false
//        }
//    }
//
//    static func == (lhs: SearchTab, rhs: SearchTab) -> Bool { return lhs.id == rhs.id }
//    func hash(into hasher: inout Hasher) { id.hash(into: &hasher) }
//}

extension ServerPB_Usearch_SearchTab {
    struct Identity: Hashable {
        var type: ServerPB_Searches_SearchTabName
        var appID: String?
        var title: String
//        var platformCustomFilters: [ServerPB.ServerPB_Searches_PlatformSearchFilter.CustomFilterInfo]
    }
    var identity: Identity { Identity(type: type, appID: appID, title: label) }
    init(type: ServerPB_Searches_SearchTabName, label: String? = nil) {
        self = .init()
        self.type = type
        if let label = label {
            self.label = label
        }
    }
    var shortDescription: String {
        if type == .openSearchTab {
            return "<type: \(self.type.rawValue), id: \(self.appID)>"
        } else {
            return "<type: \(self.type.rawValue)>"
        }
    }
}
