//
//  MailSearchFilter.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
import ServerPB
import LarkModel
import UIKit
import LarkBizAvatar

enum MailFilterInfo {
    case fromSender
    case toSender
    case hasAttach(Bool)
    case subjectText([String])
    case notContain([String])
    case labels(MailFilterLabelCellModel?)
    case folders(MailFilterLabelCellModel?)

    var displayName: String {
        switch self {
        case .fromSender:
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_From
        case .toSender:
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_To
        case .hasAttach(_):
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Attachment
        case .subjectText(_):
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Subject
        case .notContain(_):
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Exclude
        case .labels(_):
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Label
        case .folders(_):
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Folder
        }
    }

    func reset() -> MailFilterInfo {
        switch self {
        case .fromSender, .toSender:
            return self
        case .hasAttach(_):
            return .hasAttach(false)
        case .subjectText(_):
            return .subjectText([])
        case .notContain(_):
            return .notContain([])
        case .labels(_):
            return .labels(nil)
        case .folders(_):
            return .folders(nil)
        }
    }

    var isEmpty: Bool {
        switch self {
        case .fromSender, .toSender:
            return false
        case .hasAttach(let hasAttach):
            return !hasAttach
        case .subjectText(let stringList):
            return stringList.isEmpty
        case .notContain(let stringList):
            return stringList.isEmpty
        case .labels(let label):
            return label == nil
        case .folders(let folder):
            return folder == nil
        }
    }
}

extension MailFilterInfo: Equatable {
     static func == (lhs: MailFilterInfo, rhs: MailFilterInfo) -> Bool {
        switch (lhs, rhs) {
        case (.fromSender, .fromSender):
            return true
        case (.toSender, .toSender):
            return true
        case (let .hasAttach(lhasAttach), let .hasAttach(rhasAttach)):
            return lhasAttach == rhasAttach
        case (let .subjectText(lsubjectText), let .subjectText(rlsubjectText)):
            return lsubjectText == rlsubjectText
        case (let .notContain(lnotContain), let .notContain(rnotContain)):
            return lnotContain == rnotContain
        case (let .labels(llabelID), let .labels(rlabelID)):
            return llabelID == rlabelID
        case (let .folders(lfolderID), let .folders(rfolderID)):
            return lfolderID == rfolderID
        default:
            return false
        }
    }
}

enum MailSearchFilter {
    static let avatarWidth: CGFloat = 16
    static let blueCircleWidth: CGFloat = 2
    struct FilterDate: Equatable {
        var startDate: Date?
        var endDate: Date?

        init(startDate: Date?, endDate: Date?) {
            self.startDate = startDate
            self.endDate = endDate
        }

        public static func == (lhs: FilterDate, rhs: FilterDate) -> Bool {
            var sameStart: Bool = false
            var sameEnd: Bool = false
            if let lhsStart = lhs.startDate, let rhsStart = rhs.startDate {
                sameStart = lhsStart.mail.compare(date: rhsStart) == .orderedSame
            } else if lhs.startDate == nil, rhs.startDate == nil {
                sameStart = true
            }
            if let lhsEnd = lhs.endDate, let rhsEnd = rhs.endDate {
                sameEnd = lhsEnd.mail.compare(date: rhsEnd) == .orderedSame
            } else if lhs.endDate == nil, rhs.endDate == nil {
                sameEnd = true
            }
            return sameStart && sameEnd
        }
    }

    /// 会话类型： 单聊、群聊
    enum DateSource: Equatable, CaseIterable {
        case message, doc, commonFilter
    }
    enum GeneralFilter {
         enum Option {
//            case searchable(ForwardItem)
            case predefined(SearchChatterPickerItem.GeneralFilterOption)
        }
        case multiple(MailFilterInfo, [Option])
        case single(MailFilterInfo, Option?)
        case date(MailFilterInfo, FilterDate?)
        case mailUser(MailFilterInfo, [LarkModel.PickerItem])
        case inputTextFilter(MailFilterInfo, [String])
    }
    // 通用筛选器
    case general(GeneralFilter)
    case date(date: FilterDate?, source: DateSource)

