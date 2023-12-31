//
//  AppRankModel.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/18.
//

import Foundation
import SwiftyJSON
import LKCommonsLogging
import LarkWorkplaceModel

final class WorkPlaceRankPageViewModel: Codable {
    static let logger = Logger.log(WorkPlaceRankPageViewModel.self)

    /// 推荐应用列表（id）
    var recommendItemList: [String]?
    /// 用户可删除的推荐item（id）
    var distributedRecommendItemList: [String]?
    /// 常用 block 列表（id）
    var commonWidgetItemList: [String]?
    /// 常用 icon 应用列表（id）
    var commonIconItemList: [String]?
    /// 应用详情列表
    var allItemInfos: [String: RankItem]?
    /// 将应用list有序组合，用于rankPage
    lazy var orderedItemLists: [[String]] = {
        var lists: [[String]] = []
        lists.append(self.recommendItemList ?? [])
        lists.append(self.distributedRecommendItemList ?? [])
        lists.append(self.commonWidgetItemList ?? [])
        lists.append(self.commonIconItemList ?? [])
        return lists
    }()
    /// 将重排序后的数据同步到list（按照组合时的顺序）
    func reorderLists() {
        self.recommendItemList = self.orderedItemLists[recommendSection]
        self.distributedRecommendItemList = self.orderedItemLists[distributedRecommendSection]
        self.commonWidgetItemList = self.orderedItemLists[commonWidgetSection]
        self.commonIconItemList = self.orderedItemLists[commonIconSection]
    }
    /// 判断model是否为空
    func isEmptyModel() -> Bool {
        let recommendEmpty: Bool = recommendItemList?.isEmpty ?? true
        let distributedRecommendEmpty: Bool = distributedRecommendItemList?.isEmpty ?? true
        let commonWidgetEmpty: Bool = commonWidgetItemList?.isEmpty ?? true
        let commonIconEmpty: Bool = commonIconItemList?.isEmpty ?? true
        /// 三个列表均为空时，则认为model是空的
        return recommendEmpty && distributedRecommendEmpty && commonWidgetEmpty && commonIconEmpty
    }
    /// 判断排序后的model是否为空
    func isEmptyForReorderLists() -> Bool {
        let recommendItemList = self.orderedItemLists[recommendSection]
        let distributedRecommendItemList = self.orderedItemLists[distributedRecommendSection]
        let commonWidgetItemList = self.orderedItemLists[commonWidgetSection]
        let commonIconItemList = self.orderedItemLists[commonIconSection]
        let recommendEmpty: Bool = recommendItemList.isEmpty
        let commonWidgetEmpty: Bool = commonWidgetItemList.isEmpty
        let commonIconEmpty: Bool = commonIconItemList.isEmpty
        let distribuitedRecEmpty: Bool = distributedRecommendItemList.isEmpty
        /// 三个列表均为空时，则认为model是空的
        return recommendEmpty && distribuitedRecEmpty && commonWidgetEmpty && commonIconEmpty
    }
    /// 获取备份
    func getCopy() -> WorkPlaceRankPageViewModel {
        let copy = WorkPlaceRankPageViewModel()
        copy.recommendItemList = self.recommendItemList
        copy.distributedRecommendItemList = self.distributedRecommendItemList
        copy.commonWidgetItemList = self.commonWidgetItemList
        copy.commonIconItemList = self.commonIconItemList
        return copy
    }
}

/// 单个app的数据结构（和后端保持一致，json转model失败，则说明后端数据缺失）
struct RankItem: Codable {
    /// itemID
    let itemId: String
    /// 图标 icon key
    let iconKey: String
    /// item描述信息
    let desc: String?
    /// //1=应用；2=租户自定义，3=个人自定义（书签），4=原生导航栏应用
    let itemType: WPAppItem.AppType
    /// 名称
    let name: String
    /// appID
    let appId: String?
    /// block 信息
    let block: WPBlockInfo?
    /// botID
    let botId: String?
    /// 原生应用key
    let nativeAppKey: String?
    /// URL信息
    var url: WPAppItem.OpenURL?
    /// 链接信息
    let linkUrl: String?
    /// 是否是组织共享的应用
    let isSharedByOtherOrganization: Bool?
    /// 组织共享应用的分享者的 租户信息
    let sharedSourceTenantInfo: WPTenantInfo?
    /// 是否是纯bot
    func isPureBot() -> Bool {
        return (url?.isAllURLEmpty() ?? true) && !(botId?.isEmpty ?? true)
    }
}

/// 更新排序结果的数据机构
struct UpdateRankResult: Codable {
    /// 更新后的常用widget列表（id）
    var newCommonWidgetItemList: [String]
    /// 更新前常用widget列表（id）
    var originCommonWidgetItemList: [String]
    /// 更新后常用icon应用列表（id）
    var newCommonIconItemList: [String]
    /// 更新前常用icon应用列表（id）
    var originCommonIconItemList: [String]
    /// 更新后常用可编辑推荐应用
    var newDistributedRecommendItemList: [String]
    /// 更新前常用可编辑推荐应用
    var originDistributedRecommendItemList: [String]
}

// MARK: 排序页面的tableView相关data
extension WorkPlaceRankPageViewModel {
    /// 获取指定位置的itemInfo,用于排序页tableView
    /// - Parameters:
    ///   - section: item分组
    ///   - index: item在分组中的index
    func getItemInfo(in section: Int, at row: Int) -> RankItem? {
        // model检查
        guard let modelInfos = self.allItemInfos else {
             Self.logger.error("data model is empty, get itemInfo failed")
             return nil
        }
        // index越界检查
        guard section < orderedItemLists.count, row < orderedItemLists[section].count else {
            // swiftlint:disable line_length
            Self.logger.error("section(\(section)) or row(\(row)) out bounds of data model(sections: \(orderedItemLists.count), get itemInfo failed")
            // swiftlint:enable line_length
            return nil
        }
        // 获取itemInfo
        let appId: String = orderedItemLists[section][row]
        if let appInfo = modelInfos[appId] {
            return appInfo  // 此处为高频调用，不建议log
        } else {
            Self.logger.error("get app info failed with appId:\(appId)")
            return nil
        }
    }
    /// 获取item的tag类型
    /// tag 显示规则：
    /// 1. 管理员推荐标签默认不显示（因为老版工作台设置页面已经分组标题已经显示了）
    /// 2. 「共享应用」优先显示，高于其他类型
    /// 3. 其他类型（如有）默认显示：widget，bot
    /// 4. bookmark 线上没有用到，默认不显示了
    ///
    /// - Parameters:
    ///   - section: cell所在的分组
    ///   - itemInfo: cell的信息数据
    func getTagType(section: Int, itemInfo: RankItem) -> WPCellTagType {
        //  关联组织
        if (itemInfo.isSharedByOtherOrganization ?? false) && itemInfo.sharedSourceTenantInfo != nil {
            return .shared
        }

        // 小组件（block）
        if itemInfo.block != nil {
            return .block
        }

        // 小组件（widget）
        if section == commonWidgetSection {
            return .block
        }

        // bot
        if itemInfo.isPureBot() {
            return .bot
        }

        // 其他情况，隐藏 tag，包括推荐
        return .none
    }
}
