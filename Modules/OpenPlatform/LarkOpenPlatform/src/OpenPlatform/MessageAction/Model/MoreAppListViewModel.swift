//
//  MoreAppListViewModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/8.
//

import LarkReleaseConfig
import EENavigator
import LarkOPInterface
import LarkAppLinkSDK

/// Message Action和加号菜单更多应用列表页数据展示模式
enum MoreAppListSectionMode: Int {
    /// 常用AppList
    case externalList = 0
    /// 可用AppList
    case availabelList = 1
}

/// Message Action和加号菜单更多应用列表页数据状态
struct MoreAppListDataStyle: OptionSet {
    let rawValue: Int

    /// 只有外露常用AppList
    static let hasExternalList = MoreAppListDataStyle(rawValue: 1 << 0)
    /// 只有可用AppList
    static let hasAvailabeList = MoreAppListDataStyle(rawValue: 1 << 1)
    /// 常用和可用AppList都存在
    static let hasBothList: MoreAppListDataStyle = [.hasExternalList, .hasAvailabeList]
}

/// Message Action和加号菜单更多应用列表页ViewModel
/// 1. 负责请求常用应用列表和可用应用列表数据，处理为可直接显示到视图上的可展示数据
/// 2. 响应用户拖动常用应用列表条目，更新用户常用应用列表配置
class MoreAppListViewModel {
    /// 业务场景标记
    let bizScene: BizScene
    /// applink from scene
    let fromScene: FromScene
    /// 原始数据
    var data: MoreAppAllItemListModel
    /// 业务数据集
    var sectionDataList: [[MoreAppListCellViewModel]] = [[]]
    /// 业务数据集组数
    var sectionCount: Int = 0
    /// 更多应用列表页数据状态
    private(set) var dataStyle: MoreAppListDataStyle = []

    init(
        bizScene: BizScene,
        fromScene: FromScene,
        data: MoreAppAllItemListModel
    ) {
        self.bizScene = bizScene
        self.fromScene = fromScene
        self.data = data
        setupData()
    }

    func reorderData() {
        setupData()
    }

    func setupData() {
        /// 清空数据
        sectionDataList.removeAll()
        sectionCount = 0
        /// 根据业务组装数据
        var externalItemViewModels: [MoreAppListCellViewModel] = []
        if let externalItemList = data.externalItemListModel.externalItemList {
            externalItemViewModels = transformDataListToViewModelList(externalItemList, sectionMode: .externalList)
        }
        sectionDataList.append(externalItemViewModels)
        let isExternalItemListExsit = !(externalItemViewModels.isEmpty)

        var availableItemViewModels: [MoreAppListCellViewModel] = []
        if let availableItemList = data.availableItemListModel.availableItemList {
            availableItemViewModels = transformDataListToViewModelList(availableItemList, sectionMode: .availabelList)
        }
        sectionDataList.append(availableItemViewModels)
        let isAvailableListExsit = !(availableItemViewModels.isEmpty)

        dataStyle = []
        if isExternalItemListExsit {
            dataStyle.insert(.hasExternalList)
        }

        if isAvailableListExsit {
            dataStyle.insert(.hasAvailabeList)
        }

        sectionCount = sectionDataList.count
    }

    func transformDataListToViewModelList(_ dataList: [MoreAppItemModel], sectionMode: MoreAppListSectionMode) -> [MoreAppListCellViewModel] {
        return dataList.map { MoreAppListCellViewModel(bizScene: bizScene, sectionMode: sectionMode, dataModel: $0) }
    }

    /// 判断业务数据是否为空
    func isDataEmpty() -> Bool {
        return
            (data.externalItemListModel.externalItemList?.count ?? 0) == 0
            &&
            (data.availableItemListModel.availableItemList?.count ?? 0) == 0
    }

    /// 是否具有外露常用应用列表
    var hasExternalItemList: Bool {
        return dataStyle.contains(.hasExternalList)
    }

    /// 推荐应用个数是否超过1
    var externalItemListCountGreaterThan1: Bool {
        return (data.externalItemListModel.externalItemList?.count ?? 0) > 1
    }

    /// 是否具有可用应用列表
    var hasAvailabeItemList: Bool {
        return dataStyle.contains(.hasAvailabeList)
    }

    /// 获取数据分组的数量
    func getSectionCount() -> Int {
        return sectionCount
    }

    /// 获取指定位置的数据分组
    func getSectionDataList(in section: Int) -> [MoreAppListCellViewModel] {
        if section < sectionDataList.count {
            return sectionDataList[section]
        } else {
            /// celler的错误使用所致，先打异常log
            GuideIndexPageVCLogger.error("get data group info failed with section:\(section)")
            return []
        }
    }
}

/// Message Action和加号菜单索引页更多应用列表页cell的viewModel
class MoreAppListCellViewModel {
    /// 业务场景
    let bizScene: BizScene
    /// 原始数据
    let data: MoreAppItemModel
    /// 数据展示模式
    let sectionMode: MoreAppListSectionMode
    /// 跳转获取应用附加字段
    static let fromKey: String = "fromlark"
    static let fromValue: String = "open"

    init(bizScene: BizScene, sectionMode: MoreAppListSectionMode, dataModel: MoreAppItemModel) {
        self.bizScene = bizScene
        self.sectionMode = sectionMode
        self.data = dataModel
    }

    /// 根据业务场景，获取title栏内容
    func getTitleText() -> String {
        switch bizScene {
        case .addMenu:
            return data.name ?? ""
        case .msgAction:
            return data.actionName ?? ""
        }
    }

    /// 根据业务场景，获取描述栏内容
    func getDescText() -> String {
        let intro = BundleI18n.MessageAction.Lark_OpenPlatform_ScIntroTtl
        let none = BundleI18n.MessageAction.Lark_OpenPlatform_NoneDesc
        guard let desc = data.itemDesc, !desc.isEmpty else {
            return intro + none
        }
        return intro + desc
    }

    /// 根据业务场景，获取更多描述栏内容
    func getMoreDescText() -> String {
        switch bizScene {
        case .addMenu:
            // 了解更多
            return BundleI18n.MessageAction.Lark_OpenPlatform_ScViewMoreDetailsBttn
        case .msgAction:
            let title = BundleI18n.MessageAction.Lark_OpenPlatform_ScAppTtl
            guard let name = data.name, !name.isEmpty else {
                return title
            }
            // 应用：{{appName}}
            return title + name
        }
    }
}