    static func supportFilters() -> [MailSearchFilter] {
        return [.general(.mailUser(.fromSender, [])),
                .general(.mailUser(.toSender, [])),
                .general(.inputTextFilter(.subjectText([]), [])),
                .general(.single(.folders(nil), nil)),
                .general(.single(.labels(nil), nil)),
                .date(date: nil, source: .commonFilter),
                .general(.inputTextFilter(.notContain([]), [])),
                .general(.single(.hasAttach(false), nil))
                ]
    }
}

extension MailSearchFilter {
    func sameType(with filter: MailSearchFilter) -> Bool {
        switch self {
        case .date: if case .date = filter { return true }
        case let .general(generalFilter):
            switch generalFilter {
            case let .multiple(lInfo, _):
                if case let .general(.multiple(rInfo, _)) = filter {
                    return lInfo.displayName == rInfo.displayName
                }
            case let .single(lInfo, _):
                if case let .general(.single(rInfo, _)) = filter {
                    return lInfo.displayName == rInfo.displayName
                }
            case let .date(lInfo, _):
                if case let .general(.date(rInfo, _)) = filter {
                    return lInfo.displayName == rInfo.displayName
                }
            case let .mailUser(lInfo, _):
                if case let .general(.mailUser(rInfo, _)) = filter {
                    return lInfo.displayName == rInfo.displayName
                }
            case let .inputTextFilter(lInfo, _):
                if case let .general(.inputTextFilter(rInfo, _)) = filter {
                    return lInfo.displayName == rInfo.displayName
                }
            }
        }
        return false
    }

    var isEmpty: Bool {
        switch self {
        case let .general(generalFilter): return generalFilter.isEmpty
        case .date(let date, _):
            return date == nil
        }
    }

    var title: String {
        switch self {
        case .general(let generalFilter):
            return generalFilter.title
        case .date(let date, let source):
            return dateTitle(date: date, source: source)
        }
    }

    func dateTitle(date: FilterDate?, source: DateSource) -> String {
        if let date = date {
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Date + getTimeRangeString(date: date)
        } else {
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Date
        }
    }

    var name: String {
        switch self {
        case .general(let generalFilter):
            return generalFilter.name
        case .date(let date, let source):
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Date
        }
    }

    var content: String {
        switch self {
        case .general(let generalFilter):
            return generalFilter.content
        case .date(let date, let source):
            return self.getDateStr(date)
        }
    }

    var needHightLight: Bool {
        switch self {
        case .general(let generalFilter):
            switch generalFilter {
            case let .inputTextFilter(info, _):
                if case let .subjectText(_) = info {
                    return true
                } else {
                    return false
                }
            default: return false
            }
        case .date(_, _):
            return false
        }
    }

    var tagID: String? {
        switch self {
        case .general(let generalFilter):
            switch generalFilter {
            case let .single(info, _):
                if case let .folders(folder) = info {
                    return folder?.labelId
                } else {
                    return nil
                }
            default: return nil
            }
        case .date(_, _):
            return nil
        }
    }

    var avatarInfos: [MailSearchFilterView.AvatarInfo] {
        switch self {
        case let .general(generalFilter):
            switch generalFilter {
            case let .date(info, _): return []
            case let .single(info, _): return []
            case let .multiple(info, _): return []
            case let .mailUser(info, pickers):
                var avatarInfos = [MailSearchFilterView.AvatarInfo]()
                for picker in pickers {
                    switch picker.meta {
                    case .chat(let chatMate):
                        let avatarInfo = MailSearchFilterView.AvatarInfo(avatarKey: chatMate.avatarKey ?? "", avatarID: chatMate.id)
                        avatarInfos.append(avatarInfo)
                    case .chatter(let chatterMate):
                        let avatarInfo = MailSearchFilterView.AvatarInfo(avatarKey: chatterMate.avatarKey ?? "", avatarID: chatterMate.id )
                        avatarInfos.append(avatarInfo)
                    case .mailUser(let mailUserMate):
                        if let mailAddress = mailUserMate.mailAddress, let imageURL = mailUserMate.imageURL {
                            let avatarInfo = MailSearchFilterView.AvatarInfo(avatarKey: "", avatarID: mailAddress)
                            avatarInfos.append(avatarInfo)
                        }
                    default: break
                    }
                }
                return avatarInfos
            case let .inputTextFilter(info, _): return []
            }
        case .date:
            return []
        }
    }

