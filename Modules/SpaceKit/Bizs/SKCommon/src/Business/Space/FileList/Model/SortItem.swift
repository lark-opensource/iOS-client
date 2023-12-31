//
//  SortItem.swift
//  SpaceKit
//
//  Created by Ryan on 2019/2/19.
//

import SKFoundation
import SKResource

public final class LayoutManager {
    public static let isGridKey = "com.bytedance.ee.docs.is_grid_layout"
    public static let layoutChangeNotification = Notification.Name("layout_change_notification")

    public static let shared = LayoutManager()
    public var isGrid = false {
        didSet {
            if oldValue != isGrid {
                CCMKeyValue.globalUserDefault.set(isGrid, forKey: LayoutManager.isGridKey)
                NotificationCenter.default.post(name: LayoutManager.layoutChangeNotification, object: nil)
            }
        }
    }
    private init() {
        isGrid = CCMKeyValue.globalUserDefault.bool(forKey: LayoutManager.isGridKey)
    }
}

public struct SortItem: Codable, Equatable {

    enum EncodedKeys: String, CodingKey {
        case isSelected, isUp, sortType, lastLabel
    }
    public enum SortType: String {
        case updateTime = "0"
        case createTime = "3"
        case owner = "4"
        case title = "5"
        case latestOpenTime = "6"
        case latestModifiedTime = "7"
        case allTime = "8" // activityTime
        case shareTime = "9"
        case letestCreated = "-3" /// 作为参数给server端的时候，需要转换成，createTime
        case latestAddManuOffline = "10"
        /// 收藏事件，不应该作为参数出现在后端接口上
        case addFavoriteTime = "-1"

        public var reportName: String { // sort_action 参数的取值
            switch self {
            case .createTime:
                return "Created_time"
            case .owner:
                return "Owner"
            case .title:
                return "Name"
            case .updateTime:
                return "Modified_time"
            case .latestOpenTime:
                return "Latest_open_time" // 建议
            case .latestModifiedTime:
                return "Latest_modified_time" // 建议
            case .allTime:
                return "All_time" // 建议
            case .shareTime:
                return "Shared_time"
            case .letestCreated:
                return "Letest_created" // 建议
            case .latestAddManuOffline:
                return "default" // 产品定的
            case .addFavoriteTime:
                return "star_time"
            }
        }
    }
//    enum ActionType {
//        case sort
//        case filter
//    }

    public init(isSelected: Bool, isUp: Bool, sortType: SortType) {
        self.isSelected = isSelected
        self.isUp = isUp
        self.sortType = sortType
    }
    public var needShowUpArrow = true
    public var isSelected = false
    public var isUp = false // isUp标识升序
    public var lastLabel = ""
    public let sortType: SortType

    public var displayNameV2: String {
        switch sortType {
        case .createTime:
            return BundleI18n.SKResource.Doc_List_SortByCreationTime  // Doc_List_Filter_Recent_Created
        case .owner:
            return BundleI18n.SKResource.Doc_List_SortByOwner
        case .title:
            return BundleI18n.SKResource.Doc_List_SortByTitle
        case .updateTime:
            return BundleI18n.SKResource.Doc_List_SortByUpdateTime
        case .latestOpenTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_ViewedTime_Option
        case .latestModifiedTime:
            return BundleI18n.SKResource.Doc_List_SortByUpdateTime
        case .allTime:
            return BundleI18n.SKResource.Doc_List_Filter_All  // 没有定义，就用已有的
        case .shareTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_SharedTime_Menu
        case .letestCreated:
            return BundleI18n.SKResource.Doc_List_SortByCreationTime
        case .latestAddManuOffline:
            return BundleI18n.SKResource.LarkCCM_NewCM_SavedTime_Option
        case .addFavoriteTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_StarredTime_Menu
        }
    }

    public var sortDetailDescription: String {
        isUp ? ascendingDescription : descendingDescription
    }

