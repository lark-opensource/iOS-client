//
//  AddBotPageViewModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import LKCommonsLogging

/// 「添加机器人」viewModel
class AddBotPageViewModel {
    static let logger = Logger.oplog(AddBotPageViewModel.self, category: GroupBotDefines.groupBotLogCategory)

    /// 可用应用list
    var availableList: [AddBotPageCellViewModel]?
    /// 不可用的list
    var unavailableList: [AddBotPageCellViewModel]?
    /// 业务数据集
    var dataList: [[AddBotPageCellViewModel]] = [[]]
    /// 业务数据集组数
    private(set) var dataListGroupCount: Int = 0

    init(dataModel: AddBotPageDataModel) {
        self.availableList = convertDataToViewModels(dataModel.bots, isRecommended: false)
        self.unavailableList = convertDataToViewModels(dataModel.recommendBots, isRecommended: true)
        setupData()
    }

    func convertDataToViewModels(_ models: [AbstractBotModel]?, isRecommended: Bool) -> [AddBotPageCellViewModel]? {
        guard let models = models else {
            return nil
        }

        var vms: [AddBotPageCellViewModel] = []
        for model in models {
            if shouldFilterIfNewWebhookBot(model: model, isRecommended: isRecommended) {
                continue
            }
            let vm = AddBotPageCellViewModel(dataModel: model, isRecommended: isRecommended)
            vms.append(vm)
        }
        return vms
    }

    /// 一期不支持新建webhook机器人，故需要过滤掉包含function_bot_id的机器人
    /// 已与后端@zhanghangming确认，在「添加机器人」页面包含function_bot_id的机器人就是待新建的webhook机器人
    func shouldFilterIfNewWebhookBot(model: AbstractBotModel, isRecommended: Bool) -> Bool {
        if isRecommended {
            return false
        }
        guard let model = model as? GroupBotModel else {
            return false
        }
        guard let functionalBotID = model.functionalBotID, !(functionalBotID.isEmpty) else {
            return false
        }
        Self.logger.info("filter new webhook bot: \(model)")
        return true
    }

    /// 组装数据集
    private func setupData() {
        /// 清空数据
        dataList.removeAll()
        /// 根据业务组装数据
        /// 位置由业务需求决定（可用列表，不可用列表）
        if (availableList?.count ?? 0) == 0 && (unavailableList?.count ?? 0) == 0 {
            Self.logger.error("add bot page has no data")
        }
        dataList.append(availableList ?? [])
        dataList.append(unavailableList ?? [])
        dataListGroupCount = dataList.count
    }

    /// 获取数据分组的数量
    func getDataGroupCount() -> Int {
        return dataListGroupCount
    }

    /// 获取指定位置的数据分组
    func getDataGroup(in index: Int) -> [AddBotPageCellViewModel] {
        if index >= 0 && index < dataList.count {
            return dataList[index]
        } else {
            /// cell的错误使用所致，打异常log
            Self.logger.error("get data group info failed with index:\(index)")
            return []
        }
    }

    /// 判断指定分组数据是否为空
    func isDataEmpty(at section: Int) -> Bool {
        let isDataEmpty = getDataGroup(in: section).isEmpty
        return isDataEmpty
    }

    /// 判断指定分组是否展示header
    func isShowHeader(at section: Int) -> Bool {
        return !isDataEmpty(at: section) && (section == 1)
    }

    /// 获取附加安全距离
    func getBottomSafeInset(at section: Int) -> CGFloat {
        if section == dataListGroupCount - 1 {
            return 10.0  // 最后一个seciton添加底部安全距离
        } else {
            return 0
        }
    }
}