    static func specificFilterValueTitleLimit(_ title: String, limit: Int) -> String {
        var result = title
        if result.count > limit + 1 {
            result = result.substring(to: limit) + "..."
        }
        return result
    }

    func reset() -> MailSearchFilter {
        switch self {
        case .date(_, let source):
            return .date(date: nil, source: source)
        case .general(let generalFilter):
            switch generalFilter {
            case let .date(info, _): return .general(.date(info.reset(), nil))
            case let .single(info, _): return .general(.single(info.reset(), nil))
            case let .multiple(info, _): return .general(.multiple(info.reset(), []))
            case let .mailUser(info, _): return .general(.mailUser(info.reset(), []))
            case let .inputTextFilter(info, _): return .general(.inputTextFilter(info.reset(), []))
            }
        }
    }

    func getAvatarViews() -> [UIView]? {
        switch self {
        default:
            let avatarInfos = [self.avatarInfos.first].compactMap { $0 }
            if !avatarInfos.isEmpty {
                return avatarInfos
                    .map { return RoundAvatarView(avatarInfo: $0,
                                                  avatarWidth: MailSearchFilter.avatarWidth,
                                                  showBgColor: false)
                    }
            } else { return nil }
        }
    }

    func getAvatarViews(avatarWidth: CGFloat = MailSearchFilter.avatarWidth, blueCircleWidth: CGFloat = MailSearchFilter.blueCircleWidth) -> [UIView]? {
        switch self {
        case .general(.mailUser(let info, let pickers)):
            if let picker = pickers.first {
                //switch info { //  picker.meta
//                case .fromSender, .toSender:
                switch picker.meta {
                case .chat(let chatMate):
                    let avatarInfo = MailSearchFilterView.AvatarInfo(avatarKey: chatMate.avatarKey ?? "", avatarID: chatMate.id )
                    return [RoundAvatarView(avatarInfo: avatarInfo,
                                                  avatarWidth: avatarWidth,
                                                  showBgColor: false,
                                                  blueCircleWidth: blueCircleWidth)]
                case .chatter(let chatterMate):
                    let avatarInfo = MailSearchFilterView.AvatarInfo(avatarKey: chatterMate.avatarKey ?? "", avatarID: chatterMate.id )
                    return [RoundAvatarView(avatarInfo: avatarInfo,
                                                  avatarWidth: avatarWidth,
                                                  showBgColor: false,
                                                  blueCircleWidth: blueCircleWidth)]
                case .mailUser(let mailUserMate):
                    if let mailAddress = mailUserMate.mailAddress, let imageURL = mailUserMate.imageURL {
                        let placeholderImage: UIImage? = MailSearchFilterImageUtils.generateAvatarImage(withNameString: mailAddress, length: 2)
                        return [RoundAvatarView(avatarImageURL: imageURL,
                                                avatarWidth: avatarWidth,
                                                showBgColor: false,
                                                blueCircleWidth: blueCircleWidth,
                                                placeholderImage: placeholderImage)]
                    } else {
                        return nil
                    }

                default: return nil
                }
            } else {
                return nil
            }
        default:
            let avatarInfos = [self.avatarInfos.first].compactMap { $0 }
            if !avatarInfos.isEmpty {
                return avatarInfos
                    .map { return RoundAvatarView(avatarInfo: $0,
                                                  avatarWidth: avatarWidth,
                                                  showBgColor: false,
                                                  blueCircleWidth: blueCircleWidth)
                    }
            } else { return nil }
        }
    }