    public var descendingDescription: String {
        switch sortType {
        case .createTime, .updateTime, .latestOpenTime, .latestModifiedTime, .allTime, .shareTime, .letestCreated, .latestAddManuOffline, .addFavoriteTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_LatestToEarliest_Option
        case .title, .owner:
            return BundleI18n.SKResource.LarkCCM_NewCM_FromZToA_Option
        }
    }

    public var ascendingDescription: String {
        switch sortType {
        case .createTime, .updateTime, .latestOpenTime, .latestModifiedTime, .allTime, .shareTime, .letestCreated, .latestAddManuOffline, .addFavoriteTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_EarliestToLatest_Option
        case .title, .owner:
            return BundleI18n.SKResource.LarkCCM_NewCM_FromAToZ_Option
        }
    }

    public var fullDescription: String {
        switch sortType {
        case .updateTime:
            return BundleI18n.SKResource.CreationMobile_ECM_ManageGroup_SortBy_Option_LastUpdated
        case .createTime:
            return BundleI18n.SKResource.CreationMobile_ECM_ManageGroup_SortBy_Option_Created
        case .owner:
            return BundleI18n.SKResource.Doc_List_SortByOwner
        case .title:
            return BundleI18n.SKResource.CreationMobile_ECM_ManageGroup_SortBy_Option_Name
        case .latestOpenTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_Mobile_SortByVisitedTime_Option
        case .latestModifiedTime:
            return BundleI18n.SKResource.CreationMobile_ECM_ManageGroup_SortBy_Option_LastUpdated
        case .allTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_Mobile_SortByVisitedTime_Option
        case .shareTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_Mobile_SortBySharedTime_Option
        case .letestCreated:
            return BundleI18n.SKResource.CreationMobile_ECM_ManageGroup_SortBy_Option_Created
        case .latestAddManuOffline:
            return BundleI18n.SKResource.CreationMobile_ECM_ManageGroup_SortBy_Option_Added
        case .addFavoriteTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_Mobile_SortByStarredTime_Option
        }
    }

    public var reportName: String { // sort_action 参数的取值
        return sortType.reportName
    }

    public var reportNameV2: String {
        switch sortType {
        case .createTime:
            return "last_created"
        case .owner:
            return isUp ? "owner_up" : "owner_down"
        case .title:
            return isUp ? "name_up" : "name_down"
        case .updateTime:
            return isUp ? "time_created_up" : "time_created_down"
        case .latestOpenTime:
            return "last_opened"
        case .latestModifiedTime:
            return isUp ? "time_modified_up" : "time_modified_down"
        case .allTime:
            return "all"
        case .shareTime:
            return isUp ? "time_shared_up" : "time_shared_down"
        case .letestCreated:
            return  isUp ? "time_created_up" : "time_created_down"
        case .latestAddManuOffline:
            return ""
        case .addFavoriteTime:
            return "star_time"
        }
    }

    public var typeName: String {
        return BundleI18n.SKResource.Doc_List_SortBy
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: EncodedKeys.self)
        isSelected = try values.decode(Bool.self, forKey: .isSelected)
        isUp = try values.decode(Bool.self, forKey: .isUp)
        let typeRaw = try values.decode(String.self, forKey: .sortType)
        sortType = SortType(rawValue: typeRaw) ?? .title
        lastLabel = try values.decode(String.self, forKey: .lastLabel)
    }

    public func encode(to encoder: Encoder) throws {
        do {
            var container = encoder.container(keyedBy: EncodedKeys.self)
            try container.encode(isSelected, forKey: .isSelected)
            try container.encode(isUp, forKey: .isUp)
            try container.encode(sortType.rawValue, forKey: .sortType)
            try container.encode(lastLabel, forKey: .lastLabel)
        } catch {
            DocsLogger.error("error in encode sort item", extraInfo: nil, error: error, component: nil)
        }
    }
}
