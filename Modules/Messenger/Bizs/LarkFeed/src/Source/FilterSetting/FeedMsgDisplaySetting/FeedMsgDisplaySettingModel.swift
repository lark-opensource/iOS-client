//
//  FeedMsgDisplaySettingModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/20.
//
import Foundation
import RustPB
import LarkContainer

enum FeedMsgDisplayItemType: String {
    case showAll             // 始终展示
    case showNew             // 有新消息时展示
    case showAllNew          // 全部新消息
    case showAtMeMentions    // @我的新消息
    case showAtAllMentions   // @所有人的新消息
    case showStarredContacts // 星标联系人的新消息
    case showNone            // 始终不展示
}

protocol FeedMsgDisplayCellItem {
    /// 重用标识符
    var cellIdentifier: String { get }
    var title: String { get }
    var type: FeedMsgDisplayItemType { get }
    var isSelected: Bool { get set }
    var isLastRow: Bool { get set }
    var editEnable: Bool { get set }
    var isCheckBox: Bool { get }
}

struct FeedMsgDisplayCellViewModel: FeedMsgDisplayCellItem {
    let cellIdentifier: String
    let title: String
    let type: FeedMsgDisplayItemType
    var isSelected: Bool
    var isLastRow: Bool
    var editEnable: Bool
    let isCheckBox: Bool

    init(userResolver: UserResolver,
         type: FeedMsgDisplayItemType,
         isSelected: Bool = false,
         isLastRow: Bool = false,
         editEnable: Bool = true,
         isCheckBox: Bool = false) {
        self.type = type
        self.isSelected = isSelected
        self.isLastRow = isLastRow
        self.editEnable = editEnable
        self.isCheckBox = isCheckBox
        var title = FeedMsgDisplayCellViewModel.optionTitleMap[type] ?? ""
        if Feed.Feature(userResolver).groupSettingOptEnable {
            if type == .showNew {
                title = BundleI18n.LarkFeed.Lark_IM_OnlyShowImportantMsg_Text
            } else if type == .showAllNew {
                title = BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessages_Option
            }
        }
        self.title = title
        self.cellIdentifier = isCheckBox ? "FeedMsgDisplayCheckBoxCell" : "FeedMsgDisplayCell"
    }

    static let optionTitleMap: [FeedMsgDisplayItemType: String] = [
        .showAll: BundleI18n.LarkFeed.Lark_FeedFilter_ShowAllMessages_Option,
        .showNew: BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessages_Option,
        .showAllNew: BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessages_AllNew_Option,
        .showAtMeMentions: BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessages_AtMeMentions_Option,
        .showAtAllMentions: BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessages_AtAllMentions_Option,
        .showStarredContacts: BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessages_StarredContacts_Option,
        .showNone: BundleI18n.LarkFeed.Lark_FeedFilter_ShowNothing_Option]
}

protocol FeedMsgDisplayFilterItem {
    var subTitle: String { get }
    var selectedTypes: [FeedMsgDisplayItemType] { get set }
    var filterType: Feed_V1_FeedFilter.TypeEnum { get }
    var editEnable: Bool { get }
    var itemId: Int64? { get }
    var itemTitle: String? { get }
}

struct FeedMsgDisplayFilterModel: FeedMsgDisplayFilterItem {
    let userResolver: UserResolver
    var subTitle: String = ""
    var selectedTypes: [FeedMsgDisplayItemType] {
        didSet {
            updateSubTitle()
        }
    }
    let filterType: Feed_V1_FeedFilter.TypeEnum
    var editEnable: Bool {
        !selectedTypes.isEmpty
    }
    let itemId: Int64?
    let itemTitle: String?

    init(userResolver: UserResolver,
         selectedTypes: [FeedMsgDisplayItemType],
         filterType: Feed_V1_FeedFilter.TypeEnum,
         itemId: Int64? = nil,
         itemTitle: String? = nil) {
        self.userResolver = userResolver
        self.selectedTypes = selectedTypes
        self.filterType = filterType
        self.itemId = itemId
        self.itemTitle = itemTitle
        updateSubTitle()
    }

    // FG内: 一级分组副标题展示为"在消息分组中: xxx", 二级分组副标题展示为"xxx"
    // FG外: 一级分组和二级分组都展示旧文案"在消息分组中: xxx"
    mutating func updateSubTitle() {
        if selectedTypes.contains(.showAll) {
            subTitle = applySimplifiedDes() ?
                       BundleI18n.LarkFeed.Lark_FeedFilter_ShowAllMessages_Option :
                       BundleI18n.LarkFeed.Lark_FeedFilter_ShowAllMessagesInFilter_Text
        } else if selectedTypes.contains(.showNone) {
            subTitle = applySimplifiedDes() ?
                       BundleI18n.LarkFeed.Lark_FeedFilter_ShowNothing_Option :
                       BundleI18n.LarkFeed.Lark_FeedFilter_ShowNothingInFilter_Text
        } else if selectedTypes.contains(.showAllNew) {
            subTitle = applySimplifiedDes() ?
                       BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessages_Option :
                       BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowNewMessagesInFilter_Text
        } else if selectedTypes.contains(.showAtMeMentions) ||
                  selectedTypes.contains(.showAtAllMentions) ||
                  selectedTypes.contains(.showStarredContacts) {
            var titleArray: [String] = []
            if selectedTypes.contains(.showAtMeMentions) {
                titleArray.append(BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_OnlyShowVariable_Me_Text)
            }
            if selectedTypes.contains(.showAtAllMentions) {
                titleArray.append(BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_OnlyShowVariable_All_Text)
            }
            if selectedTypes.contains(.showStarredContacts) {
                titleArray.append(BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_OnlyShowVariable_Starred_Text)
            }
            let title = titleArray.joined(separator: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_OnlyShowTemplateComma_Text)
            subTitle = applySimplifiedDes() ?
                       BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_OnlyShowTemplate_Text(title) :
                       BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_InChatsOnlyShowTemplate_Text(title)
            if !Feed.Feature(userResolver).groupSettingOptEnable {
                subTitle = BundleI18n.LarkFeed.Lark_FeedFilter_OnlyShowSelectedNewMessagesInFilter_Text
            }
        } else {
            subTitle = ""
        }
    }

    func applySimplifiedDes() -> Bool {
        if Feed.Feature(userResolver).groupSettingOptEnable, filterType == .tag {
            return true
        }
        return false
    }

    static func defaultItem(userResolver: UserResolver, type: Feed_V1_FeedFilter.TypeEnum) -> FeedMsgDisplayFilterModel {
        return FeedMsgDisplayFilterModel(userResolver: userResolver, selectedTypes: [.showAll], filterType: type)
    }
}
