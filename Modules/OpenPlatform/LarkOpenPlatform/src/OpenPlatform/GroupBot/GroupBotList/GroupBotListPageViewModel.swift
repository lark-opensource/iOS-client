//
//  GroupBotListPageViewModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import LKCommonsLogging

/// 「群机器人」viewModel
class GroupBotListPageViewModel {
    static let logger = Logger.oplog(GroupBotListPageViewModel.self, category: GroupBotDefines.groupBotLogCategory)

    /// 可用应用list
    var availableList: [GroupBotListPageCellViewModel]?
    /// 业务数据集
    var dataList: [[GroupBotListPageCellViewModel]] = [[]]
    /// 业务数据集组数
    private(set) var dataListGroup: Int = 0

    init(dataModel: GroupBotListPageDataModel) {
        self.availableList = convertDataToViewModels(dataModel.bots)
        setupData()
    }

    func convertDataToViewModels(_ models: [GroupBotModel]?) -> [GroupBotListPageCellViewModel]? {
        guard let models = models else {
            return nil
        }
        var vms: [GroupBotListPageCellViewModel] = []
        for model in models {
            let vm = GroupBotListPageCellViewModel(dataModel: model)
            vms.append(vm)
        }
        return vms
    }

    /// 组装数据集
    private func setupData() {
        /// 清空数据
        dataList.removeAll()
        /// 根据业务组装数据
        /// 位置由业务需求决定（可用列表，不可用列表）
        if (availableList?.count ?? 0) == 0 {
            Self.logger.warn("add bot page has no data")
        }
        dataList.append(availableList ?? [])
        dataListGroup = dataList.count
    }

    /// 获取数据分组的数量
    func getDataGroupCount() -> Int {
        return dataListGroup
    }

    /// 获取指定位置的数据分组
    func getDataGroup(in index: Int) -> [GroupBotListPageCellViewModel] {
        if index >= 0 && index < dataList.count {
            return dataList[index]
        } else {
            /// cell的错误使用所致，打异常log
            Self.logger.error("get data group info failed with index:\(index)")
            return []
        }
    }

    /// 获取附加安全距离
    func getBottomSafeInset(at section: Int) -> CGFloat {
        if section == dataListGroup - 1 {
            return 10.0  // 最后一个seciton添加底部安全距离
        } else {
            return 0
        }
    }
}