    private func getDateStr(_ date: FilterDate?) -> String {
        if let date = date {
            return getTimeRangeString(date: date)
        } else {
            return BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Date
        }
    }
}

//extension SearchFilter.CommonFilter: Equatable {
//     static func == (lhs: SearchFilter.CommonFilter, rhs: SearchFilter.CommonFilter) -> Bool {
//        switch (lhs, rhs) {
////        case (let .mainFrom(lhsFromIds, _, lhsFromType, _), let .mainFrom(rhsFromIds, _, rhsFromType, _)):
////            return lhsFromIds == rhsFromIds && lhsFromType == rhsFromType
////        case (let .mainWith(lhsWithIds), let .mainWith(rhsWithIds)):
////            return lhsWithIds == rhsWithIds
////        case (let .mainIn(lhsInIds), let .mainIn(rsInIds)):
////            return lhsInIds == rsInIds
//        case (.mainDate(let lhsDate), .mainDate(let rhsDate)):
//            if let lhsDate = lhsDate, let rhsDate = rhsDate {
//                if let lhsStartDate = lhsDate.startDate, let rhsStartDate = rhsDate.startDate {
//                    if lhsStartDate.mail.compare(date: rhsStartDate) == .orderedSame,
//                        lhsDate.endDate.mail.compare(date: rhsDate.endDate) == .orderedSame {
//                        return true
//                    } else {
//                        return false
//                    }
//                } else if lhsDate.startDate == nil, rhsDate.startDate == nil {
//                    return lhsDate.endDate.mail.compare(date: rhsDate.endDate) == .orderedSame
//                } else {
//                    return false
//                }
//            } else if lhsDate == nil, rhsDate == nil {
//                return true
//            } else {
//                return false
//            }
//        default:
//            return false
//        }
//    }
//}
 extension MailSearchFilter.GeneralFilter.Option {
    var id: String {
        switch self {
        case let .predefined(info): return info.id
//        case let .searchable(item): return item.id
        }
    }
    var name: String {
        switch self {
        case let .predefined(info): return info.name
//        case let .searchable(item): return item.name
        }
    }
}

 extension MailSearchFilter.GeneralFilter {
    var info: MailFilterInfo {
        switch self {
        case let .date(info, _): return info
        case let .multiple(info, _): return info
        case let .single(info, _): return info
        case let .mailUser(info, _): return info
        case let .inputTextFilter(info, _): return info
        }
    }
    var isEmpty: Bool {
        switch self {
        case let .date(_, date): return date == nil
        case let .single(info, value): return info.isEmpty
        case let .multiple(_, values): return values.isEmpty
        case let .mailUser(_, values): return values.isEmpty
        case let .inputTextFilter(_, values): return values.filter { !$0.isEmpty }.isEmpty
        }
    }
    var avatarKeys: [String] {
        switch self {
//        case let .user(_, ids): return ids.map { $0.avatarKey }
//        case let .userChat(_, pickers): return pickers.map { $0.avatarKey }
        default: return []
        }
    }

    var avatarInfos: [MailSearchFilterView.AvatarInfo] {
        switch self {
//        case let .user(_, ids): return ids.map { MailSearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.chatterID) }
//        case let .userChat(_, pickers): return pickers.map { MailSearchFilterView.AvatarInfo(avatarKey: $0.avatarKey, avatarID: $0.id) }
        case let .mailUser(_, pickers): return pickers.compactMap {
            switch $0.meta {
            case .chat(let chatMate):
                return MailSearchFilterView.AvatarInfo(avatarKey: chatMate.avatarKey ?? "", avatarID: chatMate.id )
            case .chatter(let chatterMate):
                return MailSearchFilterView.AvatarInfo(avatarKey: chatterMate.avatarKey ?? "", avatarID: chatterMate.id )
            // 仅用作计数
            case .mailUser(let mailUserMate):
                return MailSearchFilterView.AvatarInfo(avatarKey: "", avatarID: mailUserMate.id )
            default: return nil
            }
        }
        default: return []
        }
    }

    var name: String {
        switch self {
        case .date(_, _):
            if !info.displayName.isEmpty {
                return info.displayName
            }
            return ""
        default: return info.displayName
        }
    }

    var content: String {
        switch self {
        case let .date(_, date):
            if let date = date {
                return getTimeRangeString(date: date)
            } else {
                return ""
            }
        case let .multiple(_, options):
            if options.isEmpty {
                return ""
            } else {
                return options.map({ $0.name }).joined(separator: "、")
            }
        case let .single(info, option):
            switch info {
            case .labels(let label):
                return label?.text ?? ""
            case .folders(let folder):
                return folder?.text ?? ""
            default:
                break
            }
            guard let option = option else {
                return ""
            }
            return option.name
        case let .mailUser(_, pickers):
            if pickers.isEmpty {
                return ""
            } else {
                switch pickers[0].meta {
                case .chatter(let chatterMeta):
                    return chatterMeta.localizedRealName ?? ""
                case .chat(let chatMeta):
                    return chatMeta.name ?? ""
                case .mailUser(let mailUserMeta):
                    return mailUserMeta.mailAddress ?? ""
                default:
                    return ""
                }
            }
        case let .inputTextFilter(_, texts):
            if let text = texts.first {
                return text
            } else {
                return ""
            }
        }
    }

    var title: String {
        switch self {
        case let .date(_, date):
            var title = !info.displayName.isEmpty ? info.displayName : BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Date
            if let _date = date {
                title += getTimeRangeString(date: _date)
            }
            return title
        case let .multiple(_, options):
            if options.isEmpty {
                return info.displayName
            } else if options.count == 1 {
                return options.first?.name ?? (info.displayName + " \(options.count)")
            } else {
                return info.displayName + " \(options.count)"
            }
        case let .single(info, option):
            guard let option = option else {
                switch info {
                case .labels(let label):
                    if let labelName = label?.text {
                        return BundleI18n.MailSDK.Mail_Manage_ManageLabelMobile + " " + labelName
                    } else {
                        return info.displayName
                    }
                case .folders(let folder):
                    if let folderName = folder?.text {
                        return BundleI18n.MailSDK.Mail_Folder_FolderTab + " " + folderName
                    } else {
                        return info.displayName
                    }
                case .hasAttach(let hasAttach):
                    if hasAttach {
                        return BundleI18n.MailSDK.Mail_shared_FilterSearch_ContainsAttachments_Radio
                    } else {
                        return info.displayName
                    }
                default:
                    return info.displayName
                }
            }
            return option.name
        case let .inputTextFilter(info, texts):
            if texts.isEmpty {
                return info.displayName
            } else {
                let countStr: String = texts.count > 1 ? "+\(texts.count - 1)" : ""
                let textStr = MailSearchFilter.specificFilterValueTitleLimit((texts.first ?? ""), limit: 10)
                return info.displayName + " " + textStr + countStr
            }
        default: return info.displayName
        }
    }

    var canReplaceByCommonUserFilter: Bool {
//        if case let .user(customFilterInfo, _) = self {
//            return customFilterInfo.hasAssociatedSmartFilter && customFilterInfo.associatedSmartFilter == .smartUser
//        }
        return false
    }

    var canReplaceByCommonDate: Bool {
//        if case let .date(customFilterInfo, _) = self {
//            return customFilterInfo.hasAssociatedSmartFilter && customFilterInfo.associatedSmartFilter == .smartTime
//        }
        return false
    }
}

// extension SearchFilter.CommonFilter {
//    var isEmpty: Bool {
//        switch self {
////        case let .mainFrom(fromIds, _, _, _):
////            return fromIds.isEmpty
////        case let .mainWith(withIds):
////            return withIds.isEmpty
////        case let .mainIn(inIds):
////            return inIds.isEmpty
//        case .mainDate(let date):
//            return date == nil
//        }
//    }
//}

extension MailSearchFilter.GeneralFilter.Option: Equatable {
     static func == (lhs: MailSearchFilter.GeneralFilter.Option, rhs: MailSearchFilter.GeneralFilter.Option) -> Bool {
        switch (lhs, rhs) {
//        case (.searchable(let lhs), .searchable(let rhs)):
//            return lhs == rhs
        case (.predefined(let lhs), .predefined(let rhs)):
            return lhs.id == rhs.id && lhs.name == rhs.name
        default:
            return false
        }
    }
}

extension MailSearchFilter.GeneralFilter: Equatable {
     static func == (lhs: MailSearchFilter.GeneralFilter, rhs: MailSearchFilter.GeneralFilter) -> Bool {
        switch (lhs, rhs) {
        case (.multiple(let lhsInfo, let lhsOptions), .multiple(let rhsInfo, let rhsOptions)):
            return lhsInfo == rhsInfo && lhsOptions == rhsOptions
        case (.single(let lhsInfo, let lhsOption), .single(let rhsInfo, let rhsOption)):
            return lhsInfo == rhsInfo && lhsOption == rhsOption
//        case (.user(let lhsInfo, let lhsItems), .user(let rhsInfo, let rhsItems)):
//            return lhsInfo == rhsInfo && lhsItems == rhsItems
        case (.date(let lhsInfo, let lhsDate), .date(let rhsInfo, let rhsDate)):
            guard lhsInfo == rhsInfo else { return false }
            if let lhsDate = lhsDate, let rhsDate = rhsDate {
                return lhsDate == rhsDate
            } else if lhsDate == nil, rhsDate == nil {
                return true
            } else {
                return false
            }
            //lijinru attention 注意
        case (.mailUser(let lhsInfo, let lhsPickers), .mailUser(let rhsInfo, let rhsPickers)):
            guard lhsInfo == rhsInfo, lhsPickers.count == rhsPickers.count else { return false }
            for lhsPicker in lhsPickers {
                if !rhsPickers.contains(where: { picker in
                    picker.id.elementsEqual(lhsPicker.id)
                }) {
                    return false
                }
            }
            return true
            //lijinru attention 注意
        case (.inputTextFilter(let lhsInfo, let lhsTexts), .inputTextFilter(let rhsInfo, let rhsTexts)):
            guard lhsInfo == rhsInfo, lhsTexts.count == rhsTexts.count else { return false }
            for lhsText in lhsTexts {
                if !rhsTexts.contains(where: { rhsText in
                    rhsText.elementsEqual(lhsText)
                }) {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}

extension MailSearchFilter: Equatable {
     static func == (lhs: MailSearchFilter, rhs: MailSearchFilter) -> Bool {
        switch (lhs, rhs) {
//        case (let .commonFilter(lhsCommonFilter), let .commonFilter(rhsCommonFilter)):
//            return lhsCommonFilter == rhsCommonFilter
//        case (let .specificFilterValue(lhsFilter, _, lhsIsSelected), let .specificFilterValue(rhsFilter, _, rhsIsSelected)):
//            return lhsFilter == rhsFilter
//        case (let .chat(lmode, lhsItems), let .chat(rmode, rhsItems)):
//            return lhsItems == rhsItems && lmode == rmode
        case (.date(let lhsDate, _), .date(let rhsDate, _)):
            if let lhsDate = lhsDate, let rhsDate = rhsDate {
                return lhsDate == rhsDate
            } else if lhsDate == nil, rhsDate == nil {
                return true
            } else {
                return false
            }
//        case (let .chatMemeber(lmode, lhsItems), let .chatMemeber(rmode, rhsItems)):
//            return lhsItems == rhsItems && lmode == rmode
//        case (.chatKeyWord(let lhsKeyWord), .chatKeyWord(let rhsKeyWord)):
//            return lhsKeyWord == rhsKeyWord
//        case (.messageType(let lhsType), .messageType(let rhsType)):
//            return lhsType == rhsType
//        case (.messageAttachmentType(let lhsType), .messageAttachmentType(let rhsType)):
//            return lhsType == rhsType
//        case (.messageMatch(let lhs), .messageMatch(let rhs)):
//            return lhs == rhs
//        case (.groupSortType(let lhs), .groupSortType(let rhs)):
//            return lhs == rhs
        case (.general(let lhs), .general(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

// struct Chatter {
//     let id: String
//     let avatarKey: String
//     let displayName: String
//     let descriptionText: String
//
//     init(
//        id: String,
//        avatarKey: String,
//        displayName: String,
//        descriptionText: String
//    ) {
//        self.id = id
//        self.avatarKey = avatarKey
//        self.displayName = displayName
//        self.descriptionText = descriptionText
//    }
//}

 enum SearchChatterPickerItem: Equatable {
     struct GeneralFilterOption {
         var name: String, id: String
         init(name: String, id: String) {
            self.name = name
            self.id = id
        }
    }
    case chatter(Chatter)
//    case searchResult(IntegrationSearchResult)
//    case chatterMeta(ChatterMeta)
//    case bot(SelectBotInfo)
//    case searchResultType(SearchResultType)

     var chatterID: String {
        switch self {
        case .chatter(let chatter):
            return chatter.id
//        case .searchResult(let searchResult):
//            return searchResult.searchResult.id
//        case .chatterMeta(let chatterMeta):
//            return chatterMeta.id
//        case .bot(let bot):
//            return bot.id
//        case .searchResultType(let result):
//            return result.id
        }
    }

     var name: String {
        switch self {
        case .chatter(let chatter):
            return chatter.name // "chatter.name"
//        case .searchResult(let searchResult):
//            return searchResult.searchResult.title
//        case .chatterMeta(let chatterMeta):
//            return chatterMeta.name
//        case .bot(let bot):
//            return bot.name
//        case .searchResultType(let result):
//            return result.title.string
        }
    }

     static func == (lhs: SearchChatterPickerItem, rhs: SearchChatterPickerItem) -> Bool {
        return lhs.chatterID == rhs.chatterID
    }

     var avatarKey: String {
        switch self {
        case .chatter(let chatter):
            return chatter.avatarKey
//        case .searchResult(let result):
//            return result.searchResult.avatarKey
//        case .chatterMeta(let chatterMeta):
//            return chatterMeta.avatarKey
//        case .bot(let bot):
//            return bot.avatarKey
//        case .searchResultType(let result):
//            return result.avatarKey
        }
    }
}


func getTimeRangeString(date: MailSearchFilter.FilterDate) -> String {
    let startYear = date.startDate?.year ?? Date().year
    let endYear = date.endDate?.year ?? Date().year
    let showYear: Bool = !(startYear == endYear && startYear == Date().year)

    let dateFormatter: (Date) -> String = { date in
        if !showYear {
            return "\(date.month)/\(date.day)"
        } else {
            return "\(date.year)/\(date.month)/\(date.day)"
        }
    }
    let startDateString = date.startDate.flatMap { dateFormatter($0) } ?? BundleI18n.MailSDK.Mail_shared_FilterSearch_AnyTime_Mobile_Text
    let endDateString = date.endDate.flatMap { dateFormatter($0) } ?? BundleI18n.MailSDK.Mail_shared_FilterSearch_AnyTime_Mobile_Text
    return " \(startDateString)-\(endDateString)"
}

extension MailSearchFilter {
    enum DisplayType {
        case unknown, text, avatars, textAvatar
    }
    var displayType: DisplayType {
        switch self {
        case .general(.mailUser):
            return .avatars
        case .general(.date), .general(.inputTextFilter), .general(.single), .general(.multiple), .date:
            return .text
        @unknown default:
            assertionFailure("unimplemented code!!")
            return .unknown
        }
    }
    var isAvatarsType: Bool { displayType == .avatars }
    var isTextType: Bool { displayType == .text }
    var isTextAvatarType: Bool { displayType == .textAvatar }
}
